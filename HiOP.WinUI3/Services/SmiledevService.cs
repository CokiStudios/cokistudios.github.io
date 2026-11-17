using System;
using System.Collections.Generic;
using System.Formats.Tar;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using HiOP.WinUI3.Models;

namespace HiOP.WinUI3.Services;

public sealed class SmiledevService
{
    public const string SupabaseUrl = "https://ayxklxciqgqeyuzkziov.supabase.co";
    public const string SupabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF5eGtseGNpcWdxZXl1emt6aW92Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTEyMTY4MzIsImV4cCI6MjEwNjc5MjgzMn0.03wUc8blB-cNq9F8Nz5o88GShtMIXeHsNYqmeK_N-hI";
    public const string OfficialHttpRepoUrl = "https://repo.cokistudios.com/modules";
    public const string OfficialGitHubPagesRepoUrl = "https://cokistudios.github.io/modules";

    public string ConfigDir { get; }
    public string GlobalModulesDir { get; }
    public string ConfigFile { get; }
    public string AuthFile { get; }
    public string ChannelFile { get; }

    private readonly HttpClient _http;
    private readonly WorkspaceService _workspace;

    public SmiledevService(WorkspaceService workspace)
    {
        _workspace = workspace;
        var home = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        ConfigDir = Path.Combine(home, ".smiledev");
        GlobalModulesDir = Path.Combine(ConfigDir, "modules");
        ConfigFile = Path.Combine(ConfigDir, "config.json");
        AuthFile = Path.Combine(ConfigDir, "auth.json");
        ChannelFile = Path.Combine(ConfigDir, "channel");

        _http = new HttpClient { Timeout = TimeSpan.FromSeconds(15) };
        _http.DefaultRequestHeaders.UserAgent.ParseAdd("smiledev/1.1 (Coki Studios HiOP WinUI 3; Windows; x64)");

        EnsureSmiledevDirs();
    }

    private void EnsureSmiledevDirs()
    {
        Directory.CreateDirectory(ConfigDir);
        Directory.CreateDirectory(GlobalModulesDir);
        if (!File.Exists(ConfigFile))
        {
            var defaultCfg = new JsonObject
            {
                ["version"] = "1.1",
                ["default_repo"] = OfficialHttpRepoUrl,
                ["repos"] = new JsonArray(OfficialHttpRepoUrl)
            };
            File.WriteAllText(ConfigFile, defaultCfg.ToJsonString(new JsonSerializerOptions { WriteIndented = true }));
        }
    }

    // ── Channels (prod | omega | alpha) ────────────────────────────────────────
    public string GetActiveChannel()
    {
        var env = Environment.GetEnvironmentVariable("LOOPING_CHANNEL");
        if (!string.IsNullOrWhiteSpace(env))
            return NormalizeChannelKey(env);

        if (File.Exists(ChannelFile))
        {
            var raw = File.ReadAllText(ChannelFile).Trim();
            if (!string.IsNullOrWhiteSpace(raw))
                return NormalizeChannelKey(raw);
        }
        return "prod";
    }

    public void SetActiveChannel(string channel)
    {
        Directory.CreateDirectory(ConfigDir);
        File.WriteAllText(ChannelFile, NormalizeChannelKey(channel) + Environment.NewLine);
    }

    public static string NormalizeChannelKey(string? ch)
    {
        var c = (ch ?? "prod").Trim().ToLowerInvariant();
        if (c is "alpha" or "alpha!" or "1.1a" or "experimental" or "super-experimental") return "alpha";
        if (c is "omega" or "rc" or "release-candidate") return "omega";
        return "prod";
    }

    public static ChannelOption GetChannelDisplay(string key) => NormalizeChannelKey(key) switch
    {
        "alpha" => new ChannelOption
        {
            Key = "alpha",
            Title = "Alpha! 1.1A",
            Tier = "Super Experimental",
            VersionLabel = "1.1A",
            Description = "Builds súper experimentales Alpha! 1.1A (bleeding-edge, laboratorios en vivo)"
        },
        "omega" => new ChannelOption
        {
            Key = "omega",
            Title = "Omega Looping",
            Tier = "Release Candidate (RC)",
            VersionLabel = "1.1-omega",
            Description = "Candidatas RC con congelación de APIs y validación QA previa a producción"
        },
        _ => new ChannelOption
        {
            Key = "prod",
            Title = "Looping",
            Tier = "Production Release",
            VersionLabel = "1.1",
            Description = "Versión oficial estable de producción para Coki Studios & Loop OS (Arch 3.0A)"
        }
    };

    // ── Registry Catalog Discovery ─────────────────────────────────────────────
    public async Task<(List<SmileModuleItem> Modules, string SourceNote)> LoadRegistryCatalogAsync()
    {
        var map = new Dictionary<string, SmileModuleItem>(StringComparer.OrdinalIgnoreCase);
        var installedNames = GetAllInstalledNames();
        var notes = new List<string>();

        // 1. Live Supabase PostgreSQL Query
        try
        {
            using var req = new HttpRequestMessage(HttpMethod.Get, $"{SupabaseUrl}/rest/v1/loop_modules?select=*&order=updated_at.desc");
            req.Headers.Add("apikey", SupabaseAnonKey);
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", SupabaseAnonKey);

            using var res = await _http.SendAsync(req);
            if (res.IsSuccessStatusCode)
            {
                var json = await res.Content.ReadAsStringAsync();
                var arr = JsonNode.Parse(json)?.AsArray();
                if (arr != null)
                {
                    foreach (var row in arr.OfType<JsonObject>())
                    {
                        var mod = ParseSupabaseRow(row);
                        if (!string.IsNullOrWhiteSpace(mod.Name))
                        {
                            mod.IsInstalled = installedNames.Contains(mod.Name);
                            map[mod.Name] = mod;
                        }
                    }
                    notes.Add($"Supabase ({arr.Count})");
                }
            }
        }
        catch (Exception ex)
        {
            notes.Add($"Supabase offline ({ex.Message})");
        }

        // 2. Local Workspace /modules/* & Built-in Official Modules fallback
        ScanLocalRepoIntoCatalog(Path.Combine(_workspace.WorkspaceRoot, "modules"), "Workspace CokiStudios", map, installedNames);

        foreach (var repoUrl in GetConfiguredRepos())
        {
            if (Directory.Exists(repoUrl.Replace("file://", "")))
            {
                ScanLocalRepoIntoCatalog(repoUrl.Replace("file://", ""), "Repositorio Local", map, installedNames);
            }
        }

        foreach (var official in GetOfficialBuiltinCatalog())
        {
            if (!map.ContainsKey(official.Name))
            {
                official.IsInstalled = installedNames.Contains(official.Name);
                map[official.Name] = official;
            }
        }

        return (map.Values
            .OrderByDescending(m => m.IsVerified)
            .ThenByDescending(m => m.DownloadCount)
            .ThenBy(m => m.Name, StringComparer.OrdinalIgnoreCase)
            .ToList(), string.Join(" • ", notes));
    }

    private void ScanLocalRepoIntoCatalog(
        string folder,
        string sourceLabel,
        Dictionary<string, SmileModuleItem> map,
        HashSet<string> installedNames)
    {
        if (!Directory.Exists(folder)) return;
        foreach (var dir in Directory.GetDirectories(folder))
        {
            var manifestPath = Path.Combine(dir, "smile.json");
            if (!File.Exists(manifestPath)) continue;
            try
            {
                var mf = JsonSerializer.Deserialize<SmileManifest>(File.ReadAllText(manifestPath));
                if (mf == null || string.IsNullOrWhiteSpace(mf.Name) || map.ContainsKey(mf.Name)) continue;

                var entryPath = Path.Combine(dir, mf.EntryPoint ?? "main.loop");
                var code = File.Exists(entryPath) ? File.ReadAllText(entryPath) : string.Empty;

                map[mf.Name] = new SmileModuleItem
                {
                    Id = $"local-{mf.Name}",
                    Name = mf.Name,
                    Version = mf.Version ?? "1.0.0",
                    Language = mf.Language ?? "loop",
                    AuthorName = mf.ResolvedAuthor,
                    Description = mf.Description ?? string.Empty,
                    License = mf.License ?? "MIT",
                    EntryPoint = mf.EntryPoint ?? "main.loop",
                    CodePayload = code,
                    IsVerified = true,
                    SourceLabel = sourceLabel,
                    RepoUrl = dir,
                    Dependencies = mf.GetDependenciesMap(),
                    Components = mf.Components ?? new(),
                    Subfiles = mf.Subfiles ?? new(),
                    IsInstalled = installedNames.Contains(mf.Name)
                };
            }
            catch { }
        }
    }

    // ── Multi-Source Package Resolution + Native Direct Downloader ─────────────
    public async Task<List<PackageSourceCandidate>> ResolveCandidatesAsync(string modName)
    {
        var candidates = new List<PackageSourceCandidate>();

        // A. Supabase PostgreSQL LoopModules
        try
        {
            using var req = new HttpRequestMessage(HttpMethod.Get, $"{SupabaseUrl}/rest/v1/loop_modules?name=eq.{Uri.EscapeDataString(modName)}&select=*");
            req.Headers.Add("apikey", SupabaseAnonKey);
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", SupabaseAnonKey);
            using var res = await _http.SendAsync(req);
            if (res.IsSuccessStatusCode)
            {
                var arr = JsonNode.Parse(await res.Content.ReadAsStringAsync())?.AsArray();
                if (arr is { Count: > 0 } && arr[0] is JsonObject row)
                {
                    var item = ParseSupabaseRow(row);
                    candidates.Add(new PackageSourceCandidate
                    {
                        Type = "postgres",
                        SourceName = "LoopModules (PostgreSQL Cloud)",
                        RepoUrl = SupabaseUrl,
                        Version = item.Version,
                        Author = item.AuthorName,
                        Description = item.Description,
                        Language = item.Language,
                        EntryPoint = item.EntryPoint,
                        ModuleData = item
                    });
                }
            }
        }
        catch { }

        // B. Local Workspace / Configured Repositories
        var repos = new List<string>(GetConfiguredRepos());
        var wsModules = Path.Combine(_workspace.WorkspaceRoot, "modules");
        if (Directory.Exists(wsModules) && !repos.Contains(wsModules, StringComparer.OrdinalIgnoreCase))
            repos.Add(wsModules);
        if (!repos.Contains(OfficialGitHubPagesRepoUrl, StringComparer.OrdinalIgnoreCase))
            repos.Add(OfficialGitHubPagesRepoUrl);

        foreach (var rawRepo in repos)
        {
            var rUrl = rawRepo.Trim();
            if (string.IsNullOrEmpty(rUrl) || rUrl.Contains("supabase.co", StringComparison.OrdinalIgnoreCase))
                continue;

            var localClean = rUrl.Replace("file://", "");
            if (Directory.Exists(localClean))
            {
                foreach (var pattern in new[]
                {
                    Path.Combine(localClean, modName),
                    Path.Combine(localClean, "modules", modName),
                    localClean
                })
                {
                    var smPath = Path.Combine(pattern, "smile.json");
                    if (!File.Exists(smPath)) continue;
                    try
                    {
                        var mf = JsonSerializer.Deserialize<SmileManifest>(File.ReadAllText(smPath));
                        if (mf != null && string.Equals(mf.Name, modName, StringComparison.OrdinalIgnoreCase))
                        {
                            candidates.Add(new PackageSourceCandidate
                            {
                                Type = "local",
                                SourceName = $"Directorio Local ({localClean})",
                                RepoUrl = localClean,
                                LocalDirPath = pattern,
                                Version = mf.Version,
                                Author = mf.ResolvedAuthor,
                                Description = mf.Description ?? string.Empty,
                                Language = mf.Language,
                                EntryPoint = mf.EntryPoint,
                                Manifest = mf
                            });
                            break;
                        }
                    }
                    catch { }
                }
                continue;
            }

            if (rUrl.EndsWith(".git", StringComparison.OrdinalIgnoreCase) ||
                rUrl.Contains("github.com", StringComparison.OrdinalIgnoreCase))
            {
                var gitCand = await ProbeGitHubRepoAsync(rUrl, modName);
                if (gitCand != null)
                    candidates.Add(gitCand);
                continue;
            }

            if (rUrl.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                rUrl.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
            {
                var cleanUrl = rUrl.TrimEnd('/');
                bool matchedIndex = false;

                foreach (var idxFile in new[] { "index.json", "registry.json" })
                {
                    try
                    {
                        var jsonStr = await _http.GetStringAsync($"{cleanUrl}/{idxFile}");
                        var idxNode = JsonNode.Parse(jsonStr)?.AsObject();
                        var modsObj = (idxNode?["modules"] ?? idxNode?["packages"])?.AsObject();
                        if (modsObj != null && modsObj.TryGetPropertyValue(modName, out var modNode) && modNode is JsonObject mObj)
                        {
                            var inlineFiles = new Dictionary<string, string>();
                            if (mObj["files"] is JsonObject fObj)
                            {
                                foreach (var kv in fObj)
                                    inlineFiles[kv.Key] = kv.Value?.ToString() ?? string.Empty;
                            }

                            candidates.Add(new PackageSourceCandidate
                            {
                                Type = "http_index",
                                SourceName = $"{idxNode?["name"]?.ToString() ?? "Repositorio HTTP"} ({cleanUrl})",
                                RepoUrl = cleanUrl,
                                Version = mObj["version"]?.ToString() ?? "1.0.0",
                                Author = mObj["author_name"]?.ToString() ?? "Remoto",
                                Description = mObj["description"]?.ToString() ?? string.Empty,
                                Language = mObj["language"]?.ToString() ?? "loop",
                                EntryPoint = mObj["entry_point"]?.ToString() ?? "main.loop",
                                TarballUrl = mObj["tarball"]?.ToString(),
                                InlineFiles = inlineFiles.Count > 0 ? inlineFiles : null,
                                ModuleData = new SmileModuleItem
                                {
                                    Name = modName,
                                    CodePayload = mObj["code_payload"]?.ToString() ?? string.Empty
                                }
                            });
                            matchedIndex = true;
                            break;
                        }
                    }
                    catch { }
                }

                if (matchedIndex) continue;

                foreach (var mfUrl in new[] { $"{cleanUrl}/{modName}/smile.json", $"{cleanUrl}/modules/{modName}/smile.json" })
                {
                    try
                    {
                        var json = await _http.GetStringAsync(mfUrl);
                        var mf = JsonSerializer.Deserialize<SmileManifest>(json);
                        if (mf != null && string.Equals(mf.Name, modName, StringComparison.OrdinalIgnoreCase))
                        {
                            var baseDir = mfUrl[..mfUrl.LastIndexOf('/')];
                            candidates.Add(new PackageSourceCandidate
                            {
                                Type = "http_direct",
                                SourceName = $"Repositorio HTTP ({cleanUrl})",
                                RepoUrl = cleanUrl,
                                BaseDirUrl = baseDir,
                                Version = mf.Version,
                                Author = mf.ResolvedAuthor,
                                Description = mf.Description ?? string.Empty,
                                Language = mf.Language,
                                EntryPoint = mf.EntryPoint,
                                Manifest = mf
                            });
                            break;
                        }
                    }
                    catch { }
                }
            }
        }

        // C. GitHub Official CokiStudios/cokistudios.github.io/modules Fallback
        if (candidates.Count == 0)
        {
            var rawSmileUrl = $"https://raw.githubusercontent.com/CokiStudios/cokistudios.github.io/main/modules/{Uri.EscapeDataString(modName)}/smile.json";
            try
            {
                var json = await _http.GetStringAsync(rawSmileUrl);
                var mf = JsonSerializer.Deserialize<SmileManifest>(json);
                if (mf != null && string.Equals(mf.Name, modName, StringComparison.OrdinalIgnoreCase))
                {
                    candidates.Add(new PackageSourceCandidate
                    {
                        Type = "http_direct",
                        SourceName = "CokiStudios GitHub Modules (raw/main)",
                        RepoUrl = "https://github.com/CokiStudios/cokistudios.github.io",
                        BaseDirUrl = $"https://raw.githubusercontent.com/CokiStudios/cokistudios.github.io/main/modules/{Uri.EscapeDataString(modName)}",
                        Version = mf.Version,
                        Author = mf.ResolvedAuthor,
                        Description = mf.Description ?? string.Empty,
                        Language = mf.Language,
                        EntryPoint = mf.EntryPoint,
                        Manifest = mf
                    });
                }
            }
            catch { }
        }

        return candidates;
    }

    private async Task<PackageSourceCandidate?> ProbeGitHubRepoAsync(string repoUrl, string modName)
    {
        if (!TryParseGitHubUrl(repoUrl, out var owner, out var repo, out var branch, out var subpath))
            return null;

        var checks = new List<string>();
        if (!string.IsNullOrEmpty(subpath))
        {
            checks.Add($"{subpath}/smile.json");
            checks.Add($"{subpath}/{modName}/smile.json");
            checks.Add($"{subpath}/modules/{modName}/smile.json");
        }
        checks.AddRange([
            $"modules/{modName}/smile.json",
            $"addons/{modName}/smile.json",
            $"packages/{modName}/smile.json",
            $"{modName}/smile.json",
            "smile.json"
        ]);

        foreach (var b in new[] { branch, "main", "master" }.Distinct())
        {
            foreach (var rel in checks)
            {
                var rawUrl = $"https://raw.githubusercontent.com/{owner}/{repo}/{b}/{rel}";
                try
                {
                    var json = await _http.GetStringAsync(rawUrl);
                    var mf = JsonSerializer.Deserialize<SmileManifest>(json);
                    if (mf != null && string.Equals(mf.Name, modName, StringComparison.OrdinalIgnoreCase))
                    {
                        var dirRel = rel.Contains('/') ? rel[..rel.LastIndexOf('/')] : string.Empty;
                        var baseRaw = string.IsNullOrEmpty(dirRel)
                            ? $"https://raw.githubusercontent.com/{owner}/{repo}/{b}"
                            : $"https://raw.githubusercontent.com/{owner}/{repo}/{b}/{dirRel}";
                        return new PackageSourceCandidate
                        {
                            Type = "git",
                            SourceName = $"GitHub ({owner}/{repo})",
                            RepoUrl = repoUrl,
                            GitCloneUrl = $"https://github.com/{owner}/{repo}.git",
                            GitBranch = b,
                            GitSubpath = dirRel,
                            BaseDirUrl = baseRaw,
                            Version = mf.Version,
                            Author = mf.ResolvedAuthor,
                            Description = mf.Description ?? string.Empty,
                            Language = mf.Language,
                            EntryPoint = mf.EntryPoint,
                            Manifest = mf
                        };
                    }
                }
                catch { }
            }
        }
        return null;
    }

    public async Task<(bool Success, string Message, List<string> Logs)> DownloadAndInstallModuleAsync(
        string moduleName,
        bool globalOnly = false,
        PackageSourceCandidate? preferredCandidate = null,
        IProgress<(string Status, double Percent)>? progress = null)
    {
        var logs = new List<string>();
        progress?.Report(($"Resolviendo orígenes para '{moduleName}'...", 10));
        logs.Add($"🔎 Buscando módulo '{moduleName}' en LoopModules & repositorios configurados...");

        var chosen = preferredCandidate;
        if (chosen == null)
        {
            var candidates = await ResolveCandidatesAsync(moduleName);
            if (candidates.Count == 0)
            {
                logs.Add($"✘ Error: '{moduleName}' no se encontró en PostgreSQL ni en repositorios externos.");
                return (false, $"Módulo '{moduleName}' no encontrado.", logs);
            }
            chosen = candidates[0];
            logs.Add($"✔ Seleccionado origen: {chosen.SourceName} (v{chosen.Version})");
        }

        var localDir = Path.Combine(_workspace.WorkspaceRoot, "modules", moduleName);
        var globalDir = Path.Combine(GlobalModulesDir, moduleName);
        var targetDirs = globalOnly ? new[] { globalDir } : new[] { localDir, globalDir };

        foreach (var td in targetDirs)
            Directory.CreateDirectory(td);

        progress?.Report(($"Descargando {moduleName} v{chosen.Version}...", 35));

        try
        {
            if (chosen.Type == "postgres" && chosen.ModuleData != null)
            {
                await InstallFromSupabaseItemAsync(chosen.ModuleData, targetDirs, logs, progress);
            }
            else if (chosen.Type == "local" && !string.IsNullOrEmpty(chosen.LocalDirPath))
            {
                foreach (var td in targetDirs)
                    CopyDirectoryOverwrite(chosen.LocalDirPath, td);
                logs.Add($"✔ Copiado desde directorio local: {chosen.LocalDirPath}");
            }
            else if (chosen.Type is "http_direct" or "git" && chosen.Manifest != null && !string.IsNullOrEmpty(chosen.BaseDirUrl))
            {
                await InstallFromHttpDirectAsync(chosen.Manifest, chosen.BaseDirUrl, targetDirs, logs, progress);
            }
            else if (chosen.Type == "http_index")
            {
                await InstallFromHttpIndexCandidateAsync(chosen, moduleName, targetDirs, logs, progress);
            }
            else
            {
                return (false, "Origen de descarga no soportado.", logs);
            }

            // Update workspace ./smile.json dependencies if present
            if (!globalOnly)
            {
                TryUpdateProjectDependenciesJson(moduleName, chosen.Version, logs);
            }

            progress?.Report(($"¡{moduleName} v{chosen.Version} instalado!", 100));
            logs.Add($"✔ [SUCCESS] '{moduleName}' v{chosen.Version} instalado en:");
            foreach (var td in targetDirs)
                logs.Add($"   • {td}");

            return (true, $"Módulo '{moduleName}' v{chosen.Version} descargado e instalado correctamente.", logs);
        }
        catch (Exception ex)
        {
            logs.Add($"✘ Error descargando '{moduleName}': {ex.Message}");
            return (false, ex.Message, logs);
        }
    }

    private async Task InstallFromSupabaseItemAsync(
        SmileModuleItem mod,
        string[] targetDirs,
        List<string> logs,
        IProgress<(string Status, double Percent)>? progress)
    {
        var payload = mod.CodePayload ?? string.Empty;
        bool extractedBundle = false;

        if (payload.TrimStart().StartsWith('{') && payload.Contains("\"__bundle__\"", StringComparison.Ordinal))
        {
            try
            {
                var obj = JsonNode.Parse(payload)?.AsObject();
                if (obj?["__bundle__"]?.GetValue<bool>() == true && obj["files"] is JsonObject filesObj)
                {
                    extractedBundle = true;
                    foreach (var td in targetDirs)
                    {
                        foreach (var kv in filesObj)
                        {
                            var dest = Path.Combine(td, kv.Key.Replace('/', Path.DirectorySeparatorChar));
                            Directory.CreateDirectory(Path.GetDirectoryName(dest)!);
                            await File.WriteAllTextAsync(dest, kv.Value?.ToString() ?? string.Empty, Encoding.UTF8);
                        }
                    }
                    logs.Add($"📦 Desempaquetado bundle JSON multi-archivo ({filesObj.Count} archivos).");
                }
            }
            catch { extractedBundle = false; }
        }

        if (!extractedBundle)
        {
            if (string.IsNullOrWhiteSpace(payload))
            {
                try
                {
                    payload = await _http.GetStringAsync($"{OfficialHttpRepoUrl}/{Uri.EscapeDataString(mod.Name)}/code");
                }
                catch { }
            }

            var manifest = new
            {
                name = mod.Name,
                version = mod.Version,
                language = mod.Language,
                entry_point = mod.EntryPoint,
                author_name = mod.AuthorName,
                description = mod.Description,
                license = mod.License,
                dependencies = mod.Dependencies
            };
            var mfJson = JsonSerializer.Serialize(manifest, new JsonSerializerOptions { WriteIndented = true });

            foreach (var td in targetDirs)
            {
                await File.WriteAllTextAsync(Path.Combine(td, "smile.json"), mfJson, Encoding.UTF8);
                if (!string.IsNullOrWhiteSpace(payload))
                {
                    var epPath = Path.Combine(td, mod.EntryPoint.Replace('/', Path.DirectorySeparatorChar));
                    Directory.CreateDirectory(Path.GetDirectoryName(epPath)!);
                    await File.WriteAllTextAsync(epPath, payload, Encoding.UTF8);
                }
            }
            logs.Add($"📦 Instalado {mod.EntryPoint} + smile.json desde LoopModules.");
        }

        progress?.Report(("Actualizando telemetría...", 85));
        try
        {
            using var req = new HttpRequestMessage(HttpMethod.Patch, $"{SupabaseUrl}/rest/v1/loop_modules?name=eq.{Uri.EscapeDataString(mod.Name)}")
            {
                Content = new StringContent(JsonSerializer.Serialize(new { updated_at = DateTime.UtcNow.ToString("O") }), Encoding.UTF8, "application/json")
            };
            req.Headers.Add("apikey", SupabaseAnonKey);
            req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", SupabaseAnonKey);
            await _http.SendAsync(req);
        }
        catch { }
    }

    private async Task InstallFromHttpDirectAsync(
        SmileManifest manifest,
        string baseDirUrl,
        string[] targetDirs,
        List<string> logs,
        IProgress<(string Status, double Percent)>? progress)
    {
        var filesToGet = new HashSet<string>(StringComparer.OrdinalIgnoreCase) { "smile.json" };
        if (!string.IsNullOrWhiteSpace(manifest.EntryPoint)) filesToGet.Add(manifest.EntryPoint);
        if (manifest.Subfiles != null)
            foreach (var sf in manifest.Subfiles.Where(s => !string.IsNullOrWhiteSpace(s)))
                filesToGet.Add(sf);
        if (manifest.Components != null)
            foreach (var kv in manifest.Components.Where(c => !string.IsNullOrWhiteSpace(c.Value)))
                filesToGet.Add(kv.Value);

        filesToGet.Add("README.md");

        int total = filesToGet.Count;
        int idx = 0;

        foreach (var rel in filesToGet)
        {
            idx++;
            progress?.Report(($"Descargando {rel} ({idx}/{total})...", 35 + (idx * 50.0 / total)));
            var cleanRel = rel.Replace('\\', '/').TrimStart('/');
            var url = $"{baseDirUrl.TrimEnd('/')}/{cleanRel}";
            try
            {
                var bytes = await _http.GetByteArrayAsync(url);
                foreach (var td in targetDirs)
                {
                    var dest = Path.Combine(td, cleanRel.Replace('/', Path.DirectorySeparatorChar));
                    Directory.CreateDirectory(Path.GetDirectoryName(dest)!);
                    await File.WriteAllBytesAsync(dest, bytes);
                }
                logs.Add($"  ⬇ {cleanRel} ({bytes.Length:N0} bytes)");
            }
            catch
            {
                if (!rel.Equals("README.md", StringComparison.OrdinalIgnoreCase))
                    logs.Add($"  ⚠ No se pudo descargar archivo opcional/faltante: {cleanRel}");
            }
        }
    }

    private async Task InstallFromHttpIndexCandidateAsync(
        PackageSourceCandidate cand,
        string modName,
        string[] targetDirs,
        List<string> logs,
        IProgress<(string Status, double Percent)>? progress)
    {
        if (!string.IsNullOrEmpty(cand.TarballUrl))
        {
            var tmpArchive = Path.Combine(Path.GetTempPath(), $"smiledev_{modName}_{Guid.NewGuid():N}");
            bool isZip = cand.TarballUrl.EndsWith(".zip", StringComparison.OrdinalIgnoreCase);
            tmpArchive += isZip ? ".zip" : ".tar.gz";

            try
            {
                logs.Add($"⬇ Descargando archivo comprimido: {cand.TarballUrl}");
                using (var stream = await _http.GetStreamAsync(cand.TarballUrl))
                using (var fs = File.Create(tmpArchive))
                {
                    await stream.CopyToAsync(fs);
                }

                progress?.Report(("Extrayendo paquete...", 75));
                foreach (var td in targetDirs)
                {
                    if (isZip)
                        ZipFile.ExtractToDirectory(tmpArchive, td, overwriteFiles: true);
                    else
                    {
                        using var fileStream = File.OpenRead(tmpArchive);
                        using var gzip = new GZipStream(fileStream, CompressionMode.Decompress);
                        await TarFile.ExtractToDirectoryAsync(gzip, td, overwriteFiles: true);
                    }
                }
                logs.Add($"📦 Paquete extraído en formato {(isZip ? "ZIP" : "TAR.GZ")}.");
            }
            finally
            {
                try { if (File.Exists(tmpArchive)) File.Delete(tmpArchive); } catch { }
            }
        }
        else if (cand.InlineFiles != null)
        {
            foreach (var td in targetDirs)
            {
                foreach (var kv in cand.InlineFiles)
                {
                    var dest = Path.Combine(td, kv.Key.Replace('/', Path.DirectorySeparatorChar));
                    Directory.CreateDirectory(Path.GetDirectoryName(dest)!);
                    await File.WriteAllTextAsync(dest, kv.Value, Encoding.UTF8);
                }
            }
            logs.Add($"📦 Instalados {cand.InlineFiles.Count} archivo(s) inline desde índice HTTP.");
        }
        else
        {
            var manifest = new
            {
                name = modName,
                version = cand.Version,
                language = cand.Language,
                entry_point = cand.EntryPoint,
                author_name = cand.Author,
                description = cand.Description
            };
            var mfJson = JsonSerializer.Serialize(manifest, new JsonSerializerOptions { WriteIndented = true });
            foreach (var td in targetDirs)
            {
                await File.WriteAllTextAsync(Path.Combine(td, "smile.json"), mfJson, Encoding.UTF8);
                await File.WriteAllTextAsync(Path.Combine(td, cand.EntryPoint), cand.ModuleData?.CodePayload ?? string.Empty, Encoding.UTF8);
            }
        }
    }

    private void TryUpdateProjectDependenciesJson(string modName, string version, List<string> logs)
    {
        var projManifest = Path.Combine(_workspace.WorkspaceRoot, "smile.json");
        if (!File.Exists(projManifest)) return;

        try
        {
            var obj = JsonNode.Parse(File.ReadAllText(projManifest))?.AsObject();
            if (obj == null) return;
            var deps = obj["dependencies"]?.AsObject() ?? new JsonObject();
            deps[modName] = $"^{version}";
            obj["dependencies"] = deps;
            File.WriteAllText(projManifest, obj.ToJsonString(new JsonSerializerOptions { WriteIndented = true }));
            logs.Add("✔ Dependencia añadida en ./smile.json.");
        }
        catch { }
    }

    // ── Local & Global Installed Modules ──────────────────────────────────────
    public List<InstalledModuleItem> ListInstalledModules()
    {
        var result = new List<InstalledModuleItem>();
        var allNames = GetAllInstalledNames();

        ScanInstalledDirectory(Path.Combine(_workspace.WorkspaceRoot, "modules"), false, "Local (./modules)", allNames, result);
        ScanInstalledDirectory(GlobalModulesDir, true, "Global (~/.smiledev/modules)", allNames, result);

        return result;
    }

    private HashSet<string> GetAllInstalledNames()
    {
        var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        foreach (var root in new[] { Path.Combine(_workspace.WorkspaceRoot, "modules"), GlobalModulesDir })
        {
            if (!Directory.Exists(root)) continue;
            foreach (var dir in Directory.GetDirectories(root))
                set.Add(Path.GetFileName(dir));
        }
        return set;
    }

    private static void ScanInstalledDirectory(
        string dirRoot,
        bool isGlobal,
        string scopeLabel,
        HashSet<string> allInstalled,
        List<InstalledModuleItem> output)
    {
        if (!Directory.Exists(dirRoot)) return;
        foreach (var dir in Directory.GetDirectories(dirRoot).OrderBy(Path.GetFileName))
        {
            var name = Path.GetFileName(dir);
            var mfPath = Path.Combine(dir, "smile.json");
            var item = new InstalledModuleItem
            {
                Name = name,
                InstallPath = dir,
                IsGlobal = isGlobal,
                ScopeLabel = scopeLabel,
                IsSymlink = new DirectoryInfo(dir).LinkTarget != null
            };

            if (File.Exists(mfPath))
            {
                try
                {
                    var mf = JsonSerializer.Deserialize<SmileManifest>(File.ReadAllText(mfPath));
                    if (mf != null)
                    {
                        item.Version = mf.Version ?? "1.0.0";
                        item.Language = mf.Language ?? "loop";
                        item.EntryPoint = mf.EntryPoint ?? "main.loop";
                        item.Description = mf.Description ?? string.Empty;
                        foreach (var dep in mf.GetDependenciesMap().Keys)
                        {
                            if (!allInstalled.Contains(dep))
                                item.MissingDependencies.Add(dep);
                        }
                    }
                }
                catch { }
            }

            output.Add(item);
        }
    }

    public string UninstallModule(string modName, bool removeGlobalToo)
    {
        var removedLocations = new List<string>();
        var local = Path.Combine(_workspace.WorkspaceRoot, "modules", modName);
        if (Directory.Exists(local))
        {
            Directory.Delete(local, true);
            removedLocations.Add(local);
        }

        if (removeGlobalToo)
        {
            var global = Path.Combine(GlobalModulesDir, modName);
            if (Directory.Exists(global))
            {
                Directory.Delete(global, true);
                removedLocations.Add(global);
            }
        }

        var projManifest = Path.Combine(_workspace.WorkspaceRoot, "smile.json");
        if (File.Exists(projManifest))
        {
            try
            {
                var obj = JsonNode.Parse(File.ReadAllText(projManifest))?.AsObject();
                if (obj?["dependencies"] is JsonObject deps && deps.Remove(modName))
                    File.WriteAllText(projManifest, obj.ToJsonString(new JsonSerializerOptions { WriteIndented = true }));
            }
            catch { }
        }

        return removedLocations.Count > 0
            ? $"✔ Desinstalado '{modName}' de: {string.Join(", ", removedLocations)}"
            : $"⚠ No se encontró '{modName}' instalado en esa ubicación.";
    }

    // ── Create, Validate, Pack (.tar.gz), Link & Publish ───────────────────────
    public string InitNewModule(string name, string lang, string author, string description, string? codeOverride = null)
    {
        var modDir = Path.Combine(_workspace.WorkspaceRoot, "modules", name);
        Directory.CreateDirectory(modDir);

        var entry = lang.ToLowerInvariant() switch
        {
            "cpp" => "main.hpp",
            "python" => "main.py",
            "node" => "index.js",
            "c2" => "main.c2",
            _ => "main.loop"
        };

        var manifest = new
        {
            name,
            version = "1.0.0",
            language = lang.ToLowerInvariant(),
            entry_point = entry,
            author_name = string.IsNullOrWhiteSpace(author) ? "Coki Developer" : author,
            description = string.IsNullOrWhiteSpace(description) ? $"Módulo {name} creado desde hiOP Studio." : description,
            license = "MIT",
            dependencies = new { }
        };

        File.WriteAllText(
            Path.Combine(modDir, "smile.json"),
            JsonSerializer.Serialize(manifest, new JsonSerializerOptions { WriteIndented = true }));

        var code = string.IsNullOrWhiteSpace(codeOverride) ? GetDefaultTemplateForLang(name, lang) : codeOverride;
        File.WriteAllText(Path.Combine(modDir, entry), code);
        File.WriteAllText(Path.Combine(modDir, "README.md"),
            $"# {name}\n\n> Official {lang} module for Looping Engine.\n\n```bash\nsmiledev install {name}\n```\n");

        return modDir;
    }

    public static SmileValidationResult ValidateManifestJson(string jsonText, string? moduleFolder = null)
    {
        var result = new SmileValidationResult();
        SmileManifest? mf;
        try
        {
            mf = JsonSerializer.Deserialize<SmileManifest>(jsonText);
        }
        catch (Exception ex)
        {
            result.Errors.Add($"Error de sintaxis JSON: {ex.Message}");
            return result;
        }

        if (mf == null)
        {
            result.Errors.Add("Manifiesto JSON nulo.");
            return result;
        }

        result.Manifest = mf;
        if (string.IsNullOrWhiteSpace(mf.Name))
            result.Errors.Add("Falta el campo obligatorio \"name\".");
        else if (!Regex.IsMatch(mf.Name, @"^[a-z0-9][a-z0-9\-_.+]*$"))
            result.Errors.Add($"Nombre \"{mf.Name}\" inválido (solo minúsculas, números, '-', '_', '.').");

        if (string.IsNullOrWhiteSpace(mf.Version))
            result.Errors.Add("Falta el campo obligatorio \"version\".");
        else if (!Regex.IsMatch(mf.Version, @"^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?$"))
            result.Warnings.Add($"La versión \"{mf.Version}\" no sigue SemVer estricto (ej. 1.0.0).");

        var allowed = new[] { "loop", "cpp", "python", "node", "c2", "hybrid" };
        if (string.IsNullOrWhiteSpace(mf.Language))
            result.Errors.Add("Falta el campo obligatorio \"language\".");
        else if (!allowed.Contains(mf.Language.ToLowerInvariant()))
            result.Errors.Add($"Lenguaje \"{mf.Language}\" no soportado. Permitidos: {string.Join(", ", allowed)}");

        if (string.IsNullOrWhiteSpace(mf.EntryPoint))
            result.Errors.Add("Falta el campo obligatorio \"entry_point\".");
        else if (!string.IsNullOrEmpty(moduleFolder) && !File.Exists(Path.Combine(moduleFolder, mf.EntryPoint)))
            result.Errors.Add($"Punto de entrada '{mf.EntryPoint}' no encontrado en disco.");

        if (string.IsNullOrWhiteSpace(mf.Description) || mf.Description.Trim().Length < 8)
            result.Warnings.Add("La descripción es muy breve (recomendado >= 8 caracteres).");
        if (string.IsNullOrWhiteSpace(mf.License))
            result.Warnings.Add("No se especificó licencia (MIT recomendada).");

        result.IsValid = result.Errors.Count == 0;
        return result;
    }

    public async Task<(string TarGzPath, string Sha256)> PackModuleTarGzAsync(string moduleFolder)
    {
        var mfPath = Path.Combine(moduleFolder, "smile.json");
        var mf = JsonSerializer.Deserialize<SmileManifest>(await File.ReadAllTextAsync(mfPath))
                 ?? throw new InvalidOperationException("No se pudo leer smile.json.");

        var outPath = Path.Combine(Path.GetDirectoryName(moduleFolder)!, $"{mf.Name}-v{mf.Version}.tar.gz");
        if (File.Exists(outPath)) File.Delete(outPath);

        await using (var fs = File.Create(outPath))
        await using (var gz = new GZipStream(fs, CompressionLevel.Optimal))
        {
            await TarFile.CreateFromDirectoryAsync(moduleFolder, gz, includeBaseDirectory: false);
        }

        await using var readFs = File.OpenRead(outPath);
        var hashBytes = await SHA256.HashDataAsync(readFs);
        return (outPath, Convert.ToHexString(hashBytes).ToLowerInvariant());
    }

    public async Task<(bool Ok, string Message)> PublishModuleToSupabaseAsync(SmileModuleItem mod)
    {
        var session = GetSession();
        var payload = new
        {
            name = mod.Name,
            version = mod.Version,
            language = mod.Language.ToLowerInvariant(),
            entry_point = mod.EntryPoint,
            author_id = (string?)null,
            author_name = session != null ? session.User : mod.AuthorName,
            description = mod.Description,
            license = mod.License,
            code_payload = mod.CodePayload,
            dependencies = Array.Empty<string>(),
            is_verified = session != null,
            updated_at = DateTime.UtcNow.ToString("O")
        };

        using var req = new HttpRequestMessage(HttpMethod.Post, $"{SupabaseUrl}/rest/v1/loop_modules")
        {
            Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json")
        };
        req.Headers.Add("apikey", SupabaseAnonKey);
        req.Headers.Authorization = new AuthenticationHeaderValue("Bearer", SupabaseAnonKey);
        req.Headers.Add("Prefer", "resolution=merge-duplicates");

        using var res = await _http.SendAsync(req);
        if (res.IsSuccessStatusCode)
            return (true, $"✔ Módulo '{mod.Name}' v{mod.Version} publicado en LoopModules Cloud.");

        var err = await res.Content.ReadAsStringAsync();
        return (false, $"✘ HTTP {(int)res.StatusCode}: {err}");
    }

    // ── Repositories Management (~/.smiledev/config.json) ───────────────────────
    public List<string> GetConfiguredRepos()
    {
        try
        {
            if (!File.Exists(ConfigFile)) return [OfficialHttpRepoUrl];
            var obj = JsonNode.Parse(File.ReadAllText(ConfigFile))?.AsObject();
            var arr = obj?["repos"]?.AsArray();
            if (arr == null) return [];
            return arr.Select(n => n?.ToString() ?? string.Empty).Where(s => !string.IsNullOrWhiteSpace(s)).ToList();
        }
        catch { return []; }
    }

    public async Task<(bool Added, string Summary)> AddRepoAsync(string url)
    {
        var clean = url.Trim();
        var repos = GetConfiguredRepos();
        string note = string.Empty;

        if (Directory.Exists(clean.Replace("file://", "")))
        {
            var localCount = Directory.GetFiles(clean.Replace("file://", ""), "smile.json", SearchOption.AllDirectories).Length;
            note = $"Directorio Local ({localCount} módulo(s))";
        }
        else if (clean.Contains("github.com", StringComparison.OrdinalIgnoreCase))
        {
            note = "Repositorio GitHub";
        }
        else if (clean.StartsWith("http", StringComparison.OrdinalIgnoreCase))
        {
            try
            {
                var idx = await _http.GetStringAsync($"{clean.TrimEnd('/')}/index.json");
                note = "HTTP Index Repository activo ✔";
            }
            catch
            {
                note = "Servidor HTTP directo";
            }
        }
        else
        {
            return (false, "Formato no válido. Usa HTTP(S), URL GitHub o ruta local.");
        }

        if (!repos.Contains(clean, StringComparer.OrdinalIgnoreCase))
        {
            repos.Add(clean);
            SaveRepos(repos);
            return (true, $"✔ Repositorio añadido ({note})");
        }
        return (false, "ℹ El repositorio ya estaba configurado.");
    }

    public void RemoveRepo(string url)
    {
        var repos = GetConfiguredRepos().Where(r => !string.Equals(r, url, StringComparison.OrdinalIgnoreCase)).ToList();
        SaveRepos(repos);
    }

    private void SaveRepos(List<string> repos)
    {
        JsonObject obj;
        try { obj = JsonNode.Parse(File.ReadAllText(ConfigFile))?.AsObject() ?? new JsonObject(); }
        catch { obj = new JsonObject(); }

        obj["repos"] = new JsonArray(repos.Select(r => JsonValue.Create(r)).ToArray());
        File.WriteAllText(ConfigFile, obj.ToJsonString(new JsonSerializerOptions { WriteIndented = true }));
    }

    // ── CS ID Auth (~/.smiledev/auth.json) ─────────────────────────────────────
    public CsIdSession? GetSession()
    {
        if (!File.Exists(AuthFile)) return null;
        try { return JsonSerializer.Deserialize<CsIdSession>(File.ReadAllText(AuthFile)); }
        catch { return null; }
    }

    public (bool Ok, string Message) LoginWithPat(string token, string? displayName = null, string? email = null)
    {
        var clean = token.Trim();
        if (!clean.StartsWith("cs_pat_", StringComparison.Ordinal) && clean.Length < 20)
            return (false, "Token inválido. Debe empezar con 'cs_pat_' o tener >= 20 caracteres.");

        var session = new CsIdSession
        {
            Token = clean,
            User = string.IsNullOrWhiteSpace(displayName) ? "Coki Studios Developer" : displayName.Trim(),
            Email = string.IsNullOrWhiteSpace(email) ? "developer@cokistudios.com" : email.Trim(),
            Scopes = ["read:modules", "publish:modules", "registry:write"],
            LoggedInAt = DateTimeOffset.UtcNow.ToUnixTimeSeconds(),
            ExpiresIn = "90d"
        };

        File.WriteAllText(AuthFile, JsonSerializer.Serialize(session, new JsonSerializerOptions { WriteIndented = true }));
        return (true, $"✔ Sesión CS ID activa para {session.User}.");
    }

    public void Logout()
    {
        if (File.Exists(AuthFile)) File.Delete(AuthFile);
    }

    // ── Helpers ────────────────────────────────────────────────────────────────
    private static SmileModuleItem ParseSupabaseRow(JsonObject row)
    {
        var deps = new Dictionary<string, string>();
        if (row["dependencies"] is JsonObject dObj)
            foreach (var kv in dObj) deps[kv.Key] = kv.Value?.ToString() ?? "*";

        return new SmileModuleItem
        {
            Id = row["id"]?.ToString() ?? Guid.NewGuid().ToString("N"),
            Name = row["name"]?.ToString() ?? string.Empty,
            Version = row["version"]?.ToString() ?? "1.0.0",
            Language = row["language"]?.ToString() ?? "loop",
            AuthorName = row["author_name"]?.ToString() ?? "Comunidad",
            Description = row["description"]?.ToString() ?? string.Empty,
            License = row["license"]?.ToString() ?? "MIT",
            EntryPoint = row["entry_point"]?.ToString() ?? "main.loop",
            DownloadCount = row["download_count"]?.GetValue<long>() ?? 0,
            IsVerified = row["is_verified"]?.GetValue<bool>() ?? false,
            CodePayload = row["code_payload"]?.ToString() ?? string.Empty,
            Dependencies = deps,
            SourceLabel = "LoopModules (PostgreSQL)"
        };
    }

    private static bool TryParseGitHubUrl(string url, out string owner, out string repo, out string branch, out string subpath)
    {
        owner = repo = subpath = string.Empty;
        branch = "main";
        if (!url.Contains("github.com", StringComparison.OrdinalIgnoreCase)) return false;

        var afterProto = url.Split("://")[^1];
        var parts = afterProto.Split('/', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length < 3) return false;
        owner = parts[1];
        repo = parts[2].Replace(".git", "", StringComparison.OrdinalIgnoreCase);
        if (parts.Length >= 5 && (parts[3] == "tree" || parts[3] == "blob"))
        {
            branch = parts[4];
            if (parts.Length > 5) subpath = string.Join("/", parts.Skip(5)).TrimEnd('/');
        }
        return true;
    }

    private static void CopyDirectoryOverwrite(string sourceDir, string destinationDir)
    {
        Directory.CreateDirectory(destinationDir);
        foreach (var file in Directory.GetFiles(sourceDir))
            File.Copy(file, Path.Combine(destinationDir, Path.GetFileName(file)), overwrite: true);
        foreach (var subDir in Directory.GetDirectories(sourceDir))
        {
            var dName = Path.GetFileName(subDir);
            if (dName is ".git" or ".github" or "__pycache__") continue;
            CopyDirectoryOverwrite(subDir, Path.Combine(destinationDir, dName));
        }
    }

    public static string GetDefaultTemplateForLang(string name, string lang) => lang.ToLowerInvariant() switch
    {
        "cpp" => $"#pragma once\n#include <iostream>\n\nnamespace {name.Replace('-', '_')} {{\n    inline void hello() {{\n        std::cout << \"Hello from C++17 module: {name}\" << std::endl;\n    }}\n}}\n",
        "python" => $"def init_module(vars_dict=None):\n    return True\n\ndef hello():\n    return \"Hello from PyLoop module {name}\"\n",
        "node" => $"module.exports = {{\n    hello: () => \"Hello from Node module {name}\"\n}};\n",
        "c2" => $"component \"{name}\" target \"flui\" {{\n    fps: 120\n    theme: \"frosted_aqua_a17\"\n    draw card at (20, 20) with title \"{name}\":\n        text \"Component 2 listo en Windows\"\n}}\n",
        _ => $"define module \"{name}\" version 1.0:\n    fn hello() => \"Hello from Looping module {name}!\"\n"
    };

    private static List<SmileModuleItem> GetOfficialBuiltinCatalog() =>
    [
        new() { Id = "off-loopize", Name = "loopize++", Version = "1.0.0", Language = "hybrid", AuthorName = "Coki Studios & Holo Entertainment", Description = "High-performance 2D/3D Game Additions Kit: Wavefront .obj, C# MonoBehaviour, ECS, Wave Director, Tweens & Quests.", EntryPoint = "loopize.loop", DownloadCount = 3420, IsVerified = true, SourceLabel = "Catálogo Oficial CS" },
        new() { Id = "off-csid", Name = "csid-login-button", Version = "1.0.0", Language = "hybrid", AuthorName = "Coki Studios Security & Identity", Description = "Componente híbrido 4-lenguajes (Loop + C++17 PKCE + Python OAuth + Node) para inicio de sesión CS ID.", EntryPoint = "main.loop", DownloadCount = 2190, IsVerified = true, SourceLabel = "Catálogo Oficial CS" },
        new() { Id = "off-core", Name = "loop-core-utils", Version = "1.1.0", Language = "loop", AuthorName = "Coki Studios", Description = "Utilidades estándar Arch 3.0A de cadenas, matemáticas vectoriales y validación.", EntryPoint = "core_utils.loop", DownloadCount = 1420, IsVerified = true, SourceLabel = "Catálogo Oficial CS" },
        new() { Id = "off-gameplus", Name = "loop-game-plus", Version = "1.2.0", Language = "loop", AuthorName = "Holo Entertainment", Description = "Física 2D/3D avanzada, cámaras Chase/Orbital, láseres y jefes finales.", EntryPoint = "loop-game-plus.loop", DownloadCount = 1280, IsVerified = true, SourceLabel = "Catálogo Oficial CS" },
        new() { Id = "off-math3d", Name = "loop-math-3d", Version = "1.0.0", Language = "cpp", AuthorName = "Coki Studios Engine Team", Description = "Cabeceras C++17 de cuaterniones, matrices 4x4 y raycasting SIMD para Quantum 3D.", EntryPoint = "loop_math_3d.hpp", DownloadCount = 960, IsVerified = true, SourceLabel = "Catálogo Oficial CS" },
        new() { Id = "off-tk", Name = "loop-gui-tk", Version = "1.0.0", Language = "python", AuthorName = "Holo Systems", Description = "Ventanas y controles multiplataforma mediante PyLoop snippets.", EntryPoint = "loop_gui_tk.py", DownloadCount = 890, IsVerified = true, SourceLabel = "Catálogo Oficial CS" },
        new() { Id = "off-ai", Name = "pyloop-ai", Version = "1.0.0", Language = "python", AuthorName = "Coki AI Lab", Description = "Puente de inferencia neuronal y NLP integrado directamente en scripts .loop.", EntryPoint = "pyloop_ai.py", DownloadCount = 810, IsVerified = true, SourceLabel = "Catálogo Oficial CS" }
    ];
}
