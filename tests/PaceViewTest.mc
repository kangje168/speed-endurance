using Toybox.Graphics;
using Toybox.System;
using Toybox.Test;

(:test)
function renderAllScreensWithoutRuntimeErrors(logger) {
    var settings = System.getDeviceSettings();
    var bitmap = Graphics.createBufferedBitmap({
        :width => settings.screenWidth, :height => settings.screenHeight
    });
    var surface = bitmap.get();
    Test.assert(surface != null);
    var dc = surface.getDc();
    var c = new TrainingController();
    c.history = [];
    c.best = {};
    var view = new PaceView(c);
    view.onUpdate(dc);
    c.showHistory = true;
    view.onUpdate(dc);
    c.showHistory = false;
    var now = System.getTimer();
    c.engine.start(now);
    c.engine.tick(now, 2.0, true);
    view.onUpdate(dc);
    c.page = 1;
    view.onUpdate(dc);
    c.heartRate = 145;
    c.heartRateAt = now;
    view.onUpdate(dc);
    c.page = 0;
    c.engine.stopRun(now + 60000);
    view.onUpdate(dc);
    c.history = [{"pace" => 330, "run" => 600, "rest" => 180}];
    c.historyIndex = 0;
    c.showHistory = true;
    view.onUpdate(dc);
    c.showHistory = false;
    c.engine.tick(now + 360000, null, false);
    view.onUpdate(dc);
    Test.assertEqual(c.engine.state, TrainingEngine.FINISHED);
    return true;
}

(:test)
function gpsStartGateAndPageNavigation(logger) {
    var c = new TrainingController();
    c.fixAt = 1000;
    c.hasLocation = true;
    c.fixQuality = Toybox.Position.QUALITY_POOR;
    c.speed = null;
    c.fixValid = false;
    Test.assert(c.canStart(2000));
    Test.assert(!c.gpsReady(2000));
    Test.assert(!c.canStart(6001));
    c.hasLocation = false;
    Test.assert(!c.canStart(2000));
    c.hasLocation = true;
    c.fixQuality = Toybox.Position.QUALITY_NOT_AVAILABLE;
    Test.assert(!c.canStart(2000));
    c.engine.start(1000);
    var target = c.engine.target;
    c.change(-15);
    Test.assertEqual(c.page, 1);
    Test.assertEqual(c.engine.target, target);
    c.change(15);
    Test.assertEqual(c.page, 0);
    c.engine.stopRun(2000);
    c.change(-15);
    Test.assertEqual(c.engine.target, target - 15);
    return true;
}
