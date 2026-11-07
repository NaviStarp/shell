.pragma library

// ==============================================================================
// MathEngine.js - Motor de evaluación matemática seguro para Quickshell
// ==============================================================================

function evaluateMath(expr) {
    if (!expr) return null;
    var s = expr.trim();
    if (s.startsWith("=")) {
        s = s.substring(1).trim();
    }
    if (s === "") return null;

    // 1. Porcentajes de una cantidad: "15% of 200", "20% * 80"
    var mPercentOf = s.match(/^(\d+(?:\.\d+)?)\s*%\s*(?:of|\*)\s*(\d+(?:\.\d+)?)$/i);
    if (mPercentOf) {
        var p = parseFloat(mPercentOf[1]);
        var tot = parseFloat(mPercentOf[2]);
        var r = (p / 100.0) * tot;
        return {
            "result": r,
            "formula": p + "% de " + tot,
            "formatted": (Math.round(r * 100000000) / 100000000).toString()
        };
    }

    // 2. Suma o resta porcentual: "200 + 10%", "150 - 20%"
    var mAddPct = s.match(/^(\d+(?:\.\d+)?)\s*([\+\-])\s*(\d+(?:\.\d+)?)\s*%$/);
    if (mAddPct) {
        var base = parseFloat(mAddPct[1]);
        var op = mAddPct[2];
        var pct = parseFloat(mAddPct[3]);
        var diff = base * (pct / 100.0);
        var r2 = op === "+" ? (base + diff) : (base - diff);
        return {
            "result": r2,
            "formula": base + " " + op + " " + pct + "%",
            "formatted": (Math.round(r2 * 100000000) / 100000000).toString()
        };
    }

    // 3. Normalizar operadores y constantes comunes
    var clean = s.replace(/×/g, "*")
                 .replace(/÷/g, "/")
                 .replace(/\^/g, "**")
                 .replace(/\bpi\b/gi, "Math.PI")
                 .replace(/π/g, "Math.PI")
                 .replace(/\be\b/gi, "Math.E")
                 .replace(/\bsqrt\b/gi, "Math.sqrt")
                 .replace(/\babs\b/gi, "Math.abs")
                 .replace(/\bsin\b/gi, "Math.sin")
                 .replace(/\bcos\b/gi, "Math.cos")
                 .replace(/\btan\b/gi, "Math.tan")
                 .replace(/\blog\b/gi, "Math.log10")
                 .replace(/\bln\b/gi, "Math.log")
                 .replace(/\bround\b/gi, "Math.round")
                 .replace(/\bfloor\b/gi, "Math.floor")
                 .replace(/\bceil\b/gi, "Math.ceil");

    // 4. Verificación de seguridad estricta: solo números, operadores y funciones matemáticas permitidas
    var testStr = clean.replace(/Math\.(PI|E|sqrt|abs|sin|cos|tan|log10|log|round|floor|ceil)/g, "");
    if (!/^[0-9\.\+\-\*\/\%\s\(\)\,]+$/.test(testStr)) {
        return null;
    }

    // Debe contener al menos un operador o función matemática para no interpretar un número suelto
    if (!/[\+\-\*\/\%\(]/.test(clean) && clean.indexOf("Math.") === -1) {
        return null;
    }

    // 5. Evaluación segura
    try {
        var fn = new Function("return (" + clean + ");");
        var val = fn();
        if (typeof val === "number" && !isNaN(val) && isFinite(val)) {
            var formatted = Math.round(val * 100000000) / 100000000;
            return {
                "result": formatted,
                "formula": expr.trim(),
                "formatted": formatted.toString()
            };
        }
    } catch(e) {}

    return null;
}
