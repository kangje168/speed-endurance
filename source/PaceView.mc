using Toybox.Graphics;
using Toybox.Lang;
using Toybox.System;
using Toybox.WatchUi;

function formatTime(seconds) {
    var value = seconds.toNumber();
    return (value / 60).toNumber().toString() + ":" + (value % 60).format("%02d");
}

class PaceView extends WatchUi.View {
    var c as TrainingController;
    function initialize(controller) { View.initialize(); c = controller; }

    function line(dc, y, text, font, color) {
        dc.setColor(color, Graphics.COLOR_BLACK);
        dc.drawText(dc.getWidth() / 2, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var h = dc.getHeight();
        var e = c.engine;
        var now = System.getTimer();
        if (c.showHistory) {
            line(dc, h * 0.12, "HISTORY", Graphics.FONT_SMALL, Graphics.COLOR_GREEN);
            if (c.history.size() == 0) {
                line(dc, h * 0.4, "No runs yet", Graphics.FONT_SMALL, Graphics.COLOR_WHITE);
            } else {
                var r = c.history[c.historyIndex] as Lang.Dictionary;
                line(dc, h * 0.27, formatTime(r["pace"]) + " /km", Graphics.FONT_MEDIUM, Graphics.COLOR_WHITE);
                line(dc, h * 0.44, "Run " + formatTime(r["run"]), Graphics.FONT_SMALL, Graphics.COLOR_WHITE);
                line(dc, h * 0.58, "Rest " + formatTime(r["rest"]), Graphics.FONT_SMALL, Graphics.COLOR_WHITE);
                line(dc, h * 0.73, (c.historyIndex + 1).toString() + "/" + c.history.size().toString(), Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY);
            }
            return;
        }
        if (c.page == 1) {
            var hr = c.heartRate != null && c.heartRateAt != null && now - c.heartRateAt <= 5000 ? c.heartRate.toString() : "--";
            line(dc, h * 0.10, "HEART RATE", Graphics.FONT_SMALL, Graphics.COLOR_GREEN);
            line(dc, h * 0.23, hr + " bpm", Graphics.FONT_LARGE, Graphics.COLOR_WHITE);
            line(dc, h * 0.43, "Run " + formatTime(e.elapsed / 1000), Graphics.FONT_SMALL, Graphics.COLOR_WHITE);
            var total = c.completedRunMs + (e.state == TrainingEngine.RUNNING ? e.elapsed : 0);
            line(dc, h * 0.57, "Total " + formatTime(total / 1000), Graphics.FONT_SMALL, Graphics.COLOR_WHITE);
            var clock = System.getClockTime();
            line(dc, h * 0.70, clock.hour.format("%02d") + ":" + clock.min.format("%02d"), Graphics.FONT_SMALL, Graphics.COLOR_YELLOW);
            line(dc, h * 0.81, "UP/DOWN: page", Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY);
            return;
        }
        var label = "SELECT PACE";
        if (e.state == TrainingEngine.RUNNING) { label = "RUNNING"; }
        if (e.state == TrainingEngine.RESTING) { label = "REST"; }
        if (e.state == TrainingEngine.FINISHED) { label = "FINISHED"; }
        line(dc, h * 0.10, label, Graphics.FONT_SMALL, Graphics.COLOR_GREEN);
        line(dc, h * 0.23, "Target " + formatTime(e.target) + "/km", Graphics.FONT_SMALL, Graphics.COLOR_WHITE);
        var main = formatTime(e.target);
        if (e.state == TrainingEngine.RUNNING) { main = formatTime(e.elapsed / 1000); }
        if (e.state == TrainingEngine.RESTING || e.state == TrainingEngine.FINISHED) {
            main = formatTime(e.restElapsed / 1000);
        }
        line(dc, h * 0.37, main, Graphics.FONT_LARGE, Graphics.COLOR_WHITE);
        var detail = c.gpsStatus(now);
        if (c.gpsReady(now)) {
            detail = "Pace " + (c.speed > 0 ? formatTime(1000.0 / c.speed) : "--:--");
        }
        if (e.state == TrainingEngine.RUNNING && e.slowSince != null) {
            detail = "Slow " + ((now - e.slowSince) / 1000).toNumber().toString() + "/60s";
        }
        if (e.state == TrainingEngine.RESTING) {
            detail = "Last " + formatTime(e.lastDuration / 1000);
        }
        line(dc, h * 0.57, detail, Graphics.FONT_SMALL, Graphics.COLOR_YELLOW);
        var record = c.best[e.target.toString()];
        line(dc, h * 0.70, "Best " + (record == null ? "--:--" : formatTime(record)), Graphics.FONT_XTINY, Graphics.COLOR_LT_GRAY);
        var footer = e.state == TrainingEngine.RUNNING ? "START: stop" : "START: run";
        if (e.state == TrainingEngine.FINISHED) { footer = "START: save"; }
        if (now < c.noticeUntil) { footer = c.notice; }
        line(dc, h * 0.81, footer, Graphics.FONT_XTINY, Graphics.COLOR_WHITE);
    }
}

class PaceDelegate extends WatchUi.BehaviorDelegate {
    var c as TrainingController;
    function initialize(controller) { BehaviorDelegate.initialize(); c = controller; }
    function onSelect() { c.startOrStop(); return true; }
    function onBack() { c.back(); return true; }
    function onPreviousPage() { c.change(-15); return true; }
    function onNextPage() { c.change(15); return true; }
    function onMenu() { c.menu(); return true; }
}
