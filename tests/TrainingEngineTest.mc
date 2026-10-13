using Toybox.Test;

(:test)
function slowSixtySeconds(logger) {
    var e = new TrainingEngine();
    e.start(0);
    for (var t = 0; t < 60000; t += 1000) {
        Test.assert(e.tick(t, 2.0, true) == null);
    }
    Test.assertEqual(e.tick(60000, 2.0, true), "slow_stop");
    Test.assertEqual(e.lastDuration, 60000);
    Test.assertEqual(e.state, TrainingEngine.RESTING);
    Test.assert(e.tick(61000, 2.0, true) == null);
    return true;
}

(:test)
function recoveryResetsCountdown(logger) {
    var e = new TrainingEngine();
    e.start(0);
    for (var t = 0; t <= 59000; t += 1000) { e.tick(t, 2.0, true); }
    e.tick(60000, 4.0, true);
    Test.assert(e.slowSince == null);
    for (var t = 61000; t < 121000; t += 1000) {
        Test.assert(e.tick(t, 2.0, true) == null);
    }
    Test.assertEqual(e.tick(121000, 2.0, true), "slow_stop");
    return true;
}

(:test)
function gpsLossIsNotSlow(logger) {
    var e = new TrainingEngine();
    e.start(0);
    for (var t = 0; t < 59000; t += 1000) { e.tick(t, 2.0, true); }
    Test.assert(e.tick(59000, null, false) == null);
    Test.assert(e.slowSince == null);
    Test.assertEqual(e.recordEligible, false);
    for (var t = 60000; t < 120000; t += 1000) {
        Test.assert(e.tick(t, 2.0, true) == null);
    }
    Test.assertEqual(e.tick(120000, 2.0, true), "slow_stop");
    return true;
}

(:test)
function restBoundaries(logger) {
    var e = new TrainingEngine();
    e.start(0);
    e.stopRun(10000);
    Test.assert(e.tick(190000, null, false) == null);
    Test.assertEqual(e.tick(191000, null, false), "rest_warning");
    Test.assert(e.tick(192000, null, false) == null);
    Test.assert(e.tick(309999, null, false) == null);
    Test.assertEqual(e.tick(310000, null, false), "rest_exit");
    Test.assert(e.tick(311000, null, false) == null);
    return true;
}

(:test)
function stoppedRunnerCountsAsSlow(logger) {
    var e = new TrainingEngine();
    e.start(0);
    for (var t = 0; t < 60000; t += 1000) { e.tick(t, 0.0, true); }
    Test.assertEqual(e.tick(60000, 0.0, true), "slow_stop");
    Test.assertEqual(e.reachedTarget, false);
    return true;
}

(:test)
function paceSelectionAndLock(logger) {
    var e = new TrainingEngine();
    for (var i = 0; i < 11; i += 1) { e.selectTarget(-15); }
    Test.assertEqual(e.target, 165);
    e.selectTarget(-15);
    Test.assertEqual(e.target, 165);
    e.start(0);
    e.selectTarget(15);
    Test.assertEqual(e.target, 165);
    e.stopRun(1000);
    for (var i = 0; i < 20; i += 1) { e.selectTarget(15); }
    Test.assertEqual(e.target, 330);
    return true;
}

(:test)
function missedSamplesResetContinuity(logger) {
    var e = new TrainingEngine();
    e.start(0);
    e.tick(0, 2.0, true);
    Test.assert(e.tick(61000, 2.0, true) == null);
    Test.assertEqual(e.slowSince, 61000);
    Test.assertEqual(e.recordEligible, false);
    return true;
}

(:test)
function nextRunResetsState(logger) {
    var e = new TrainingEngine();
    e.start(0);
    e.tick(1000, 4.0, true);
    e.tick(2000, null, false);
    e.stopRun(5000);
    Test.assertEqual(e.start(10000), true);
    Test.assertEqual(e.elapsed, 0);
    Test.assertEqual(e.recordEligible, true);
    Test.assertEqual(e.reachedTarget, false);
    Test.assert(e.slowSince == null);
    Test.assertEqual(e.start(11000), false);
    return true;
}

(:test)
function targetEqualityCountsAsRecovery(logger) {
    var e = new TrainingEngine();
    e.target = 300;
    e.start(0);
    e.tick(0, 2.0, true);
    e.tick(1000, 1000.0 / 300, true);
    Test.assert(e.slowSince == null);
    Test.assertEqual(e.reachedTarget, true);
    return true;
}

(:test)
function slowBoundaryBeforeDeadline(logger) {
    var e = new TrainingEngine();
    e.start(0);
    for (var t = 0; t <= 59000; t += 1000) { e.tick(t, 2.0, true); }
    Test.assert(e.tick(59999, 2.0, true) == null);
    Test.assertEqual(e.state, TrainingEngine.RUNNING);
    Test.assertEqual(e.tick(60000, 2.0, true), "slow_stop");
    return true;
}

(:test)
function manuallyStoppingAfterDataGapCannotSetRecord(logger) {
    var e = new TrainingEngine();
    e.start(0);
    e.tick(0, 4.0, true);
    e.stopRun(5000);
    Test.assertEqual(e.recordEligible, false);
    return true;
}
