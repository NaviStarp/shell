pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "."

Item {
    id: service

    // ==========================================
    // SCREENSHOT TOAST STATE & ACTIONS
    // ==========================================
    property string toastPath: ""
    property bool toastVisible: false

    function showToast(path) {
        if (!path) return;
        var clean = path.trim().replace(/^file:\/\//, "");
        service.toastPath = clean;
        service.toastVisible = true;
        screenshotTimer.restart();
    }

    function hideToast() {
        service.toastVisible = false;
    }

    function editScreenshot(path) {
        var p = path || service.toastPath;
        if (!p) return;
        var clean = p.replace(/^file:\/\//, "");
        SwayService.exec("satty -f \"" + clean + "\" --early-exit --copy-command wl-copy");
        service.toastVisible = false;
    }

    function copyScreenshot(path) {
        var p = path || service.toastPath;
        if (!p) return;
        var clean = p.replace(/^file:\/\//, "");
        SwayService.exec("wl-copy --type image/png < \"" + clean + "\"");
    }

    function openFolder(path) {
        var p = path || service.toastPath;
        if (!p) return;
        var clean = p.replace(/^file:\/\//, "");
        SwayService.exec("thunar --select \"" + clean + "\" || xdg-open \"$(dirname \"" + clean + "\")\"");
        service.toastVisible = false;
    }

    Timer {
        id: screenshotTimer
        interval: 3000
        repeat: false
        onTriggered: service.toastVisible = false
    }
}
