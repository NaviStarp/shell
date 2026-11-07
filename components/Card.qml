import QtQuick
import "../theme"

Rectangle {
    id: root

    property alias content: placeholder.data
    property bool showCadMarks: false
    property string cadStyle: "corner"

    color: Colors.surface
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusLg
    clip: true

    // Línea de brillo especular superior
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 1
        height: 1
        color: Qt.rgba(1, 1, 1, 0.06)
        radius: Colors.radiusLg
    }

    Item {
        id: placeholder
        anchors.fill: parent
        anchors.margins: 10
    }
}
