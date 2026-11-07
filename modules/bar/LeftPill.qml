import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"
import "../../components"
import "../../services"

Rectangle {
    id: leftPill

    property var barWindow: null
    property string screenName: barWindow ? (barWindow.screen ? barWindow.screen.name : "") : ""

    readonly property string activeWs: {
        if (SwayService.activeWorkspaceByOutput && SwayService.activeWorkspaceByOutput[screenName]) {
            return SwayService.activeWorkspaceByOutput[screenName];
        }
        return SwayService.activeWorkspaceName;
    }

    anchors.top: parent ? parent.top : undefined
    anchors.topMargin: 8
    anchors.left: parent ? parent.left : undefined
    anchors.leftMargin: 12
    height: 32
    width: leftRow.implicitWidth + 14
    radius: height / 2
    color: Colors.surface
    border.color: (barWindow && barWindow.activeModule === "launcher") ? Colors.borderEmeraldGlow : Colors.border
    border.width: 1
    clip: true
    z: 2

    Behavior on border.color { ColorAnimation { duration: 140 } }

    RowLayout {
        id: leftRow
        anchors.centerIn: parent
        spacing: 4

        // Launcher Button
        BarIconButton {
            icon: "󱓞"
            width: 26
            height: 24
            radius: height / 2
            Layout.alignment: Qt.AlignVCenter
            isActive: barWindow && barWindow.activeModule === "launcher"
            activeColor: Colors.primary
            onClicked: if (barWindow) barWindow.toggleModule("launcher")
        }

        // Divider
        Rectangle {
            width: 1
            height: 12
            color: Colors.border
            Layout.alignment: Qt.AlignVCenter
        }

        // Workspace track container with sliding liquid capsule indicator
        Item {
            id: wsTrack
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: wsRow.implicitWidth
            implicitHeight: 22

            readonly property var activeItem: {
                var actName = leftPill.activeWs;
                for (var i = 0; i < wsRepeater.count; i++) {
                    var it = wsRepeater.itemAt(i);
                    if (it && it.wsName === actName) {
                        return it;
                    }
                }
                return null;
            }

            // ----------------------------------------------------
            // ACTIVE SLIDING INDICATOR (Apple Segmented Style)
            // ----------------------------------------------------
            Rectangle {
                id: activeSlider
                z: 1
                height: 22
                radius: height / 2
                color: Colors.primaryGlow
                border.color: Colors.primary
                border.width: 1

                visible: opacity > 0.01
                opacity: wsTrack.activeItem !== null ? 1.0 : 0.0
                scale: (wsTrack.activeItem && wsTrack.activeItem.isPressed) ? 0.90 : 1.0

                x: wsTrack.activeItem ? wsTrack.activeItem.x : 0
                width: wsTrack.activeItem ? wsTrack.activeItem.width : 24

                Behavior on x {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.18
                    }
                }

                Behavior on width {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.12
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 80
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.15
                    }
                }

                // Micro LED dot traveling with the capsule
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2.5
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 2.5
                    height: 2.5
                    radius: 1.25
                    color: Colors.primary
                }
            }

            // Workspace buttons row
            Row {
                id: wsRow
                spacing: 4
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    id: wsRepeater
                    model: {
                        var list = SwayService.workspaces;
                        var sName = leftPill.screenName;
                        var filtered = [];
                        for (var i = 0; i < list.length; i++) {
                            if (sName === "" || list[i].output === sName) {
                                filtered.push(list[i]);
                            }
                        }
                        return filtered;
                    }

                    Item {
                        id: wsBtn
                        required property var modelData
                        readonly property string wsName: modelData ? (modelData.name || "") : ""
                        readonly property bool isCurrent: wsBtn.wsName === leftPill.activeWs
                        readonly property bool isPressed: wsMouse.pressed
                        readonly property bool isHovered: wsMouse.containsMouse

                        width: Math.max(24, numText.implicitWidth + 12)
                        height: 22
                        z: 2

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: wsBtn.isHovered && !wsBtn.isCurrent ? Colors.hover : "transparent"
                            border.color: wsBtn.isHovered && !wsBtn.isCurrent ? Colors.borderHover : "transparent"
                            border.width: 1
                            scale: wsBtn.isPressed ? 0.88 : (wsBtn.isHovered ? 1.06 : 1.0)

                            Behavior on scale {
                                NumberAnimation {
                                    duration: wsBtn.isPressed ? 70 : 160
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.15
                                }
                            }
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            id: numText
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: wsBtn.isCurrent ? -1 : 0
                            text: {
                                var num = parseInt(wsBtn.wsName);
                                if (!isNaN(num)) return num.toString();
                                return wsBtn.wsName;
                            }
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            color: wsBtn.isCurrent ? Colors.primary : (wsBtn.isHovered ? Colors.text : Colors.textDim)
                            font.family: Colors.fontSans
                            font.pixelSize: 11
                            font.bold: wsBtn.isCurrent
                            scale: wsBtn.isCurrent ? 1.08 : 1.0

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 220
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.2
                                }
                            }
                        }

                        MouseArea {
                            id: wsMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                SwayService.activeWorkspaceName = wsBtn.wsName;
                                if (leftPill.screenName !== "") {
                                    var c = Object.assign({}, SwayService.activeWorkspaceByOutput);
                                    c[leftPill.screenName] = wsBtn.wsName;
                                    SwayService.activeWorkspaceByOutput = c;
                                }
                                SwayService.switchWorkspace(wsBtn.wsName);
                            }
                        }
                    }
                }
            }
        }
    }
}
