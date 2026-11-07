import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../components"

Item {
    id: pickerRoot
    signal closeRequested()

    Process {
        id: setWallpaperProc
    }

    function applyWallpaper(rawPath) {
        var cleanPath = rawPath.toString().replace(/^file:\/\//, "");
        setWallpaperProc.command = ["awww", "img", cleanPath, "--transition-type", "fade", "--transition-duration", "1"];
        setWallpaperProc.running = true;
        pickerRoot.closeRequested();
        if (typeof barWindow !== "undefined") {
            barWindow.activeModule = "";
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // Cabecera elegante
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                width: 4
                height: 4
                radius: 2
                color: Colors.primary
            }

            Text {
                text: "FONDOS DE PANTALLA"
                color: Colors.text
                font.family: Colors.fontSans
                font.pixelSize: 11
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                height: 18
                width: wpCount.implicitWidth + 12
                radius: Colors.radiusSm
                color: Colors.surfacePill
                border.color: Colors.border
                border.width: 1

                Text {
                    id: wpCount
                    anchors.centerIn: parent
                    text: wallpaperModel.count + " IMÁGENES"
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.5
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.border
        }

        FolderListModel {
            id: wallpaperModel
            folder: "file://" + Quickshell.env("HOME") + "/Pictures/Wallpapers"
            nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif"]
            showDirs: false
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: 184
            cellHeight: 134
            model: wallpaperModel

            delegate: Item {
                id: cardItem
                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    id: cardFrame
                    anchors.fill: parent
                    anchors.margins: 5
                    radius: Colors.radiusMd
                    color: Colors.surface
                    border.color: itemMouseArea.containsMouse ? Colors.primary : Colors.border
                    border.width: 1
                    clip: true

                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    // Brillo especular superior
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 1
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.08)
                        radius: Colors.radiusMd
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 1
                        source: Qt.resolvedUrl(filePath)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 300
                        sourceSize.height: 200
                        scale: itemMouseArea.containsMouse ? 1.04 : 1.0

                        Behavior on scale {
                            NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
                        }
                    }

                    // Tira inferior oscura con micro-nombre técnico
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 20
                        color: Qt.rgba(1/255, 3/255, 2/255, 0.85)
                        border.color: Colors.border
                        border.width: 1

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            verticalAlignment: Text.AlignVCenter
                            text: fileName
                            font.family: Colors.fontMono
                            font.pixelSize: 9
                            color: itemMouseArea.containsMouse ? Colors.primary : Colors.textMuted
                            elide: Text.ElideMiddle
                        }
                    }

                    // Indicador LED de foco en hover
                    Rectangle {
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: itemMouseArea.containsMouse ? 20 : 0
                        height: 1.5
                        radius: 1
                        color: Colors.primary
                        Behavior on width { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: itemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pickerRoot.applyWallpaper(filePath)
                    }
                }
            }
        }
    }
}
