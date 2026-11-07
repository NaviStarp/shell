import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../services"

PanelWindow {
    id: barWindowInstance

    required property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusiveZone: 48
    WlrLayershell.keyboardFocus: activeModule !== "" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    implicitHeight: 520
    color: "transparent"

    property string activeModule: ""

    function toggleModule(name) {
        activeModule = (activeModule === name) ? "" : name;
    }

    function closeModule() {
        activeModule = "";
    }

    Shortcut {
        sequence: "Escape"
        enabled: barWindowInstance.activeModule !== ""
        onActivated: barWindowInstance.activeModule = ""
    }

    // Input mask: only pills receive clicks; when module open, backdrop captures clicks to dismiss
    mask: Region {
        item: leftPill

        Region {
            item: centerPill
        }

        Region {
            item: rightPill
        }

        Region {
            item: barWindowInstance.activeModule !== "" ? dismissBackdrop : null
        }
    }

    // Transparent backdrop to dismiss dynamic island when clicking outside
    MouseArea {
        id: dismissBackdrop
        anchors.fill: parent
        visible: barWindowInstance.activeModule !== ""
        z: 1
        onClicked: barWindowInstance.activeModule = ""
    }

    LeftPill {
        id: leftPill
        barWindow: barWindowInstance
    }

    CenterPill {
        id: centerPill
        barWindow: barWindowInstance
    }

    RightPill {
        id: rightPill
        barWindow: barWindowInstance
    }

    Connections {
        target: NotificationService
        function onNotificationActivated() {
            if (barWindowInstance.activeModule === "notifications") {
                barWindowInstance.activeModule = "";
            }
        }
    }
}
