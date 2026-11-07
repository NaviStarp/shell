import QtQuick
import "../theme"

Item {
    id: root
    anchors.fill: parent
    z: 3
    enabled: false // Componente puramente decorativo, nunca intercepta eventos

    property color markColor: Colors.cadMark
    property int markSize: 8
    property int markThickness: 1
    property int markInset: 0
    property string style: "corner" // "corner" ('L') o "plus" ('+')

    // ==========================================
    // TOP-LEFT CORNER
    // ==========================================
    Item {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: root.markInset
        anchors.topMargin: root.markInset
        width: root.markSize
        height: root.markSize

        // Horizontal
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.verticalCenter: root.style === "plus" ? parent.top : undefined
            width: root.markSize
            height: root.markThickness
            color: root.markColor
        }
        // Vertical
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.horizontalCenter: root.style === "plus" ? parent.left : undefined
            width: root.markThickness
            height: root.markSize
            color: root.markColor
        }
    }

    // ==========================================
    // TOP-RIGHT CORNER
    // ==========================================
    Item {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: root.markInset
        anchors.topMargin: root.markInset
        width: root.markSize
        height: root.markSize

        // Horizontal
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.verticalCenter: root.style === "plus" ? parent.top : undefined
            width: root.markSize
            height: root.markThickness
            color: root.markColor
        }
        // Vertical
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.horizontalCenter: root.style === "plus" ? parent.right : undefined
            width: root.markThickness
            height: root.markSize
            color: root.markColor
        }
    }

    // ==========================================
    // BOTTOM-LEFT CORNER
    // ==========================================
    Item {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.markInset
        anchors.bottomMargin: root.markInset
        width: root.markSize
        height: root.markSize

        // Horizontal
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.verticalCenter: root.style === "plus" ? parent.bottom : undefined
            width: root.markSize
            height: root.markThickness
            color: root.markColor
        }
        // Vertical
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.horizontalCenter: root.style === "plus" ? parent.left : undefined
            width: root.markThickness
            height: root.markSize
            color: root.markColor
        }
    }

    // ==========================================
    // BOTTOM-RIGHT CORNER
    // ==========================================
    Item {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: root.markInset
        anchors.bottomMargin: root.markInset
        width: root.markSize
        height: root.markSize

        // Horizontal
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.verticalCenter: root.style === "plus" ? parent.bottom : undefined
            width: root.markSize
            height: root.markThickness
            color: root.markColor
        }
        // Vertical
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.horizontalCenter: root.style === "plus" ? parent.right : undefined
            width: root.markThickness
            height: root.markSize
            color: root.markColor
        }
    }
}
