using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using HiOP.WinUI3.Models;

namespace HiOP.WinUI3.Services;

public sealed partial class EngineProcessService
{
    private readonly WorkspaceService _workspace;
    private Process? _activeProcess;
    private CancellationTokenSource? _activeCts;

    public string? CustomLoopingExePath { get; set; }

    public EngineProcessService(WorkspaceService workspace)
    {
        _workspace = workspace;
    }

    public string ResolvePreferredEnginePath(out string engineKind)
    {
        if (!string.IsNullOrWhiteSpace(CustomLoopingExePath) && File.Exists(CustomLoopingExePath))
        {
            engineKind = CustomLoopingExePath.EndsWith(".js", StringComparison.OrdinalIgnoreCase)
                ? "Node.js Runtime"
                : "Personalizado";
            return CustomLoopingExePath;
        }

        var userBin = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
            ".smiledev", "bin", "looping.exe");

        var candidates = new (string Path, string Kind)[]
        {
            (userBin, "Smiledev Bin (~/.smiledev/bin/looping.exe)"),
            (Path.Combine(_workspace.WorkspaceRoot, "bin", "looping.exe"), "Workspace Looping Win32"),
            (Path.Combine(_workspace.EngineRepoRoot, "bin", "looping.exe"), "Engine Repo C++17 Native"),
            (Path.Combine(_workspace.WorkspaceRoot, "bin", "looping.js"), "Node.js Looping Runtime"),
            (Path.Combine(_workspace.EngineRepoRoot, "bin", "looping.js"), "Node.js Looping Runtime")
        };

        foreach (var (path, kind) in candidates)
        {
            if (!string.IsNullOrWhiteSpace(path) && File.Exists(path))
            {
                engineKind = kind;
                return path;
            }
        }

        engineKind = "No detectado";
        return string.Empty;
    }

    public string? FindNodeExecutable() => FindCommandOnPath("node.exe", @"C:\Program Files\nodejs\node.exe");
    public string? FindPythonExecutable() => FindCommandOnPath("python.exe",
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), @"Programs\Python\Python313\python.exe"));
    public string? FindGitBashExecutable() => FindCommandOnPath("bash.exe", @"C:\Program Files\Git\bin\bash.exe", @"C:\Program Files\Git\usr\bin\bash.exe");
    public string? FindGitExecutable() => FindCommandOnPath("git.exe", @"C:\Program Files\Git\cmd\git.exe");

    private static string? FindCommandOnPath(string exeName, params string[] explicitPaths)
    {
        foreach (var p in explicitPaths)
        {
            if (!string.IsNullOrWhiteSpace(p) && File.Exists(p))
                return p;
        }

        var pathVar = Environment.GetEnvironmentVariable("PATH") ?? string.Empty;
        foreach (var dir in pathVar.Split(Path.PathSeparator, StringSplitOptions.RemoveEmptyEntries))
        {
            try
            {
                var candidate = Path.Combine(dir.Trim(), exeName);
                if (File.Exists(candidate))
                    return candidate;
            }
            catch { }
        }
        return null;
    }

    public void StopActiveProcess()
    {
        try
        {
            _activeCts?.Cancel();
            if (_activeProcess is { HasExited: false })
            {
                _activeProcess.Kill(entireProcessTree: true);
            }
        }
        catch { }
        finally
        {
            _activeProcess = null;
        }
    }

    public async Task<(int ExitCode, double ElapsedMs, string CombinedOutput)> RunLoopingCommandAsync(
        IEnumerable<string> arguments,
        string? workingDir,
        Action<string> onLogLine,
        bool preferNodeFallback = true)
    {
        StopActiveProcess();
        _activeCts = new CancellationTokenSource();
        var ct = _activeCts.Token;

        var argsList = arguments.ToList();
        var enginePath = ResolvePreferredEnginePath(out var kind);
        if (string.IsNullOrEmpty(enginePath))
        {
            onLogLine("⚠️ No se encontró ningún binario 'looping.exe' ni 'looping.js'. Usa Actualizaciones para descargar o instalar el motor.");
            return (-1, 0, string.Empty);
        }

        return await ExecuteWithFallbackAsync(enginePath, kind, argsList, workingDir, onLogLine, preferNodeFallback, ct);
    }

    private async Task<(int ExitCode, double ElapsedMs, string CombinedOutput)> ExecuteWithFallbackAsync(
        string enginePath,
        string kind,
        List<string> argsList,
        string? workingDir,
        Action<string> onLogLine,
        bool preferNodeFallback,
        CancellationToken ct)
    {
        var sw = Stopwatch.StartNew();
        var outputBuf = new StringBuilder();

        string fileToRun = enginePath;
        var finalArgs = new List<string>(argsList);

        if (enginePath.EndsWith(".js", StringComparison.OrdinalIgnoreCase))
        {
            var nodeExe = FindNodeExecutable();
            if (string.IsNullOrEmpty(nodeExe))
            {
                onLogLine("✘ Node.js no está instalado para ejecutar looping.js.");
                return (-1, 0, string.Empty);
            }
            fileToRun = nodeExe;
            finalArgs.Insert(0, enginePath);
        }

        onLogLine($"▶ Motor: {kind} ({Path.GetFileName(fileToRun)})");
        onLogLine($"▶ Comando: {Path.GetFileName(enginePath)} {string.Join(" ", argsList.Select(QuoteIfNeeded))}");

        try
        {
            var (exit, text) = await RunCapturedProcessAsync(fileToRun, finalArgs, workingDir, line =>
            {
                outputBuf.AppendLine(line);
                onLogLine(line);
            }, ct);
            sw.Stop();
            return (exit, sw.Elapsed.TotalMilliseconds, outputBuf.ToString());
        }
        catch (Win32Exception ex) when (ex.NativeErrorCode == 4551)
        {
            onLogLine("⚠️ Windows Smart App Control / Application Control bloqueó este ejecutable sin firmar (" + enginePath + ").");

            if (preferNodeFallback && !enginePath.EndsWith(".js", StringComparison.OrdinalIgnoreCase))
            {
                var wsExe = Path.Combine(_workspace.WorkspaceRoot, "bin", "looping.exe");
                if (!string.Equals(enginePath, wsExe, StringComparison.OrdinalIgnoreCase) && File.Exists(wsExe))
                {
                    onLogLine("↻ Intentando con Workspace Looping Runtime (" + wsExe + ")...");
                    return await ExecuteWithFallbackAsync(wsExe, "Workspace Looping Win32", argsList, workingDir, onLogLine, false, ct);
                }

                var jsPath = Path.Combine(_workspace.WorkspaceRoot, "bin", "looping.js");
                var nodeExe = FindNodeExecutable();
                if (File.Exists(jsPath) && !string.IsNullOrEmpty(nodeExe))
                {
                    onLogLine("↻ Fallback automático a Node.js Looping Runtime (" + jsPath + ")...");
                    return await ExecuteWithFallbackAsync(jsPath, "Node.js Fallback", argsList, workingDir, onLogLine, false, ct);
                }
            }

            onLogLine("💡 Usa la pestaña 'Quantum 3D & Stage' (WebView2) o el analizador integrado AST / FMT / Check.");
            sw.Stop();
            return (4551, sw.Elapsed.TotalMilliseconds, ex.Message);
        }
        catch (Exception ex)
        {
            sw.Stop();
            onLogLine($"✘ Error al ejecutar proceso: {ex.Message}");
            return (-1, sw.Elapsed.TotalMilliseconds, ex.Message);
        }
    }

    public async Task<(int ExitCode, string Output)> RunSmiledevCliAsync(
        IEnumerable<string> args,
        string? workingDir,
        Action<string> onLogLine)
    {
        var bash = FindGitBashExecutable();
        var shCandidates = new[]
        {
            Path.Combine(_workspace.EngineRepoRoot, "bin", "smiledev"),
            Path.Combine(_workspace.WorkspaceRoot, "bin", "smiledev"),
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".smiledev", "bin", "smiledev")
        };

        var script = shCandidates.FirstOrDefault(File.Exists);
        if (!string.IsNullOrEmpty(bash) && !string.IsNullOrEmpty(script))
        {
            var argList = new List<string> { script };
            argList.AddRange(args);
            var sb = new StringBuilder();
            var (exit, _) = await RunCapturedProcessAsync(bash, argList, workingDir, line =>
            {
                sb.AppendLine(line);
                onLogLine(line);
            }, CancellationToken.None);
            return (exit, sb.ToString());
        }

        var psScript = Path.Combine(_workspace.EngineRepoRoot, "bin", "smiledev.ps1");
        if (File.Exists(psScript))
        {
            var argList = new List<string> { "-ExecutionPolicy", "Bypass", "-File", psScript };
            argList.AddRange(args);
            var sb = new StringBuilder();
            var (exit, _) = await RunCapturedProcessAsync("pwsh", argList, workingDir, line =>
            {
                sb.AppendLine(line);
                onLogLine(line);
            }, CancellationToken.None);
            return (exit, sb.ToString());
        }

        onLogLine("ℹ Git Bash / smiledev script no localizado; usando el gestor nativo integrado en C#.");
        return (-1, string.Empty);
    }

    public async Task<string> ProbeInstalledEngineVersionAsync()
    {
        var pathsToProbe = new[]
        {
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".smiledev", "bin", "looping.exe"),
            Path.Combine(_workspace.WorkspaceRoot, "bin", "looping.exe"),
            Path.Combine(_workspace.EngineRepoRoot, "bin", "looping.exe"),
            Path.Combine(_workspace.WorkspaceRoot, "bin", "looping.js")
        };

        foreach (var p in pathsToProbe.Distinct(StringComparer.OrdinalIgnoreCase))
        {
            if (string.IsNullOrEmpty(p) || !File.Exists(p)) continue;
            try
            {
                string exe = p;
                var args = new List<string> { "--version" };
                if (p.EndsWith(".js", StringComparison.OrdinalIgnoreCase))
                {
                    var node = FindNodeExecutable();
                    if (string.IsNullOrEmpty(node)) continue;
                    exe = node;
                    args.Insert(0, p);
                }

                var (_, outText) = await RunCapturedProcessAsync(exe, args, _workspace.WorkspaceRoot, null, CancellationToken.None, 4000);
                var m = VersionRegex().Match(outText);
                if (m.Success)
                    return m.Value.Trim();
                if (!string.IsNullOrWhiteSpace(outText))
                    return outText.Split('\n')[0].Trim();
            }
            catch (Win32Exception ex) when (ex.NativeErrorCode == 4551)
            {
                continue;
            }
            catch
            {
                continue;
            }
        }

        return "v1.1 (Web/Native Bridge)";
    }

    public async Task<List<DoctorCheckItem>> RunHostDiagnosticsAsync()
    {
        var items = new List<DoctorCheckItem>();

        // 1. .NET Runtime
        items.Add(new DoctorCheckItem
        {
            Component = ".NET Desktop / WinUI 3 Runtime",
            Status = "OK",
            Detail = $".NET {Environment.Version} • Windows {Environment.OSVersion.Version}",
            Hint = "Motor gráfico nativo Fluent 2 / WinUI 3 operativo"
        });

        // 2. Engine Native C++ (.exe)
        var engExe = Path.Combine(_workspace.EngineRepoRoot, "bin", "looping.exe");
        var wsExe = Path.Combine(_workspace.WorkspaceRoot, "bin", "looping.exe");
        await CheckExecutableDoctorItem(items, "Looping C++17 Native (.exe)", File.Exists(engExe) ? engExe : wsExe);

        // 3. Node.js + looping.js
        var node = FindNodeExecutable();
        var loopJs = Path.Combine(_workspace.WorkspaceRoot, "bin", "looping.js");
        items.Add(new DoctorCheckItem
        {
            Component = "Looping JS / Node Bridge",
            Status = (!string.IsNullOrEmpty(node) && File.Exists(loopJs)) ? "OK" : "WARN",
            Detail = !string.IsNullOrEmpty(node) ? $"Node: {node}" : "Node.js no encontrado",
            Hint = File.Exists(loopJs) ? "bin/looping.js listo para ejecución sin restricciones" : "Usa WebView2 Quantum Stage"
        });

        // 4. Python PyLoop
        var py = FindPythonExecutable();
        items.Add(new DoctorCheckItem
        {
            Component = "Python PyLoop (pysnippet / runpy)",
            Status = !string.IsNullOrEmpty(py) ? "OK" : "MISSING",
            Detail = py ?? "python.exe no detectado en PATH",
            Hint = !string.IsNullOrEmpty(py) ? "Interoperabilidad bidireccional activa" : "Instala Python 3.11+ para PyLoop"
        });

        // 5. Git
        var git = FindGitExecutable();
        items.Add(new DoctorCheckItem
        {
            Component = "Git CLI (Repositorios Smiledev)",
            Status = !string.IsNullOrEmpty(git) ? "OK" : "WARN",
            Detail = git ?? "git.exe no encontrado",
            Hint = "Smiledev descargará paquetes GitHub vía HTTPS tarball incluso sin Git"
        });

        // 6. Smiledev Home Directory
        var smileHome = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".smiledev");
        items.Add(new DoctorCheckItem
        {
            Component = "Smiledev Home & Global Cache",
            Status = Directory.Exists(smileHome) ? "OK" : "WARN",
            Detail = smileHome,
            Hint = Directory.Exists(smileHome) ? "Configuración, auth.json y caché global compartidos" : "Se inicializará automáticamente al descargar un módulo"
        });

        return items;
    }

    private async Task CheckExecutableDoctorItem(List<DoctorCheckItem> list, string name, string exePath)
    {
        if (string.IsNullOrEmpty(exePath) || !File.Exists(exePath))
        {
            list.Add(new DoctorCheckItem
            {
                Component = name,
                Status = "MISSING",
                Detail = "Archivo no encontrado",
                Hint = "Descárgalo en la pestaña Actualizaciones o compila C++17"
            });
            return;
        }

        try
        {
            var (_, output) = await RunCapturedProcessAsync(exePath, ["--version"], Path.GetDirectoryName(exePath), null, CancellationToken.None, 3000);
            list.Add(new DoctorCheckItem
            {
                Component = name,
                Status = "OK",
                Detail = string.IsNullOrWhiteSpace(output) ? exePath : output.Split('\n')[0].Trim(),
                Hint = exePath
            });
        }
        catch (Win32Exception ex) when (ex.NativeErrorCode == 4551)
        {
            list.Add(new DoctorCheckItem
            {
                Component = name,
                Status = "BLOCKED",
                Detail = $"Bloqueado por Smart App Control: {Path.GetFileName(exePath)}",
                Hint = "hiOP usará automáticamente WebView2 Quantum Stage o bin/looping.exe confiable"
            });
        }
        catch (Exception ex)
        {
            list.Add(new DoctorCheckItem
            {
                Component = name,
                Status = "WARN",
                Detail = ex.Message,
                Hint = exePath
            });
        }
    }

    private async Task<(int ExitCode, string Output)> RunCapturedProcessAsync(
        string executable,
        IReadOnlyList<string> args,
        string? workingDir,
        Action<string>? onLine,
        CancellationToken ct,
        int timeoutMs = 120000)
    {
        var psi = new ProcessStartInfo
        {
            FileName = executable,
            WorkingDirectory = (!string.IsNullOrEmpty(workingDir) && Directory.Exists(workingDir))
                ? workingDir
                : Environment.CurrentDirectory,
            UseShellExecute = false,
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            CreateNoWindow = true,
            StandardOutputEncoding = Encoding.UTF8,
            StandardErrorEncoding = Encoding.UTF8
        };

        foreach (var a in args)
            psi.ArgumentList.Add(a);

        psi.Environment["LOOPING_NO_COLOR"] = "1";
        psi.Environment["TERM"] = "dumb";

        using var proc = new Process { StartInfo = psi, EnableRaisingEvents = true };
        var sb = new StringBuilder();

        proc.OutputDataReceived += (_, e) =>
        {
            if (e.Data == null) return;
            var clean = StripAnsi(e.Data);
            lock (sb) sb.AppendLine(clean);
            onLine?.Invoke(clean);
        };
        proc.ErrorDataReceived += (_, e) =>
        {
            if (e.Data == null) return;
            var clean = StripAnsi(e.Data);
            lock (sb) sb.AppendLine(clean);
            onLine?.Invoke("⚠️ " + clean);
        };

        if (!proc.Start())
            throw new InvalidOperationException("No se pudo iniciar el proceso.");

        _activeProcess = proc;
        proc.BeginOutputReadLine();
        proc.BeginErrorReadLine();

        using var linked = CancellationTokenSource.CreateLinkedTokenSource(ct);
        linked.CancelAfter(timeoutMs);

        try
        {
            await proc.WaitForExitAsync(linked.Token);
        }
        catch (OperationCanceledException)
        {
            try { proc.Kill(entireProcessTree: true); } catch { }
            return (-1, sb.ToString());
        }
        finally
        {
            if (_activeProcess == proc) _activeProcess = null;
        }

        return (proc.ExitCode, sb.ToString());
    }

    private static string StripAnsi(string input) => AnsiRegex().Replace(input, string.Empty);

    private static string QuoteIfNeeded(string arg) => arg.Contains(' ') ? $"\"{arg}\"" : arg;

    [GeneratedRegex(@"\x1B\[[0-9;]*[mGKHFJ]")]
    private static partial Regex AnsiRegex();

    [GeneratedRegex(@"v?\d+\.\d+([.\-A-Za-z0-9]*)")]
    private static partial Regex VersionRegex();
}
