import QtQuick
import Quickshell
import Quickshell.Io
import "services"
import "modules/bar"
import "modules/notifications"

ShellRoot {
    id: root

    // ==========================================
    // IPC HANDLER: Main Bar Module Control
    // ==========================================
    IpcHandler {
        target: "bar"

        function toggle(name: string): string {
            var targetModule = name.trim().toLowerCase();
            var matched = false;

            for (var i = 0; i < screenVariants.instances.length; i++) {
                var bar = screenVariants.instances[i];
                if (!bar) continue;

                var isTarget = SwayService.focusedOutputName !== ""
                    ? (bar.screen && bar.screen.name === SwayService.focusedOutputName)
                    : (i === 0);

                if (isTarget) {
                    matched = true;
                    if (bar.activeModule === targetModule) {
                        bar.activeModule = "";
                    } else {
                        bar.activeModule = targetModule;
                    }
                } else {
                    bar.activeModule = "";
                }
            }

            if (!matched && screenVariants.instances.length > 0) {
                var firstBar = screenVariants.instances[0];
                if (firstBar) {
                    firstBar.activeModule = (firstBar.activeModule === targetModule) ? "" : targetModule;
                }
            }
            return "OK";
        }

        function close(): string {
            for (var i = 0; i < screenVariants.instances.length; i++) {
                var bar = screenVariants.instances[i];
                if (bar) bar.activeModule = "";
            }
            return "Closed";
        }
    }

    // ==========================================
    // IPC HANDLER: Screenshot Toast Control
    // ==========================================
    IpcHandler {
        target: "screenshot"

        function display(path: string): string {
            ScreenshotService.showToast(path);
            return "OK";
        }

        function hide(): string {
            ScreenshotService.hideToast();
            return "OK";
        }
    }

    // ==========================================
    // MULTI-MONITOR FLOATING BAR INSTANCES
    // ==========================================
    Variants {
        id: screenVariants
        model: Quickshell.screens

        delegate: BarWindow {}
    }

    // ==========================================
    // FLOATING SCREENSHOT TOAST INSTANCES
    // ==========================================
    Variants {
        model: Quickshell.screens

        delegate: ScreenshotToast {}
    }
}
