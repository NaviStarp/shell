import QtQuick
import "../theme"

Item {
    id: root
    anchors.fill: parent
    clip: true

    property int spacing: 24
    property real dotOpacity: 0.03
    property color dotColor: Qt.rgba(1, 1, 1, 1)

    Canvas {
        id: canvas
        anchors.fill: parent
        renderTarget: Canvas.FramebufferObject

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var s = root.spacing;
            var cx = width / 2;
            var cy = height / 2;
            var maxDist = Math.sqrt(cx * cx + cy * cy) || 1;
            var baseA = root.dotOpacity;

            for (var x = s / 2; x < width; x += s) {
                for (var y = s / 2; y < height; y += s) {
                    var dx = x - cx;
                    var dy = y - cy;
                    var dist = Math.sqrt(dx * dx + dy * dy);
                    // Radial attenuation (3% at center down to ~1.5% at edges)
                    var radialFalloff = 1.0 - (dist / maxDist) * 0.45;
                    var alpha = Math.max(0.008, baseA * radialFalloff);

                    ctx.fillStyle = "rgba(255, 255, 255, " + alpha.toFixed(4) + ")";
                    ctx.fillRect(Math.floor(x), Math.floor(y), 1.2, 1.2);
                }
            }
        }
    }
}
