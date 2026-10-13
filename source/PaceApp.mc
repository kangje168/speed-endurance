using Toybox.Application;
using Toybox.WatchUi;

class PaceApp extends Application.AppBase {
    var controller as TrainingController;
    function initialize() {
        AppBase.initialize();
        controller = new TrainingController();
    }
    function onStart(state) { controller.open(); }
    function onStop(state) { controller.close(); }
    function getInitialView() {
        return [new PaceView(controller), new PaceDelegate(controller)];
    }
}
