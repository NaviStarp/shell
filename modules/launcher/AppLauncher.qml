import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../theme"
import "../../components"
import "EmojiData.js" as EmojiData
import "MathEngine.js" as MathEngine

Item {
    id: launcherRoot
    signal closeRequested()

    // ==========================================
    // ESTADO Y MODOS DEL LANZADOR
    // ==========================================
    // Modos disponibles: "apps" | "calc" | "emojis"
    property string currentMode: "apps"
    property string selectedCategory: "all"

    property var allApps: []
    property var filteredApps: []
    property int selectedIndex: 0

    property var filteredEmojis: []
    property int selectedEmojiIndex: 0

    property var calcHistory: []
    property var liveMathResult: null

    property string toastMessage: ""
    property bool toastVisible: false

    function showToast(msg) {
        toastMessage = msg;
        toastVisible = true;
        toastTimer.restart();
    }

    Timer {
        id: toastTimer
        interval: 1800
        repeat: false
        onTriggered: launcherRoot.toastVisible = false
    }

    // Copiador seguro de portapapeles (Wayland wl-copy + Quickshell)
    Process {
        id: copyProc
        function copyText(str) {
            command = ["wl-copy", str];
            running = true;
            Quickshell.clipboardText = str;
        }
    }

    // Proceso auxiliar para ejecutar comandos directos de terminal o scripts
    Process {
        id: sysCmd
        function exec(cmd) {
            command = ["sh", "-c", cmd + " &"];
            running = true;
            launcherRoot.closeRequested();
        }
    }

    // Función segura para resolver iconos de aplicación
    function resolveIconSource(ico) {
        if (!ico) return "";
        var s = ico.trim();
        if (!s) return "";
        if (s.startsWith("/") || s.startsWith("file://")) {
            return s.startsWith("file://") ? s : ("file://" + s);
        }
        try {
            var p = Quickshell.iconPath(s, true);
            if (p) return p;
        } catch(e) {}
        return "";
    }

    // ==========================================
    // 1. CARGA Y FILTRADO DE APLICACIONES
    // ==========================================
    function refreshApps() {
        var list = [];
        try {
            var rawApps = DesktopEntries.applications.values;
            for (var i = 0; i < rawApps.length; i++) {
                var app = rawApps[i];
                if (!app || app.noDisplay) continue;

                var appName = (app.name || app.id || "").trim();
                if (appName === "") continue;

                var idLow = (app.id || "").toLowerCase();
                var nameLow = appName.toLowerCase();
                var execLow = (app.execString || "").toLowerCase();

                var kwList = [];
                try {
                    if (app.keywords) {
                        for (var k = 0; k < app.keywords.length; k++) {
                            var kw = (app.keywords[k] || "").toString().trim().toLowerCase();
                            if (kw && kwList.indexOf(kw) === -1) kwList.push(kw);
                        }
                    }
                } catch(e) {}

                // Diccionario de aliases inteligentes
                if (idLow.indexOf("vesktop") !== -1 || nameLow.indexOf("vesktop") !== -1 || execLow.indexOf("vesktop") !== -1) {
                    var vAliases = ["discord", "disc", "vencord", "chat", "discord-desktop", "voip"];
                    for (var vi = 0; vi < vAliases.length; vi++) {
                        if (kwList.indexOf(vAliases[vi]) === -1) kwList.push(vAliases[vi]);
                    }
                }
                if (idLow.indexOf("brave") !== -1 || idLow.indexOf("zen") !== -1 || idLow.indexOf("firefox") !== -1 || idLow.indexOf("chromium") !== -1) {
                    var bAliases = ["browser", "navegador", "internet", "web"];
                    for (var bi = 0; bi < bAliases.length; bi++) {
                        if (kwList.indexOf(bAliases[bi]) === -1) kwList.push(bAliases[bi]);
                    }
                }
                if (idLow.indexOf("ghostty") !== -1 || idLow.indexOf("foot") !== -1 || idLow.indexOf("kitty") !== -1 || idLow.indexOf("alacritty") !== -1 || idLow.indexOf("xterm") !== -1) {
                    var tAliases = ["terminal", "consola", "shell", "bash"];
                    for (var ti = 0; ti < tAliases.length; ti++) {
                        if (kwList.indexOf(tAliases[ti]) === -1) kwList.push(tAliases[ti]);
                    }
                }
                if (idLow.indexOf("thunar") !== -1 || idLow.indexOf("nautilus") !== -1 || idLow.indexOf("dolphin") !== -1 || idLow.indexOf("yazi") !== -1) {
                    var fAliases = ["files", "archivos", "explorador", "carpetas", "file manager"];
                    for (var fi = 0; fi < fAliases.length; fi++) {
                        if (kwList.indexOf(fAliases[fi]) === -1) kwList.push(fAliases[fi]);
                    }
                }
                if (idLow.indexOf("pavucontrol") !== -1) {
                    var aAliases = ["audio", "volumen", "sound", "sonido", "pulseaudio", "pipewire"];
                    for (var ai = 0; ai < aAliases.length; ai++) {
                        if (kwList.indexOf(aAliases[ai]) === -1) kwList.push(aAliases[ai]);
                    }
                }
                if (idLow.indexOf("btop") !== -1 || idLow.indexOf("htop") !== -1) {
                    var sAliases = ["task manager", "system monitor", "procesos", "ram", "cpu"];
                    for (var si = 0; si < sAliases.length; si++) {
                        if (kwList.indexOf(sAliases[si]) === -1) kwList.push(sAliases[si]);
                    }
                }
                if (idLow.indexOf("nvim") !== -1 || idLow.indexOf("antigravity") !== -1 || idLow.indexOf("code") !== -1) {
                    var eAliases = ["editor", "codigo", "code", "ide", "text editor"];
                    for (var ei = 0; ei < eAliases.length; ei++) {
                        if (kwList.indexOf(eAliases[ei]) === -1) kwList.push(eAliases[ei]);
                    }
                }

                list.push({
                    "id": app.id,
                    "name": appName,
                    "genericName": (app.genericName || "").trim(),
                    "comment": (app.comment || "").trim(),
                    "icon": app.icon || "",
                    "entry": app,
                    "isCommand": false,
                    "isCalculation": false,
                    "isEmoji": false,
                    "keywordList": kwList,
                    "displayAlias": (idLow.indexOf("vesktop") !== -1) ? "Discord Client" : ""
                });
            }

            list.sort(function(a, b) {
                return a.name.localeCompare(b.name, undefined, { sensitivity: 'base' });
            });
        } catch(e) {}

        launcherRoot.allApps = list;
        filterContent();
    }

    // ==========================================
    // 2. FILTRADO MULTI-MODO Y AUTO-DETECCIÓN
    // ==========================================
    function filterContent() {
        var rawText = searchInput.text;
        var q = rawText.trim().toLowerCase();

        // 1. Evaluación matemática en tiempo real
        launcherRoot.liveMathResult = MathEngine.evaluateMath(rawText);

        // Si estamos en modo Emojis
        if (launcherRoot.currentMode === "emojis") {
            filterEmojis(q);
            return;
        }

        // Si estamos en modo Calculadora dedicado
        if (launcherRoot.currentMode === "calc") {
            return;
        }

        // MODO APPS: Búsqueda de aplicaciones con detección inteligente de cálculo y emojis
        var res = [];

        // Si se detecta un cálculo matemático, se coloca una tarjeta hero al inicio
        if (launcherRoot.liveMathResult !== null) {
            res.push({
                "id": "calc-result",
                "name": "= " + launcherRoot.liveMathResult.formatted,
                "genericName": "Cálculo Matemático",
                "comment": launcherRoot.liveMathResult.formula + "  // Presione Enter para copiar al portapapeles",
                "icon": "",
                "isCalculation": true,
                "calcValue": launcherRoot.liveMathResult.formatted,
                "formula": launcherRoot.liveMathResult.formula
            });
        }

        // Si el usuario escribe prefijo de emoji ":algo" o "emoji:algo"
        if (q.startsWith(":") || q.startsWith("emoji:")) {
            var eq = q.replace(/^emoji:/, "").replace(/^:/, "").replace(/:$/, "").trim();
            var emMatches = searchEmojis(eq, "all", 6);
            for (var em = 0; em < emMatches.length; em++) {
                var emItem = emMatches[em];
                res.push({
                    "id": "emoji-" + emItem.code,
                    "name": emItem.char + "  " + emItem.name,
                    "genericName": emItem.code,
                    "comment": "Copiar emoji '" + emItem.char + "' al portapapeles",
                    "icon": "",
                    "isEmoji": true,
                    "emojiChar": emItem.char,
                    "emojiName": emItem.name
                });
            }
        }

        if (q === "") {
            for (var a0 = 0; a0 < launcherRoot.allApps.length; a0++) {
                res.push(launcherRoot.allApps[a0]);
            }
        } else {
            var scoredList = [];

            for (var i = 0; i < launcherRoot.allApps.length; i++) {
                var it = launcherRoot.allApps[i];
                var score = 0;
                var nameLow = it.name.toLowerCase();
                var idLow = it.id.toLowerCase();
                var genericLow = it.genericName.toLowerCase();
                var commentLow = it.comment.toLowerCase();

                if (nameLow === q) {
                    score = 1000;
                } else if (nameLow.startsWith(q)) {
                    score = 800;
                } else {
                    for (var k = 0; k < it.keywordList.length; k++) {
                        var kw = it.keywordList[k];
                        if (kw === q) {
                            score = Math.max(score, 750);
                        } else if (kw.startsWith(q)) {
                            score = Math.max(score, 700);
                        } else if (kw.indexOf(q) !== -1) {
                            score = Math.max(score, 450);
                        }
                    }
                }

                if (score === 0 && nameLow.indexOf(q) !== -1) score = 500;
                if (score === 0 && genericLow.startsWith(q)) score = 400;
                else if (score === 0 && genericLow.indexOf(q) !== -1) score = 300;
                if (score === 0 && idLow.indexOf(q) !== -1) score = 250;
                if (score === 0 && commentLow.indexOf(q) !== -1) score = 150;

                if (score > 0) {
                    scoredList.push({ "item": it, "score": score });
                }
            }

            scoredList.sort(function(a, b) {
                if (b.score !== a.score) return b.score - a.score;
                return a.item.name.localeCompare(b.item.name);
            });

            for (var s = 0; s < scoredList.length; s++) {
                res.push(scoredList[s].item);
            }

            // Opción de comando directo de terminal
            if (!launcherRoot.liveMathResult && !q.startsWith(":")) {
                res.push({
                    "id": "cmd-" + q,
                    "name": q,
                    "genericName": "Comando directo de sistema",
                    "comment": "Presione Enter para ejecutar '" + q + "' en segundo plano",
                    "icon": "",
                    "entry": null,
                    "isCommand": true,
                    "isCalculation": false,
                    "isEmoji": false,
                    "keywordList": [],
                    "displayAlias": ""
                });
            }
        }

        launcherRoot.filteredApps = res;
        launcherRoot.selectedIndex = 0;
        if (appList.count > 0) {
            appList.positionViewAtIndex(0, ListView.Beginning);
        }
    }

    // ==========================================
    // 3. MOTOR DE BÚSQUEDA DE EMOJIS
    // ==========================================
    function searchEmojis(q, category, limit) {
        var all = EmojiData.list || [];
        var matches = [];
        var maxItems = limit || 200;

        for (var i = 0; i < all.length; i++) {
            var e = all[i];
            if (category && category !== "all" && e.cat !== category) continue;

            if (!q || q === "") {
                matches.push(e);
            } else {
                var match = false;
                if (e.name.toLowerCase().indexOf(q) !== -1) match = true;
                else if (e.code.toLowerCase().indexOf(q) !== -1) match = true;
                else if (e.char === q) match = true;
                else {
                    for (var k = 0; k < e.kw.length; k++) {
                        if (e.kw[k].toLowerCase().indexOf(q) !== -1) {
                            match = true;
                            break;
                        }
                    }
                }
                if (match) matches.push(e);
            }

            if (matches.length >= maxItems) break;
        }
        return matches;
    }

    function filterEmojis(q) {
        launcherRoot.filteredEmojis = searchEmojis(q, launcherRoot.selectedCategory, 200);
        launcherRoot.selectedEmojiIndex = 0;
    }

    // ==========================================
    // 4. ACCIONES DE EJECUCIÓN / COPIADO
    // ==========================================
    function launchIndex(idx) {
        if (launcherRoot.currentMode === "calc") {
            if (launcherRoot.liveMathResult !== null) {
                copyResult(launcherRoot.liveMathResult.formatted);
            }
            return;
        }

        if (launcherRoot.currentMode === "emojis") {
            if (idx >= 0 && idx < launcherRoot.filteredEmojis.length) {
                copyEmojiItem(launcherRoot.filteredEmojis[idx]);
            }
            return;
        }

        // Modo Apps
        if (idx < 0 || idx >= launcherRoot.filteredApps.length) return;
        var it = launcherRoot.filteredApps[idx];
        if (!it) return;

        if (it.isCalculation) {
            copyResult(it.calcValue);
        } else if (it.isEmoji) {
            copyEmoji(it.emojiChar, it.emojiName);
        } else if (it.isCommand) {
            sysCmd.exec(it.name);
        } else if (it.entry && typeof it.entry.execute === "function") {
            try {
                it.entry.execute();
            } catch(e) {
                sysCmd.exec(it.id);
            }
            launcherRoot.closeRequested();
        }
    }

    function copyResult(val) {
        copyProc.copyText(val);
        showToast("Copiado al portapapeles: " + val);

        // Guardar en historial de cálculos
        var hist = launcherRoot.calcHistory.slice();
        hist.unshift({
            "formula": searchInput.text.trim(),
            "result": val
        });
        if (hist.length > 8) hist.pop();
        launcherRoot.calcHistory = hist;

        launcherRoot.closeRequested();
    }

    function copyEmoji(ch, name) {
        copyProc.copyText(ch);
        showToast("Emoji copiado: " + ch + " (" + name + ")");
        launcherRoot.closeRequested();
    }

    function copyEmojiItem(em) {
        if (!em) return;
        copyEmoji(em.char, em.name);
    }

    // Cambiar de modo
    function setMode(mode) {
        launcherRoot.currentMode = mode;
        if (mode === "emojis") {
            filterEmojis(searchInput.text.trim().toLowerCase());
        } else {
            filterContent();
        }
        searchInput.forceActiveFocus();
    }

    // ==========================================
    // 5. INTERFAZ VISUAL OBSIDIAN & CAD
    // ==========================================
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        // ==========================================
        // CABECERA: TÍTULO + SEGMENTED SWITCHER (APPS | CALC | EMOJIS)
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                width: 3
                height: 14
                radius: 1.5
                color: Colors.primary
            }

            Text {
                text: "LANZADOR"
                color: Colors.text
                font.family: Colors.fontSans
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 0.8
            }

            Item { Layout.fillWidth: true }

            // Cápsula Segmentada de Modos (Estilo Apple)
            Rectangle {
                height: 26
                width: segRow.implicitWidth + 8
                radius: 13
                color: Colors.surfacePill
                border.color: Colors.border
                border.width: 1

                Row {
                    id: segRow
                    anchors.centerIn: parent
                    spacing: 2

                    // Componente de botón de modo
                    component ModeTab: Rectangle {
                        id: tabBtn
                        property string modeId: "apps"
                        property string iconChar: ""
                        property string labelText: ""
                        property bool isActive: launcherRoot.currentMode === modeId

                        width: tabContent.implicitWidth + 14
                        height: 20
                        radius: 10
                        color: isActive ? Colors.primaryGlow : (tabMouse.containsMouse ? Colors.hover : "transparent")
                        border.color: isActive ? Colors.primary : "transparent"
                        border.width: 1

                        scale: tabMouse.pressed ? 0.92 : (tabMouse.containsMouse ? 1.04 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }

                        Row {
                            id: tabContent
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: tabBtn.iconChar
                                color: tabBtn.isActive ? Colors.primary : (tabMouse.containsMouse ? Colors.text : Colors.textDim)
                                font.family: Colors.fontMono
                                font.pixelSize: 10
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: tabBtn.labelText
                                color: tabBtn.isActive ? Colors.primary : (tabMouse.containsMouse ? Colors.text : Colors.textMuted)
                                font.family: Colors.fontSans
                                font.pixelSize: 9
                                font.bold: tabBtn.isActive
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: launcherRoot.setMode(tabBtn.modeId)
                        }
                    }

                    ModeTab {
                        modeId: "apps"
                        iconChar: "󰣆"
                        labelText: "Apps"
                    }

                    ModeTab {
                        modeId: "calc"
                        iconChar: "󰃬"
                        labelText: "Calculadora"
                    }

                    ModeTab {
                        modeId: "emojis"
                        iconChar: "󰞅"
                        labelText: "Emojis"
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Badge de Estado / Contador
            Rectangle {
                height: 20
                width: countText.implicitWidth + 12
                radius: Colors.radiusSm
                color: Colors.surfacePill
                border.color: Colors.border
                border.width: 1

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: {
                        if (launcherRoot.currentMode === "apps") {
                            return launcherRoot.filteredApps.length + " ITEMS";
                        } else if (launcherRoot.currentMode === "calc") {
                            return "MODO MATEMÁTICO";
                        } else {
                            return launcherRoot.filteredEmojis.length + " EMOJIS";
                        }
                    }
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.5
                }
            }
        }

        // ==========================================
        // BUSCADOR PRINCIPAL (ESTILO RAYCAST)
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            height: 38
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

                // Micro-indicador LED de búsqueda
                Rectangle {
                    width: 4
                    height: 4
                    radius: 2
                    color: searchInput.activeFocus ? Colors.primary : Colors.textDim
                }

                // Icono dinámico según el modo
                Text {
                    text: {
                        if (launcherRoot.currentMode === "apps") return "󱓞";
                        if (launcherRoot.currentMode === "calc") return "󰃬";
                        return "󰞅";
                    }
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
                        text: {
                            if (launcherRoot.currentMode === "apps") {
                                return "Buscar apps, operaciones (ej. 15*8) o emojis (:fire)...";
                            } else if (launcherRoot.currentMode === "calc") {
                                return "Escriba una operación (ej. 120*1.21, sqrt(144), 15% of 200, 2^8)...";
                            } else {
                                return "Buscar emojis por nombre o categoría (ej. fuego, risa, corazon)...";
                            }
                        }
                        color: Colors.textDim
                        visible: !searchInput.text && !searchInput.activeFocus
                        font.family: Colors.fontMono
                        font.pixelSize: 11
                        opacity: 0.6
                    }

                    onTextChanged: launcherRoot.filterContent()

                    // Atajos de navegación entre modos con Tab / Shift+Tab cuando el texto está vacío
                    Keys.onTabPressed: {
                        if (searchInput.text === "") {
                            if (launcherRoot.currentMode === "apps") launcherRoot.setMode("calc");
                            else if (launcherRoot.currentMode === "calc") launcherRoot.setMode("emojis");
                            else launcherRoot.setMode("apps");
                        } else if (launcherRoot.currentMode === "apps") {
                            if (launcherRoot.filteredApps.length > 0) {
                                launcherRoot.selectedIndex = (launcherRoot.selectedIndex + 1) % launcherRoot.filteredApps.length;
                                appList.positionViewAtIndex(launcherRoot.selectedIndex, ListView.Contain);
                            }
                        }
                    }

                    Keys.onBacktabPressed: {
                        if (searchInput.text === "") {
                            if (launcherRoot.currentMode === "apps") launcherRoot.setMode("emojis");
                            else if (launcherRoot.currentMode === "emojis") launcherRoot.setMode("calc");
                            else launcherRoot.setMode("apps");
                        } else if (launcherRoot.currentMode === "apps") {
                            if (launcherRoot.filteredApps.length > 0) {
                                launcherRoot.selectedIndex = (launcherRoot.selectedIndex - 1 + launcherRoot.filteredApps.length) % launcherRoot.filteredApps.length;
                                appList.positionViewAtIndex(launcherRoot.selectedIndex, ListView.Contain);
                            }
                        }
                    }

                    // Navegación con flechas
                    Keys.onDownPressed: {
                        if (launcherRoot.currentMode === "apps") {
                            if (launcherRoot.filteredApps.length > 0 && launcherRoot.selectedIndex < launcherRoot.filteredApps.length - 1) {
                                launcherRoot.selectedIndex++;
                                appList.positionViewAtIndex(launcherRoot.selectedIndex, ListView.Contain);
                            }
                        } else if (launcherRoot.currentMode === "emojis") {
                            if (launcherRoot.filteredEmojis.length > 0 && launcherRoot.selectedEmojiIndex < launcherRoot.filteredEmojis.length - 1) {
                                launcherRoot.selectedEmojiIndex = Math.min(launcherRoot.selectedEmojiIndex + 8, launcherRoot.filteredEmojis.length - 1);
                                emojiGrid.positionViewAtIndex(launcherRoot.selectedEmojiIndex, GridView.Contain);
                            }
                        }
                    }

                    Keys.onUpPressed: {
                        if (launcherRoot.currentMode === "apps") {
                            if (launcherRoot.filteredApps.length > 0 && launcherRoot.selectedIndex > 0) {
                                launcherRoot.selectedIndex--;
                                appList.positionViewAtIndex(launcherRoot.selectedIndex, ListView.Contain);
                            }
                        } else if (launcherRoot.currentMode === "emojis") {
                            if (launcherRoot.filteredEmojis.length > 0 && launcherRoot.selectedEmojiIndex >= 8) {
                                launcherRoot.selectedEmojiIndex -= 8;
                                emojiGrid.positionViewAtIndex(launcherRoot.selectedEmojiIndex, GridView.Contain);
                            }
                        }
                    }

                    Keys.onRightPressed: {
                        if (launcherRoot.currentMode === "emojis") {
                            if (launcherRoot.selectedEmojiIndex < launcherRoot.filteredEmojis.length - 1) {
                                launcherRoot.selectedEmojiIndex++;
                                emojiGrid.positionViewAtIndex(launcherRoot.selectedEmojiIndex, GridView.Contain);
                            }
                        }
                    }

                    Keys.onLeftPressed: {
                        if (launcherRoot.currentMode === "emojis") {
                            if (launcherRoot.selectedEmojiIndex > 0) {
                                launcherRoot.selectedEmojiIndex--;
                                emojiGrid.positionViewAtIndex(launcherRoot.selectedEmojiIndex, GridView.Contain);
                            }
                        }
                    }

                    Keys.onReturnPressed: launcherRoot.launchIndex(launcherRoot.currentMode === "emojis" ? launcherRoot.selectedEmojiIndex : launcherRoot.selectedIndex)
                    Keys.onEnterPressed: launcherRoot.launchIndex(launcherRoot.currentMode === "emojis" ? launcherRoot.selectedEmojiIndex : launcherRoot.selectedIndex)
                    Keys.onEscapePressed: launcherRoot.closeRequested()
                }

                // Botón Limpiar búsqueda (X)
                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    visible: searchInput.text !== ""
                    color: clearMouse.containsMouse ? Colors.hover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: Colors.fontMono
                        font.pixelSize: 10
                        color: Colors.textMuted
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = "";
                            searchInput.forceActiveFocus();
                        }
                    }
                }
            }
        }

        // ==========================================
        // VISTA 1: APLICACIONES (CON CÁLCULO INLINE)
        // ==========================================
        ListView {
            id: appList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 3
            visible: launcherRoot.currentMode === "apps"

            model: launcherRoot.filteredApps

            delegate: Rectangle {
                id: itemRoot
                required property var modelData
                required property int index

                readonly property bool isSelected: launcherRoot.selectedIndex === index
                readonly property bool isHovered: itemMouse.containsMouse
                readonly property bool isCalc: itemRoot.modelData && itemRoot.modelData.isCalculation === true
                readonly property bool isEm: itemRoot.modelData && itemRoot.modelData.isEmoji === true
                readonly property string iconSrc: launcherRoot.resolveIconSource((itemRoot.modelData && itemRoot.modelData.icon) ? itemRoot.modelData.icon : "")

                width: appList.width
                height: isCalc ? 50 : 44
                radius: Colors.radiusSm
                color: isSelected
                    ? (isCalc ? Qt.rgba(0.063, 0.725, 0.506, 0.12) : Colors.surfaceElevated)
                    : (isHovered ? Colors.hover : (isCalc ? Qt.rgba(0.063, 0.725, 0.506, 0.04) : "transparent"))

                border.color: isSelected
                    ? Colors.primary
                    : (isHovered ? Colors.borderHover : (isCalc ? Colors.borderEmerald : "transparent"))
                border.width: 1

                scale: itemMouse.pressed ? 0.985 : 1.0
                Behavior on scale { NumberAnimation { duration: itemMouse.pressed ? 50 : 120; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 80 } }
                Behavior on border.color { ColorAnimation { duration: 80 } }

                // Micro-indicador LED de selección
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 6
                    width: 2.5
                    radius: 1
                    color: isCalc ? Colors.primary : Colors.primary
                    visible: itemRoot.isSelected
                }

                // 1. Contenedor de Icono
                Item {
                    id: iconBox
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: isCalc ? 30 : 26
                    height: isCalc ? 30 : 26

                    // Si es tarjeta de cálculo
                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: Colors.primaryGlow
                        border.color: Colors.borderEmerald
                        border.width: 1
                        visible: itemRoot.isCalc

                        Text {
                            anchors.centerIn: parent
                            text: "󰃬"
                            font.family: Colors.fontMono
                            font.pixelSize: 16
                            color: Colors.primary
                        }
                    }

                    // Si es tarjeta de emoji
                    Text {
                        anchors.centerIn: parent
                        visible: itemRoot.isEm
                        text: (itemRoot.modelData && itemRoot.modelData.emojiChar) ? itemRoot.modelData.emojiChar : ""
                        font.pixelSize: 20
                    }

                    // Si es aplicación normal
                    Image {
                        id: appImg
                        anchors.fill: parent
                        source: itemRoot.iconSrc
                        sourceSize.width: 26
                        sourceSize.height: 26
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        visible: !itemRoot.isCalc && !itemRoot.isEm && status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !itemRoot.isCalc && !itemRoot.isEm && !appImg.visible
                        text: (itemRoot.modelData && itemRoot.modelData.isCommand) ? "󰞷" : "󰣆"
                        font.family: Colors.fontMono
                        font.pixelSize: 15
                        color: itemRoot.isSelected ? Colors.primary : Colors.textDim
                    }
                }

                // 2. Columna de Textos
                Column {
                    id: textCol
                    anchors.left: iconBox.right
                    anchors.leftMargin: 12
                    anchors.right: actionTag.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Row {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: (itemRoot.modelData && itemRoot.modelData.name) ? itemRoot.modelData.name : ""
                            textFormat: Text.PlainText
                            color: itemRoot.isCalc ? Colors.primary : (itemRoot.isSelected ? Colors.text : Colors.textMuted)
                            font.family: itemRoot.isCalc ? Colors.fontMono : Colors.fontSans
                            font.pixelSize: itemRoot.isCalc ? 14 : 12
                            font.bold: itemRoot.isSelected || itemRoot.isCalc
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: itemRoot.modelData && ((itemRoot.modelData.displayAlias && itemRoot.modelData.displayAlias !== "") || (itemRoot.modelData.genericName && itemRoot.modelData.genericName !== ""))
                            textFormat: Text.PlainText
                            text: {
                                if (!itemRoot.modelData) return "";
                                if (itemRoot.modelData.displayAlias) return "// " + itemRoot.modelData.displayAlias;
                                if (itemRoot.modelData.genericName) return "// " + itemRoot.modelData.genericName;
                                return "";
                            }
                            color: (itemRoot.modelData && itemRoot.modelData.displayAlias) ? Colors.primary : Colors.textDim
                            font.family: Colors.fontMono
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        width: parent.width
                        visible: itemRoot.modelData && itemRoot.modelData.comment && itemRoot.modelData.comment !== ""
                        textFormat: Text.PlainText
                        text: (itemRoot.modelData && itemRoot.modelData.comment) ? itemRoot.modelData.comment : ""
                        color: itemRoot.isCalc ? Colors.text : Colors.textDim
                        font.family: Colors.fontMono
                        font.pixelSize: 9
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }
                }

                // 3. Etiqueta técnica de acción (derecha)
                Rectangle {
                    id: actionTag
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: (itemRoot.isCalc || itemRoot.isEm) ? 68 : 58
                    height: 20
                    radius: Colors.radiusSm
                    color: itemRoot.isSelected ? Colors.primaryGlow : "transparent"
                    border.color: itemRoot.isSelected ? Colors.primary : Colors.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (itemRoot.isCalc || itemRoot.isEm) return "COPIAR";
                            if (itemRoot.modelData && itemRoot.modelData.isCommand) return "RUN";
                            return "ABRIR";
                        }
                        font.family: Colors.fontMono
                        font.pixelSize: 8
                        font.letterSpacing: 0.8
                        font.weight: Font.DemiBold
                        color: itemRoot.isSelected ? Colors.primary : Colors.textDim
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: launcherRoot.selectedIndex = itemRoot.index
                    onClicked: launcherRoot.launchIndex(itemRoot.index)
                }
            }
        }

        // ==========================================
        // VISTA 2: CALCULADORA DEDICADA
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10
            visible: launcherRoot.currentMode === "calc"

            // Pantalla Hero de Resultado
            Rectangle {
                Layout.fillWidth: true
                height: 84
                radius: Colors.radiusMd
                color: Colors.surfacePill
                border.color: launcherRoot.liveMathResult ? Colors.primary : Colors.border
                border.width: 1

                Behavior on border.color { ColorAnimation { duration: 140 } }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: launcherRoot.liveMathResult ? (launcherRoot.liveMathResult.formula + " =") : "FÓRMULA MATEMÁTICA"
                            color: Colors.textDim
                            font.family: Colors.fontMono
                            font.pixelSize: 10
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        // Botón Copiar Resultado
                        Rectangle {
                            height: 22
                            width: copyBtnRow.implicitWidth + 14
                            radius: 11
                            color: copyBtnMouse.containsMouse ? Colors.hover : Colors.primaryGlow
                            border.color: Colors.primary
                            border.width: 1
                            visible: launcherRoot.liveMathResult !== null

                            scale: copyBtnMouse.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 80 } }

                            Row {
                                id: copyBtnRow
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: "󰆏"
                                    color: Colors.primary
                                    font.family: Colors.fontMono
                                    font.pixelSize: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: "COPIAR"
                                    color: Colors.primary
                                    font.family: Colors.fontMono
                                    font.pixelSize: 9
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: copyBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (launcherRoot.liveMathResult) {
                                        launcherRoot.copyResult(launcherRoot.liveMathResult.formatted);
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: launcherRoot.liveMathResult ? launcherRoot.liveMathResult.formatted : (searchInput.text === "" ? "0" : "[ Expresión incompleta ]")
                        color: launcherRoot.liveMathResult ? Colors.primary : (searchInput.text === "" ? Colors.textDim : Colors.textMuted)
                        font.family: Colors.fontMono
                        font.pixelSize: 26
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }

            // Barra de Botones de Acceso Rápido Matemático (Chips)
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                component CalcChip: Rectangle {
                    id: chip
                    property string symbol: ""
                    property string insertValue: symbol

                    height: 26
                    Layout.fillWidth: true
                    radius: Colors.radiusSm
                    color: chipMouse.containsMouse ? Colors.hover : Colors.surfacePill
                    border.color: chipMouse.containsMouse ? Colors.borderEmerald : Colors.border
                    border.width: 1

                    scale: chipMouse.pressed ? 0.90 : (chipMouse.containsMouse ? 1.05 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutBack } }

                    Text {
                        anchors.centerIn: parent
                        text: chip.symbol
                        color: chipMouse.containsMouse ? Colors.primary : Colors.text
                        font.family: Colors.fontMono
                        font.pixelSize: 11
                        font.bold: true
                    }

                    MouseArea {
                        id: chipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (chip.insertValue === "C") {
                                searchInput.text = "";
                            } else {
                                searchInput.text = searchInput.text + chip.insertValue;
                            }
                            searchInput.forceActiveFocus();
                        }
                    }
                }

                CalcChip { symbol: "+"; insertValue: " + " }
                CalcChip { symbol: "−"; insertValue: " - " }
                CalcChip { symbol: "×"; insertValue: " * " }
                CalcChip { symbol: "÷"; insertValue: " / " }
                CalcChip { symbol: "^"; insertValue: "^" }
                CalcChip { symbol: "√"; insertValue: "sqrt(" }
                CalcChip { symbol: "%"; insertValue: "%" }
                CalcChip { symbol: "( )"; insertValue: "(" }
                CalcChip { symbol: "π"; insertValue: "pi" }
                CalcChip { symbol: "e"; insertValue: "e" }
                CalcChip { symbol: "C"; insertValue: "C" }
            }

            // Historial de Cálculos Recientes
            Text {
                text: "HISTORIAL DE CÁLCULOS"
                color: Colors.textDim
                font.family: Colors.fontMono
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 0.8
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 3
                model: launcherRoot.calcHistory

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: parent ? parent.width : 0
                    height: 32
                    radius: Colors.radiusSm
                    color: hMouse.containsMouse ? Colors.surfaceElevated : Colors.surfacePill
                    border.color: hMouse.containsMouse ? Colors.borderEmerald : Colors.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        Text {
                            text: modelData.formula
                            color: Colors.textMuted
                            font.family: Colors.fontMono
                            font.pixelSize: 11
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "= " + modelData.result
                            color: Colors.primary
                            font.family: Colors.fontMono
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: hMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = modelData.formula;
                            launcherRoot.copyResult(modelData.result);
                        }
                    }
                }

                Item {
                    anchors.centerIn: parent
                    visible: launcherRoot.calcHistory.length === 0

                    Text {
                        anchors.centerIn: parent
                        text: "No hay cálculos recientes. Escriba una operación para calcular."
                        color: Colors.textDim
                        font.family: Colors.fontMono
                        font.pixelSize: 10
                    }
                }
            }
        }

        // ==========================================
        // VISTA 3: SELECTOR DE EMOJIS
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            visible: launcherRoot.currentMode === "emojis"

            // Selector de Categorías (Chips horizontales)
            ScrollView {
                Layout.fillWidth: true
                height: 28
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                Row {
                    spacing: 6

                    component CatChip: Rectangle {
                        id: catChip
                        property string catId: "all"
                        property string label: ""
                        property bool isSelected: launcherRoot.selectedCategory === catId

                        height: 24
                        width: catText.implicitWidth + 14
                        radius: 12
                        color: isSelected ? Colors.primaryGlow : (catMouse.containsMouse ? Colors.hover : Colors.surfacePill)
                        border.color: isSelected ? Colors.primary : Colors.border
                        border.width: 1

                        Text {
                            id: catText
                            anchors.centerIn: parent
                            text: catChip.label
                            color: catChip.isSelected ? Colors.primary : (catMouse.containsMouse ? Colors.text : Colors.textMuted)
                            font.family: Colors.fontSans
                            font.pixelSize: 9
                            font.bold: catChip.isSelected
                        }

                        MouseArea {
                            id: catMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                launcherRoot.selectedCategory = catChip.catId;
                                launcherRoot.filterEmojis(searchInput.text.trim().toLowerCase());
                            }
                        }
                    }

                    CatChip { catId: "all"; label: "Todos" }
                    CatChip { catId: "smileys"; label: "😀 Caras" }
                    CatChip { catId: "people"; label: "👍 Gestos" }
                    CatChip { catId: "animals"; label: "🐶 Animales" }
                    CatChip { catId: "food"; label: "🍔 Comida" }
                    CatChip { catId: "travel"; label: "🚀 Viajes" }
                    CatChip { catId: "objects"; label: "💡 Objetos" }
                    CatChip { catId: "symbols"; label: "❤️ Símbolos" }
                }
            }

            // GridView de Emojis
            GridView {
                id: emojiGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: Math.floor(emojiGrid.width / 8)
                cellHeight: 46

                model: launcherRoot.filteredEmojis

                delegate: Rectangle {
                    id: emojiCell
                    required property var modelData
                    required property int index

                    readonly property bool isSelected: launcherRoot.selectedEmojiIndex === index
                    readonly property bool isHovered: cellMouse.containsMouse

                    width: emojiGrid.cellWidth - 4
                    height: emojiGrid.cellHeight - 4
                    anchors.centerIn: parent
                    radius: Colors.radiusSm
                    color: isSelected ? Colors.surfaceElevated : (isHovered ? Colors.hover : Colors.surfacePill)
                    border.color: isSelected ? Colors.primary : (isHovered ? Colors.borderHover : Colors.border)
                    border.width: 1

                    scale: cellMouse.pressed ? 0.90 : (isHovered ? 1.15 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

                    Text {
                        anchors.centerIn: parent
                        text: emojiCell.modelData ? emojiCell.modelData.char : ""
                        font.pixelSize: 22
                    }

                    MouseArea {
                        id: cellMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: launcherRoot.selectedEmojiIndex = emojiCell.index
                        onClicked: launcherRoot.copyEmojiItem(emojiCell.modelData)
                    }
                }
            }

            // Barra inferior con información del emoji seleccionado
            Rectangle {
                Layout.fillWidth: true
                height: 28
                radius: Colors.radiusSm
                color: Colors.surfacePill
                border.color: Colors.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10

                    readonly property var currentEmoji: {
                        if (launcherRoot.selectedEmojiIndex >= 0 && launcherRoot.selectedEmojiIndex < launcherRoot.filteredEmojis.length) {
                            return launcherRoot.filteredEmojis[launcherRoot.selectedEmojiIndex];
                        }
                        return null;
                    }

                    Text {
                        text: parent.currentEmoji ? parent.currentEmoji.char : "󰞅"
                        font.pixelSize: 14
                    }

                    Text {
                        text: parent.currentEmoji ? (parent.currentEmoji.name + " (" + parent.currentEmoji.code + ")") : "Seleccione o busque un emoji"
                        color: Colors.text
                        font.family: Colors.fontSans
                        font.pixelSize: 10
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "Clic o Enter para copiar"
                        color: Colors.primary
                        font.family: Colors.fontMono
                        font.pixelSize: 9
                    }
                }
            }
        }
    }

    // ==========================================
    // NOTIFICACIÓN FLOTANTE (TOAST DE COPIADO)
    // ==========================================
    Rectangle {
        id: toastPill
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        height: 28
        width: toastRow.implicitWidth + 24
        radius: 14
        color: Colors.surfaceElevated
        border.color: Colors.primary
        border.width: 1
        z: 100

        visible: opacity > 0.01
        opacity: launcherRoot.toastVisible ? 1.0 : 0.0
        scale: launcherRoot.toastVisible ? 1.0 : 0.85

        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

        Row {
            id: toastRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: "󰄬"
                color: Colors.primary
                font.family: Colors.fontMono
                font.pixelSize: 11
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: launcherRoot.toastMessage
                color: Colors.text
                font.family: Colors.fontSans
                font.pixelSize: 10
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Component.onCompleted: {
        refreshApps();
    }

    onVisibleChanged: {
        if (visible) {
            refreshApps();
            searchInput.text = "";
            searchInput.forceActiveFocus();
        }
    }
}
