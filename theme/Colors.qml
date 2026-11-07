pragma Singleton
import QtQuick

QtObject {
    // ==========================================
    // PALETA OBSIDIAN PRECISION - REFINED GLASS
    // ==========================================

    // Fondos principales en escala carbón ultra profunda
    readonly property color background:        "#010302"
    readonly property color backgroundPure:    "#000000"

    // Superficies pulidas con profundidad táctil
    readonly property color surface:           "#070d0a" // Superficie base obsidiana
    readonly property color surfacePill:       "#0a120e" // Pistas segmentadas / contenedores
    readonly property color surfaceElevated:   "#0e1813" // Celdas seleccionadas / elevadas
    readonly property color surfaceCard:       "#09110d"
    readonly property color overlay:           "#111c16"

    // Acento Esmeralda (#10b981) - OLED Glow
    readonly property color primary:           "#10b981"
    readonly property color primaryGlow:       Qt.rgba(0.063, 0.725, 0.506, 0.18)
    readonly property color primarySubtle:     Qt.rgba(0.063, 0.725, 0.506, 0.08)
    readonly property color secondary:         "#34d399"
    readonly property color secondaryMuted:    Qt.rgba(0.063, 0.725, 0.506, 0.28)

    // Bordes translúcidos de alta definición
    readonly property color border:            Qt.rgba(1, 1, 1, 0.08)
    readonly property color borderHover:       Qt.rgba(1, 1, 1, 0.16)
    readonly property color borderHighlight:   Qt.rgba(1, 1, 1, 0.12)
    readonly property color borderEmerald:     Qt.rgba(0.063, 0.725, 0.506, 0.32)
    readonly property color borderEmeraldGlow: Qt.rgba(0.063, 0.725, 0.506, 0.65)

    // Estados de interacción
    readonly property color hover:             Qt.rgba(1, 1, 1, 0.05)
    readonly property color active:            Qt.rgba(0.063, 0.725, 0.506, 0.14)

    // Tipografía
    readonly property string fontSans:         "Inter, DejaVu Sans, sans-serif"
    readonly property string fontMono:         "JetBrains Mono, MesloLGS Nerd Font, monospace"

    readonly property color text:              "#f3f4f6" // Blanco frío nítido
    readonly property color textMuted:         "#9ca3af" // Gris medio elegante
    readonly property color textDim:           "#64748b" // Metadatos tenues
    readonly property color textTechnical:     "#10b981" // Verde esmeralda para tags activos

    // Estados del sistema
    readonly property color error:             "#ef4444"
    readonly property color danger:            "#ef4444"
    readonly property color dangerSurface:     Qt.rgba(0.937, 0.267, 0.267, 0.15)
    readonly property color warning:           "#f59e0b"
    readonly property color info:              "#38bdf8"

    // Decoraciones CAD sutiles
    readonly property color cadMark:           Qt.rgba(0.063, 0.725, 0.506, 0.40)
    readonly property color cadMarkMuted:      Qt.rgba(1, 1, 1, 0.15)

    // Radios refinados (acordes con SwayFX corner_radius 10)
    readonly property int radiusXs:            3
    readonly property int radiusSm:            5
    readonly property int radiusMd:            6
    readonly property int radiusLg:            8
    readonly property int radiusXl:            10
}
