import Foundation

public enum LoopingBuiltInAnalyzer {
    public static func buildAst(_ code: String) -> [AstNodeItem] {
        guard !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        let lines = code.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        var roots: [AstNodeItem] = []
        var activeContainerIndex: Int? = nil

        for (idx, raw) in lines.enumerated() {
            let trim = raw.trimmingCharacters(in: .whitespaces)
            if trim.isEmpty || trim.hasPrefix("#") || trim.hasPrefix("//") { continue }

            let lineNum = idx + 1
            let indent = raw.prefix { $0 == " " || $0 == "\t" }.count
            var node: AstNodeItem? = nil

            if trim.hasPrefix("@app") {
                node = AstNodeItem(lineNumber: lineNum, kind: "AppHeader", name: extractQuoted(trim, fallback: "@app"), detail: trim)
            } else if trim.hasPrefix("define game3d") {
                node = AstNodeItem(lineNumber: lineNum, kind: "Game3DDecl", name: extractQuoted(trim, fallback: "Game3D"), detail: trim)
            } else if trim.hasPrefix("define game") {
                node = AstNodeItem(lineNumber: lineNum, kind: "Game2DDecl", name: extractQuoted(trim, fallback: "Game2D"), detail: trim)
            } else if trim.hasPrefix("define app") {
                node = AstNodeItem(lineNumber: lineNum, kind: "AppDecl", name: extractQuoted(trim, fallback: "App"), detail: trim)
            } else if trim.hasPrefix("view ") && trim.hasSuffix("{") {
                let parts = trim.split(separator: " ")
                node = AstNodeItem(lineNumber: lineNum, kind: "SwiftUIView", name: parts.count > 1 ? String(parts[1]) : "View", detail: "SwiftUI Declarative")
            } else if trim.hasPrefix("component ") {
                node = AstNodeItem(lineNumber: lineNum, kind: "Component2", name: extractQuoted(trim, fallback: "Component2"), detail: trim)
            } else if trim.hasPrefix("use ") || trim.hasPrefix("import ") {
                node = AstNodeItem(lineNumber: lineNum, kind: "ImportStmt", name: trim, detail: "Module")
            } else if trim.hasPrefix("cs!") {
                node = AstNodeItem(lineNumber: lineNum, kind: "CSharpBlock", name: "CSharpMonoBehaviour", detail: trim)
            } else if trim.hasPrefix("py!") || trim.hasPrefix("insert pysnippet") {
                node = AstNodeItem(lineNumber: lineNum, kind: "PyFastPath", name: "NativePyEval", detail: trim)
            } else if trim.hasPrefix("fn ") {
                node = AstNodeItem(lineNumber: lineNum, kind: "FunctionDecl", name: extractIdentAfter(trim, prefix: "fn "), detail: trim)
            } else if trim.hasPrefix("let ") || trim.hasPrefix("mut ") || trim.hasPrefix("val ") || trim.hasPrefix("set ") {
                let firstTok = String(trim.split(separator: " ").first ?? "val")
                node = AstNodeItem(lineNumber: lineNum, kind: "VarDecl", name: extractIdentAfter(trim, prefix: firstTok + " "), detail: trim)
            } else if trim.hasPrefix("scene3d.") || trim.hasPrefix("camera3d.") || trim.hasPrefix("light3d.") || trim.hasPrefix("physics3d.") {
                let fn = String(trim.split(separator: "(").first ?? "scene3d")
                node = AstNodeItem(lineNumber: lineNum, kind: "Quantum3D", name: fn, detail: trim)
            } else if trim.hasPrefix("spawn3d.") || trim.hasPrefix("spawn.") {
                let fn = String(trim.split(separator: "(").first ?? "spawn")
                node = AstNodeItem(lineNumber: lineNum, kind: "EntitySpawn", name: extractQuoted(trim, fallback: fn), detail: trim)
            } else if trim.hasPrefix("ui.") || trim.hasPrefix("draw ") || trim.hasPrefix("window.") || trim.hasPrefix("create window") {
                node = AstNodeItem(lineNumber: lineNum, kind: "UiDirective", name: String(trim.prefix(44)), detail: trim)
            } else if trim.hasPrefix("say(") || trim.hasPrefix("print") || trim.hasPrefix("out(") {
                node = AstNodeItem(lineNumber: lineNum, kind: "OutputStmt", name: String(trim.prefix(40)), detail: trim)
            }

            guard let built = node else { continue }
            let isContainer = ["Game3DDecl", "Game2DDecl", "AppDecl", "SwiftUIView", "Component2"].contains(built.kind)

            if indent == 0 || isContainer || built.kind == "AppHeader" {
                roots.append(built)
                activeContainerIndex = isContainer ? (roots.count - 1) : nil
            } else if let cIdx = activeContainerIndex {
                roots[cIdx].children.append(built)
            } else {
                roots.append(built)
            }
        }
        return roots
    }

    public static func checkCode(_ code: String) -> [DiagnosticItem] {
        guard !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return [DiagnosticItem(severity: "Warning", line: 1, message: "El script está vacío.")]
        }
        let lines = code.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        var diags: [DiagnosticItem] = []
        var braceBalance = 0
        var parenBalance = 0

        for (idx, line) in lines.enumerated() {
            let trim = line.trimmingCharacters(in: .whitespaces)
            if trim.isEmpty || trim.hasPrefix("#") || trim.hasPrefix("//") { continue }
            var inSingle = false
            var inDouble = false
            var escaped = false
            for ch in line {
                if escaped { escaped = false; continue }
                if ch == "\\" && (inSingle || inDouble) { escaped = true; continue }
                if ch == "'" && !inDouble { inSingle.toggle(); continue }
                if ch == "\"" && !inSingle { inDouble.toggle(); continue }
                if !inSingle && !inDouble {
                    if ch == "{" { braceBalance += 1 }
                    else if ch == "}" { braceBalance -= 1 }
                    else if ch == "(" { parenBalance += 1 }
                    else if ch == ")" { parenBalance -= 1 }
                    if braceBalance < 0 {
                        diags.append(DiagnosticItem(severity: "Error", line: idx + 1, message: "Llave de cierre '}' inesperada."))
                        braceBalance = 0
                    }
                    if parenBalance < 0 {
                        diags.append(DiagnosticItem(severity: "Error", line: idx + 1, message: "Paréntesis ')' inesperado."))
                        parenBalance = 0
                    }
                }
            }
        }

        if braceBalance > 0 {
            diags.append(DiagnosticItem(severity: "Error", line: lines.count, message: "Falta cerrar \(braceBalance) llave(s) '}'."))
        }
        if parenBalance > 0 {
            diags.append(DiagnosticItem(severity: "Error", line: lines.count, message: "Falta cerrar \(parenBalance) paréntesis ')'."))
        }
        if diags.isEmpty {
            diags.append(DiagnosticItem(severity: "OK", line: 1, message: "Verificación sintáctica limpia en Arch 3.1A."))
        }
        return diags
    }

    private static func extractQuoted(_ text: String, fallback: String) -> String {
        guard let first = text.firstIndex(of: "\"") else { return fallback }
        let after = text.index(after: first)
        guard let second = text[after...].firstIndex(of: "\"") else { return fallback }
        let val = String(text[after..<second])
        return val.isEmpty ? fallback : val
    }

    private static func extractIdentAfter(_ text: String, prefix: String) -> String {
        guard text.hasPrefix(prefix) else { return text }
        let rest = text.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
        let ident = rest.prefix { $0.isLetter || $0.isNumber || $0 == "_" }
        return ident.isEmpty ? String(rest.prefix(24)) : String(ident)
    }
}
