// Pure state machine: all timestamps are monotonic milliseconds.
class TrainingEngine {
    static const READY = 0;
    static const RUNNING = 1;
    static const RESTING = 2;
    static const FINISHED = 3;
    var state = READY;
    var target = 330;
    var runStart = 0;
    var restStart = 0;
    var slowSince = null;
    var previousSample = null;
    var restWarned = false;
    var elapsed = 0;
    var restElapsed = 0;
    var lastDuration = 0;
    var reachedTarget = false;
    var recordEligible = true;

    function initialize() {}

    function selectTarget(delta) {
        if (state != RUNNING && state != FINISHED) {
            target = target + delta;
            if (target < 165) { target = 165; }
            if (target > 330) { target = 330; }
        }
    }

    function start(now) {
        if (state != READY && state != RESTING) { return false; }
        state = RUNNING;
        runStart = now;
        elapsed = 0;
        slowSince = null;
        previousSample = null;
        reachedTarget = false;
        recordEligible = true;
        return true;
    }

    // Returns a one-shot action consumed by the controller.
    function tick(now, speed, valid) {
        if (state == RUNNING) {
            elapsed = now - runStart;
            if (!valid || (previousSample != null && now - previousSample > 2500)) {
                slowSince = null;
                recordEligible = false;
            }
            previousSample = now;
            if (!valid) { return null; }
            if (speed * target >= 1000.0) {
                reachedTarget = true;
                slowSince = null;
            } else {
                if (slowSince == null) { slowSince = now; }
                if (now - slowSince >= 60000) {
                    stopRun(now);
                    return "slow_stop";
                }
            }
        } else if (state == RESTING) {
            restElapsed = now - restStart;
            if (restElapsed >= 300000) {
                state = FINISHED;
                return "rest_exit";
            }
            if (restElapsed > 180000 && !restWarned) {
                restWarned = true;
                return "rest_warning";
            }
        }
        return null;
    }

    function stopRun(now) {
        if (state != RUNNING) { return false; }
        if (previousSample == null || now - previousSample > 2500) { recordEligible = false; }
        elapsed = now - runStart;
        lastDuration = elapsed;
        state = RESTING;
        restStart = now;
        restElapsed = 0;
        restWarned = false;
        slowSince = null;
        return true;
    }
}
