using Toybox.Application;
using Toybox.Activity;
using Toybox.ActivityRecording;
using Toybox.Attention;
using Toybox.Lang;
using Toybox.Position;
using Toybox.Sensor;
using Toybox.System;
using Toybox.Time;
using Toybox.Timer;
using Toybox.WatchUi;

class TrainingController {
    var engine as TrainingEngine;
    var timer as Timer.Timer;
    var session = null;
    var speed = null;
    var fixValid = false;
    var fixAt = null;
    var fixQuality = Position.QUALITY_NOT_AVAILABLE;
    var hasLocation = false;
    var page = 0;
    var heartRate = null;
    var heartRateAt = null;
    var completedRunMs = 0;
    var best as Lang.Dictionary;
    var history as Lang.Array;
    var pendingRest as Lang.Dictionary or Null = null;
    var notice = "Waiting for GPS";
    var noticeUntil = 0;
    var closed = false;
    var showHistory = false;
    var historyIndex = 0;
    var recordingError = false;
    var checkpointAt = 0;

    function initialize() {
        engine = new TrainingEngine();
        timer = new Timer.Timer();
        best = Application.Storage.getValue("best_v1");
        history = Application.Storage.getValue("history_v1");
        if (!(best instanceof Lang.Dictionary)) { best = {}; }
        if (!(history instanceof Lang.Array)) { history = []; }
        var cleanHistory = [];
        for (var i = 0; i < history.size(); i += 1) {
            var record = history[i];
            if (record instanceof Lang.Dictionary && record["pace"] instanceof Lang.Number &&
                record["run"] instanceof Lang.Number && record["rest"] instanceof Lang.Number &&
                record["pace"] >= 165 && record["pace"] <= 330 && record["pace"] % 15 == 0 &&
                record["run"] >= 0 && record["rest"] >= 0) {
                cleanHistory.add(record);
            }
        }
        history = cleanHistory;
        if (history.size() > 40) { history = history.slice(history.size() - 40, history.size()); }
        var cleanBest = {};
        for (var pace = 165; pace <= 330; pace += 15) {
            var value = best[pace.toString()];
            if (value instanceof Lang.Number && value >= 0) { cleanBest[pace.toString()] = value; }
        }
        best = cleanBest;
        var target = Application.Storage.getValue("target_v1");
        if (target instanceof Lang.Number && target >= 165 && target <= 330 && target % 15 == 0) {
            engine.target = target;
        }
    }

    function open() {
        var options = { :acquisitionType => Position.LOCATION_CONTINUOUS };
        if (Position has :hasConfigurationSupport) {
            if ((Position has :CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1_L5) &&
                Position.hasConfigurationSupport(Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1_L5)) {
                options[:configuration] = Position.CONFIGURATION_GPS_GLONASS_GALILEO_BEIDOU_L1_L5;
            }
        }
        Position.enableLocationEvents(options, method(:onPosition));
        Sensor.setEnabledSensors([Sensor.SENSOR_HEARTRATE]);
        Sensor.enableSensorEvents(method(:onSensor));
        timer.start(method(:onTick), 1000, true);
    }

    function onSensor(info as Sensor.Info) as Void {
        heartRate = info.heartRate;
        heartRateAt = System.getTimer();
    }

    function onPosition(info as Position.Info) as Void {
        speed = info.speed;
        fixQuality = info.accuracy;
        hasLocation = info.position != null;
        fixValid = info.accuracy >= Position.QUALITY_USABLE && speed != null && speed >= 0;
        fixAt = System.getTimer();
        if (!fixValid && engine.state == TrainingEngine.RUNNING) {
            engine.tick(fixAt, null, false);
        }
    }

    function gpsReady(now) {
        return fixValid && fixAt != null && now - fixAt <= 2500;
    }

    function canStart(now) {
        return hasLocation && fixQuality >= Position.QUALITY_POOR && fixAt != null && now - fixAt <= 5000;
    }

    function gpsStatus(now) {
        if (fixAt == null) { return "GPS: searching"; }
        if (now - fixAt > 5000) { return "GPS: stale"; }
        if (!hasLocation || fixQuality < Position.QUALITY_POOR) { return "GPS: searching"; }
        if (fixQuality < Position.QUALITY_USABLE) { return "GPS: weak"; }
        if (speed == null || speed < 0) { return "Speed: waiting"; }
        return "GPS: ready";
    }

    function onTick() as Void {
        var now = System.getTimer();
        var action = engine.tick(now, speed, gpsReady(now));
        if (pendingRest != null) {
            pendingRest["rest"] = ((now - engine.restStart) / 1000).toNumber();
            if (now - checkpointAt >= 10000) { persist(); checkpointAt = now; }
        }
        if (recordingError) { pauseRecording(); }
        if (action == "slow_stop") {
            finishRun("slow");
            alert("Too slow - rest");
        } else if (action == "rest_warning") {
            alert("Rest over 3 min");
        } else if (action == "rest_exit") {
            finishRest(now);
            saveAndExit();
            return;
        }
        WatchUi.requestUpdate();
    }

    function startOrStop() {
        if (showHistory) { showHistory = false; WatchUi.requestUpdate(); return; }
        var now = System.getTimer();
        if (engine.state == TrainingEngine.FINISHED) { saveAndExit(); return; }
        // Enforce rest deadline even if a key arrives before the timer callback.
        if (engine.state == TrainingEngine.RESTING && now - engine.restStart >= 300000) {
            finishRest(now);
            saveAndExit();
            return;
        }
        if (engine.state == TrainingEngine.RUNNING) {
            if (!gpsReady(now)) { engine.recordEligible = false; }
            engine.stopRun(now);
            finishRun("manual");
            alert("Stopped - rest");
        } else if (engine.state == TrainingEngine.READY || engine.state == TrainingEngine.RESTING) {
            if (!canStart(now)) { alert(gpsStatus(now)); return; }
            if (recordingError) { alert("FIT stop failed"); return; }
            try {
                if (session == null) {
                    session = ActivityRecording.createSession({
                        :name => "Speed Endurance", :sport => Activity.SPORT_RUNNING
                    });
                }
                if (!session.start()) { alert("Cannot start FIT"); return; }
            } catch (error) {
                alert("Cannot start FIT");
                return;
            }
            finishRest(now);
            engine.start(now);
            engine.tick(now, speed, gpsReady(now));
            notice = "";
        }
        WatchUi.requestUpdate();
    }

    function finishRun(reason) {
        page = 0;
        completedRunMs += engine.lastDuration;
        if (session != null && session.isRecording()) {
            try { session.addLap(); } catch (error) { System.println("FIT lap failed"); }
            pauseRecording();
        }
        var key = engine.target.toString();
        var duration = (engine.lastDuration / 1000).toNumber();
        var eligible = engine.recordEligible && engine.reachedTarget;
        if (eligible && (best[key] == null || duration > best[key])) {
            best[key] = duration;
            Application.Storage.setValue("best_v1", best);
        }
        pendingRest = {
            "pace" => engine.target, "run" => duration, "rest" => 0,
            "date" => Time.now().value(), "reason" => reason, "eligible" => eligible
        };
        history.add(pendingRest);
        // Bound memory/storage consumption on the watch.
        if (history.size() > 40) { history = history.slice(1, history.size()); }
        if (historyIndex < 0 || historyIndex >= history.size()) { historyIndex = history.size() - 1; }
        checkpointAt = System.getTimer();
        persist();
    }

    function pauseRecording() {
        if (session == null) { recordingError = false; return true; }
        try {
            if (!session.isRecording() || session.stop()) { recordingError = false; return true; }
        } catch (error) { System.println("FIT stop failed"); }
        recordingError = true;
        notice = "FIT stop failed";
        noticeUntil = System.getTimer() + 5000;
        return false;
    }

    function finishRest(now) {
        if (pendingRest != null) {
            pendingRest["rest"] = ((now - engine.restStart) / 1000).toNumber();
            pendingRest = null;
            persist();
        }
    }

    function change(delta) {
        if (showHistory) {
            if (history.size() > 0) {
                historyIndex = (historyIndex + (delta < 0 ? 1 : -1) + history.size()) % history.size();
            }
        } else if (engine.state == TrainingEngine.RUNNING) {
            page = 1 - page;
        } else {
            engine.selectTarget(delta);
            Application.Storage.setValue("target_v1", engine.target);
        }
        WatchUi.requestUpdate();
    }

    function menu() {
        showHistory = !showHistory;
        historyIndex = history.size() > 0 ? history.size() - 1 : 0;
        WatchUi.requestUpdate();
    }

    function back() {
        if (showHistory) { showHistory = false; WatchUi.requestUpdate(); }
        else if (engine.state == TrainingEngine.RUNNING) { startOrStop(); }
        else { saveAndExit(); }
    }

    function alert(message) {
        notice = message;
        noticeUntil = System.getTimer() + 5000;
        if (Attention has :vibrate) {
            Attention.vibrate([new Attention.VibeProfile(100, 500), new Attention.VibeProfile(0, 200), new Attention.VibeProfile(100, 500)]);
        }
        if (Attention has :playTone) { Attention.playTone(Attention.TONE_ALERT_HI); }
    }

    function persist() { Application.Storage.setValue("history_v1", history); }

    function close() {
        if (closed) { return true; }
        timer.stop();
        var now = System.getTimer();
        if (engine.state == TrainingEngine.RUNNING) {
            if (!gpsReady(now)) { engine.recordEligible = false; }
            engine.stopRun(now);
            finishRun("exit");
        }
        finishRest(now);
        if (session != null) {
            if (!pauseRecording()) { alert("FIT stop failed"); return false; }
            try {
                if (!session.save()) { alert("FIT save failed"); return false; }
            } catch (error) { alert("FIT save failed"); return false; }
            session = null;
        }
        closed = true;
        Position.enableLocationEvents(Position.LOCATION_DISABLE, null);
        Sensor.enableSensorEvents(null);
        persist();
        return true;
    }

    function saveAndExit() {
        if (close()) { System.exit(); }
        else { timer.start(method(:onTick), 1000, true); WatchUi.requestUpdate(); }
    }
}
