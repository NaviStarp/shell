import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"
import "../../components"
import "../../services"
import "../launcher"
import "../clipboard"
import "../wallpaper"
import "../power"
import "../calendar"
import "../notifications"

Rectangle {
    id: centerPill

    property var barWindow: null

    readonly property string activeModule: barWindow ? barWindow.activeModule : ""
    readonly property bool isExpanded: activeModule !== ""
    readonly property bool isShowingNotif: NotificationService.incomingNotification !== null && !isExpanded

    property var currentTime: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: centerPill.currentTime = new Date()
    }

    anchors.top: parent ? parent.top : undefined
    anchors.topMargin: 8
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

    // Resting dimensions (Clock Pill)
    readonly property int idleW: clockRow.implicitWidth + 24
    readonly property int idleH: 32

    // Target dimensions for morphing
    readonly property int targetW: {
        if (isExpanded) {
            switch (activeModule) {
                case "launcher":      return 700;
                case "clipboard":     return 720;
                case "wallpaper":     return 970;
                case "power":         return 620;
                case "calendar":      return 320;
                case "notifications": return 600;
                default:              return idleW;
            }
        } else if (isShowingNotif) {
            return 380;
        } else {
            return idleW;
        }
    }

    readonly property int targetH: {
        if (isExpanded) {
            switch (activeModule) {
                case "launcher":      return 440;
                case "clipboard":     return 440;
                case "wallpaper":     return 380;
                case "power":         return 136;
                case "calendar":      return 270;
                case "notifications": return 460;
                default:              return idleH;
            }
        } else if (isShowingNotif) {
            return 36;
        } else {
            return idleH;
        }
    }

    width: targetW
    height: targetH

    radius: isExpanded ? 12 : (height / 2)

    color: isExpanded
        ? Colors.surface
        : (isShowingNotif
            ? Colors.surfaceElevated
            : (clockMouse.containsMouse ? Colors.surfaceElevated : Colors.surface))

    border.color: isExpanded
        ? Colors.borderEmerald
        : (isShowingNotif
            ? Colors.primary
            : (clockMouse.containsMouse ? Colors.borderEmerald : Colors.border))
    border.width: 1

    clip: true
    z: isExpanded ? 10 : 2

    Behavior on width {
        NumberAnimation {
            duration: centerPill.isExpanded ? 280 : (centerPill.isShowingNotif ? 260 : 200)
            easing.type: (centerPill.isExpanded || centerPill.isShowingNotif) ? Easing.OutBack : Easing.OutExpo
            easing.overshoot: 1.06
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: centerPill.isExpanded ? 280 : (centerPill.isShowingNotif ? 260 : 200)
            easing.type: (centerPill.isExpanded || centerPill.isShowingNotif) ? Easing.OutBack : Easing.OutExpo
            easing.overshoot: 1.06
        }
    }
    Behavior on radius {
        NumberAnimation {
            duration: centerPill.isExpanded ? 240 : 180
            easing.type: Easing.OutExpo
        }
    }
    Behavior on color {
        ColorAnimation { duration: 140 }
    }
    Behavior on border.color {
        ColorAnimation { duration: 140 }
    }

    DotMatrixBackground {
        spacing: 24
        dotOpacity: 0.025
        visible: centerPill.isExpanded
    }

    // ----------------------------------------------------
    // 1. IDLE STATE: Clock & Date
    // ----------------------------------------------------
    Item {
        id: clockContainer
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: clockRow.implicitWidth + 24
        height: 32
        visible: opacity > 0.01
        opacity: (centerPill.isExpanded || centerPill.isShowingNotif) ? 0.0 : 1.0
        scale: (centerPill.isExpanded || centerPill.isShowingNotif) ? 0.90 : (clockMouse.pressed ? 0.95 : 1.0)

        Behavior on opacity {
            NumberAnimation {
                duration: (centerPill.isExpanded || centerPill.isShowingNotif) ? 80 : 180
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: (centerPill.isExpanded || centerPill.isShowingNotif) ? 90 : 220
                easing.type: (centerPill.isExpanded || centerPill.isShowingNotif) ? Easing.OutExpo : Easing.OutBack
                easing.overshoot: 1.12
            }
        }

        MouseArea {
            id: clockMouse
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            enabled: !centerPill.isExpanded && !centerPill.isShowingNotif
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (!barWindow) return;
                if (mouse.button === Qt.LeftButton) {
                    barWindow.toggleModule("calendar");
                } else if (mouse.button === Qt.RightButton) {
                    barWindow.toggleModule("power");
                } else if (mouse.button === Qt.MiddleButton) {
                    barWindow.toggleModule("notifications");
                }
            }
        }

        RowLayout {
            id: clockRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                id: dateDisplay
                text: Qt.formatDateTime(centerPill.currentTime, "ddd d MMM")
                color: Colors.textMuted
                font.family: Colors.fontSans
                font.pixelSize: 11
                font.weight: Font.Medium
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                width: 4
                height: 4
                radius: 2
                color: Colors.primary
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    anchors.centerIn: parent
                    width: 8
                    height: 8
                    radius: 4
                    color: Colors.primaryGlow
                }
            }

            Text {
                id: timeDisplay
                text: Qt.formatDateTime(centerPill.currentTime, "hh:mm")
                color: Colors.text
                font.family: Colors.fontMono
                font.pixelSize: 12
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // ----------------------------------------------------
    // 2. INCOMING NOTIFICATION STATE: Dynamic Island Banner
    // ----------------------------------------------------
    Item {
        id: notifBanner
        anchors.fill: parent
        visible: opacity > 0.01
        opacity: centerPill.isShowingNotif ? 1.0 : 0.0
        scale: centerPill.isShowingNotif ? (bannerMouse.pressed ? 0.98 : 1.0) : 0.93

        Behavior on opacity {
            NumberAnimation {
                duration: centerPill.isShowingNotif ? 180 : 80
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: centerPill.isShowingNotif ? 260 : 120
                easing.type: centerPill.isShowingNotif ? Easing.OutBack : Easing.OutExpo
                easing.overshoot: 1.08
            }
        }

        MouseArea {
            id: bannerMouse
            anchors.fill: parent
            enabled: centerPill.isShowingNotif
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
                    NotificationService.dismissNotificationById(NotificationService.incomingNotification ? NotificationService.incomingNotification.id : -1);
                } else {
                    NotificationService.activateNotification(NotificationService.incomingNotification);
                }
            }
            onWheel: wheel => {
                NotificationService.dismissNotificationById(NotificationService.incomingNotification ? NotificationService.incomingNotification.id : -1);
            }
        }

        RowLayout {
            id: notifBannerLayout
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 8

            Rectangle {
                width: 20
                height: 20
                radius: 4
                color: "#000000"
                border.color: Colors.border
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                Image {
                    anchors.fill: parent
                    anchors.margins: 2
                    source: {
                        if (!NotificationService.incomingNotification || !NotificationService.incomingNotification.appIcon) return "";
                        var p = Quickshell.iconPath(NotificationService.incomingNotification.appIcon, true);
                        return p ? p : "";
                    }
                    visible: source !== ""
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰂚"
                    visible: !parent.children[0].visible
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: 11
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 1

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Text {
                        text: NotificationService.incomingNotification ? (NotificationService.incomingNotification.appName || "SISTEMA").toUpperCase() : ""
                        color: Colors.primary
                        font.family: Colors.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                        textFormat: Text.PlainText
                    }

                    Text {
                        text: "·"
                        color: Colors.textDim
                        font.family: Colors.fontMono
                        font.pixelSize: 9
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        text: NotificationService.incomingNotification ? (NotificationService.incomingNotification.summary || "") : ""
                        color: Colors.text
                        font.family: Colors.fontSans
                        font.pixelSize: 11
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        textFormat: Text.PlainText
                    }
                }

                Text {
                    visible: text !== ""
                    text: NotificationService.incomingNotification ? (NotificationService.incomingNotification.body || "") : ""
                    color: Colors.textMuted
                    font.family: Colors.fontSans
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    textFormat: Text.PlainText
                }
            }
        }
    }

    // ----------------------------------------------------
    // 3. EXPANDED STATE: Interactive Modules
    // ----------------------------------------------------
    Item {
        id: moduleContent
        anchors.fill: parent
        clip: true
        visible: opacity > 0.01
        opacity: centerPill.isExpanded ? 1.0 : 0.0
        scale: centerPill.isExpanded ? 1.0 : 0.97
        y: centerPill.isExpanded ? 0 : -6

        Behavior on opacity {
            NumberAnimation {
                duration: centerPill.isExpanded ? 190 : 80
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: centerPill.isExpanded ? 280 : 160
                easing.type: Easing.OutExpo
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: centerPill.isExpanded ? 280 : 160
                easing.type: Easing.OutExpo
            }
        }

        AppLauncher {
            anchors.fill: parent
            anchors.margins: 10
            visible: centerPill.activeModule === "launcher"
            onCloseRequested: if (barWindow) barWindow.activeModule = ""
        }

        Clipboard {
            anchors.fill: parent
            anchors.margins: 10
            visible: centerPill.activeModule === "clipboard"
            onCloseRequested: if (barWindow) barWindow.activeModule = ""
        }

        WallpaperPicker {
            anchors.fill: parent
            anchors.margins: 10
            visible: centerPill.activeModule === "wallpaper"
            onCloseRequested: if (barWindow) barWindow.activeModule = ""
        }

        PowerMenu {
            anchors.fill: parent
            anchors.margins: 10
            visible: centerPill.activeModule === "power"
            onCloseRequested: if (barWindow) barWindow.activeModule = ""
        }

        CalendarView {
            anchors.fill: parent
            anchors.margins: 12
            visible: centerPill.activeModule === "calendar"
            onCloseRequested: if (barWindow) barWindow.activeModule = ""
        }

        NotificationCenter {
            anchors.fill: parent
            anchors.margins: 12
            visible: centerPill.activeModule === "notifications"
            onCloseRequested: if (barWindow) barWindow.activeModule = ""
        }
    }
}
