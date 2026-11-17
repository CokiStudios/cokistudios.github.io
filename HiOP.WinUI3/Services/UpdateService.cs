using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Formats.Tar;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net.Http;
using System.Reflection;
using System.Security.Cryptography;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using HiOP.WinUI3.Models;

namespace HiOP.WinUI3.Services;

public sealed class UpdateService
{
    public static readonly string[] ManifestMirrors =
    [
        "https://raw.githubusercontent.com/CokiStudios/cokistudios.github.io/main/engine/latest.json",
        "https://repo.cokistudios.com/engine/latest.json",
        "https://cokistudios.github.io/engine/latest.json"
    ];

    public static readonly string[] GitHubReleaseApis =
    [
        "https://api.github.com/repos/CokiStudios/cokistudios.github.io/releases?per_page=8",
        "https://api.github.com/repos/CokiStudios/engine/releases?per_page=8"
    ];

    private readonly HttpClient _http;
    private readonly WorkspaceService _workspace;
    private readonly SmiledevService _smiledev;
    private readonly EngineProcessService _engine;

    public UpdateService(WorkspaceService workspace, SmiledevService smiledev, EngineProcessService engine)
    {
        _workspace = workspace;
        _smiledev = smiledev;
        _engine = engine;
        _http = new HttpClient { Timeout = TimeSpan.FromSeconds(20) };
        _http.DefaultRequestHeaders.UserAgent.ParseAdd("HiOP-WinUI3-Updater/1.1.0");
    }

    public static string GetCurrentAppVersion()
    {
        var ver = Assembly.GetExecutingAssembly().GetName().Version;
        return ver != null ? $"{ver.Major}.{ver.Minor}.{ver.Build}" : "1.1.0";
    }

    public async Task<UpdateCheckResult> CheckForUpdatesAsync(CancellationToken ct = default)
    {
        var channel = _smiledev.GetActiveChannel();
        var chInfo = SmiledevService.GetChannelDisplay(channel);

        EngineLatestManifest? manifest = null;
        string mirrorUsed = string.Empty;

        foreach (var mirror in ManifestMirrors)
        {
            try
            {
                using var req = new HttpRequestMessage(HttpMethod.Get, mirror);
                req.Headers.CacheControl = new System.Net.Http.Headers.CacheControlHeaderValue { NoCache = true };
                using var res = await _http.SendAsync(req, ct);
                if (res.IsSuccessStatusCode)
                {
                    var json = await res.Content.ReadAsStringAsync(ct);
                    manifest = JsonSerializer.Deserialize<EngineLatestManifest>(json);
                    if (manifest != null)
                    {
                        mirrorUsed = mirror;
                        break;
                    }
                }
            }
            catch { }
        }

        if (manifest == null)
        {
            foreach (var localManifest in new[]
            {
                Path.Combine(_workspace.WorkspaceRoot, "engine", "latest.json"),
                Path.Combine(_workspace.EngineRepoRoot, "version.json")
            })
            {
                if (!File.Exists(localManifest)) continue;
                try
                {
                    manifest = JsonSerializer.Deserialize<EngineLatestManifest>(await File.ReadAllTextAsync(localManifest, ct));
                    if (manifest != null)
                    {
                        mirrorUsed = $"Manifiesto Local ({localManifest})";
                        break;
                    }
                }
                catch { }
            }
        }

        manifest ??= new EngineLatestManifest();

        manifest.Channels.TryGetValue(channel, out var chEntry);
        var remoteVer = !string.IsNullOrEmpty(chEntry?.Version) ? chEntry!.Version : manifest.Version;
        var remoteArch = !string.IsNullOrEmpty(chEntry?.ArchVersion) ? chEntry!.ArchVersion : manifest.ArchVersion;
        var installedEngVer = await _engine.ProbeInstalledEngineVersionAsync();
        var engPath = _engine.ResolvePreferredEnginePath(out _);

        var ghReleases = await FetchGitHubReleasesAsync(ct);

        string? appPkgUrl = chEntry?.HiopWindowsUrl ?? manifest.HiopWindowsUrl;
        string? appPkgSha = chEntry?.HiopWindowsSha256 ?? manifest.HiopWindowsSha256;
        string? appPkgName = !string.IsNullOrEmpty(appPkgUrl) ? Path.GetFileName(appPkgUrl) : null;
        string? remoteAppVer = manifest.HiopWindowsVersion;

        foreach (var rel in ghReleases)
        {
            var winAsset = rel.Assets.FirstOrDefault(a =>
                a.Name.Contains("hiop", StringComparison.OrdinalIgnoreCase) &&
                (a.Name.Contains("win", StringComparison.OrdinalIgnoreCase) ||
                 a.Name.EndsWith(".msix", StringComparison.OrdinalIgnoreCase) ||
                 a.Name.EndsWith(".zip", StringComparison.OrdinalIgnoreCase)));

            if (winAsset != null && string.IsNullOrEmpty(appPkgUrl))
            {
                appPkgUrl = winAsset.BrowserDownloadUrl;
                appPkgName = winAsset.Name;
                remoteAppVer = rel.TagName.TrimStart('v', 'V');
                break;
            }
        }

        var currApp = GetCurrentAppVersion();
        bool appNewer = !string.IsNullOrEmpty(remoteAppVer) && CompareVersions(remoteAppVer, currApp) > 0;
        bool engNewer = CompareVersions(remoteVer, installedEngVer) != 0;

        return new UpdateCheckResult
        {
            CurrentAppVersion = currApp,
            ActiveChannel = channel,
            ChannelTitle = chInfo.Title,
            ChannelTier = chInfo.Tier,
            RemoteChannelVersion = remoteVer,
            RemoteArchVersion = remoteArch,
            InstalledEngineVersion = installedEngVer,
            InstalledEnginePath = engPath,
            EngineUpdateAvailable = engNewer,
            AppUpdateAvailable = appNewer,
            EnginePackageUrl = !string.IsNullOrEmpty(chEntry?.WindowsUrl)
                ? chEntry!.WindowsUrl!
                : (!string.IsNullOrEmpty(chEntry?.TarballUrl) ? chEntry!.TarballUrl : manifest.TarballUrl),
            EngineExpectedSha256 = !string.IsNullOrEmpty(chEntry?.WindowsSha256)
                ? chEntry!.WindowsSha256!
                : (!string.IsNullOrEmpty(chEntry?.TarballSha256) ? chEntry!.TarballSha256 : manifest.TarballSha256),
            AppPackageUrl = appPkgUrl,
            AppPackageName = appPkgName,
            AppExpectedSha256 = appPkgSha,
            RemoteAppVersion = remoteAppVer ?? currApp,
            ReleaseNotes = chEntry?.ReleaseNotes ?? manifest.ReleaseNotes,
            SourceMirror = mirrorUsed,
            ArchitectureTimeline = manifest.History?.ArchitectureVersions ?? [],
            GitHubReleases = ghReleases
        };
    }

    private async Task<List<GitHubReleaseDto>> FetchGitHubReleasesAsync(CancellationToken ct)
    {
        var list = new List<GitHubReleaseDto>();
        foreach (var api in GitHubReleaseApis)
        {
            try
            {
                using var res = await _http.GetAsync(api, ct);
                if (!res.IsSuccessStatusCode) continue;
                var items = JsonSerializer.Deserialize<List<GitHubReleaseDto>>(await res.Content.ReadAsStringAsync(ct));
                if (items != null) list.AddRange(items);
            }
            catch { }
        }
        return list.OrderByDescending(r => r.PublishedAt).Take(10).ToList();
    }

    public async Task<(bool Success, string Message, string DownloadedFilePath, string ComputedSha256)> DownloadWithVerificationAsync(
        string url,
        string destFile,
        string? expectedSha256,
        IProgress<(string Status, double Percent)>? progress = null,
        CancellationToken ct = default)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(destFile)!);
        progress?.Report(($"Conectando a {url}...", 5));

        using var res = await _http.GetAsync(url, HttpCompletionOption.ResponseHeadersRead, ct);
        if (!res.IsSuccessStatusCode)
            return (false, $"HTTP {(int)res.StatusCode} descargando {url}", string.Empty, string.Empty);

        var totalBytes = res.Content.Headers.ContentLength ?? -1L;
        await using (var remoteStream = await res.Content.ReadAsStreamAsync(ct))
        await using (var fileStream = File.Create(destFile))
        {
            var buffer = new byte[81920];
            long received = 0;
            int read;
            while ((read = await remoteStream.ReadAsync(buffer, ct)) > 0)
            {
                await fileStream.WriteAsync(buffer.AsMemory(0, read), ct);
                received += read;
                if (totalBytes > 0)
                {
                    var pct = Math.Clamp(received * 90.0 / totalBytes, 5, 92);
                    progress?.Report(($"Descargando ({received / 1024.0:N0} KB / {totalBytes / 1024.0:N0} KB)...", pct));
                }
                else
                {
                    progress?.Report(($"Descargando ({received / 1024.0:N0} KB)...", 50));
                }
            }
        }

        progress?.Report(("Verificando SHA-256...", 95));
        await using var hashStream = File.OpenRead(destFile);
        var sha = Convert.ToHexString(await SHA256.HashDataAsync(hashStream, ct)).ToLowerInvariant();

        if (!string.IsNullOrWhiteSpace(expectedSha256) &&
            !string.Equals(sha, expectedSha256.Trim(), StringComparison.OrdinalIgnoreCase))
        {
            return (false, $"✘ Fallo de integridad SHA-256. Esperado: {expectedSha256}, Obtenido: {sha}", destFile, sha);
        }

        progress?.Report(("Descarga verificada ✔", 100));
        return (true, $"✔ Descargado y verificado (SHA-256: {sha[..16]}...)", destFile, sha);
    }

    public async Task<(bool Ok, List<string> Logs)> ApplyEngineAndWebCoreUpdateAsync(
        UpdateCheckResult checkResult,
        IProgress<(string Status, double Percent)>? progress = null,
        CancellationToken ct = default)
    {
        var logs = new List<string>();
        var smileBinDir = Path.Combine(_smiledev.ConfigDir, "bin");
        Directory.CreateDirectory(smileBinDir);

        // 1. Update local hiOP runtime cache (latest.json, looping_core.js, web-loopize-kit.js)
        var webCacheDir = Path.Combine(_smiledev.ConfigDir, "webcache");
        Directory.CreateDirectory(webCacheDir);

        var mirrorFiles = new (string Url, string LocalName)[]
        {
            ("https://raw.githubusercontent.com/CokiStudios/cokistudios.github.io/main/engine/latest.json", "latest.json"),
            ("https://raw.githubusercontent.com/CokiStudios/cokistudios.github.io/main/LoopingEngine/looping_core.js", "looping_core.js"),
            ("https://raw.githubusercontent.com/CokiStudios/cokistudios.github.io/main/web-loopize-kit.js", "web-loopize-kit.js"),
            ("https://raw.githubusercontent.com/CokiStudios/engine/main/bin/smiledev", "smiledev"),
            ("https://raw.githubusercontent.com/CokiStudios/engine/main/bin/smiledev.ps1", "smiledev.ps1"),
            ("https://raw.githubusercontent.com/CokiStudios/engine/main/bin/smiledev.cmd", "smiledev.cmd")
        };

        int step = 0;
        foreach (var (url, localName) in mirrorFiles)
        {
            step++;
            progress?.Report(($"Sincronizando {localName}...", step * 10.0));
            try
            {
                var content = await _http.GetByteArrayAsync(url, ct);
                var dest = localName.StartsWith("smiledev") ? Path.Combine(smileBinDir, localName) : Path.Combine(webCacheDir, localName);
                await File.WriteAllBytesAsync(dest, content, ct);
                logs.Add($"✔ Actualizado {localName} ({content.Length:N0} bytes)");
            }
            catch (Exception ex)
            {
                logs.Add($"⚠ No se pudo sincronizar {localName}: {ex.Message}");
            }
        }

        // 2. Sync Windows engine binary if remote Windows package exists or local engine repo has newer build
        if (!string.IsNullOrEmpty(checkResult.EnginePackageUrl) &&
            (checkResult.EnginePackageUrl.Contains("win", StringComparison.OrdinalIgnoreCase) ||
             checkResult.EnginePackageUrl.EndsWith(".zip", StringComparison.OrdinalIgnoreCase)))
        {
            var pkgName = Path.GetFileName(checkResult.EnginePackageUrl);
            var tmpPkg = Path.Combine(Path.GetTempPath(), pkgName);
            var dl = await DownloadWithVerificationAsync(
                checkResult.EnginePackageUrl,
                tmpPkg,
                checkResult.EngineExpectedSha256,
                progress,
                ct);
            logs.Add(dl.Message);
            if (dl.Success)
            {
                if (tmpPkg.EndsWith(".zip", StringComparison.OrdinalIgnoreCase))
                    ZipFile.ExtractToDirectory(tmpPkg, smileBinDir, overwriteFiles: true);
                else if (tmpPkg.EndsWith(".tar.gz", StringComparison.OrdinalIgnoreCase))
                {
                    using var fs = File.OpenRead(tmpPkg);
                    using var gz = new GZipStream(fs, CompressionMode.Decompress);
                    await TarFile.ExtractToDirectoryAsync(gz, smileBinDir, overwriteFiles: true);
                }
                logs.Add($"✔ Binarios extraídos en {smileBinDir}");
            }
        }
        else if (!string.IsNullOrEmpty(_workspace.EngineRepoRoot))
        {
            var srcExe = Path.Combine(_workspace.EngineRepoRoot, "bin", "looping.exe");
            var wsExe = Path.Combine(_workspace.WorkspaceRoot, "bin", "looping.exe");
            var copySrc = File.Exists(wsExe) ? wsExe : (File.Exists(srcExe) ? srcExe : string.Empty);
            if (!string.IsNullOrEmpty(copySrc))
            {
                File.Copy(copySrc, Path.Combine(smileBinDir, "looping.exe"), overwrite: true);
                logs.Add($"✔ Motor Windows sincronizado en {smileBinDir}\\looping.exe");
            }
        }

        progress?.Report(("Actualización completada ✔", 100));
        return (true, logs);
    }

    public async Task<(bool Ok, string Message)> DownloadAndLaunchAppSelfUpdateAsync(
        string assetUrl,
        string? expectedSha256,
        IProgress<(string Status, double Percent)>? progress = null,
        CancellationToken ct = default)
    {
        var fileName = Path.GetFileName(new Uri(assetUrl).LocalPath);
        if (string.IsNullOrWhiteSpace(fileName)) fileName = "HiOP-WinUI3-Update.zip";

        var dlPath = Path.Combine(Path.GetTempPath(), "HiOPUpdates", fileName);
        var dl = await DownloadWithVerificationAsync(assetUrl, dlPath, expectedSha256, progress, ct);
        if (!dl.Success) return (false, dl.Message);

        if (fileName.EndsWith(".msix", StringComparison.OrdinalIgnoreCase) ||
            fileName.EndsWith(".msixbundle", StringComparison.OrdinalIgnoreCase) ||
            fileName.EndsWith(".exe", StringComparison.OrdinalIgnoreCase))
        {
            Process.Start(new ProcessStartInfo(dlPath) { UseShellExecute = true });
            return (true, $"✔ Instalador {fileName} iniciado. Sigue el asistente de Windows para completar.");
        }

        if (fileName.EndsWith(".zip", StringComparison.OrdinalIgnoreCase))
        {
            var stageDir = Path.Combine(Path.GetTempPath(), "HiOPUpdates", "Staged_" + DateTime.UtcNow.ToString("yyyyMMddHHmmss"));
            ZipFile.ExtractToDirectory(dlPath, stageDir, overwriteFiles: true);

            var currentDir = AppContext.BaseDirectory.TrimEnd('\\');
            var pid = Environment.ProcessId;
            var exePath = Environment.ProcessPath ?? Path.Combine(currentDir, "HiOP.WinUI3.exe");

            var scriptPath = Path.Combine(Path.GetTempPath(), "HiOPUpdates", "apply_hiop_update.ps1");
            var psScript = $$"""
                $ErrorActionPreference = 'SilentlyContinue'
                Wait-Process -Id {{pid}} -Timeout 15
                Start-Sleep -Milliseconds 500
                Copy-Item -Path "{{stageDir}}\*" -Destination "{{currentDir}}" -Recurse -Force
                Start-Process -FilePath "{{exePath}}"
                """;
            await File.WriteAllTextAsync(scriptPath, psScript, ct);

            Process.Start(new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = $"-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"{scriptPath}\"",
                UseShellExecute = false,
                CreateNoWindow = true
            });

            return (true, "✔ Actualización preparada. Reiniciando hiOP Studio para aplicar los nuevos archivos...");
        }

        return (false, $"Formato de paquete '{fileName}' no reconocido automáticamente ({dlPath}).");
    }

    public static int CompareVersions(string a, string b)
    {
        var na = ExtractNumericParts(a);
        var nb = ExtractNumericParts(b);
        int len = Math.Max(na.Count, nb.Count);
        for (int i = 0; i < len; i++)
        {
            int va = i < na.Count ? na[i] : 0;
            int vb = i < nb.Count ? nb[i] : 0;
            if (va != vb) return va.CompareTo(vb);
        }
        return string.Compare(a, b, StringComparison.OrdinalIgnoreCase);
    }

    private static List<int> ExtractNumericParts(string v)
    {
        var list = new List<int>();
        var cur = string.Empty;
        foreach (var ch in v)
        {
            if (char.IsDigit(ch)) cur += ch;
            else if (cur.Length > 0) { if (int.TryParse(cur, out int n)) list.Add(n); cur = string.Empty; }
        }
        if (cur.Length > 0 && int.TryParse(cur, out int last)) list.Add(last);
        return list;
    }
}
