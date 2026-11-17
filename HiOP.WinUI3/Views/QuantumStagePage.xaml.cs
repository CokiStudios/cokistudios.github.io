using System;
using System.Collections.Generic;
using System.Text.Json;
using HiOP.WinUI3.Services;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.Web.WebView2.Core;

namespace HiOP.WinUI3.Views;

public sealed partial class QuantumStagePage : Page
{
    private readonly AppStateService _state = AppStateService.Current;
    private bool _webViewReady;
    private string? _queuedCodeOnReady;
    private readonly List<(string Label, string Code)> _presets = new();

    public QuantumStagePage()
    {
        InitializeComponent();
        PopulatePresets();
        Loaded += QuantumStagePage_Loaded;
    }

    private void PopulatePresets()
    {
        _presets.Add(("📄 Script Activo del Editor IDE", string.Empty));
        foreach (var t in WorkspaceService.GetNewArch30ATemplates())
            _presets.Add((t.Title, t.Code));

        StagePresetCombo.ItemsSource = _presets.ConvertAll(p => p.Label);
        StagePresetCombo.SelectedIndex = 0;
    }

    private async void QuantumStagePage_Loaded(object sender, RoutedEventArgs e)
    {
        try
        {
            if (!_webViewReady)
            {
                await StageWebView.EnsureCoreWebView2Async();
                var dir = WebStageService.ResolveWebStageDirectory(_state);
                StageWebView.CoreWebView2.SetVirtualHostNameToFolderMapping(
                    WebStageService.VirtualHostName,
                    dir,
                    CoreWebView2HostResourceAccessKind.Allow);

                StageWebView.CoreWebView2.WebMessageReceived += CoreWebView2_WebMessageReceived;
                StageWebView.CoreWebView2.Navigate($"https://{WebStageService.VirtualHostName}/stage.html");
                StageSubtitleText.Text = $"WebView2 VirtualHost activo ({dir})";
            }

            if (!string.IsNullOrEmpty(_state.PendingStageCode))
            {
                var code = _state.PendingStageCode;
                _state.PendingStageCode = null;
                StagePresetCombo.SelectedIndex = 0;
                RunCodeInStage(code);
            }
        }
        catch (Exception ex)
        {
            StageSubtitleText.Text = $"⚠ Error inicializando WebView2: {ex.Message}";
        }
    }

    private void CoreWebView2_WebMessageReceived(CoreWebView2 sender, CoreWebView2WebMessageReceivedEventArgs args)
    {
        try
        {
            using var doc = JsonDocument.Parse(args.WebMessageAsJson);
            if (doc.RootElement.TryGetProperty("type", out var t))
            {
                if (t.GetString() == "ready")
                {
                    _webViewReady = true;
                    var initial = _queuedCodeOnReady ?? _state.ActiveTab?.Content ?? WorkspaceService.GetNewArch30ATemplates()[0].Code;
                    _queuedCodeOnReady = null;
                    RunCodeInStage(initial);
                }
                else if (t.GetString() == "log" && doc.RootElement.TryGetProperty("message", out var msg))
                {
                    _state.AppendTerminalLog($"[Stage] {msg.GetString()}");
                }
            }
        }
        catch { }
    }

    private void RunCodeInStage(string code)
    {
        if (!_webViewReady || StageWebView.CoreWebView2 == null)
        {
            _queuedCodeOnReady = code;
            return;
        }

        var payload = JsonSerializer.Serialize(new
        {
            command = "run",
            code,
            channel = _state.Smiledev.GetActiveChannel()
        });
        StageWebView.CoreWebView2.PostWebMessageAsJson(payload);
    }

    private void BtnRunCurrent_Click(object sender, RoutedEventArgs e)
    {
        int idx = StagePresetCombo.SelectedIndex;
        string code = idx <= 0
            ? (_state.ActiveTab?.Content ?? WorkspaceService.GetNewArch30ATemplates()[0].Code)
            : _presets[idx].Code;
        RunCodeInStage(code);
    }

    private void BtnStopStage_Click(object sender, RoutedEventArgs e)
    {
        if (_webViewReady && StageWebView.CoreWebView2 != null)
        {
            StageWebView.CoreWebView2.PostWebMessageAsJson("{\"command\":\"stop\"}");
        }
    }

    private void StagePresetCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (!_webViewReady || StagePresetCombo.SelectedIndex < 0) return;
        BtnRunCurrent_Click(sender, new RoutedEventArgs());
    }
}
