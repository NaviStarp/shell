import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../components"

Item {
    id: powerRoot
    signal closeRequested()

    Process {
        id: sysCmd
        function run(c) {
            command = ["sh", "-c", c];
            running = true;
            powerRoot.closeRequested();
            if (typeof barWindow !== "undefined") {
                barWindow.activeModule = "";
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 10

        // Cabecera elegante
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Rectangle {
                width: 4
                height: 4
                radius: 2
                color: Colors.primary
            }

            Text {
                text: "CONTROL DE ENERGÍA"
                color: Colors.textMuted
                font.family: Colors.fontSans
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1.2
            }
        }

        RowLayout {
            spacing: 12

            // Componente de tarjeta de acción táctil
            component ActionCard: Rectangle {
                id: card
                property string indexTag: "00"
                property string icon: ""
                property string label: ""
                property color accent: Colors.primary
                signal triggered()

                width: 106
                height: 86
                radius: Colors.radiusMd
                color: mouse.containsMouse ? Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.10) : Colors.surfacePill
                border.color: mouse.containsMouse ? card.accent : Colors.border
                border.width: 1
                clip: true

                scale: mouse.pressed ? 0.93 : (mouse.containsMouse ? 1.03 : 1.0)
                Behavior on scale {
                    NumberAnimation {
                        duration: mouse.pressed ? 60 : 150
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.15
                    }
                }

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                // Brillo especular superior
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 1
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.06)
                    radius: Colors.radiusMd
                }

                // Micro-indicador LED superior en hover
                Rectangle {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: mouse.containsMouse ? 24 : 0
                    height: 2
                    radius: 1
                    color: card.accent
                    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: card.indexTag
                        font.family: Colors.fontMono
                        font.pixelSize: 8
                        font.letterSpacing: 1.0
                        color: mouse.containsMouse ? card.accent : Colors.textDim
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: card.icon
                        font.family: Colors.fontMono
                        font.pixelSize: 22
                        color: mouse.containsMouse ? card.accent : Colors.text
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: card.label
                        font.family: Colors.fontMono
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 0.8
                        color: mouse.containsMouse ? Colors.text : Colors.textMuted
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.triggered()
                }
            }

            ActionCard {
                indexTag: "01"
                icon: "󰐥"
                label: "APAGAR"
                accent: Colors.error
                onTriggered: sysCmd.run("systemctl poweroff")
            }

            ActionCard {
                indexTag: "02"
                icon: "󰜉"
                label: "REINICIAR"
                accent: Colors.warning
                onTriggered: sysCmd.run("systemctl reboot")
            }

            ActionCard {
                indexTag: "03"
                icon: "󰤄"
                label: "SUSPENDER"
                accent: Colors.primary
                onTriggered: sysCmd.run("systemctl suspend")
            }

            ActionCard {
                indexTag: "04"
                icon: "󰌾"
                label: "BLOQUEAR"
                accent: Colors.secondary
                onTriggered: sysCmd.run("~/.config/quickshell/lockscreen/lock.sh")
            }

            ActionCard {
                indexTag: "05"
                icon: "󰗽"
                label: "SALIR"
                accent: Colors.textMuted
                onTriggered: sysCmd.run("swaymsg exit")
            }
        }
    }
}
