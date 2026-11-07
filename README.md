# Quickshell Obsidian Emerald // Sway Desktop Shell

Una suite moderna, modular y ultraligera de interfaz de escritorio para **Wayland (Sway / SwayFX)** construida sobre **Quickshell** (Qt Quick / QML), inspirada en la precisión CAD y el diseño de interacción fluida estilo Apple (físicas elásticas, Dynamic Island y modo reposo ambiental).

---

## ✨ Características Principales

- **Barra Flotante Segmentada (3 Píldoras):**
  - **Píldora Izquierda:** Lanzador de aplicaciones y selector de escritorios Sway con indicador de cápsula líquida deslizante en tiempo real (0ms de latencia).
  - **Píldora Central (Dynamic Island):** Metamorfosis elástica entre reloj ambiental, banner de notificación entrante interactivo y contenedor de submódulos.
  - **Píldora Derecha:** Herramientas del sistema (DND / No molestar, Centro de Notificaciones con micro-LED reactivo, Historial de portapapeles, Selector de fondos de pantalla y Menú de energía).
- **Lanzador de Aplicaciones Multifunción:**
  - Búsqueda inteligente con alias técnicos (p. ej. *Vesktop* ➔ *Discord*, *Ghostty* ➔ *Terminal*).
  - **Calculadora integrada en tiempo real** (aritmética, porcentajes `200 + 10%`, funciones matemáticas `sqrt`, potencias y constantes) con historial y copia rápida.
  - **Selector visual de emojis** (178+ emojis clasificados, atajos de búsqueda inline `:fire:` y vista en cuadrícula táctil).
- **Servidor Nativo de Notificaciones D-Bus:**
  - Sustituye herramientas externas como `swaync`.
  - Filtro inteligente de iconos vs imágenes para Discord, Vesktop y apps Electron.
  - Alertas flotantes con cuenta atrás, descarte con clic derecho/rueda y foco automático de ventanas en Sway.
- **Pantalla de Bloqueo Standalone (`ext-session-lock-v1`):**
  - Protocolo nativo seguro de bloqueo Wayland.
  - **Modo Reposo:** Reloj y fecha minimalistas en el centro de la pantalla.
  - **Modo Activo:** Transición elástica al tocar cualquier tecla o clic, revelando avatar circular (`~/.face`), campo de contraseña con puntos dinámicos y animación *Apple Shake* ante errores.
- **Sistema de Capturas Integrado:**
  - Toast interactivo abajo a la derecha con previsualización inmediata.
  - Clic en cualquier punto para editar al instante en **Satty** o descarte con clic central.

---

## 📦 Dependencias y Programas Necesarios

Para que todas las funciones de la shell funcionen de forma óptima, se requieren los siguientes componentes:

### 1. Entorno Base
| Paquete | Descripción |
|---|---|
| `quickshell` | Framework de shell de escritorio Wayland basado en Qt Quick. |
| `sway` o `swayfx` | Compositor Wayland con soporte para IPC y Layer Shell. |

### 2. Utilidades del Sistema
| Paquete | Comando | Uso en la Shell |
|---|---|---|
| `wl-clipboard` | `wl-copy`, `wl-paste` | Copiado rápido de resultados de calculadora, emojis y capturas. |
| `cliphist` | `cliphist` | Demonio y almacenamiento del historial del portapapeles. |
| `satty` | `satty` | Editor y anotador visual de capturas de pantalla. |
| `grim` | `grim` | Captura de imagen en Wayland. |
| `slurp` | `slurp` | Selección interactiva de regiones de pantalla. |
| `awww` / `swww` | `awww` | Demonio de fondos de pantalla con transiciones suaves. |
| `libcanberra` | `canberra-gtk-play` | Efectos sonoros de notificaciones y disparador de cámara. |
| `thunar` (opcional) | `thunar` | Explorador de archivos para el botón de abrir carpeta de capturas. |

### 3. Fuentes Tipográficas Obligatorias
La paleta tipográfica y los iconos vectoriales dependen de:
- **`JetBrains Mono`** o **`MesloLGS Nerd Font`**: Iconos Nerd Font (`󱓞`, `󰂚`, `󰅍`, etc.) y números monospace.
- **`Inter`** o **`DejaVu Sans`**: Tipografía de interfaz y títulos.
- **`Noto Color Emoji`**: Renderizado a todo color del selector de emojis.

---

## 🚀 Guía de Instalación por Distribución

### NixOS (Flake / `configuration.nix` o Home Manager)
```nix
environment.systemPackages = with pkgs; [
  # Core
  quickshell
  swayfx
  
  # Utilidades
  wl-clipboard
  cliphist
  satty
  grim
  slurp
  awww        # o swww
  libcanberra-gtk3
  xfce.thunar

  # Fuentes
  inter
  nerd-fonts.jetbrains-mono
  nerd-fonts.meslo-lg
  noto-fonts-color-emoji
];
```

### Arch Linux / EndeavourOS (Pacman + AUR)
```bash
# Dependencias oficiales
sudo pacman -S --needed \
  wl-clipboard \
  cliphist \
  satty \
  grim \
  slurp \
  libcanberra \
  thunar \
  inter-font \
  ttf-jetbrains-mono-nerd \
  noto-fonts-emoji

# Quickshell y Demonio de Wallpapers (AUR)
yay -S quickshell-git awww
# (o swww si prefieres swww en lugar de awww)
```

### Fedora
```bash
sudo dnf install -y \
  wl-clipboard \
  cliphist \
  grim \
  slurp \
  libcanberra \
  satty \
  Thunar \
  rsms-inter-fonts \
  jetbrains-mono-fonts-all \
  google-noto-color-emoji-fonts
```

---

## 🛠️ Instalación y Puesta en Marcha

### 1. Clonar o copiar los archivos de configuración
Asegúrate de que esta carpeta se encuentre en `~/.config/quickshell`:
```bash
git clone <tu-repositorio> ~/.config/quickshell
```

### 2. Configurar la foto de perfil del Lockscreen (Opcional)
La pantalla de bloqueo recortará automáticamente en un círculo perfecto tu imagen personal si la colocas en:
```bash
cp /ruta/a/tu/foto.png ~/.face
```

### 3. Script de Captura de Pantalla (`~/.local/bin/captura.sh`)
Crea o edita el script en `~/.local/bin/captura.sh`:
```bash
mkdir -p ~/.local/bin
cat << 'EOF' > ~/.local/bin/captura.sh
#!/usr/bin/env bash
MODO="${1:-area}"
FECHA=$(date +'%Y-%m-%d_%H-%M-%S')
DIR_CAPTURAS="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$DIR_CAPTURAS"
ARCHIVO="$DIR_CAPTURAS/Screenshot_${FECHA}.png"

case "$MODO" in
    "area")
        GEOM=$(slurp -d 2>/dev/null)
        [ -z "$GEOM" ] && exit 0
        grim -g "$GEOM" "$ARCHIVO" || exit 1
        ;;
    "full")
        grim "$ARCHIVO" || exit 1
        ;;
    "satty")
        GEOM=$(slurp -d 2>/dev/null)
        [ -z "$GEOM" ] && exit 0
        canberra-gtk-play -i camera-shutter 2>/dev/null &
        grim -g "$GEOM" - | satty --filename - --early-exit --copy-command wl-copy
        exit 0
        ;;
esac

# Copiar al portapapeles y notificar a Quickshell
wl-copy --type image/png < "$ARCHIVO"
canberra-gtk-play -i camera-shutter 2>/dev/null &
quickshell ipc call screenshot display "$ARCHIVO" 2>/dev/null
EOF
chmod +x ~/.local/bin/captura.sh
```

---

## ⌨️ Integración con Sway (`~/.config/sway/config`)

Agrega estas líneas a tu archivo de configuración de Sway:

```sway
# --- Autostart ---
exec quickshell
exec awww-daemon --format xrgb
exec wl-paste --watch cliphist store
exec wl-paste --type image --watch cliphist store

# --- Atajos de Quickshell ---
# Lanzador de aplicaciones / Calculadora / Emojis
bindsym $mod+d exec quickshell ipc call bar toggle launcher

# Centro de notificaciones
bindsym $mod+n exec quickshell ipc call bar toggle notifications

# Gestor de portapapeles
bindsym $mod+v exec quickshell ipc call bar toggle clipboard

# Selector de fondos de pantalla
bindsym $mod+Shift+v exec quickshell ipc call bar toggle wallpaper

# Bloqueo de pantalla Quickshell
bindsym $mod+l exec ~/.config/quickshell/lockscreen/lock.sh

# Capturas de pantalla
bindsym $mod+Shift+s exec ~/.local/bin/captura.sh area
bindsym Print exec ~/.local/bin/captura.sh area
bindsym $mod+Shift+a exec ~/.local/bin/captura.sh satty
bindsym F12 exec ~/.local/bin/captura.sh full

# Regla de flotación para el editor Satty
for_window [app_id="satty"] floating enable
```

---

## 📂 Arquitectura Modular del Código

La shell está estructurada en módulos independientes y servicios singleton para facilitar su mantenimiento:

```text
~/.config/quickshell/
├── services/                          # Lógica global desacoplada (Singletons)
│   ├── qmldir                         # Registro de Singletons
│   ├── SwayService.qml                # Workspaces de Sway y eventos 0ms
│   ├── NotificationService.qml        # Servidor D-Bus, cola de notificaciones y DND
│   └── ScreenshotService.qml          # Toasts y acciones de captura de pantalla
│
├── modules/
│   ├── bar/                           # Componentes de la barra superior
│   │   ├── BarWindow.qml              # PanelWindow Wayland con máscaras de entrada
│   │   ├── LeftPill.qml               # Píldora 1: Launcher + Workspaces
│   │   ├── CenterPill.qml             # Píldora 2: Dynamic Island (Reloj, Notifs, Módulos)
│   │   └── RightPill.qml              # Píldora 3: Herramientas del sistema
│   ├── launcher/                      # AppLauncher.qml, MathEngine.js, EmojiData.js
│   ├── notifications/                 # NotificationCenter.qml, ScreenshotToast.qml
│   ├── calendar/                      # CalendarView.qml
│   ├── clipboard/                     # Clipboard.qml
│   ├── wallpaper/                     # WallpaperPicker.qml
│   └── power/                         # PowerMenu.qml
│
├── lockscreen/                        # Pantalla de bloqueo independiente
│   ├── shell.qml                      # Bloqueo Wayland con WlSessionLock
│   ├── lock.sh                        # Lanzador de bloqueo
│   └── auth.sh                        # Validador PAM / setuid unix_chkpwd
│
├── theme/
│   └── Colors.qml                     # Paleta de colores Obsidian Precision / Emerald
│
└── shell.qml                          # Orquestador principal conciso (~90 líneas)
```

---

## 💡 Control por Terminal (IPC)

Puedes interactuar con la shell en cualquier momento desde scripts o tu terminal:

```bash
# Alternar cualquier módulo en la pantalla enfocada
quickshell ipc call bar toggle launcher
quickshell ipc call bar toggle notifications
quickshell ipc call bar toggle clipboard
quickshell ipc call bar toggle wallpaper
quickshell ipc call bar toggle calendar
quickshell ipc call bar toggle power

# Cerrar cualquier módulo abierto
quickshell ipc call bar close

# Disparar un toast de captura manualmente
quickshell ipc call screenshot display "/ruta/a/imagen.png"
```
