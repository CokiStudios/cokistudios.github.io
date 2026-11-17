using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.CompilerServices;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace HiOP.WinUI3.Models;

public sealed class SmileModuleItem : INotifyPropertyChanged
{
    private bool _isInstalled;
    private bool _isBusy;

    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Version { get; set; } = "1.0.0";
    public string Language { get; set; } = "loop";
    public string AuthorName { get; set; } = "Coki Studios";
    public string Description { get; set; } = string.Empty;
    public string License { get; set; } = "MIT";
    public string EntryPoint { get; set; } = "main.loop";
    public long DownloadCount { get; set; }
    public bool IsVerified { get; set; }
    public string CodePayload { get; set; } = string.Empty;
    public string SourceLabel { get; set; } = "LoopModules (PostgreSQL)";
    public string RepoUrl { get; set; } = string.Empty;
    public string? TarballUrl { get; set; }
    public Dictionary<string, string> Dependencies { get; set; } = new();
    public Dictionary<string, string> Components { get; set; } = new();
    public List<string> Subfiles { get; set; } = new();
    public Dictionary<string, string>? InlineFiles { get; set; }

    public bool IsInstalled
    {
        get => _isInstalled;
        set
        {
            if (_isInstalled != value)
            {
                _isInstalled = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(InstallButtonText));
            }
        }
    }

    public bool IsBusy
    {
        get => _isBusy;
        set
        {
            if (_isBusy != value)
            {
                _isBusy = value;
                OnPropertyChanged();
            }
        }
    }

    public string InstallButtonText => IsInstalled ? "Reinstalar / Actualizar" : "Descargar e Instalar";
    public string VersionTag => $"v{Version}";
    public string AuthorDisplay => IsVerified ? $"Por {AuthorName} ✔" : $"Por {AuthorName}";
    public string DownloadsDisplay => $"{DownloadCount:N0} descargas";
    public string LanguageLabel => Language.ToLowerInvariant() switch
    {
        "cpp" => "C++17",
        "python" => "PYTHON",
        "node" => "NODE/WEB",
        "c2" => "C2 UI",
        "hybrid" => "HÍBRIDO 4L",
        _ => "LOOP"
    };

    public SolidColorBrush LanguageBrush => new(Language.ToLowerInvariant() switch
    {
        "cpp" => Color.FromArgb(255, 56, 189, 248),
        "python" => Color.FromArgb(255, 251, 191, 36),
        "node" => Color.FromArgb(255, 96, 165, 250),
        "c2" => Color.FromArgb(255, 192, 132, 252),
        "hybrid" => Color.FromArgb(255, 0, 245, 212),
        _ => Color.FromArgb(255, 16, 185, 129)
    });

    public event PropertyChangedEventHandler? PropertyChanged;
    private void OnPropertyChanged([CallerMemberName] string? prop = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(prop));
}

public sealed class SmileManifest
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("version")]
    public string Version { get; set; } = "1.0.0";

    [JsonPropertyName("language")]
    public string Language { get; set; } = "loop";

    [JsonPropertyName("entry_point")]
    public string EntryPoint { get; set; } = "main.loop";

    [JsonPropertyName("author_name")]
    public string? AuthorName { get; set; }

    [JsonPropertyName("author")]
    public string? Author { get; set; }

    [JsonPropertyName("description")]
    public string? Description { get; set; }

    [JsonPropertyName("license")]
    public string? License { get; set; }

    [JsonPropertyName("dependencies")]
    public JsonElement? Dependencies { get; set; }

    [JsonPropertyName("components")]
    public Dictionary<string, string>? Components { get; set; }

    [JsonPropertyName("subfiles")]
    public List<string>? Subfiles { get; set; }

    [JsonIgnore]
    public string ResolvedAuthor => !string.IsNullOrWhiteSpace(AuthorName) ? AuthorName! :
                                    (!string.IsNullOrWhiteSpace(Author) ? Author! : "Comunidad");

    public Dictionary<string, string> GetDependenciesMap()
    {
        var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        if (Dependencies is not { } el) return result;
        if (el.ValueKind == JsonValueKind.Object)
        {
            foreach (var prop in el.EnumerateObject())
            {
                result[prop.Name] = prop.Value.ToString();
            }
        }
        else if (el.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in el.EnumerateArray())
            {
                var name = item.GetString();
                if (!string.IsNullOrWhiteSpace(name))
                    result[name] = "*";
            }
        }
        return result;
    }
}

public sealed class InstalledModuleItem
{
    public string Name { get; set; } = string.Empty;
    public string Version { get; set; } = "1.0.0";
    public string Language { get; set; } = "loop";
    public string EntryPoint { get; set; } = "main.loop";
    public string Description { get; set; } = string.Empty;
    public string ScopeLabel { get; set; } = "Local (./modules)";
    public bool IsGlobal { get; set; }
    public string InstallPath { get; set; } = string.Empty;
    public bool IsSymlink { get; set; }
    public List<string> MissingDependencies { get; set; } = new();
    public string MissingDependenciesSummary => MissingDependencies.Count > 0
        ? $"Faltan deps: {string.Join(", ", MissingDependencies)}"
        : "Dependencias OK ✔";
}

public sealed class RepoSourceItem
{
    public int Index { get; set; }
    public string Url { get; set; } = string.Empty;
    public string RepoType { get; set; } = "HTTP";
    public bool IsDefault { get; set; }
    public string StatusSummary { get; set; } = string.Empty;
    public bool CanRemove => !IsDefault;
}

public sealed class PackageSourceCandidate
{
    public string Type { get; set; } = string.Empty; // postgres | local | http_index | http_direct | git | builtin
    public string SourceName { get; set; } = string.Empty;
    public string RepoUrl { get; set; } = string.Empty;
    public string Version { get; set; } = "1.0.0";
    public string Author { get; set; } = "Comunidad";
    public string Description { get; set; } = string.Empty;
    public string Language { get; set; } = "loop";
    public string EntryPoint { get; set; } = "main.loop";
    public string? BaseDirUrl { get; set; }
    public string? TarballUrl { get; set; }
    public string? LocalDirPath { get; set; }
    public string? GitCloneUrl { get; set; }
    public string? GitBranch { get; set; }
    public string? GitSubpath { get; set; }
    public SmileManifest? Manifest { get; set; }
    public SmileModuleItem? ModuleData { get; set; }
    public Dictionary<string, string>? InlineFiles { get; set; }
}

public sealed class SmileValidationResult
{
    public bool IsValid { get; set; }
    public List<string> Errors { get; } = new();
    public List<string> Warnings { get; } = new();
    public SmileManifest? Manifest { get; set; }
}

public sealed class CsIdSession
{
    [JsonPropertyName("token")]
    public string Token { get; set; } = string.Empty;

    [JsonPropertyName("user")]
    public string User { get; set; } = "Coki Studios Developer";

    [JsonPropertyName("email")]
    public string Email { get; set; } = "developer@cokistudios.com";

    [JsonPropertyName("scopes")]
    public List<string> Scopes { get; set; } = new() { "read:modules", "publish:modules", "registry:write" };

    [JsonPropertyName("logged_in_at")]
    public long LoggedInAt { get; set; }

    [JsonPropertyName("expires_in")]
    public string ExpiresIn { get; set; } = "90d";
}
