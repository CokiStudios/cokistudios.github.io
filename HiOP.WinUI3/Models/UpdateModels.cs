using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace HiOP.WinUI3.Models;

public sealed class ChannelOption
{
    public string Key { get; init; } = "prod";
    public string Title { get; init; } = "Looping";
    public string Tier { get; init; } = "Production Release";
    public string VersionLabel { get; init; } = "1.1";
    public string Description { get; init; } = string.Empty;
}

public sealed class EngineChannelEntry
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("tier")]
    public string Tier { get; set; } = string.Empty;

    [JsonPropertyName("version")]
    public string Version { get; set; } = string.Empty;

    [JsonPropertyName("engine_version")]
    public string EngineVersion { get; set; } = string.Empty;

    [JsonPropertyName("smiledev_version")]
    public string SmiledevVersion { get; set; } = string.Empty;

    [JsonPropertyName("arch_version")]
    public string ArchVersion { get; set; } = "3.0A";

    [JsonPropertyName("tarball_url")]
    public string TarballUrl { get; set; } = string.Empty;

    [JsonPropertyName("tarball_sha256")]
    public string TarballSha256 { get; set; } = string.Empty;

    [JsonPropertyName("windows_url")]
    public string? WindowsUrl { get; set; }

    [JsonPropertyName("windows_sha256")]
    public string? WindowsSha256 { get; set; }

    [JsonPropertyName("hiop_windows_url")]
    public string? HiopWindowsUrl { get; set; }

    [JsonPropertyName("hiop_windows_sha256")]
    public string? HiopWindowsSha256 { get; set; }

    [JsonPropertyName("release_notes")]
    public string? ReleaseNotes { get; set; }
}

public sealed class ArchHistoryEntry
{
    [JsonPropertyName("version")]
    public string Version { get; set; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("tarball_url")]
    public string? TarballUrl { get; set; }

    [JsonPropertyName("tarball_sha256")]
    public string? TarballSha256 { get; set; }
}

public sealed class EngineLatestManifest
{
    [JsonPropertyName("version")]
    public string Version { get; set; } = "1.1";

    [JsonPropertyName("semver")]
    public string Semver { get; set; } = "1.1.0";

    [JsonPropertyName("alpha_version")]
    public string AlphaVersion { get; set; } = "1.1A";

    [JsonPropertyName("arch_version")]
    public string ArchVersion { get; set; } = "3.0A";

    [JsonPropertyName("release_name")]
    public string ReleaseName { get; set; } = string.Empty;

    [JsonPropertyName("release_date")]
    public string ReleaseDate { get; set; } = string.Empty;

    [JsonPropertyName("release_notes")]
    public string ReleaseNotes { get; set; } = string.Empty;

    [JsonPropertyName("tarball_url")]
    public string TarballUrl { get; set; } = string.Empty;

    [JsonPropertyName("tarball_sha256")]
    public string TarballSha256 { get; set; } = string.Empty;

    [JsonPropertyName("hiop_windows_version")]
    public string? HiopWindowsVersion { get; set; }

    [JsonPropertyName("hiop_windows_url")]
    public string? HiopWindowsUrl { get; set; }

    [JsonPropertyName("hiop_windows_sha256")]
    public string? HiopWindowsSha256 { get; set; }

    [JsonPropertyName("channels")]
    public Dictionary<string, EngineChannelEntry> Channels { get; set; } = new();

    [JsonPropertyName("history")]
    public ManifestHistoryContainer? History { get; set; }
}

public sealed class ManifestHistoryContainer
{
    [JsonPropertyName("architecture_versions")]
    public List<ArchHistoryEntry> ArchitectureVersions { get; set; } = new();
}

public sealed class GitHubAssetDto
{
    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("browser_download_url")]
    public string BrowserDownloadUrl { get; set; } = string.Empty;

    [JsonPropertyName("size")]
    public long Size { get; set; }
}

public sealed class GitHubReleaseDto
{
    [JsonPropertyName("tag_name")]
    public string TagName { get; set; } = string.Empty;

    [JsonPropertyName("name")]
    public string Name { get; set; } = string.Empty;

    [JsonPropertyName("body")]
    public string Body { get; set; } = string.Empty;

    [JsonPropertyName("html_url")]
    public string HtmlUrl { get; set; } = string.Empty;

    [JsonPropertyName("prerelease")]
    public bool Prerelease { get; set; }

    [JsonPropertyName("published_at")]
    public string PublishedAt { get; set; } = string.Empty;

    [JsonPropertyName("assets")]
    public List<GitHubAssetDto> Assets { get; set; } = new();
}

public sealed class UpdateCheckResult
{
    public string CurrentAppVersion { get; set; } = "1.1.0";
    public string ActiveChannel { get; set; } = "prod";
    public string ChannelTitle { get; set; } = "Looping";
    public string ChannelTier { get; set; } = "Production Release";
    public string RemoteChannelVersion { get; set; } = "1.1";
    public string RemoteArchVersion { get; set; } = "3.0A";
    public string InstalledEngineVersion { get; set; } = "No detectado";
    public string InstalledEnginePath { get; set; } = string.Empty;
    public bool EngineUpdateAvailable { get; set; }
    public bool AppUpdateAvailable { get; set; }
    public string EnginePackageUrl { get; set; } = string.Empty;
    public string EngineExpectedSha256 { get; set; } = string.Empty;
    public string? AppPackageUrl { get; set; }
    public string? AppPackageName { get; set; }
    public string? AppExpectedSha256 { get; set; }
    public string? RemoteAppVersion { get; set; }
    public string ReleaseNotes { get; set; } = string.Empty;
    public string SourceMirror { get; set; } = string.Empty;
    public List<ArchHistoryEntry> ArchitectureTimeline { get; set; } = new();
    public List<GitHubReleaseDto> GitHubReleases { get; set; } = new();
}
