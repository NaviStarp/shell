import QtQuick
import "../theme"

Rectangle {
    id: btnRoot

    property string icon: ""
    property color iconColor: Colors.textMuted
    property color activeColor: Colors.primary
    property bool isActive: false
    property bool danger: false
    signal clicked()

    width: 26
    height: 22
    radius: Colors.radiusSm

    scale: mouseArea.pressed ? 0.90 : (mouseArea.containsMouse ? 1.05 : 1.0)

    Behavior on scale {
        NumberAnimation {
            duration: mouseArea.pressed ? 70 : 140
            easing.type: Easing.OutBack
            easing.overshoot: 1.15
        }
    }

    color: {
        if (danger && mouseArea.containsMouse) return Qt.rgba(239/255, 68/255, 68/255, 0.16);
        if (isActive) return Colors.primaryGlow;
        if (mouseArea.containsMouse) return Colors.hover;
        return "transparent";
    }

    border.color: {
        if (danger && mouseArea.containsMouse) return Colors.error;
        if (isActive) return Colors.borderEmerald;
        if (mouseArea.containsMouse) return Colors.borderHover;
        return "transparent";
    }
    border.width: 1

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    Text {
        anchors.centerIn: parent
        text: btnRoot.icon
        color: {
            if (btnRoot.danger && mouseArea.containsMouse) return Colors.error;
            if (btnRoot.isActive || mouseArea.containsMouse) return btnRoot.activeColor;
            return btnRoot.iconColor;
        }
        font.family: Colors.fontMono
        font.pixelSize: 11
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    // Micro-indicador LED de punto inferior para estado activo
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        width: 3
        height: 3
        radius: 1.5
        color: btnRoot.danger ? Colors.error : Colors.primary
        visible: btnRoot.isActive
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btnRoot.clicked()
    }
}
