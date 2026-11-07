import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import "../../theme"
import "../../components"
import "../../services"

Item {
    id: notifRoot
    signal closeRequested()

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // ==========================================
        // CABECERA: Título, Contador, DND y Limpiar
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Indicador LED
            Rectangle {
                width: 5
                height: 5
                radius: 2.5
                color: NotificationService.dndEnabled ? Colors.danger : Colors.primary
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                text: "CENTRO DE NOTIFICACIONES"
                color: Colors.text
                font.family: Colors.fontSans
                font.pixelSize: 12
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }

            // Badge contador
            Rectangle {
                height: 18
                width: notifCountText.implicitWidth + 12
                radius: 9
                color: NotificationService.notificationList.length > 0 ? Colors.primaryGlow : Colors.surfacePill
                border.color: NotificationService.notificationList.length > 0 ? Colors.primary : Colors.border
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                Text {
                    id: notifCountText
                    anchors.centerIn: parent
                    text: NotificationService.notificationList.length + " ACTIVAS"
                    color: NotificationService.notificationList.length > 0 ? Colors.primary : Colors.textDim
                    font.family: Colors.fontMono
                    font.pixelSize: 9
                    font.bold: true
                }
            }

            Item { Layout.fillWidth: true }

            // Botón Modo No Molestar (DND)
            Rectangle {
                height: 24
                width: dndRow.implicitWidth + 14
                radius: Colors.radiusSm
                Layout.alignment: Qt.AlignVCenter
                color: NotificationService.dndEnabled
                    ? Qt.rgba(239, 68, 68, 0.15)
                    : (dndMouse.containsMouse ? Colors.hover : Colors.surfacePill)
                border.color: NotificationService.dndEnabled
                    ? Colors.danger
                    : (dndMouse.containsMouse ? Colors.borderHover : Colors.border)
                border.width: 1

                scale: dndMouse.pressed ? 0.92 : (dndMouse.containsMouse ? 1.04 : 1.0)
                Behavior on scale { NumberAnimation { duration: dndMouse.pressed ? 60 : 140; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                Behavior on color { ColorAnimation { duration: 120 } }

                Row {
                    id: dndRow
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: NotificationService.dndEnabled ? "󰂛" : "󰂚"
                        color: NotificationService.dndEnabled ? Colors.danger : (dndMouse.containsMouse ? Colors.primary : Colors.textMuted)
                        font.family: Colors.fontMono
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: NotificationService.dndEnabled ? "SILENCIADO" : "DND"
                        color: NotificationService.dndEnabled ? Colors.danger : (dndMouse.containsMouse ? Colors.text : Colors.textMuted)
                        font.family: Colors.fontSans
                        font.pixelSize: 10
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: dndMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.toggleDnd()
                }
            }

            // Botón Limpiar Todo
            Rectangle {
                height: 24
                width: clearRow.implicitWidth + 14
                radius: Colors.radiusSm
                visible: NotificationService.notificationList.length > 0
                color: clearMouse.containsMouse ? Colors.dangerSurface : Colors.surfacePill
                border.color: clearMouse.containsMouse ? Colors.danger : Colors.border
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                scale: clearMouse.pressed ? 0.92 : (clearMouse.containsMouse ? 1.04 : 1.0)
                Behavior on scale { NumberAnimation { duration: clearMouse.pressed ? 60 : 140; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
                Behavior on color { ColorAnimation { duration: 120 } }

                Row {
                    id: clearRow
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text: "󰎟"
                        color: clearMouse.containsMouse ? Colors.danger : Colors.textMuted
                        font.family: Colors.fontMono
                        font.pixelSize: 11
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: "LIMPIAR"
                        color: clearMouse.containsMouse ? Colors.danger : Colors.textMuted
                        font.family: Colors.fontSans
                        font.pixelSize: 10
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationService.clearAllNotifications()
                }
            }

            // Botón Cerrar
            Rectangle {
                width: 24
                height: 24
                radius: Colors.radiusSm
                color: closePanelMouse.containsMouse ? Colors.hover : "transparent"
                border.color: closePanelMouse.containsMouse ? Colors.borderHover : "transparent"
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                scale: closePanelMouse.pressed ? 0.90 : (closePanelMouse.containsMouse ? 1.06 : 1.0)
                Behavior on scale { NumberAnimation { duration: closePanelMouse.pressed ? 60 : 140; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: closePanelMouse.containsMouse ? Colors.text : Colors.textMuted
                    font.family: Colors.fontMono
                    font.pixelSize: 12
                }

                MouseArea {
                    id: closePanelMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: notifRoot.closeRequested()
                }
            }
        }

        // Línea divisoria CAD tenue
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.border
        }

        // ==========================================
        // LISTA DE NOTIFICACIONES O ESTADO VACÍO
        // ==========================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Estado vacío
            Item {
                anchors.fill: parent
                visible: NotificationService.notificationList.length === 0

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰂚"
                        font.family: Colors.fontMono
                        font.pixelSize: 28
                        color: Colors.textDim
                        opacity: 0.4
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "[ BANDEJA DE ENTRADA VACÍA ]"
                        color: Colors.textDim
                        font.family: Colors.fontMono
                        font.pixelSize: 11
                        font.bold: true
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No hay notificaciones pendientes en el sistema"
                        color: Colors.textDim
                        font.family: Colors.fontSans
                        font.pixelSize: 10
                        opacity: 0.7
                    }
                }
            }

            // Lista con scroll suave
            ListView {
                id: notifList
                anchors.fill: parent
                clip: true
                spacing: 8
                visible: NotificationService.notificationList.length > 0
                model: NotificationService.notificationList

                delegate: Rectangle {
                    id: itemCard
                    required property var modelData
                    required property int index

                    width: notifList.width
                    implicitHeight: cardCol.implicitHeight + 16
                    radius: Colors.radiusSm
                    color: itemMouse.containsMouse ? Colors.surfaceElevated : Colors.surfacePill
                    border.color: itemMouse.containsMouse ? Colors.borderEmerald : Colors.border
                    border.width: 1

                    scale: itemMouse.pressed ? 0.985 : (itemMouse.containsMouse ? 1.008 : 1.0)
                    Behavior on scale {
                        NumberAnimation {
                            duration: itemMouse.pressed ? 60 : 140
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.10
                        }
                    }

                    Behavior on color { ColorAnimation { duration: 100 } }
                    Behavior on border.color { ColorAnimation { duration: 100 } }

                    // Icono resuelto con seguridad
                    readonly property string resolvedIcon: {
                        if (!modelData) return "";
                        var iconName = modelData.appIcon || "";
                        if (iconName !== "") {
                            var p = Quickshell.iconPath(iconName, true);
                            if (p && p !== "") return p;
                        }
                        var app = (modelData.appName || "").toLowerCase().trim();
                        if (app === "discord" || app === "vesktop") {
                            var d = Quickshell.iconPath("discord", true) || Quickshell.iconPath("vesktop", true);
                            if (d) return d;
                        }
                        var p2 = Quickshell.iconPath(app, true);
                        if (p2 && p2 !== "") return p2;
                        return "";
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        cursorShape: Qt.PointingHandCursor

                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
                                // Clic derecho o central: descartar directamente
                                NotificationService.dismissNotificationById(itemCard.modelData ? itemCard.modelData.id : -1);
                            } else {
                                // Clic izquierdo: enfocar / abrir la aplicación
                                NotificationService.activateNotification(itemCard.modelData);
                            }
                        }
                    }

                    ColumnLayout {
                        id: cardCol
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 10
                        spacing: 6

                        // Fila superior: Icono, Nombre de App, Hora y Descartar
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            // Icono de app
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
                                    source: itemCard.resolvedIcon
                                    visible: itemCard.resolvedIcon !== ""
                                    fillMode: Image.PreserveAspectFit
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰂚"
                                    visible: itemCard.resolvedIcon === ""
                                    color: Colors.primary
                                    font.family: Colors.fontMono
                                    font.pixelSize: 11
                                }
                            }

                            // Nombre de la App
                            Text {
                                text: itemCard.modelData ? (itemCard.modelData.appName || "Sistema") : ""
                                color: itemMouse.containsMouse ? Colors.primary : Colors.text
                                font.family: Colors.fontSans
                                font.pixelSize: 11
                                font.bold: true
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on color { ColorAnimation { duration: 100 } }
                            }

                            Item { Layout.fillWidth: true }

                            // Hint interactivo al pasar el ratón
                            Text {
                                text: "󰅖 Clic derecho: borrar"
                                color: Colors.textDim
                                font.family: Colors.fontMono
                                font.pixelSize: 9
                                visible: itemMouse.containsMouse
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Hora
                            Text {
                                text: itemCard.modelData ? (itemCard.modelData.time || "") : ""
                                color: Colors.textDim
                                font.family: Colors.fontMono
                                font.pixelSize: 10
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Botón Descartar (X)
                            Rectangle {
                                width: 18
                                height: 18
                                radius: Colors.radiusSm
                                color: dismissMouse.containsMouse ? Colors.dangerSurface : "transparent"
                                border.color: dismissMouse.containsMouse ? Colors.danger : "transparent"
                                border.width: 1
                                Layout.alignment: Qt.AlignVCenter
                                z: 3

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    color: dismissMouse.containsMouse ? Colors.danger : Colors.textMuted
                                    font.family: Colors.fontMono
                                    font.pixelSize: 10
                                }

                                MouseArea {
                                    id: dismissMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NotificationService.dismissNotification(itemCard.index)
                                }
                            }
                        }

                        // Resumen / Título
                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: itemCard.modelData ? (itemCard.modelData.summary || "") : ""
                            color: Colors.text
                            font.family: Colors.fontSans
                            font.pixelSize: 12
                            font.bold: true
                            wrapMode: Text.Wrap
                            textFormat: Text.PlainText
                        }

                        // Cuerpo del mensaje
                        Text {
                            Layout.fillWidth: true
                            visible: text !== ""
                            text: itemCard.modelData ? (itemCard.modelData.body || "") : ""
                            color: Colors.textMuted
                            font.family: Colors.fontSans
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                            textFormat: Text.PlainText
                        }

                        // Imagen adjunta (solo visible si existe y carga sin error)
                        Rectangle {
                            id: imgBox
                            Layout.fillWidth: true
                            Layout.preferredHeight: (visible && notifImg.status === Image.Ready) ? Math.min(140, Math.max(60, notifImg.paintedHeight + 8)) : 0
                            radius: Colors.radiusSm
                            color: "#010302"
                            border.color: Colors.border
                            border.width: 1
                            clip: true
                            visible: itemCard.modelData && itemCard.modelData.image && itemCard.modelData.image !== "" && notifImg.status === Image.Ready

                            Image {
                                id: notifImg
                                anchors.fill: parent
                                anchors.margins: 4
                                source: (itemCard.modelData && itemCard.modelData.image) ? ("file://" + itemCard.modelData.image.replace(/^file:\/\//, "")) : ""
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (itemCard.modelData && itemCard.modelData.image && (itemCard.modelData.image.includes("Screenshot") || itemCard.modelData.image.includes(".png"))) {
                                        ScreenshotService.editScreenshot(itemCard.modelData.image.replace(/^file:\/\//, ""));
                                    } else {
                                        NotificationService.activateNotification(itemCard.modelData);
                                    }
                                }
                            }
                        }

                        // Acciones interactivas (Botones)
                        Flow {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: itemCard.modelData && itemCard.modelData.actions && itemCard.modelData.actions.length > 0

                            Repeater {
                                model: (itemCard.modelData && itemCard.modelData.actions) ? itemCard.modelData.actions : []

                                Rectangle {
                                    id: actionBtn
                                    required property var modelData
                                    height: 22
                                    width: actionTxt.implicitWidth + 14
                                    radius: Colors.radiusSm
                                    color: actionMouse.containsMouse ? Colors.primary : Colors.surfaceElevated
                                    border.color: actionMouse.containsMouse ? Colors.primary : Colors.borderEmerald
                                    border.width: 1

                                    Text {
                                        id: actionTxt
                                        anchors.centerIn: parent
                                        text: actionBtn.modelData ? (actionBtn.modelData.text || "Ejecutar") : ""
                                        color: actionMouse.containsMouse ? "#010302" : Colors.primary
                                        font.family: Colors.fontSans
                                        font.pixelSize: 10
                                        font.bold: true
                                        textFormat: Text.PlainText
                                    }

                                    MouseArea {
                                        id: actionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (actionBtn.modelData && typeof actionBtn.modelData.invoke === "function") {
                                                actionBtn.modelData.invoke();
                                            }
                                            NotificationService.dismissNotification(itemCard.index);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
