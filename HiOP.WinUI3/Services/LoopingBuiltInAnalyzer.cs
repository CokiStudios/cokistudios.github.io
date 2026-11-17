using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using HiOP.WinUI3.Models;

namespace HiOP.WinUI3.Services;

public static partial class LoopingBuiltInAnalyzer
{
    public static List<AstNodeItem> BuildAst(string code)
    {
        var nodes = new List<AstNodeItem>();
        if (string.IsNullOrWhiteSpace(code)) return nodes;

        var lines = code.Replace("\r\n", "\n").Split('\n');
        AstNodeItem? currentContainer = null;

        for (int i = 0; i < lines.Length; i++)
        {
            var raw = lines[i];
            var trim = raw.Trim();
            if (string.IsNullOrEmpty(trim) || trim.StartsWith('#') || trim.StartsWith("//"))
                continue;

            int lineNum = i + 1;
            var indent = raw.Length - raw.TrimStart().Length;
            AstNodeItem? item = null;

            if (trim.StartsWith("@app"))
                item = new AstNodeItem { LineNumber = lineNum, Kind = "AppHeader", Name = ExtractQuoted(trim, "@app"), Detail = trim };
            else if (trim.StartsWith("define game3d"))
                item = new AstNodeItem { LineNumber = lineNum, Kind = "Game3DDecl", Name = ExtractQuoted(trim, "game3d"), Detail = trim };
            else if (trim.StartsWith("define app"))
                item = new AstNodeItem { LineNumber = lineNum, Kind = "AppDecl", Name = ExtractQuoted(trim, "app"), Detail = trim };
            else if (trim.StartsWith("define module"))
                item = new AstNodeItem { LineNumber = lineNum, Kind = "ModuleDecl", Name = ExtractQuoted(trim, "module"), Detail = trim };
            else if (trim.StartsWith("view ") && trim.EndsWith('{'))
                item = new AstNodeItem { LineNumber = lineNum, Kind = "SwiftUIView", Name = trim.Split(' ')[1], Detail = "Declarative View" };
            else if (trim.StartsWith("component "))
                item = new AstNodeItem { LineNumber = lineNum, Kind = "Component2", Name = ExtractQuoted(trim, "component"), Detail = trim };
            else if (trim.StartsWith("use ") || trim.StartsWith("import ") || trim.StartsWith("from "))
                item = new AstNodeItem { LineNumber = lineNum, Kind = "ImportStmt", Name = trim, Detail = "Module / Bridge" };
            else if (trim.StartsWith("cs!"))
                item = new AstNodeItem { LineNumber = lineNum, Kind = "CSharpBlock", Name = "MonoBehaviour Interop", Detail = trim };
            else if (trim.StartsWith("insert pysnippet"))
                item = new AstNodeItem { LineNumber = lineNum, Kind = "PySnippet", Name = trim.Replace("insert pysnippet", "").Trim(':', ' '), Detail = "Python PyLoop Block" };
            else if (trim.StartsWith("fn "))
                item = new AstNodeItem { LineNumber = lineNum, Kind = "FunctionDecl", Name = ExtractIdentifierAfter(trim, "fn "), Detail = trim };
            else if (trim.StartsWith("let ") || trim.StartsWith("mut ") || trim.StartsWith("val ") || trim.StartsWith("set "))
                item = new AstNodeItem { LineNumber = lineNum, Kind = "VarDecl", Name = ExtractIdentifierAfter(trim, trim.Split(' ')[0] + " "), Detail = trim };
            else if (trim.StartsWith("scene3d.") || trim.StartsWith("camera3d.") || trim.StartsWith("light3d.") || trim.StartsWith("physics3d."))
                item = new AstNodeItem { LineNumber = lineNum, Kind = "Quantum3D", Name = trim.Split('(')[0], Detail = trim };
            else if (trim.StartsWith("spawn3d.") || trim.StartsWith("spawn.") || trim.StartsWith("obj3d."))
                item = new AstNodeItem { LineNumber = lineNum, Kind = "EntitySpawn", Name = ExtractQuoted(trim, trim.Split('(')[0]), Detail = trim };
            else if (trim.StartsWith("ui.") || trim.StartsWith("draw ") || trim.StartsWith("create window") || trim.StartsWith("window("))
                item = new AstNodeItem { LineNumber = lineNum, Kind = "UiDirective", Name = trim.Length > 48 ? trim[..48] + "..." : trim, Detail = trim };
            else if (trim.StartsWith("match ") || trim.Contains(" match "))
                item = new AstNodeItem { LineNumber = lineNum, Kind = "MatchExpr", Name = "Pattern Match", Detail = trim };
            else if (trim.StartsWith("print") || trim.StartsWith("out("))
                item = new AstNodeItem { LineNumber = lineNum, Kind = "OutputStmt", Name = trim.Length > 42 ? trim[..42] + "..." : trim, Detail = trim };

            if (item == null) continue;

            if (indent == 0 || item.Kind is "AppHeader" or "Game3DDecl" or "AppDecl" or "ModuleDecl" or "SwiftUIView" or "Component2")
            {
                nodes.Add(item);
                if (item.Kind is "Game3DDecl" or "AppDecl" or "ModuleDecl" or "SwiftUIView" or "Component2")
                    currentContainer = item;
                else
                    currentContainer = null;
            }
            else if (currentContainer != null)
            {
                currentContainer.Children.Add(item);
            }
            else
            {
                nodes.Add(item);
            }
        }

        return nodes;
    }

    public static List<DiagnosticItem> CheckCode(string code, string fileName = "script.loop")
    {
        var diagnostics = new List<DiagnosticItem>();
        if (string.IsNullOrWhiteSpace(code))
        {
            diagnostics.Add(new DiagnosticItem { Severity = "Warning", Line = 1, Message = "El archivo está vacío." });
            return diagnostics;
        }

        var lines = code.Replace("\r\n", "\n").Split('\n');
        int braceBalance = 0;
        int parenBalance = 0;
        bool hasCSharp = false;
        bool hasPy = false;
        bool hasQuantum3d = false;
        bool hasSwiftUi = false;

        for (int i = 0; i < lines.Length; i++)
        {
            var trim = lines[i].Trim();
            int ln = i + 1;
            if (string.IsNullOrEmpty(trim) || trim.StartsWith('#') || trim.StartsWith("//"))
                continue;

            if (trim.Contains("cs!")) hasCSharp = true;
            if (trim.Contains("pysnippet") || trim.Contains("use python") || trim.Contains("py!")) hasPy = true;
            if (trim.Contains("scene3d.") || trim.Contains("spawn3d.") || trim.Contains("define game3d")) hasQuantum3d = true;
            if (trim.StartsWith("view ") && trim.EndsWith('{')) hasSwiftUi = true;

            bool inSingle = false;
            bool inDouble = false;
            for (int c = 0; c < lines[i].Length; c++)
            {
                char ch = lines[i][c];
                if (c > 0 && lines[i][c - 1] == '\\') continue;
                if (ch == '"' && !inSingle) inDouble = !inDouble;
                else if (ch == '\'' && !inDouble) inSingle = !inSingle;
                else if (!inSingle && !inDouble)
                {
                    if (ch == '/' && c + 1 < lines[i].Length && lines[i][c + 1] == '/') break;
                    if (ch == '{') braceBalance++;
                    else if (ch == '}') braceBalance--;
                    else if (ch == '(') parenBalance++;
                    else if (ch == ')') parenBalance--;
                }
            }

            if (inDouble || inSingle)
            {
                diagnostics.Add(new DiagnosticItem
                {
                    Severity = "Error",
                    Line = ln,
                    Message = "Cadena de texto sin cerrar al final de la línea."
                });
            }

            if (braceBalance < 0)
            {
                diagnostics.Add(new DiagnosticItem
                {
                    Severity = "Error",
                    Line = ln,
                    Message = "Llave de cierre '}' inesperada sin apertura previa."
                });
                braceBalance = 0;
            }

            if (parenBalance < 0)
            {
                diagnostics.Add(new DiagnosticItem
                {
                    Severity = "Error",
                    Line = ln,
                    Message = "Paréntesis de cierre ')' inesperado sin apertura previa."
                });
                parenBalance = 0;
            }
        }

        if (braceBalance > 0)
            diagnostics.Add(new DiagnosticItem { Severity = "Error", Line = lines.Length, Message = $"Faltan {braceBalance} llave(s) de cierre '}}' al final del archivo." });
        if (parenBalance > 0)
            diagnostics.Add(new DiagnosticItem { Severity = "Error", Line = lines.Length, Message = $"Faltan {parenBalance} paréntesis de cierre ')' al final del archivo." });

        if (diagnostics.Count(d => d.Severity == "Error") == 0)
        {
            var features = new List<string>();
            if (hasQuantum3d) features.Add("Quantum 3D");
            if (hasCSharp) features.Add("C# MonoBehaviour");
            if (hasPy) features.Add("PyLoop Bridge");
            if (hasSwiftUi) features.Add("SwiftUI Transpiler");
            var featText = features.Count > 0 ? $" • Subsistemas: {string.Join(", ", features)}" : "";

            diagnostics.Add(new DiagnosticItem
            {
                Severity = "Info",
                Line = 1,
                Message = $"✔ Verificación estática limpia para {fileName} ({lines.Length} líneas{featText})."
            });
        }

        return diagnostics;
    }

    public static string FormatCode(string code)
    {
        if (string.IsNullOrEmpty(code)) return code;
        var lines = code.Replace("\r\n", "\n").Split('\n');
        var sb = new StringBuilder();
        int indent = 0;
        bool inColonBlock = false;

        foreach (var raw in lines)
        {
            var trim = raw.Trim();
            if (string.IsNullOrEmpty(trim))
            {
                sb.AppendLine();
                continue;
            }

            bool isClosingBrace = trim.StartsWith('}');
            if (isClosingBrace && indent > 0)
                indent--;

            // Keep single top-level indent when colon-style block is active
            int effectiveIndent = indent + (inColonBlock && !trim.StartsWith("define ") ? 1 : 0);
            if (trim.StartsWith("define ") || trim.StartsWith("@app ") || trim.StartsWith("view ") || trim.StartsWith("component "))
            {
                inColonBlock = false;
                effectiveIndent = indent;
            }

            sb.Append(new string(' ', Math.Max(0, effectiveIndent * 4)));
            sb.AppendLine(trim);

            if (trim.EndsWith('{') && !trim.StartsWith('#') && !trim.StartsWith("//"))
            {
                indent++;
            }
            else if ((trim.StartsWith("define ") || trim.StartsWith("insert pysnippet") || trim.StartsWith("code:")) && trim.EndsWith(':'))
            {
                inColonBlock = true;
            }
        }

        return sb.ToString().TrimEnd() + Environment.NewLine;
    }

    public static string GenerateSwiftUiOrC2PreviewSummary(string code)
    {
        var sb = new StringBuilder();
        var lines = code.Replace("\r\n", "\n").Split('\n');
        bool isC2 = lines.Any(l => l.TrimStart().StartsWith("component "));
        bool isSwift = lines.Any(l => l.TrimStart().StartsWith("view "));

        if (isSwift)
        {
            sb.AppendLine("// Transpilado por hiOP Studio (Arch 3.0A SwiftUI -> C#/WinUI & Swift Preview)");
            sb.AppendLine("import SwiftUI");
            sb.AppendLine();
            foreach (var raw in lines)
            {
                var t = raw.Trim();
                if (t.StartsWith("#") || string.IsNullOrEmpty(t)) continue;
                if (t.StartsWith("view "))
                    sb.AppendLine($"struct {t.Split(' ')[1]}: View {{");
                else if (t.StartsWith("@state "))
                    sb.AppendLine("    @State private var " + t["@state ".Length..]);
                else if (t.StartsWith("VStack") || t.StartsWith("HStack"))
                    sb.AppendLine("    var body: some View {\n        " + t);
                else
                    sb.AppendLine("    " + raw.TrimEnd());
            }
        }
        else if (isC2)
        {
            sb.AppendLine("╔═══════════════════════════════════════════════════════════╗");
            sb.AppendLine("║     COMPONENT 2 (.c2) INSPECTOR — SHINE OS / CS WEBS     ║");
            sb.AppendLine("╚═══════════════════════════════════════════════════════════╝");
            foreach (var raw in lines)
            {
                var t = raw.Trim();
                if (t.StartsWith("component ") || t.StartsWith("device:") || t.StartsWith("family:") || t.StartsWith("theme:") || t.StartsWith("fps:") || t.StartsWith("draw "))
                    sb.AppendLine("  ▸ " + t);
            }
        }
        else
        {
            sb.AppendLine("Este archivo no contiene bloques 'view { ... }' (SwiftUI) ni 'component { ... }' (.c2).");
            sb.AppendLine("Mostrando nodos AST detectados:");
            foreach (var node in BuildAst(code))
            {
                sb.AppendLine($"  • {node.LineDisplay}");
                foreach (var ch in node.Children)
                    sb.AppendLine($"     └─ {ch.LineDisplay}");
            }
        }

        return sb.ToString();
    }

    public static string ExtractPolyglotSummary(string code)
    {
        var sb = new StringBuilder();
        var csMatches = CSharpBlockRegex().Matches(code);
        var pyMatches = Regex.Matches(code, @"insert\s+pysnippet\s+as\s+([a-zA-Z0-9_]+)\s*:");

        sb.AppendLine($"Bloques C# MonoBehaviour (cs!): {csMatches.Count}");
        foreach (Match m in csMatches)
        {
            var body = m.Groups[1].Value.Trim();
            var classMatch = Regex.Match(body, @"class\s+([A-Za-z0-9_]+)");
            sb.AppendLine($"  • C# Class: {(classMatch.Success ? classMatch.Groups[1].Value : "EmbeddedBlock")} ({body.Length} chars)");
        }

        sb.AppendLine($"Snippets Python (PyLoop): {pyMatches.Count}");
        foreach (Match m in pyMatches)
        {
            sb.AppendLine($"  • pysnippet: {m.Groups[1].Value}");
        }

        return sb.ToString();
    }

    private static string ExtractQuoted(string text, string fallback)
    {
        var m = QuotedTextRegex().Match(text);
        return m.Success ? m.Groups[1].Value : fallback.Trim();
    }

    private static string ExtractIdentifierAfter(string text, string prefix)
    {
        var idx = text.IndexOf(prefix, StringComparison.Ordinal);
        if (idx < 0) return text;
        var rest = text[(idx + prefix.Length)..].Trim();
        var split = rest.Split([' ', '(', '=', ':'], StringSplitOptions.RemoveEmptyEntries);
        return split.Length > 0 ? split[0] : rest;
    }

    [GeneratedRegex(@"[\""']([^""']+)[\""']")]
    private static partial Regex QuotedTextRegex();

    [GeneratedRegex(@"cs!\s*\{([\s\S]*?)\n\s*\}", RegexOptions.Multiline)]
    private static partial Regex CSharpBlockRegex();
}
