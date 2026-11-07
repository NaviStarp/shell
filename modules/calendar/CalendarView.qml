import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../../theme"
import "../../components"

Item {
    id: calRoot
    signal closeRequested()

    readonly property date realNow: new Date()
    property int currentMonth: realNow.getMonth()
    property int currentYear: realNow.getFullYear()

    readonly property bool isCurrentViewToday: currentMonth === realNow.getMonth() && currentYear === realNow.getFullYear()

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // ==========================================
        // CABECERA ELEGANTE: Mes, Año y Controles
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: Qt.formatDateTime(new Date(calRoot.currentYear, calRoot.currentMonth, 1), "MMMM yyyy").toUpperCase()
                    color: Colors.text
                    font.family: Colors.fontSans
                    font.pixelSize: 13
                    font.bold: true
                }

                Text {
                    text: "VISTA MENSUAL"
                    color: Colors.textDim
                    font.family: Colors.fontMono
                    font.pixelSize: 8
                    font.letterSpacing: 1.0
                }
            }

            // Botón HOY (solo visible si no estamos en el mes actual)
            Rectangle {
                width: 38
                height: 22
                radius: Colors.radiusSm
                visible: !calRoot.isCurrentViewToday
                color: todayMouse.containsMouse ? Colors.hover : Colors.surfacePill
                border.color: todayMouse.containsMouse ? Colors.primary : Colors.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "HOY"
                    color: todayMouse.containsMouse ? Colors.primary : Colors.textMuted
                    font.family: Colors.fontMono
                    font.pixelSize: 9
                    font.bold: true
                }

                MouseArea {
                    id: todayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        calRoot.currentMonth = calRoot.realNow.getMonth();
                        calRoot.currentYear = calRoot.realNow.getFullYear();
                    }
                }
            }

            // Mes anterior
            Rectangle {
                width: 22
                height: 22
                radius: Colors.radiusSm
                color: prevM.containsMouse ? Colors.hover : Colors.surfacePill
                border.color: prevM.containsMouse ? Colors.primary : Colors.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "󰅁"
                    color: prevM.containsMouse ? Colors.primary : Colors.textMuted
                    font.family: Colors.fontMono
                    font.pixelSize: 11
                }
                MouseArea {
                    id: prevM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (calRoot.currentMonth === 0) {
                            calRoot.currentMonth = 11;
                            calRoot.currentYear--;
                        } else {
                            calRoot.currentMonth--;
                        }
                    }
                }
            }

            // Mes siguiente
            Rectangle {
                width: 22
                height: 22
                radius: Colors.radiusSm
                color: nextM.containsMouse ? Colors.hover : Colors.surfacePill
                border.color: nextM.containsMouse ? Colors.primary : Colors.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "󰅂"
                    color: nextM.containsMouse ? Colors.primary : Colors.textMuted
                    font.family: Colors.fontMono
                    font.pixelSize: 11
                }
                MouseArea {
                    id: nextM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (calRoot.currentMonth === 11) {
                            calRoot.currentMonth = 0;
                            calRoot.currentYear++;
                        } else {
                            calRoot.currentMonth++;
                        }
                    }
                }
            }

            // Botón Cerrar
            Rectangle {
                width: 22
                height: 22
                radius: Colors.radiusSm
                color: closeM.containsMouse ? Colors.dangerSurface : Colors.surfacePill
                border.color: closeM.containsMouse ? Colors.danger : Colors.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: closeM.containsMouse ? Colors.danger : Colors.textMuted
                    font.family: Colors.fontMono
                    font.pixelSize: 11
                }
                MouseArea {
                    id: closeM
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: calRoot.closeRequested()
                }
            }
        }

        // Línea divisoria tenue
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.border
        }

        // ==========================================
        // DÍAS DE LA SEMANA (L M X J V S D)
        // ==========================================
        DayOfWeekRow {
            id: dayRow
            Layout.fillWidth: true
            locale: Qt.locale("es_ES")

            delegate: Text {
                text: model.narrowName.toUpperCase()
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: Colors.textDim
                font.family: Colors.fontMono
                font.pixelSize: 10
                font.letterSpacing: 1.0
                font.bold: true
            }
        }

        // ==========================================
        // REJILLA DEL MES (ALTO CONTRASTE TÁCTICO)
        // ==========================================
        MonthGrid {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            month: calRoot.currentMonth
            year: calRoot.currentYear
            locale: Qt.locale("es_ES")

            delegate: Rectangle {
                id: dayCell

                readonly property bool isToday: {
                    if (!model || !model.date) return false;
                    var d = model.date;
                    return d.getDate() === calRoot.realNow.getDate() &&
                           d.getMonth() === calRoot.realNow.getMonth() &&
                           d.getFullYear() === calRoot.realNow.getFullYear();
                }

                readonly property bool inOtherMonth: model && model.month !== undefined ? (model.month !== calRoot.currentMonth) : false

                radius: Colors.radiusSm

                color: {
                    if (isToday) return Colors.primary;
                    if (dayMouse.containsMouse && !inOtherMonth) return Colors.hover;
                    return "transparent";
                }

                border.color: {
                    if (isToday) return Colors.secondary;
                    if (dayMouse.containsMouse && !inOtherMonth) return Colors.borderEmerald;
                    return "transparent";
                }
                border.width: 1

                Behavior on color { ColorAnimation { duration: 100 } }
                Behavior on border.color { ColorAnimation { duration: 100 } }

                Column {
                    anchors.centerIn: parent
                    spacing: 1

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: (model && model.day !== undefined) ? model.day : ""
                        font.family: Colors.fontMono
                        font.pixelSize: 11
                        font.bold: isToday

                        color: {
                            if (isToday) return "#010302"; // Negro carbón sobre verde esmeralda
                            if (inOtherMonth) return "#2d3732"; // Muted para otros meses
                            return dayMouse.containsMouse ? "#ffffff" : Colors.text;
                        }
                    }

                    // Micro-indicador LED de punto bajo el día de hoy (si no fuera sólido, o como marca)
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 3
                        height: 3
                        radius: 0
                        color: "#010302"
                        visible: isToday
                    }
                }

                MouseArea {
                    id: dayMouse
                    anchors.fill: parent
                    hoverEnabled: !inOtherMonth
                }
            }
        }
    }
}
