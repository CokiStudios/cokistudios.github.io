using System.ComponentModel;
using System.IO;
using System.Runtime.CompilerServices;

namespace HiOP.WinUI3.Models;

public sealed class EditorTab : INotifyPropertyChanged
{
    private string _content = string.Empty;
    private bool _isDirty;
    private string _title = string.Empty;
    private string _filePath = string.Empty;

    public string Id { get; init; } = string.Empty;

    public string FilePath
    {
        get => _filePath;
        set
        {
            if (_filePath != value)
            {
                _filePath = value;
                _title = Path.GetFileName(value);
                OnPropertyChanged();
                OnPropertyChanged(nameof(Title));
                OnPropertyChanged(nameof(DisplayTitle));
                OnPropertyChanged(nameof(LanguageTag));
            }
        }
    }

    public string Title
    {
        get => _title;
        set
        {
            if (_title != value)
            {
                _title = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(DisplayTitle));
            }
        }
    }

    public string Content
    {
        get => _content;
        set
        {
            if (_content != value)
            {
                _content = value;
                OnPropertyChanged();
            }
        }
    }

    public bool IsDirty
    {
        get => _isDirty;
        set
        {
            if (_isDirty != value)
            {
                _isDirty = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(DisplayTitle));
            }
        }
    }

    public bool IsVirtualSample { get; set; }

    public string DisplayTitle => IsDirty ? $"{Title} •" : Title;

    public string LanguageTag => Path.GetExtension(FilePath).ToLowerInvariant() switch
    {
        ".loop" => "Looping v1.1 (Arch 3.0A)",
        ".ruup" => "Ruuping Native",
        ".c2" => "Component 2 (.c2)",
        ".cs" => "C# MonoBehaviour",
        ".cpp" or ".hpp" or ".h" => "C++17 Bridge",
        ".py" => "Python PyLoop",
        ".js" or ".mjs" => "Node / Web Loopize",
        ".json" => "JSON Manifest",
        _ => "Plain Text"
    };

    public event PropertyChangedEventHandler? PropertyChanged;

    private void OnPropertyChanged([CallerMemberName] string? prop = null)
        => PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(prop));
}
