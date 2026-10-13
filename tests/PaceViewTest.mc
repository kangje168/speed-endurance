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
