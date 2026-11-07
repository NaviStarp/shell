import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../../theme"
import "../../components"

Item {
    id: clipRoot
    signal closeRequested()

    ListModel { id: rawClipModel }
    ListModel { id: clipModel }

    property int previewCounter: 0

    function applyFilter() {
        clipModel.clear();
        var query = searchInput.text.trim().toLowerCase();

        for (var i = 0; i < rawClipModel.count; ++i) {
            var item = rawClipModel.get(i);
            if (query === "" || item.rawText.toLowerCase().includes(query)) {
                clipModel.append({
                    "id": item.id,
                    "rawText": item.rawText,
                    "isImage": item.isImage
                });
            }
        }

        if (clipModel.count > 0) {
            clipList.currentIndex = 0;
            var first = clipModel.get(0);
            showPreview(first.id, first.isImage, first.rawText);
        } else {
            clipList.currentIndex = -1;
            imgPreview.visible = false;
            textScroll.visible = false;
        }
    }

    Row {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // --- LISTA (Izquierda) ---
        Column {
            width: parent.width * 0.54
            height: parent.height
            spacing: 8

            // Cabecera elegante
            RowLayout {
                width: parent.width

                Text {
                    text: "PORTAPAPELES"
                    color: Colors.text
                    font.family: Colors.fontSans
                    font.pixelSize: 11
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    height: 18
                    width: clipCountText.implicitWidth + 12
                    radius: Colors.radiusSm
                    color: Colors.surfacePill
                    border.color: Colors.border
                    border.width: 1

                    Text {
                        id: clipCountText
                        anchors.centerIn: parent
                        text: clipModel.count + " ELEMENTOS"
                        color: Colors.primary
                        font.family: Colors.fontMono
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.5
                    }
                }
            }

            // Buscador minimalista estilo Linear / Raycast
            Rectangle {
                width: parent.width
                height: 36
                radius: Colors.radiusMd
                color: Colors.surfacePill
                border.color: searchInput.activeFocus ? Colors.primary : Colors.border
                border.width: 1

                Behavior on border.color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    // Micro-LED indicador de búsqueda
                    Rectangle {
                        width: 4
                        height: 4
                        radius: 2
                        color: searchInput.activeFocus ? Colors.primary : Colors.textDim
                    }

                    Text {
                        text: "󰅍"
                        color: searchInput.activeFocus ? Colors.primary : Colors.textMuted
                        font.family: Colors.fontMono
                        font.pixelSize: 13
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: Colors.text
                        font.family: Colors.fontMono
                        font.pixelSize: 12
                        clip: true
                        selectByMouse: true

                        Text {
                            text: "Buscar en historial (Escribir o Enter para copiar)..."
                            color: Colors.textDim
                            visible: !searchInput.text && !searchInput.activeFocus
                            font.family: Colors.fontMono
                            font.pixelSize: 11
                            opacity: 0.6
                        }

                        onTextChanged: applyFilter()

                        Keys.onDownPressed: {
                            if (clipList.count > 0) {
                                if (clipList.currentIndex < clipList.count - 1) {
                                    clipList.currentIndex++;
                                    var it = clipModel.get(clipList.currentIndex);
                                    if (it) showPreview(it.id, it.isImage, it.rawText);
                                }
                            }
                        }

                        Keys.onUpPressed: {
                            if (clipList.count > 0 && clipList.currentIndex > 0) {
                                clipList.currentIndex--;
                                var it = clipModel.get(clipList.currentIndex);
                                if (it) showPreview(it.id, it.isImage, it.rawText);
                            }
                        }

                        Keys.onReturnPressed: {
                            if (clipModel.count > 0 && clipList.currentIndex >= 0) {
                                pasteProcess.copyItem(clipModel.get(clipList.currentIndex).id);
                            }
                        }
                        Keys.onEnterPressed: {
                            if (clipModel.count > 0 && clipList.currentIndex >= 0) {
                                pasteProcess.copyItem(clipModel.get(clipList.currentIndex).id);
                            }
                        }
                    }
                }
            }

            // Lista de entradas
            ListView {
                id: clipList
                width: parent.width
                height: parent.height - 76
                clip: true
                spacing: 4

                model: clipModel

                delegate: Rectangle {
                    id: itemRoot
                    required property var model
                    required property int index

                    readonly property bool isSelected: clipList.currentIndex === index
                    readonly property bool isHovered: itemMouse.containsMouse

                    width: clipList.width
                    height: 36
                    radius: Colors.radiusSm
                    color: isSelected ? Colors.surfaceElevated : (isHovered ? Colors.hover : "transparent")
                    border.color: isSelected ? Colors.borderEmerald : (isHovered ? Colors.borderHover : "transparent")
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 80 } }
                    Behavior on border.color { ColorAnimation { duration: 80 } }

                    // Micro-indicador LED de selección
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 6
                        width: 2
                        radius: 1
                        color: Colors.primary
                        visible: itemRoot.isSelected
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        // Tag técnico [ IMG ] o [ TXT ]
                        Text {
                            text: itemRoot.model.isImage ? "󰋩 IMG" : "󰅍 TXT"
                            color: itemRoot.model.isImage ? Colors.primary : (itemRoot.isSelected ? Colors.secondary : Colors.textDim)
                            font.family: Colors.fontMono
                            font.pixelSize: 10
                            font.bold: itemRoot.isSelected
                        }

                        Rectangle {
                            width: 1
                            height: 10
                            color: Colors.border
                        }

                        Text {
                            Layout.fillWidth: true
                            text: itemRoot.model.rawText
                            textFormat: Text.PlainText
                            color: itemRoot.isSelected ? Colors.text : Colors.textMuted
                            font.family: Colors.fontMono
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            clipList.currentIndex = itemRoot.index;
                            clipRoot.showPreview(itemRoot.model.id, itemRoot.model.isImage, itemRoot.model.rawText);
                        }
                        onClicked: {
                            pasteProcess.copyItem(itemRoot.model.id);
                        }
                    }
                }
            }
        }

        // Separador vertical con micro marca CAD
        Item {
            width: 1
            height: parent.height

            Rectangle {
                anchors.fill: parent
                color: Colors.border
            }
        }

        // --- PREVIEW (Derecha) ---
        Rectangle {
            width: parent.width * 0.46 - 15
            height: parent.height
            color: Colors.surfacePill
            radius: Colors.radiusMd
            border.color: Colors.border
            border.width: 1
            clip: true

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

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // Header de Preview
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "VISTA PREVIA"
                        color: Colors.textMuted
                        font.family: Colors.fontSans
                        font.pixelSize: 10
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        height: 16
                        width: badgeText.implicitWidth + 10
                        radius: Colors.radiusXs
                        color: Colors.surfaceElevated
                        border.color: Colors.border
                        border.width: 1

                        Text {
                            id: badgeText
                            anchors.centerIn: parent
                            text: imgPreview.visible ? "IMAGEN" : "TEXTO"
                            color: Colors.primary
                            font.family: Colors.fontMono
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colors.border
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Image {
                        id: imgPreview
                        anchors.centerIn: parent
                        width: parent.width - 12
                        height: parent.height - 12
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        visible: false
                        cache: false
                    }

                    ScrollView {
                        id: textScroll
                        anchors.fill: parent
                        visible: !imgPreview.visible

                        TextEdit {
                            id: textPreview
                            width: textScroll.width
                            textFormat: TextEdit.PlainText
                            color: Colors.text
                            font.family: Colors.fontMono
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                            readOnly: true
                            selectByMouse: true
                        }
                    }

                    // Estado vacío
                    Text {
                        anchors.centerIn: parent
                        text: "[ SIN SELECCIÓN ]"
                        color: Colors.textDim
                        font.family: Colors.fontMono
                        font.pixelSize: 10
                        visible: clipModel.count === 0
                    }
                }
            }
        }
    }

    // --- PROCESOS CLIPHIST ---
    Timer {
        id: reloadTimer
        interval: 20
        repeat: false
        onTriggered: {
            rawClipModel.clear();
            clipModel.clear();
            searchInput.text = "";
            listProc.running = true;
        }
    }

    function reload(): void {
        if (listProc.running) listProc.running = false;
        reloadTimer.start();
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: SplitParser {
            onRead: line => {
                var entry = line.trim();
                if (!entry) return;
                var tabIdx = entry.indexOf("\t");
                if (tabIdx === -1) return;

                var id = entry.substring(0, tabIdx);
                var content = entry.substring(tabIdx + 1);
                var isImg = content.indexOf("[[ binary data") !== -1;
                var cleanText = isImg ? "Captura de pantalla / Imagen" : content;

                rawClipModel.append({
                    "id": id,
                    "rawText": cleanText,
                    "isImage": isImg
                });

                if (searchInput.text.trim() === "") {
                    clipModel.append({
                        "id": id,
                        "rawText": cleanText,
                        "isImage": isImg
                    });

                    if (clipModel.count === 1) {
                        clipList.currentIndex = 0;
                        clipRoot.showPreview(id, isImg, cleanText);
                    }
                }
            }
        }
    }

    Process {
        id: previewProc
        onExited: {
            imgPreview.source = "";
            imgPreview.source = "file:///tmp/clip_preview.png?" + clipRoot.previewCounter;
            imgPreview.visible = true;
        }
    }

    function showPreview(clipId, isImg, fullText) {
        if (isImg) {
            textScroll.visible = false;
            clipRoot.previewCounter++;
            previewProc.command = ["sh", "-c", "cliphist decode \"$1\" > /tmp/clip_preview.png", "sh", clipId.toString()];
            previewProc.running = true;
        } else {
            imgPreview.visible = false;
            textScroll.visible = true;
            textPreview.text = fullText;
        }
    }

    Process {
        id: pasteProcess
        function copyItem(clipId) {
            command = ["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", clipId.toString()];
            running = true;
        }
        onExited: {
            clipRoot.closeRequested();
            if (typeof barWindow !== "undefined") {
                barWindow.activeModule = "";
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            reload();
            searchInput.forceActiveFocus();
        }
    }
}
