using System;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using HiOP.WinUI3.Models;

namespace HiOP.WinUI3.Services;

public sealed class AppStateService
{
    public static AppStateService Current { get; } = new();

    public WorkspaceService Workspace { get; }
    public EngineProcessService Engine { get; }
    public SmiledevService Smiledev { get; }
    public UpdateService Updates { get; }

    public ObservableCollection<EditorTab> OpenTabs { get; } = new();
    public EditorTab? ActiveTab { get; set; }
    public ObservableCollection<string> TerminalLogs { get; } = new();

    public string? PendingStageCode { get; set; }
    public bool AutoCheckUpdatesOnStartup { get; set; } = true;
    public string PreferredBackdrop { get; set; } = "Mica";

    public event Action<string>? NavigateRequested;
    public event Action? ChannelOrStatusChanged;
    public event Action<UpdateCheckResult>? UpdateBannerReady;

    private AppStateService()
    {
        Workspace = new WorkspaceService();
        Engine = new EngineProcessService(Workspace);
        Smiledev = new SmiledevService(Workspace);
        Updates = new UpdateService(Workspace, Smiledev, Engine);

        SeedInitialTabs();
    }

    private void SeedInitialTabs()
    {
        var files = Workspace.FindInitialFilesToOpen();
        if (files.Count > 0)
        {
            OpenFileInTab(files[0]);
        }
        else
        {
            var preset = WorkspaceService.GetNewArch30ATemplates()[0];
            var virtualTab = new EditorTab
            {
                Id = "sample://" + preset.FileName,
                FilePath = Path.Combine(Workspace.WorkspaceRoot, "sample_loop_projects", preset.FileName),
                Content = preset.Code,
                IsDirty = false,
                IsVirtualSample = true
            };
            OpenTabs.Add(virtualTab);
            ActiveTab = virtualTab;
        }
    }

    public EditorTab? OpenFileInTab(string filePath)
    {
        var existing = OpenTabs.FirstOrDefault(t => string.Equals(t.FilePath, filePath, StringComparison.OrdinalIgnoreCase));
        if (existing != null)
        {
            ActiveTab = existing;
            return existing;
        }

        if (!File.Exists(filePath)) return null;
        try
        {
            var content = File.ReadAllText(filePath);
            var tab = new EditorTab
            {
                Id = filePath,
                FilePath = filePath,
                Content = content,
                IsDirty = false
            };
            OpenTabs.Add(tab);
            ActiveTab = tab;
            return tab;
        }
        catch (Exception ex)
        {
            AppendTerminalLog($"✘ No se pudo leer {filePath}: {ex.Message}");
            return null;
        }
    }

    public void AppendTerminalLog(string line)
    {
        TerminalLogs.Add(line);
        if (TerminalLogs.Count > 1000)
            TerminalLogs.RemoveAt(0);
    }

    public void RequestNavigate(string tag) => NavigateRequested?.Invoke(tag);
    public void NotifyChannelOrStatusChanged() => ChannelOrStatusChanged?.Invoke();
    public void PublishUpdateCheck(UpdateCheckResult result) => UpdateBannerReady?.Invoke(result);
}
