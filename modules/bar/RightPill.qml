import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"
import "../../components"
import "../../services"

Rectangle {
    id: rightPill

    property var barWindow: null

    readonly property string activeModule: barWindow ? barWindow.activeModule : ""

    anchors.top: parent ? parent.top : undefined
    anchors.topMargin: 8
    anchors.right: parent ? parent.right : undefined
    anchors.rightMargin: 12
    height: 32
    width: rightRow.implicitWidth + 14
    radius: height / 2
    color: Colors.surface
    border.color: (activeModule !== "" && activeModule !== "launcher" && activeModule !== "calendar")
        ? Colors.borderEmeraldGlow : Colors.border
    border.width: 1
    clip: true
    z: 2

    Behavior on border.color { ColorAnimation { duration: 140 } }

    RowLayout {
        id: rightRow
        anchors.centerIn: parent
        spacing: 4

        // Wallpaper Picker
        BarIconButton {
            icon: "󰸉"
            width: 26
            height: 24
            radius: height / 2
            Layout.alignment: Qt.AlignVCenter
            isActive: rightPill.activeModule === "wallpaper"
            activeColor: Colors.primary
            onClicked: if (barWindow) barWindow.toggleModule("wallpaper")
        }

        // Clipboard Manager
        BarIconButton {
            icon: "󰅍"
            width: 26
            height: 24
            radius: height / 2
            Layout.alignment: Qt.AlignVCenter
            isActive: rightPill.activeModule === "clipboard"
            activeColor: Colors.primary
            onClicked: if (barWindow) barWindow.toggleModule("clipboard")
        }

        // Divider
        Rectangle {
            width: 1
            height: 12
            color: Colors.border
            Layout.alignment: Qt.AlignVCenter
        }

        // Notification Center
        BarIconButton {
            icon: NotificationService.dndEnabled ? "󰂛" : (NotificationService.notificationList.length > 0 ? "󱅫" : "󰂚")
            width: 26
            height: 24
            radius: height / 2
            Layout.alignment: Qt.AlignVCenter
            isActive: rightPill.activeModule === "notifications"
            activeColor: Colors.primary
            onClicked: if (barWindow) barWindow.toggleModule("notifications")

            // Active notifications micro LED
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 3
                width: 5
                height: 5
                radius: 2.5
                color: NotificationService.dndEnabled ? Colors.danger : Colors.primary
                visible: NotificationService.notificationList.length > 0
            }
        }

        // Power Menu
        BarIconButton {
            icon: "󰐥"
            width: 26
            height: 24
            radius: height / 2
            Layout.alignment: Qt.AlignVCenter
            danger: true
            isActive: rightPill.activeModule === "power"
            onClicked: if (barWindow) barWindow.toggleModule("power")
        }
    }
}
