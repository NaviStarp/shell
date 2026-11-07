import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets
import "theme"
import "components"

Scope {
    id: root

    // ==========================================
    // ESTADO DE LA PANTALLA DE BLOQUEO
    // ==========================================
    property bool entered: false
    property bool showAuth: false
    property bool isAuthenticating: false
    property bool authError: false
    property bool authSuccess: false
    property string activePassword: ""
    property string submittedPass: ""
    property bool capsLockOn: false
    property var currentTime: new Date()

    onShowAuthChanged: {
        if (showAuth) {
            passInput.forceActiveFocus();
            idleTimer.restart();
        } else {
            root.activePassword = "";
            passInput.text = "";
            root.authError = false;
        }
    }

    // Timer de inactividad: si no se escribe durante 20s en modo auth, regresa suavemente al reloj ambiental
    Timer {
        id: idleTimer
        interval: 20000
        repeat: false
        running: root.showAuth && root.activePassword.length === 0 && !root.isAuthenticating
        onTriggered: {
            root.showAuth = false;
        }
    }

    // Reloj del sistema (actualización cada segundo)
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentTime = new Date()
    }

    // Disparador de la animación de entrada suave
    Timer {
        interval: 35
        running: true
        repeat: false
        onTriggered: root.entered = true
    }

    // Monitor de Bloqueo de Mayúsculas (Caps Lock)
    Process {
        id: capsProc
        command: ["sh", "-c", "cat /sys/class/leds/*::capslock/brightness 2>/dev/null | grep -q '1' && echo 1 || echo 0"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                root.capsLockOn = (line.trim() === "1");
            }
        }
    }
    Timer {
        interval: 400
        running: true
        repeat: true
        onTriggered: if (!capsProc.running) capsProc.running = true
    }

    // Proceso de autenticación seguro
    Process {
        id: authProc
        command: ["bash", Quickshell.shellDir + "/auth.sh"]
        stdinEnabled: true

        onStarted: {
            write(root.submittedPass + "\n");
        }

        onExited: (code, status) => {
            root.submittedPass = "";
            root.isAuthenticating = false;
            if (code === 0) {
                root.handleSuccess();
            } else {
                root.handleFailure();
            }
        }
    }

    // Comandos de energía del sistema
    Process {
        id: sysPower
        function exec(cmd) {
            command = ["sh", "-c", cmd];
            running = true;
        }
    }

    function submitAuth(pass) {
        if (root.isAuthenticating || root.authSuccess) return;
        if (!pass || pass.length === 0) return;

        root.authError = false;
        root.isAuthenticating = true;
        root.submittedPass = pass;
        authProc.running = true;
    }

    function handleSuccess() {
        root.authSuccess = true;
        root.authError = false;
        unlockTimer.restart();
    }

    function handleFailure() {
        root.authError = true;
        root.activePassword = "";
        if (typeof passInput !== "undefined") passInput.text = "";
        idleTimer.restart();
        errorTimer.restart();
    }

    // Timer para resetear el feedback de error
    Timer {
        id: errorTimer
        interval: 1600
        repeat: false
        onTriggered: root.authError = false
    }

    // Timer para desbloquear la sesión tras la animación de éxito
    Timer {
        id: unlockTimer
        interval: 240
        repeat: false
        onTriggered: {
            sessionLock.locked = false;
            killProc.terminate();
        }
    }

    // Proceso para terminar limpiamente el proceso de lockscreen
    Process {
        id: killProc
        function terminate() {
            command = ["kill", "-9", Quickshell.processId.toString()];
            running = true;
        }
    }

    // ==========================================
    // WAYLAND SESSION LOCK (ext-session-lock-v1)
    // ==========================================
    WlSessionLock {
        id: sessionLock
        locked: true

        surface: Component {
            WlSessionLockSurface {
                id: lockSurface
                color: Colors.backgroundPure

                FocusScope {
                    id: screenScope
                    anchors.fill: parent
                    focus: true

                    Component.onCompleted: passInput.forceActiveFocus()

                    // Interceptor invisible de teclado
                    TextInput {
                        id: passInput
                        anchors.fill: parent
                        opacity: 0
                        focus: true
                        text: root.activePassword

                        onTextChanged: {
                            if (root.activePassword !== text) {
                                root.activePassword = text;
                            }
                            if (text.length > 0 && !root.showAuth) {
                                root.showAuth = true;
                            }
                            idleTimer.restart();
                        }

                        Keys.onPressed: event => {
                            idleTimer.restart();
                            if (!root.showAuth) {
                                root.showAuth = true;
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    event.accepted = true;
                                    return;
                                }
                                if (event.key === Qt.Key_Space && root.activePassword.length === 0) {
                                    event.accepted = true;
                                    return;
                                }
                            }
                        }

                        Keys.onReturnPressed: {
                            idleTimer.restart();
                            if (root.showAuth) {
                                root.submitAuth(root.activePassword);
                            } else {
                                root.showAuth = true;
                            }
                        }

                        Keys.onEnterPressed: {
                            idleTimer.restart();
                            if (root.showAuth) {
                                root.submitAuth(root.activePassword);
                            } else {
                                root.showAuth = true;
                            }
                        }

                        Keys.onEscapePressed: event => {
                            idleTimer.restart();
                            if (root.activePassword.length > 0) {
                                root.activePassword = "";
                                text = "";
                                root.authError = false;
                            } else {
                                root.showAuth = false;
                            }
                            event.accepted = true;
                        }
                    }

                    // Detector táctil / clic en pantalla completa para despertar o reenfocar
                    MouseArea {
                        id: screenMouseArea
                        anchors.fill: parent
                        z: 1
                        hoverEnabled: true

                        property real lastX: -1
                        property real lastY: -1

                        onClicked: {
                            idleTimer.restart();
                            if (!root.showAuth) {
                                root.showAuth = true;
                            }
                            passInput.forceActiveFocus();
                        }

                        onPositionChanged: mouse => {
                            if (!root.showAuth) {
                                if (lastX >= 0 && lastY >= 0) {
                                    var dx = mouse.x - lastX;
                                    var dy = mouse.y - lastY;
                                    if ((dx * dx + dy * dy) > 3600) { // movimiento voluntario > 60px
                                        root.showAuth = true;
                                        idleTimer.restart();
                                        passInput.forceActiveFocus();
                                    }
                                }
                                lastX = mouse.x;
                                lastY = mouse.y;
                            } else {
                                idleTimer.restart();
                            }
                        }

                        onWheel: wheel => {
                            idleTimer.restart();
                            if (!root.showAuth) {
                                root.showAuth = true;
                                passInput.forceActiveFocus();
                            }
                        }
                    }

                    // ----------------------------------------------------
                    // CAPA DE FONDO: Obsidiana + Aura Esmeralda + Dot Matrix
                    // ----------------------------------------------------
                    Rectangle {
                        anchors.fill: parent
                        color: Colors.background
                    }

                    // Brillo ambiental esmeralda central difuso
                    RadialGradientBackground {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, 1000)
                        height: Math.min(parent.height, 800)
                        opacity: root.entered ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                    }

                    // Micro dot-matrix CAD
                    DotMatrixBackground {
                        spacing: 24
                        dotOpacity: root.entered ? 0.03 : 0.0
                        Behavior on dotOpacity { NumberAnimation { duration: 500 } }
                    }

                    // Marcas CAD perimetrales en las esquinas de la pantalla
                    CadCornerMarks {
                        markSize: 10
                        markColor: Colors.primary
                        opacity: root.entered ? 0.4 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 400 } }
                    }

                    // ----------------------------------------------------
                    // 1. CABECERA SUPERIOR
                    // ----------------------------------------------------
                    Item {
                        id: topHeader
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 28
                        height: 32
                        z: 3

                        opacity: (root.showAuth && root.entered) ? 1.0 : 0.0
                        y: (root.showAuth && root.entered) ? 0 : -25
                        visible: opacity > 0.01

                        Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.10 } }

                        RowLayout {
                            anchors.fill: parent

                            // Badge de seguridad
                            Rectangle {
                                height: 26
                                width: secBadgeRow.implicitWidth + 16
                                radius: height / 2
                                color: Colors.surfacePill
                                border.color: Colors.borderEmerald
                                border.width: 1

                                Row {
                                    id: secBadgeRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Rectangle {
                                        width: 5
                                        height: 5
                                        radius: 2.5
                                        color: Colors.primary
                                        anchors.verticalCenter: parent.verticalCenter

                                        SequentialAnimation on opacity {
                                            loops: Animation.Infinite
                                            NumberAnimation { to: 0.3; duration: 900; easing.type: Easing.InOutQuad }
                                            NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
                                        }
                                    }

                                    Text {
                                        text: "SWAY WAYLAND // SECURED SESSION"
                                        color: Colors.primary
                                        font.family: Colors.fontMono
                                        font.pixelSize: 9
                                        font.bold: true
                                        font.letterSpacing: 0.8
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Badge de Hostname / Usuario
                            Rectangle {
                                height: 26
                                width: hostBadgeRow.implicitWidth + 16
                                radius: height / 2
                                color: Colors.surfacePill
                                border.color: Colors.border
                                border.width: 1

                                Row {
                                    id: hostBadgeRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: "󰌾"
                                        color: Colors.textMuted
                                        font.family: Colors.fontMono
                                        font.pixelSize: 11
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: Quickshell.env("USER") + "@" + (Quickshell.env("HOSTNAME") || "sway")
                                        color: Colors.textMuted
                                        font.family: Colors.fontMono
                                        font.pixelSize: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }
                    }

                    // ----------------------------------------------------
                    // 2. HERO CONTAINER: RELOJ AMBIENTAL + LOCK ISLAND
                    // ----------------------------------------------------
                    Item {
                        id: heroContainer
                        anchors.fill: parent
                        z: 2

                        // SECCIÓN A: RELOJ Y FECHA APPLE-STYLE
                        Column {
                            id: clockSection
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: root.showAuth ? -150 : 0
                            spacing: 4

                            scale: root.showAuth ? 0.88 : (root.entered ? 1.0 : 0.92)
                            opacity: root.entered ? 1.0 : 0.0

                            Behavior on anchors.verticalCenterOffset {
                                NumberAnimation {
                                    duration: 520
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.10
                                }
                            }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 480
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 420
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatDateTime(root.currentTime, "hh:mm")
                                font.family: Colors.fontSans
                                font.pixelSize: 84
                                font.bold: true
                                color: "#ffffff"
                                font.letterSpacing: -1.0
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: {
                                    var d = Qt.formatDateTime(root.currentTime, "dddd, d 'de' MMMM");
                                    return d.charAt(0).toUpperCase() + d.slice(1);
                                }
                                font.family: Colors.fontSans
                                font.pixelSize: 16
                                font.weight: Font.Medium
                                color: Colors.textMuted
                                font.letterSpacing: 0.3
                            }
                        }

                        // PISTA AMBIENTAL MINIMALISTA (Visible únicamente en modo reposo)
                        Rectangle {
                            id: ambientHint
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: clockSection.bottom
                            anchors.topMargin: 32
                            height: 32
                            width: hintRow.implicitWidth + 28
                            radius: height / 2
                            color: Colors.surfacePill
                            border.color: Colors.borderEmerald
                            border.width: 1

                            opacity: (!root.showAuth && root.entered) ? 0.85 : 0.0
                            scale: (!root.showAuth && root.entered) ? 1.0 : 0.90
                            visible: opacity > 0.01

                            Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 360; easing.type: Easing.OutBack } }

                            Row {
                                id: hintRow
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: "󰌾"
                                    color: Colors.primary
                                    font.family: Colors.fontMono
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "Toca o pulsa cualquier tecla para desbloquear"
                                    color: Colors.textMuted
                                    font.family: Colors.fontSans
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            SequentialAnimation on opacity {
                                running: !root.showAuth && root.entered
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.45; duration: 1600; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 0.90; duration: 1600; easing.type: Easing.InOutSine }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    idleTimer.restart();
                                    root.showAuth = true;
                                    passInput.forceActiveFocus();
                                }
                            }
                        }

                        // SECCIÓN B: TARJETA CENTRAL (DYNAMIC ISLAND LOCK CARD)
                        Rectangle {
                            id: lockCard
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.horizontalCenterOffset: lockCard.xOffset
                            property real xOffset: 0
                            anchors.top: clockSection.bottom
                            anchors.topMargin: root.showAuth ? 20 : 45

                            width: 370
                            implicitHeight: cardContent.implicitHeight + 44
                            radius: 14
                            color: Colors.surface
                            border.color: root.authError
                                ? Colors.error
                                : (root.authSuccess ? Colors.primary : (root.isAuthenticating ? Colors.borderEmeraldGlow : Colors.borderEmerald))
                            border.width: 1
                            clip: true

                            opacity: (root.showAuth && root.entered) ? 1.0 : 0.0
                            scale: root.authSuccess ? 1.04 : ((root.showAuth && root.entered) ? 1.0 : 0.88)
                            visible: opacity > 0.001

                            Behavior on anchors.topMargin { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
                            Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: root.authSuccess ? 200 : 500; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }

                            // Animación de Agitado (Apple Shake) en caso de contraseña errónea
                            SequentialAnimation {
                                id: shakeAnim
                                NumberAnimation { target: lockCard; property: "xOffset"; to: -14; duration: 45; easing.type: Easing.OutQuad }
                                NumberAnimation { target: lockCard; property: "xOffset"; to: 14; duration: 50; easing.type: Easing.InOutQuad }
                                NumberAnimation { target: lockCard; property: "xOffset"; to: -10; duration: 50; easing.type: Easing.InOutQuad }
                                NumberAnimation { target: lockCard; property: "xOffset"; to: 10; duration: 50; easing.type: Easing.InOutQuad }
                                NumberAnimation { target: lockCard; property: "xOffset"; to: -5; duration: 45; easing.type: Easing.InOutQuad }
                                NumberAnimation { target: lockCard; property: "xOffset"; to: 5; duration: 45; easing.type: Easing.InOutQuad }
                                NumberAnimation { target: lockCard; property: "xOffset"; to: 0; duration: 40; easing.type: Easing.OutQuad }
                            }

                            Connections {
                                target: root
                                function onAuthErrorChanged() {
                                    if (root.authError) shakeAnim.restart();
                                }
                            }

                            // Marcas CAD en esquinas de la tarjeta
                            CadCornerMarks {
                                markSize: 6
                                markColor: root.authError ? Colors.error : Colors.primary
                                opacity: 0.45
                            }

                            // Línea superior de brillo especular
                            Rectangle {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 1
                                color: Qt.rgba(1, 1, 1, 0.08)
                            }

                            ColumnLayout {
                                id: cardContent
                                anchors.top: parent.top
                                anchors.topMargin: 22
                                anchors.left: parent.left
                                anchors.leftMargin: 22
                                anchors.right: parent.right
                                anchors.rightMargin: 22
                                spacing: 18

                                // Perfil de Usuario con Avatar Circular
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 8

                                    // Contenedor del Avatar
                                    Item {
                                        width: 72
                                        height: 72
                                        Layout.alignment: Qt.AlignHCenter

                                        // Halo exterior
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: width / 2
                                            color: Colors.surfacePill
                                            border.color: root.authError ? Colors.error : (root.authSuccess ? Colors.primary : Colors.borderEmerald)
                                            border.width: 1

                                            Behavior on border.color { ColorAnimation { duration: 150 } }
                                        }

                                        // Imagen de Avatar recortada perfectamente en círculo (sin esquinas)
                                        ClippingRectangle {
                                            anchors.fill: parent
                                            anchors.margins: 4
                                            radius: width / 2
                                            color: Colors.surfaceElevated

                                            Image {
                                                id: avatarImg
                                                anchors.fill: parent
                                                source: "file:///home/ivan/.face"
                                                fillMode: Image.PreserveAspectCrop
                                                sourceSize.width: 128
                                                sourceSize.height: 128
                                                visible: status === Image.Ready
                                                asynchronous: true
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                visible: !avatarImg.visible
                                                text: "󰀉"
                                                font.family: Colors.fontMono
                                                font.pixelSize: 30
                                                color: root.authError ? Colors.error : Colors.primary
                                            }
                                        }

                                        // Micro-LED de estado en borde inferior
                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            width: 9
                                            height: 9
                                            radius: 4.5
                                            color: root.authError ? Colors.error : (root.authSuccess ? Colors.primary : (root.isAuthenticating ? Colors.info : Colors.primary))
                                            border.color: Colors.surface
                                            border.width: 1.5
                                            z: 3

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: 13
                                                height: 13
                                                radius: 6.5
                                                color: parent.color
                                                opacity: 0.25
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: Quickshell.env("USER").toUpperCase()
                                        font.family: Colors.fontSans
                                        font.pixelSize: 14
                                        font.bold: true
                                        font.letterSpacing: 0.8
                                        color: Colors.text
                                    }
                                }

                                // Campo de Entrada de Contraseña (Cápsula Apple Obsidian)
                                Rectangle {
                                    id: passBox
                                    Layout.fillWidth: true
                                    height: 44
                                    radius: height / 2
                                    color: Colors.surfacePill
                                    border.color: root.authError
                                        ? Colors.error
                                        : (root.authSuccess
                                            ? Colors.primary
                                            : (root.isAuthenticating
                                                ? Colors.info
                                                : (passInput.activeFocus ? Colors.primary : Colors.border)))
                                    border.width: 1

                                    Behavior on border.color { ColorAnimation { duration: 120 } }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.IBeamCursor
                                        onClicked: passInput.forceActiveFocus()
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 14
                                        anchors.rightMargin: 6
                                        spacing: 10

                                        // Icono de Candado / Estado
                                        Text {
                                            Layout.alignment: Qt.AlignVCenter
                                            text: root.authSuccess ? "󰌿" : (root.authError ? "󰅖" : (root.isAuthenticating ? "󱑊" : "󰌾"))
                                            color: root.authError ? Colors.error : (root.authSuccess ? Colors.primary : (root.isAuthenticating ? Colors.info : Colors.primary))
                                            font.family: Colors.fontMono
                                            font.pixelSize: 15

                                            Behavior on color { ColorAnimation { duration: 120 } }
                                        }

                                        // Contenedor central: Puntos Dinámicos o Placeholder
                                        Item {
                                            Layout.fillWidth: true
                                            height: parent.height
                                            clip: true

                                            // Placeholder cuando está vacío
                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 2
                                                visible: root.activePassword.length === 0

                                                Text {
                                                    text: "Escriba la contraseña..."
                                                    color: Colors.textDim
                                                    font.family: Colors.fontSans
                                                    font.pixelSize: 11
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }

                                                // Cursor parpadeante
                                                Text {
                                                    text: "|"
                                                    color: Colors.primary
                                                    font.family: Colors.fontMono
                                                    font.pixelSize: 12
                                                    anchors.verticalCenter: parent.verticalCenter

                                                    SequentialAnimation on opacity {
                                                        loops: Animation.Infinite
                                                        NumberAnimation { to: 0.1; duration: 500 }
                                                        NumberAnimation { to: 1.0; duration: 500 }
                                                    }
                                                }
                                            }

                                            // Puntos elásticos esmeralda al escribir
                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                visible: root.activePassword.length > 0

                                                Repeater {
                                                    model: Math.min(root.activePassword.length, 20)

                                                    Rectangle {
                                                        width: 7
                                                        height: 7
                                                        radius: 3.5
                                                        color: root.authError ? Colors.error : (root.authSuccess ? Colors.primary : Colors.secondary)
                                                        border.color: root.authError ? Colors.danger : Colors.primary
                                                        border.width: 1

                                                        scale: 0.0
                                                        Component.onCompleted: scale = 1.0

                                                        Behavior on scale {
                                                            NumberAnimation {
                                                                duration: 160
                                                                easing.type: Easing.OutBack
                                                                easing.overshoot: 1.25
                                                            }
                                                        }
                                                        Behavior on color { ColorAnimation { duration: 120 } }
                                                    }
                                                }
                                            }
                                        }

                                        // Botón de Enviar (Flecha Enter)
                                        Rectangle {
                                            width: 32
                                            height: 32
                                            radius: 16
                                            Layout.alignment: Qt.AlignVCenter
                                            color: enterBtnMouse.containsMouse ? Colors.hover : "transparent"
                                            border.color: enterBtnMouse.containsMouse ? Colors.borderHover : "transparent"
                                            border.width: 1
                                            scale: enterBtnMouse.pressed ? 0.88 : (enterBtnMouse.containsMouse ? 1.06 : 1.0)

                                            Behavior on scale {
                                                NumberAnimation {
                                                    duration: enterBtnMouse.pressed ? 60 : 140
                                                    easing.type: Easing.OutBack
                                                    easing.overshoot: 1.15
                                                }
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰁔"
                                                color: root.activePassword.length > 0 ? Colors.primary : Colors.textDim
                                                font.family: Colors.fontMono
                                                font.pixelSize: 13
                                            }

                                            MouseArea {
                                                id: enterBtnMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.submitAuth(root.activePassword)
                                            }
                                        }
                                    }
                                }

                                // Badge de Bloqueo de Mayúsculas (Aparece sólo si está activo)
                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    height: root.capsLockOn ? 22 : 0
                                    width: capsRow.implicitWidth + 14
                                    radius: Colors.radiusSm
                                    color: Qt.rgba(245, 158, 11, 0.12)
                                    border.color: Colors.warning
                                    border.width: 1
                                    visible: height > 0
                                    clip: true

                                    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                                    Row {
                                        id: capsRow
                                        anchors.centerIn: parent
                                        spacing: 5

                                        Text {
                                            text: "󰪛"
                                            color: Colors.warning
                                            font.family: Colors.fontMono
                                            font.pixelSize: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: "BLOQ MAYÚS ACTIVADO"
                                            color: Colors.warning
                                            font.family: Colors.fontMono
                                            font.pixelSize: 8
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                                // Etiqueta de Estado / Mensaje de Retroalimentación
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: {
                                        if (root.authSuccess) return "[ ACCESO AUTORIZADO · DESBLOQUEANDO ]";
                                        if (root.authError) return "[ CONTRASEÑA INCORRECTA ]";
                                        if (root.isAuthenticating) return "[ VERIFICANDO CREDENCIALES... ]";
                                        return "[ PRESIONE ENTER PARA DESBLOQUEAR ]";
                                    }
                                    font.family: Colors.fontMono
                                    font.pixelSize: 9
                                    font.bold: root.authError || root.authSuccess
                                    font.letterSpacing: 0.6
                                    color: root.authError ? Colors.error : (root.authSuccess ? Colors.primary : (root.isAuthenticating ? Colors.info : Colors.textDim))

                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                            }
                        }
                    }

                    // ----------------------------------------------------
                    // 3. PIE INFERIOR (ACCIONES Y ATAJOS)
                    // ----------------------------------------------------
                    Item {
                        id: bottomFooter
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 28
                        height: 36
                        z: 3

                        opacity: (root.showAuth && root.entered) ? 1.0 : 0.0
                        y: (root.showAuth && root.entered) ? 0 : 25
                        visible: opacity > 0.01

                        Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.10 } }

                        RowLayout {
                            anchors.fill: parent

                            // Botón Suspender
                            Rectangle {
                                height: 28
                                width: suspRow.implicitWidth + 16
                                radius: height / 2
                                color: suspMouse.containsMouse ? Colors.hover : Colors.surfacePill
                                border.color: suspMouse.containsMouse ? Colors.borderHover : Colors.border
                                border.width: 1
                                scale: suspMouse.pressed ? 0.90 : 1.0

                                Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutBack } }

                                Row {
                                    id: suspRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Text {
                                        text: "󰤄"
                                        color: Colors.primary
                                        font.family: Colors.fontMono
                                        font.pixelSize: 11
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "SUSPENDER"
                                        color: Colors.textMuted
                                        font.family: Colors.fontSans
                                        font.pixelSize: 9
                                        font.bold: true
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    id: suspMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: sysPower.exec("systemctl suspend")
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Indicaciones de Atajos
                            Text {
                                text: "[ ESC ] VOLVER  ·  [ ENTER ] DESBLOQUEAR"
                                color: Colors.textDim
                                font.family: Colors.fontMono
                                font.pixelSize: 9
                                font.letterSpacing: 0.6
                                opacity: 0.65
                            }

                            Item { Layout.fillWidth: true }

                            // Botones de Reiniciar y Apagar
                            RowLayout {
                                spacing: 8

                                Rectangle {
                                    height: 28
                                    width: rebootRow.implicitWidth + 16
                                    radius: height / 2
                                    color: rebMouse.containsMouse ? Qt.rgba(245, 158, 11, 0.12) : Colors.surfacePill
                                    border.color: rebMouse.containsMouse ? Colors.warning : Colors.border
                                    border.width: 1
                                    scale: rebMouse.pressed ? 0.90 : 1.0

                                    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutBack } }

                                    Row {
                                        id: rebootRow
                                        anchors.centerIn: parent
                                        spacing: 5

                                        Text {
                                            text: "󰜉"
                                            color: Colors.warning
                                            font.family: Colors.fontMono
                                            font.pixelSize: 11
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: "REINICIAR"
                                            color: Colors.textMuted
                                            font.family: Colors.fontSans
                                            font.pixelSize: 9
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: rebMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: sysPower.exec("systemctl reboot")
                                    }
                                }

                                Rectangle {
                                    height: 28
                                    width: powerRow.implicitWidth + 16
                                    radius: height / 2
                                    color: pwrMouse.containsMouse ? Qt.rgba(239, 68, 68, 0.12) : Colors.surfacePill
                                    border.color: pwrMouse.containsMouse ? Colors.error : Colors.border
                                    border.width: 1
                                    scale: pwrMouse.pressed ? 0.90 : 1.0

                                    Behavior on scale { NumberAnimation { duration: 80; easing.type: Easing.OutBack } }

                                    Row {
                                        id: powerRow
                                        anchors.centerIn: parent
                                        spacing: 5

                                        Text {
                                            text: "󰐥"
                                            color: Colors.error
                                            font.family: Colors.fontMono
                                            font.pixelSize: 11
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Text {
                                            text: "APAGAR"
                                            color: Colors.textMuted
                                            font.family: Colors.fontSans
                                            font.pixelSize: 9
                                            font.bold: true
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: pwrMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: sysPower.exec("systemctl poweroff")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // COMPONENTE: GRADIENTE RADIAL AMBIENTAL
    // ==========================================
    component RadialGradientBackground: Item {
        Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            radius: Math.min(width, height) / 2
            color: Colors.primary
            opacity: 0.05
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.6
            height: parent.height * 0.6
            radius: Math.min(width, height) / 2
            color: Colors.primary
            opacity: 0.08
        }
    }
}
