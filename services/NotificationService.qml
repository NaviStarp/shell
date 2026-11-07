pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "."

Item {
    id: service

    // ==========================================
    // NOTIFICATION STATE & SIGNALS
    // ==========================================
    property var notificationList: []
    property var incomingNotification: null
    property bool dndEnabled: false

    signal notificationActivated(var notificationItem)

    function toggleDnd() {
        service.dndEnabled = !service.dndEnabled;
    }

    function dismissNotification(index) {
        if (index >= 0 && index < service.notificationList.length) {
            var item = service.notificationList[index];
            if (item && item.ref && typeof item.ref.dismiss === "function") {
                try { item.ref.dismiss(); } catch(e) {}
            }
            var copy = service.notificationList.slice();
            copy.splice(index, 1);
            service.notificationList = copy;
        }
    }

    function dismissNotificationById(notifId) {
        if (service.incomingNotification && service.incomingNotification.id === notifId) {
            service.incomingNotification = null;
        }
        for (var i = 0; i < service.notificationList.length; i++) {
            if (service.notificationList[i].id === notifId) {
                var item = service.notificationList[i];
                if (item && item.ref && typeof item.ref.dismiss === "function") {
                    try { item.ref.dismiss(); } catch(e) {}
                }
                var copy = service.notificationList.slice();
                copy.splice(i, 1);
                service.notificationList = copy;
                break;
            }
        }
    }

    function activateNotification(notifItem) {
        if (!notifItem) return;

        var actionInvoked = false;

        // 1. Invoke default notification action if available
        if (notifItem.actions && notifItem.actions.length > 0) {
            for (var a = 0; a < notifItem.actions.length; a++) {
                var act = notifItem.actions[a];
                if (act && (act.identifier === "default" || act.identifier === "open" || act.identifier === "activate")) {
                    try {
                        act.invoke();
                        actionInvoked = true;
                        break;
                    } catch(e) {}
                }
            }
            if (!actionInvoked && notifItem.actions.length > 0 && typeof notifItem.actions[0].invoke === "function") {
                try {
                    notifItem.actions[0].invoke();
                    actionInvoked = true;
                } catch(e) {}
            }
        }

        // 2. Bring corresponding app window to front in Sway
        var app = (notifItem.appName || notifItem.appIcon || "").toLowerCase().trim();
        var summary = (notifItem.summary || "").toLowerCase();

        if (app.includes("discord") || app.includes("vesktop") || summary.includes("discord")) {
            SwayService.exec("swaymsg '[app_id=\"(?i).*(vesktop|discord).*\"] focus' 2>/dev/null || swaymsg '[title=\"(?i).*discord.*\"] focus' 2>/dev/null");
        } else if (app.includes("zen") || app.includes("firefox") || app.includes("browser")) {
            SwayService.exec("swaymsg '[app_id=\"(?i).*(zen|firefox|chromium|chrome).*\"] focus' 2>/dev/null");
        } else if (app.includes("ghostty") || app.includes("terminal") || app.includes("kitty") || app.includes("alacritty")) {
            SwayService.exec("swaymsg '[app_id=\"(?i).*(ghostty|kitty|alacritty|foot).*\"] focus' 2>/dev/null");
        } else if (app.includes("spotify")) {
            SwayService.exec("swaymsg '[app_id=\"(?i).*spotify.*\"] focus' 2>/dev/null || swaymsg '[class=\"(?i).*spotify.*\"] focus' 2>/dev/null");
        } else if (app.includes("thunar") || app.includes("nautilus") || app.includes("file")) {
            SwayService.exec("swaymsg '[app_id=\"(?i).*(thunar|nautilus).*\"] focus' 2>/dev/null");
        } else if (app !== "" && app !== "sistema") {
            var cleanApp = app.replace(/[^a-z0-9_-]/g, "");
            SwayService.exec("swaymsg '[app_id=\"(?i).*" + cleanApp + ".*\"] focus' 2>/dev/null || swaymsg '[class=\"(?i).*" + cleanApp + ".*\"] focus' 2>/dev/null || swaymsg '[title=\"(?i).*" + cleanApp + ".*\"] focus' 2>/dev/null");
        }

        // 3. Dismiss notification
        service.dismissNotificationById(notifItem.id);

        // 4. Notify listeners to close notification center if open
        service.notificationActivated(notifItem);
    }

    function clearAllNotifications() {
        for (var i = 0; i < service.notificationList.length; i++) {
            var item = service.notificationList[i];
            if (item && item.ref && typeof item.ref.dismiss === "function") {
                try { item.ref.dismiss(); } catch(e) {}
            }
        }
        service.notificationList = [];
        service.incomingNotification = null;
    }

    Timer {
        id: incomingNotifTimer
        interval: 5000
        repeat: false
        onTriggered: service.incomingNotification = null
    }

    Process {
        id: notifSound
        command: ["canberra-gtk-play", "-i", "message", "-d", "quickshell-notification"]
    }

    // ==========================================
    // D-BUS NOTIFICATION SERVER
    // ==========================================
    NotificationServer {
        id: notifServer
        actionsSupported: true
        imageSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: notif => {
            notif.tracked = true;

            var notifId = notif.id;
            var appName = notif.appName || "Sistema";
            var summary = notif.summary || "";
            var body = notif.body || "";
            var rawImage = notif.image || "";
            var rawIcon = notif.appIcon || notif.desktopEntry || "";
            var actions = notif.actions || [];
            var timeout = notif.expireTimeout > 0 ? notif.expireTimeout : 3000;

            var attachedImage = "";

            // Process icon vs image (handles Discord/Electron issues)
            if (rawImage.startsWith("image://icon/")) {
                var stripped = rawImage.replace("image://icon/", "");
                if (stripped.startsWith("/") && /\.(png|jpg|jpeg|webp|gif|bmp)$/i.test(stripped)) {
                    attachedImage = stripped;
                    rawImage = "";
                } else {
                    if (rawIcon === "") rawIcon = stripped;
                    rawImage = "";
                }
            } else if (rawIcon === "" && (appName.toLowerCase() === "discord" || appName.toLowerCase() === "vesktop")) {
                rawIcon = "discord";
            }

            if (attachedImage === "" && rawImage !== "") {
                var cleanPath = rawImage.replace(/^file:\/\//, "");
                if (cleanPath.startsWith("/") && /\.(png|jpg|jpeg|webp|gif|bmp)$/i.test(cleanPath)) {
                    attachedImage = cleanPath;
                }
            }

            var notifItem = {
                "id": notifId,
                "ref": notif,
                "appName": appName,
                "appIcon": rawIcon,
                "summary": summary,
                "body": body,
                "image": attachedImage,
                "actions": actions,
                "time": Qt.formatDateTime(new Date(), "hh:mm"),
                "timeout": timeout
            };

            // Detect external screenshots
            if (attachedImage !== "" && (appName.toLowerCase().includes("captura") || summary.toLowerCase().includes("captura"))) {
                ScreenshotService.showToast(attachedImage);
            }

            // Insert into history
            var listCopy = service.notificationList.slice();
            listCopy.unshift(notifItem);
            service.notificationList = listCopy;

            // Show incoming notification in Dynamic Island
            if (!service.dndEnabled) {
                service.incomingNotification = notifItem;
                notifSound.running = true;
                incomingNotifTimer.interval = timeout;
                incomingNotifTimer.restart();
            }

            notif.closed.connect(function() {
                if (service.incomingNotification && service.incomingNotification.id === notifId) {
                    service.incomingNotification = null;
                }
            });
        }
    }
}
