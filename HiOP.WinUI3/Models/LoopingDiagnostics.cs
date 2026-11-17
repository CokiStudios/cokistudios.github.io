using System.Collections.ObjectModel;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace HiOP.WinUI3.Models;

public sealed class AstNodeItem
{
    public int LineNumber { get; set; }
    public string Kind { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Detail { get; set; } = string.Empty;
    public ObservableCollection<AstNodeItem> Children { get; } = new();
    public string LineDisplay => $"L{LineNumber}: [{Kind}] {Name}";
}

public sealed class DiagnosticItem
{
    public string Severity { get; set; } = "Info"; // Error | Warning | Info
    public int Line { get; set; }
    public string Message { get; set; } = string.Empty;
    public SolidColorBrush SeverityBrush => new(Severity switch
    {
        "Error" => Color.FromArgb(255, 244, 63, 94),
        "Warning" => Color.FromArgb(255, 251, 191, 36),
        _ => Color.FromArgb(255, 56, 189, 248)
    });
}

public sealed class DoctorCheckItem
{
    public string Component { get; set; } = string.Empty;
    public string Status { get; set; } = "OK"; // OK | WARN | BLOCKED | MISSING
    public string Detail { get; set; } = string.Empty;
    public string Hint { get; set; } = string.Empty;

    public SolidColorBrush StatusBrush => new(Status switch
    {
        "OK" => Color.FromArgb(255, 16, 185, 129),
        "WARN" => Color.FromArgb(255, 251, 191, 36),
        "BLOCKED" => Color.FromArgb(255, 249, 115, 22),
        _ => Color.FromArgb(255, 244, 63, 94)
    });
}
