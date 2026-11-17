using System.Collections.ObjectModel;
using Microsoft.UI;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace HiOP.WinUI3.Models;

public sealed class FileNode
{
    public string Id { get; init; } = string.Empty;
    public string Name { get; init; } = string.Empty;
    public string FullPath { get; init; } = string.Empty;
    public bool IsDirectory { get; init; }
    public string Extension { get; init; } = string.Empty;
    public ObservableCollection<FileNode> Children { get; } = new();

    public string Glyph => IsDirectory
        ? "\uE8B7" // FolderFill
        : Extension switch
        {
            ".loop" => "\uE943",   // Code
            ".ruup" => "\uE945",   // Lightning / fast
            ".c2" => "\uEB3C",     // App / UI component
            ".cs" => "\uE99A",     // Chip
            ".cpp" or ".hpp" or ".h" or ".c" => "\uE756", // Command/C++
            ".py" => "\uE8F1",     // Script
            ".js" or ".mjs" or ".ts" => "\uE774", // Web/Node
            ".json" or ".yaml" or ".yml" => "\uE713", // Config
            ".md" or ".txt" => "\uE8A5", // Document
            ".obj" => "\uF158",    // 3D Cube
            _ => "\uE8A5"
        };

    public string BadgeText => IsDirectory
        ? ""
        : Extension switch
        {
            ".loop" => "LOOP",
            ".ruup" => "RUUP",
            ".c2" => "C2 UI",
            ".cs" => "C#",
            ".cpp" or ".hpp" => "C++",
            ".py" => "PY",
            ".js" or ".mjs" => "JS",
            ".json" => "JSON",
            ".obj" => "3D",
            _ => Extension.TrimStart('.').ToUpperInvariant()
        };

    public SolidColorBrush AccentBrush
    {
        get
        {
            var c = IsDirectory
                ? Color.FromArgb(255, 56, 189, 248)
                : Extension switch
                {
                    ".loop" => Color.FromArgb(255, 0, 245, 212),
                    ".ruup" => Color.FromArgb(255, 244, 63, 94),
                    ".c2" => Color.FromArgb(255, 192, 132, 252),
                    ".cs" => Color.FromArgb(255, 16, 185, 129),
                    ".cpp" or ".hpp" or ".h" => Color.FromArgb(255, 59, 130, 246),
                    ".py" => Color.FromArgb(255, 251, 191, 36),
                    ".js" or ".mjs" => Color.FromArgb(255, 250, 204, 21),
                    ".json" => Color.FromArgb(255, 148, 163, 184),
                    ".obj" => Color.FromArgb(255, 232, 121, 249),
                    _ => Color.FromArgb(255, 203, 213, 225)
                };
            return new SolidColorBrush(c);
        }
    }
}
