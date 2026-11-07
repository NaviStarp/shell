import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../theme"
import "../../components"
import "../../services"

PanelWindow {
    id: toastWin

    required property var modelData
    screen: modelData

    anchors {
        bottom: true
        right: true
    }

    margins {
        bottom: 24
        right: 24
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0

    implicitWidth: 300
    implicitHeight: 200
    color: "transparent"

    visible: ScreenshotService.toastVisible && ScreenshotService.toastPath !== ""

    mask: Region {
        item: toastWin.visible ? toastCard : null
    }

    Rectangle {
        id: toastCard
        anchors.fill: parent
        color: Colors.surface
        border.color: cardMouse.containsMouse ? Colors.primary : Colors.borderEmerald
        border.width: 1
        radius: Colors.radiusLg
        clip: true

        scale: cardMouse.pressed ? 0.97 : (cardMouse.containsMouse ? 1.02 : 1.0)
        Behavior on scale {
            NumberAnimation {
                duration: cardMouse.pressed ? 60 : 150
                easing.type: Easing.OutBack
                easing.overshoot: 1.15
            }
        }

        Behavior on border.color { ColorAnimation { duration: 140 } }

        // Marcas CAD decorativas
        CadCornerMarks {
            markSize: 4
            markColor: Colors.primary
            opacity: 0.35
        }

        DotMatrixBackground {
            spacing: 24
            dotOpacity: 0.02
        }

        // Clic en CUALQUIER sitio de la tarjeta para editar directamente con Satty
        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onEntered: {
                if (typeof screenshotTimer !== "undefined") screenshotTimer.stop();
            }
            onExited: {
                if (typeof screenshotTimer !== "undefined") screenshotTimer.restart();
            }
            onClicked: (mouse) => {
              if (mouse.button === Qt.LeftButton) {
                ScreenshotService.editScreenshot(ScreenshotService.toastPath);
              } else if (mouse.button === Qt.MiddleButton) {
                ScreenshotService.hideToast();
              }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 7

            // Cabecera compacta
            // RowLayout {
            //     Layout.fillWidth: true
            //     spacing: 6
            //
            //     // Micro LED esmeralda
            //     Rectangle {
            //         width: 5
            //         height: 5
            //         radius: 2.5
            //         color: Colors.primary
            //         Layout.alignment: Qt.AlignVCenter
            //     }
            //
            //     Text {
            //         text: "CAPTURA COPIADA"
            //         color: Colors.text
            //         font.family: Colors.fontMono
            //         font.pixelSize: 10
            //         font.bold: true
            //         font.letterSpacing: 0.8
            //         Layout.alignment: Qt.AlignVCenter
            //     }
            //
            //     Item { Layout.fillWidth: true }
            //
            //     Text {
            //         text: "󰏫 CLIC PARA EDITAR"
            //         color: cardMouse.containsMouse ? Colors.primary : Colors.textDim
            //         font.family: Colors.fontMono
            //         font.pixelSize: 9
            //         Layout.alignment: Qt.AlignVCenter
            //     }
            //
            //     // Botón Cerrar (sin editar)
            //     Rectangle {
            //         width: 18
            //         height: 18
            //         radius: Colors.radiusSm
            //         color: closeMouse.containsMouse ? Colors.dangerSurface : "transparent"
            //         border.color: closeMouse.containsMouse ? Colors.danger : "transparent"
            //         border.width: 1
            //         Layout.alignment: Qt.AlignVCenter
            //         z: 5
            //
            //         Text {
            //             anchors.centerIn: parent
            //             text: "󰅖"
            //             color: closeMouse.containsMouse ? Colors.danger : Colors.textMuted
            //             font.family: Colors.fontMono
            //             font.pixelSize: 10
            //         }
            //
            //         MouseArea {
            //             id: closeMouse
            //             anchors.fill: parent
            //             hoverEnabled: true
            //             cursorShape: Qt.PointingHandCursor
            //             onClicked: root.screenshotToastVisible = false
            //         }
            //     }
            // }

            // Vista previa de la captura (ocupa el centro)
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Colors.radiusSm
                color: "#010302"
                border.color: cardMouse.containsMouse ? Colors.borderEmerald : Colors.border
                border.width: 1
                clip: true

                Behavior on border.color { ColorAnimation { duration: 140 } }

                Image {
                    anchors.fill: parent
                    anchors.margins: 4
                    source: ScreenshotService.toastPath !== "" ? ("file://" + ScreenshotService.toastPath) : ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    cache: false
                }
            }
        }

        // Micro-barra de cuenta regresiva inferior
        Rectangle {
            id: progressBar
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            height: 1.5
            color: Colors.primary
            opacity: 0.6
            width: parent.width * (progressAnim.running ? (1.0 - progressAnim.progress) : 0.0)

            NumberAnimation {
                id: progressAnim
                target: progressBar
                property: "width"
                from: toastCard.width
                to: 0
                duration: 3000
                running: ScreenshotService.toastVisible && !cardMouse.containsMouse
            }
        }
    }
}
