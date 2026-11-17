using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;

namespace HiOP.WinUI3.Services;

public sealed class PrettierOptions
{
    public int TabWidth { get; set; } = 4;
    public bool UseTabs { get; set; } = false;
    public bool SingleQuote { get; set; } = false;
    public bool Semi { get; set; } = true;
    public int PrintWidth { get; set; } = 100;
    public bool FormatOnSave { get; set; } = false;
}

public sealed class PrettierResult
{
    public bool Success { get; init; }
    public string FormattedCode { get; init; } = string.Empty;
    public bool Changed { get; init; }
    public bool Unsupported { get; init; }
    public bool UsedFallback { get; init; }
    public string Version { get; init; } = string.Empty;
    public string ConfigFile { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
}

public sealed class PrettierService
{
    private static readonly UTF8Encoding Utf8NoBom = new(encoderShouldEmitUTF8Identifier: false);

    private static readonly HashSet<string> NativePrettierExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".js", ".mjs", ".cjs", ".jsx",
        ".ts", ".mts", ".cts", ".tsx",
        ".json", ".jsonc", ".json5",
        ".html", ".htm", ".css", ".scss", ".less",
        ".md", ".mdx", ".markdown",
        ".yaml", ".yml", ".vue", ".graphql", ".gql"
    };

    private static readonly HashSet<string> LoopingExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".loop", ".ruup", ".c2"
    };

    private static readonly HashSet<string> IgnoredScanDirs = new(StringComparer.OrdinalIgnoreCase)
    {
        ".git", "node_modules", "bin", "obj", "build", "dist", ".vs", ".smiledev", "AppPackages"
    };

    private readonly EngineProcessService _engine;

    public PrettierService(EngineProcessService engine)
    {
        _engine = engine;
    }

    public static bool IsSupportedExtension(string? filePath)
    {
        var ext = Path.GetExtension(filePath ?? string.Empty);
        return NativePrettierExtensions.Contains(ext) || LoopingExtensions.Contains(ext);
    }

    public (bool Available, string RunnerPath, string PrettierLocation, string NodePath) ProbeInstallation(string workspaceRoot)
    {
        var node = _engine.FindNodeExecutable() ?? string.Empty;
        var runner = ResolveRunnerScriptPath();
        var prettierLoc = ResolvePrettierPackagePath(workspaceRoot);
        bool ok = !string.IsNullOrEmpty(node) && !string.IsNullOrEmpty(runner) && !string.IsNullOrEmpty(prettierLoc);
        return (ok, runner, prettierLoc, node);
    }

    public async Task<string> GetVersionAsync(string workspaceRoot)
    {
        var (available, runner, _, node) = ProbeInstallation(workspaceRoot);
        if (!available) return string.Empty;

        try
        {
            var (exit, stdout, _) = await RunNodeRunnerAsync(node, runner, ["--version", "--workspace", workspaceRoot], string.Empty, workspaceRoot);
            if (exit == 0 && !string.IsNullOrWhiteSpace(stdout))
            {
                using var doc = JsonDocument.Parse(stdout);
                if (doc.RootElement.TryGetProperty("version", out var v))
                    return v.GetString() ?? string.Empty;
            }
        }
        catch { }
        return string.Empty;
    }

    public Task<PrettierResult> FormatAsync(string code, string filePath, string workspaceRoot, PrettierOptions? opts = null)
        => ExecutePrettierAsync(code, filePath, workspaceRoot, checkOnly: false, opts ?? new PrettierOptions());

    public Task<PrettierResult> CheckAsync(string code, string filePath, string workspaceRoot, PrettierOptions? opts = null)
        => ExecutePrettierAsync(code, filePath, workspaceRoot, checkOnly: true, opts ?? new PrettierOptions());

    private async Task<PrettierResult> ExecutePrettierAsync(
        string code,
        string filePath,
        string workspaceRoot,
        bool checkOnly,
        PrettierOptions opts)
    {
        var effectivePath = string.IsNullOrWhiteSpace(filePath) ? Path.Combine(workspaceRoot, "untitled.loop") : filePath;
        var (available, runner, _, node) = ProbeInstallation(workspaceRoot);

        if (!available)
        {
            return TryBuiltinFallback(code, effectivePath, checkOnly);
        }

        var args = new List<string>
        {
            checkOnly ? "--check" : "--format",
            "--filepath", effectivePath,
            "--workspace", workspaceRoot,
            "--tab-width", Math.Clamp(opts.TabWidth, 1, 8).ToString(),
            "--use-tabs", opts.UseTabs ? "true" : "false",
            "--single-quote", opts.SingleQuote ? "true" : "false",
            "--semi", opts.Semi ? "true" : "false",
            "--print-width", Math.Clamp(opts.PrintWidth, 40, 200).ToString()
        };

        try
        {
            var (exit, stdout, stderr) = await RunNodeRunnerAsync(node, runner, args, code, workspaceRoot);
            if (string.IsNullOrWhiteSpace(stdout))
            {
                return new PrettierResult
                {
                    Success = false,
                    FormattedCode = code,
                    Message = string.IsNullOrWhiteSpace(stderr) ? $"Prettier finalizó sin salida (exit {exit})." : stderr.Trim()
                };
            }

            using var doc = JsonDocument.Parse(stdout);
            var root = doc.RootElement;
            bool ok = root.TryGetProperty("ok", out var okEl) && okEl.GetBoolean();
            string ver = root.TryGetProperty("version", out var vEl) ? (vEl.GetString() ?? string.Empty) : string.Empty;
            string cfg = root.TryGetProperty("configFile", out var cEl) ? (cEl.GetString() ?? string.Empty) : string.Empty;

            if (!ok)
            {
                bool unsupported = root.TryGetProperty("unsupported", out var uEl) && uEl.GetBoolean();
                string err = root.TryGetProperty("error", out var eEl) ? (eEl.GetString() ?? "Error de Prettier") : "Error de Prettier";
                return new PrettierResult
                {
                    Success = false,
                    Unsupported = unsupported,
                    FormattedCode = code,
                    Version = ver,
                    ConfigFile = cfg,
                    Message = err
                };
            }

            string formatted = root.TryGetProperty("formatted", out var fEl) ? (fEl.GetString() ?? code) : code;
            bool changed = root.TryGetProperty("changed", out var chEl) && chEl.GetBoolean();

            string cfgNote = string.IsNullOrEmpty(cfg) ? "config por defecto" : Path.GetFileName(cfg);
            string msg = checkOnly
                ? (changed ? $"⚠ Requiere formateo Prettier v{ver} ({cfgNote})." : $"✔ Formato Prettier v{ver} correcto ({cfgNote}).")
                : (changed ? $"✔ Formateado con Prettier v{ver} ({cfgNote})." : $"✔ Ya estaba formateado según Prettier v{ver} ({cfgNote}).");

            return new PrettierResult
            {
                Success = true,
                FormattedCode = formatted,
                Changed = changed,
                Version = ver,
                ConfigFile = cfg,
                Message = msg
            };
        }
        catch (Exception ex)
        {
            return new PrettierResult
            {
                Success = false,
                FormattedCode = code,
                Message = $"Error ejecutando Prettier: {ex.Message}"
            };
        }
    }

    public async Task<(int FormattedCount, int CheckedCount, int ErrorCount)> FormatDirectoryAsync(
        string directory,
        PrettierOptions opts,
        Action<string> onLog,
        bool checkOnly = false,
        CancellationToken ct = default)
    {
        if (!Directory.Exists(directory))
        {
            onLog($"✘ El directorio no existe: {directory}");
            return (0, 0, 1);
        }

        var files = EnumerateSupportedFiles(directory).ToList();
        onLog($"✨ Prettier {(checkOnly ? "--check" : "--write")} sobre {files.Count} archivo(s) en {directory}...");

        int changedCount = 0;
        int checkedCount = 0;
        int errorCount = 0;

        foreach (var file in files)
        {
            if (ct.IsCancellationRequested) break;
            try
            {
                var original = await File.ReadAllTextAsync(file, Utf8NoBom, ct);
                var res = await ExecutePrettierAsync(original, file, directory, checkOnly, opts);
                checkedCount++;

                if (!res.Success)
                {
                    if (!res.Unsupported)
                    {
                        errorCount++;
                        onLog($"  ✘ {Path.GetRelativePath(directory, file)}: {res.Message}");
                    }
                    continue;
                }

                if (res.Changed)
                {
                    changedCount++;
                    if (!checkOnly)
                    {
                        await File.WriteAllTextAsync(file, res.FormattedCode, Utf8NoBom, ct);
                        onLog($"  ✨ Formateado: {Path.GetRelativePath(directory, file)}");
                    }
                    else
                    {
                        onLog($"  ⚠ Sin formato: {Path.GetRelativePath(directory, file)}");
                    }
                }
            }
            catch (Exception ex)
            {
                errorCount++;
                onLog($"  ✘ {Path.GetRelativePath(directory, file)}: {ex.Message}");
            }
        }

        onLog(checkOnly
            ? $"■ Prettier Check completado: {checkedCount} revisados, {changedCount} sin formatear, {errorCount} errores."
            : $"■ Prettier completado: {changedCount}/{checkedCount} archivo(s) actualizados, {errorCount} errores.");
        return (changedCount, checkedCount, errorCount);
    }

    public async Task<string> CreateConfigFileAsync(string directory, PrettierOptions opts)
    {
        Directory.CreateDirectory(directory);
        var path = Path.Combine(directory, ".prettierrc");
        var cfg = new
        {
            tabWidth = Math.Clamp(opts.TabWidth, 1, 8),
            useTabs = opts.UseTabs,
            singleQuote = opts.SingleQuote,
            semi = opts.Semi,
            printWidth = Math.Clamp(opts.PrintWidth, 40, 200),
            trailingComma = "none"
        };
        var json = JsonSerializer.Serialize(cfg, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine;
        await File.WriteAllTextAsync(path, json, Utf8NoBom);
        return path;
    }

    private static IEnumerable<string> EnumerateSupportedFiles(string root)
    {
        var stack = new Stack<string>();
        stack.Push(root);
        int count = 0;

        while (stack.Count > 0 && count < 400)
        {
            var dir = stack.Pop();
            IEnumerable<string> files;
            try { files = Directory.EnumerateFiles(dir); }
            catch { continue; }

            foreach (var f in files)
            {
                if (IsSupportedExtension(f))
                {
                    yield return f;
                    count++;
                    if (count >= 400) yield break;
                }
            }

            IEnumerable<string> subDirs;
            try { subDirs = Directory.EnumerateDirectories(dir); }
            catch { continue; }

            foreach (var sub in subDirs)
            {
                var name = Path.GetFileName(sub);
                if (string.IsNullOrEmpty(name) || name.StartsWith('.') || IgnoredScanDirs.Contains(name))
                    continue;
                stack.Push(sub);
            }
        }
    }

    private static PrettierResult TryBuiltinFallback(string code, string filePath, bool checkOnly)
    {
        var ext = Path.GetExtension(filePath).ToLowerInvariant();
        if (LoopingExtensions.Contains(ext))
        {
            var formatted = LoopingBuiltInAnalyzer.FormatCode(code);
            bool changed = !string.Equals(formatted, code, StringComparison.Ordinal);
            return new PrettierResult
            {
                Success = true,
                UsedFallback = true,
                FormattedCode = checkOnly ? code : formatted,
                Changed = changed,
                Message = checkOnly
                    ? (changed ? "⚠ Requiere formateo (Node.js no detectado; fallback integrado)." : "✔ Formato Looping correcto (fallback integrado).")
                    : "✔ Formateado con motor integrado (instala Node.js para Prettier completo)."
            };
        }

        if (ext == ".json")
        {
            try
            {
                using var doc = JsonDocument.Parse(code);
                var formatted = JsonSerializer.Serialize(doc.RootElement, new JsonSerializerOptions { WriteIndented = true }) + Environment.NewLine;
                bool changed = !string.Equals(formatted, code, StringComparison.Ordinal);
                return new PrettierResult
                {
                    Success = true,
                    UsedFallback = true,
                    FormattedCode = checkOnly ? code : formatted,
                    Changed = changed,
                    Message = "✔ JSON formateado con serializador nativo (Node.js no detectado)."
                };
            }
            catch (Exception ex)
            {
                return new PrettierResult { Success = false, FormattedCode = code, Message = $"JSON inválido: {ex.Message}" };
            }
        }

        return new PrettierResult
        {
            Success = false,
            UsedFallback = true,
            FormattedCode = code,
            Message = "Instala Node.js para ejecutar Prettier sobre " + (string.IsNullOrEmpty(ext) ? "este archivo." : ext)
        };
    }

    private static string ResolveRunnerScriptPath()
    {
        var bundled = Path.Combine(AppContext.BaseDirectory, "Assets", "Prettier", "run-prettier.cjs");
        if (File.Exists(bundled)) return bundled;

        var repo = Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "Assets", "Prettier", "run-prettier.cjs");
        if (File.Exists(repo)) return Path.GetFullPath(repo);
        return string.Empty;
    }

    private static string ResolvePrettierPackagePath(string workspaceRoot)
    {
        var candidates = new List<string>();
        if (!string.IsNullOrWhiteSpace(workspaceRoot))
            candidates.Add(Path.Combine(workspaceRoot, "node_modules", "prettier"));

        var appData = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
        if (!string.IsNullOrEmpty(appData))
            candidates.Add(Path.Combine(appData, "npm", "node_modules", "prettier"));

        var home = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        if (!string.IsNullOrEmpty(home))
            candidates.Add(Path.Combine(home, ".smiledev", "tools", "prettier", "node_modules", "prettier"));

        candidates.Add(Path.Combine(AppContext.BaseDirectory, "Assets", "Prettier", "node_modules", "prettier"));

        return candidates.FirstOrDefault(Directory.Exists) ?? string.Empty;
    }

    private static async Task<(int ExitCode, string Stdout, string Stderr)> RunNodeRunnerAsync(
        string nodeExe,
        string runnerPath,
        IReadOnlyList<string> args,
        string stdinContent,
        string workingDir)
    {
        var psi = new ProcessStartInfo
        {
            FileName = nodeExe,
            WorkingDirectory = Directory.Exists(workingDir) ? workingDir : Environment.CurrentDirectory,
            UseShellExecute = false,
            RedirectStandardInput = true,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true,
            StandardInputEncoding = Utf8NoBom,
            StandardOutputEncoding = Encoding.UTF8,
            StandardErrorEncoding = Encoding.UTF8
        };

        psi.ArgumentList.Add(runnerPath);
        foreach (var a in args) psi.ArgumentList.Add(a);

        using var proc = new Process { StartInfo = psi };
        if (!proc.Start())
            throw new InvalidOperationException("No se pudo iniciar node.exe para Prettier.");

        await proc.StandardInput.WriteAsync(stdinContent);
        proc.StandardInput.Close();

        var outTask = proc.StandardOutput.ReadToEndAsync();
        var errTask = proc.StandardError.ReadToEndAsync();
        await Task.WhenAll(outTask, errTask, proc.WaitForExitAsync());

        return (proc.ExitCode, outTask.Result, errTask.Result);
    }
}
