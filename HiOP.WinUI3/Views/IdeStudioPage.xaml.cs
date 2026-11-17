using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using HiOP.WinUI3.Models;
using HiOP.WinUI3.Services;
using Microsoft.UI;
using Microsoft.UI.Text;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Input;
using Microsoft.UI.Xaml.Media;
using Windows.Storage.Pickers;
using Windows.System;
using Windows.UI;
using WinRT.Interop;

namespace HiOP.WinUI3.Views;

public sealed partial class IdeStudioPage : Page
{
    private readonly AppStateService _state = AppStateService.Current;
    private bool _suppressEditorTextChanged;
    private bool _sidebarVisible = true;
    private bool _terminalVisible = true;

    public IdeStudioPage()
    {
        InitializeComponent();
        BuildNewTemplateMenu();
        Loaded += IdeStudioPage_Loaded;
    }

    private void IdeStudioPage_Loaded(object sender, RoutedEventArgs e)
    {
        RefreshWorkspaceTree();
        SyncTabsUi();
        LoadActiveTabIntoEditor();
        RefreshInspector();
        RefreshFooter();
    }

    private void BuildNewTemplateMenu()
    {
        NewTemplateMenuFlyout.Items.Clear();
        foreach (var preset in WorkspaceService.GetNewArch30ATemplates())
        {
            var item = new MenuFlyoutItem
            {
                Text = $"{preset.Title} ({preset.FileName})"
            };
            item.Click += (_, _) => CreateTabFromPreset(preset.FileName, preset.Code);
            NewTemplateMenuFlyout.Items.Add(item);
        }
    }

    private void CreateTabFromPreset(string fileName, string code)
    {
        var dir = Path.Combine(_state.Workspace.WorkspaceRoot, "sample_loop_projects");
        Directory.CreateDirectory(dir);
        var fullPath = Path.Combine(dir, fileName);

        var tab = new EditorTab
        {
            Id = fullPath,
            FilePath = fullPath,
            Content = code,
            IsDirty = true
        };
        _state.OpenTabs.Add(tab);
        _state.ActiveTab = tab;
        SyncTabsUi();
        LoadActiveTabIntoEditor();
        RefreshInspector();
        AppendTerminal($"✨ Nueva plantilla Arch 3.0A abierta: {fileName}");
    }

    private void RefreshWorkspaceTree()
    {
        var nodes = _state.Workspace.BuildWorkspaceTree(2);
        WorkspaceTree.ItemsSource = nodes;
        WorkspacePathLabel.Text = _state.Workspace.WorkspaceRoot;
    }

    private void SyncTabsUi()
    {
        TabsStrip.Children.Clear();
        foreach (var tab in _state.OpenTabs.ToList())
        {
            bool isActive = tab == _state.ActiveTab;
            var pill = new Grid
            {
                ColumnSpacing = 6,
                Padding = new Thickness(10, 5, 6, 5),
                CornerRadius = new CornerRadius(6),
                Background = new SolidColorBrush(isActive
                    ? Color.FromArgb(255, 22, 34, 58)
                    : Color.FromArgb(140, 12, 18, 32)),
                BorderBrush = new SolidColorBrush(isActive
                    ? Color.FromArgb(255, 0, 245, 212)
                    : Color.FromArgb(60, 148, 163, 184)),
                BorderThickness = new Thickness(1)
            };
            pill.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });
            pill.ColumnDefinitions.Add(new ColumnDefinition { Width = GridLength.Auto });

            var selectBtn = new Button
            {
                Content = tab.DisplayTitle,
                Padding = new Thickness(2, 0, 2, 0),
                Background = new SolidColorBrush(Colors.Transparent),
                BorderThickness = new Thickness(0),
                FontSize = 12,
                FontWeight = isActive ? FontWeights.SemiBold : FontWeights.Normal,
                Foreground = new SolidColorBrush(isActive
                    ? Color.FromArgb(255, 248, 250, 252)
                    : Color.FromArgb(255, 148, 163, 184))
            };
            selectBtn.Click += (_, _) =>
            {
                _state.ActiveTab = tab;
                SyncTabsUi();
                LoadActiveTabIntoEditor();
                RefreshInspector();
            };

            var closeBtn = new Button
            {
                Content = "✕",
                Padding = new Thickness(4, 0, 4, 0),
                FontSize = 10,
                Background = new SolidColorBrush(Colors.Transparent),
                BorderThickness = new Thickness(0),
                Foreground = new SolidColorBrush(Color.FromArgb(180, 148, 163, 184))
            };
            closeBtn.Click += (_, _) =>
            {
                _state.OpenTabs.Remove(tab);
                if (_state.ActiveTab == tab)
                    _state.ActiveTab = _state.OpenTabs.LastOrDefault();
                SyncTabsUi();
                LoadActiveTabIntoEditor();
                RefreshInspector();
            };

            Grid.SetColumn(selectBtn, 0);
            Grid.SetColumn(closeBtn, 1);
            pill.Children.Add(selectBtn);
            pill.Children.Add(closeBtn);
            TabsStrip.Children.Add(pill);
        }
    }

    private void LoadActiveTabIntoEditor()
    {
        _suppressEditorTextChanged = true;
        try
        {
            if (_state.ActiveTab is { } tab)
            {
                CodeEditorBox.IsEnabled = true;
                CodeEditorBox.Text = tab.Content;
                ActiveFileInfoText.Text = $"{tab.FilePath}  •  {tab.LanguageTag}";
                UpdateLineNumbersAndStats(tab.Content);
            }
            else
            {
                CodeEditorBox.IsEnabled = false;
                CodeEditorBox.Text = string.Empty;
                ActiveFileInfoText.Text = "Ningún archivo abierto";
                LineNumbersText.Text = "1";
                EditorStatsText.Text = "0 líneas";
            }
        }
        finally
        {
            _suppressEditorTextChanged = false;
        }
    }

    private void UpdateLineNumbersAndStats(string text)
    {
        var lines = text.Replace("\r\n", "\n").Split('\n');
        int count = Math.Max(1, lines.Length);
        var sb = new StringBuilder();
        for (int i = 1; i <= count; i++)
            sb.AppendLine(i.ToString());
        LineNumbersText.Text = sb.ToString().TrimEnd();
        EditorStatsText.Text = $"{count} líneas  •  {text.Length:N0} caracteres";
    }

    private void RefreshInspector()
    {
        var code = _state.ActiveTab?.Content ?? string.Empty;
        var astNodes = LoopingBuiltInAnalyzer.BuildAst(code);
        var astSb = new StringBuilder();
        foreach (var node in astNodes.Take(30))
        {
            astSb.AppendLine($"• {node.LineDisplay}");
            foreach (var ch in node.Children.Take(10))
                astSb.AppendLine($"   └─ {ch.LineDisplay}");
        }
        AstSummaryText.Text = astSb.Length > 0 ? astSb.ToString().TrimEnd() : "(Sin nodos AST)";

        var checks = LoopingBuiltInAnalyzer.CheckCode(code, _state.ActiveTab?.Title ?? "script.loop");
        CheckSummaryText.Text = string.Join(Environment.NewLine, checks.Select(c => $"[L{c.Line}] {c.Message}"));

        PolyglotSummaryText.Text = LoopingBuiltInAnalyzer.ExtractPolyglotSummary(code) + Environment.NewLine +
                                   LoopingBuiltInAnalyzer.GenerateSwiftUiOrC2PreviewSummary(code);
    }

    private void RefreshFooter()
    {
        var eng = _state.Engine.ResolvePreferredEnginePath(out var kind);
        var ch = SmiledevService.GetChannelDisplay(_state.Smiledev.GetActiveChannel());
        StatusFooterLeft.Text = string.IsNullOrEmpty(eng)
            ? "Motor local: WebView2 Stage activo (descarga binario nativo en Actualizaciones)"
            : $"Motor activo: {kind} ({Path.GetFileName(eng)})";
        StatusFooterRight.Text = $"Canal: {ch.Title} (v{ch.VersionLabel}) • Arch 3.0A";
    }

    private void AppendTerminal(string text)
    {
        _state.AppendTerminalLog(text);
        TerminalOutputBox.Text = string.Join(Environment.NewLine, _state.TerminalLogs);
        TerminalScroll.ChangeView(null, TerminalScroll.ScrollableHeight, null);
    }

    // ── Events ─────────────────────────────────────────────────────────────────
    private void WorkspaceTree_ItemInvoked(TreeView sender, TreeViewItemInvokedEventArgs args)
    {
        if (args.InvokedItem is FileNode { IsDirectory: false } fileNode)
        {
            _state.OpenFileInTab(fileNode.FullPath);
            SyncTabsUi();
            LoadActiveTabIntoEditor();
            RefreshInspector();
        }
    }

    private void CodeEditorBox_TextChanged(object sender, TextChangedEventArgs e)
    {
        if (_suppressEditorTextChanged || _state.ActiveTab == null) return;
        _state.ActiveTab.Content = CodeEditorBox.Text;
        if (!_state.ActiveTab.IsDirty)
        {
            _state.ActiveTab.IsDirty = true;
            SyncTabsUi();
        }
        UpdateLineNumbersAndStats(CodeEditorBox.Text);
    }

    private void CodeEditorBox_KeyDown(object sender, KeyRoutedEventArgs e)
    {
        if (e.Key == VirtualKey.Tab)
        {
            e.Handled = true;
            int sel = CodeEditorBox.SelectionStart;
            CodeEditorBox.SelectedText = "    ";
            CodeEditorBox.SelectionStart = sel + 4;
        }
        else if (e.Key == VirtualKey.F5)
        {
            e.Handled = true;
            BtnRunNative_Click(this, new RoutedEventArgs());
        }
    }

    private void BtnToggleSidebar_Click(object sender, RoutedEventArgs e)
    {
        _sidebarVisible = !_sidebarVisible;
        SidebarColumn.Width = _sidebarVisible ? new GridLength(260) : new GridLength(0);
    }

    private void BtnToggleTerminal_Click(object sender, RoutedEventArgs e)
    {
        _terminalVisible = !_terminalVisible;
        TerminalDrawer.Visibility = _terminalVisible ? Visibility.Visible : Visibility.Collapsed;
    }

    private async void BtnOpenFile_Click(object sender, RoutedEventArgs e)
    {
        var picker = new FileOpenPicker();
        picker.FileTypeFilter.Add(".loop");
        picker.FileTypeFilter.Add(".ruup");
        picker.FileTypeFilter.Add(".c2");
        picker.FileTypeFilter.Add(".json");
        picker.FileTypeFilter.Add(".cs");
        picker.FileTypeFilter.Add(".py");
        picker.FileTypeFilter.Add(".hpp");
        picker.FileTypeFilter.Add("*");

        if (App.MainAppWindow != null)
        {
            var hwnd = WindowNative.GetWindowHandle(App.MainAppWindow);
            InitializeWithWindow.Initialize(picker, hwnd);
        }

        var file = await picker.PickSingleFileAsync();
        if (file != null)
        {
            _state.OpenFileInTab(file.Path);
            SyncTabsUi();
            LoadActiveTabIntoEditor();
            RefreshInspector();
        }
    }

    private void BtnSaveFile_Click(object sender, RoutedEventArgs e) => SaveActiveTab();

    private bool SaveActiveTab()
    {
        if (_state.ActiveTab == null) return false;
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(_state.ActiveTab.FilePath)!);
            File.WriteAllText(_state.ActiveTab.FilePath, _state.ActiveTab.Content, Encoding.UTF8);
            _state.ActiveTab.IsDirty = false;
            SyncTabsUi();
            AppendTerminal($"💾 Guardado: {_state.ActiveTab.FilePath} ({_state.ActiveTab.Content.Length:N0} chars)");
            return true;
        }
        catch (Exception ex)
        {
            AppendTerminal($"✘ Error guardando archivo: {ex.Message}");
            return false;
        }
    }

    private async void BtnRunNative_Click(object sender, RoutedEventArgs e)
    {
        if (_state.ActiveTab == null) return;
        SaveActiveTab();

        if (!_terminalVisible) BtnToggleTerminal_Click(sender, e);
        BtnRunNative.IsEnabled = false;
        BtnStopRun.IsEnabled = true;
        ExecutionStatusBadge.Text = "● EJECUTANDO...";

        var ch = _state.Smiledev.GetActiveChannel();
        AppendTerminal("==================================================================");
        AppendTerminal($"⚡ [hiOP STUDIO] Ejecutando {_state.ActiveTab.Title} (Canal: {ch})");

        var args = new List<string>();
        if (TargetCombo.SelectedIndex == 3)
            args.AddRange(["preview", _state.ActiveTab.FilePath]);
        else
            args.AddRange(["--channel", ch, _state.ActiveTab.FilePath]);

        var (exit, ms, _) = await _state.Engine.RunLoopingCommandAsync(
            args,
            _state.Workspace.WorkspaceRoot,
            line => DispatcherQueue.TryEnqueue(() => AppendTerminal(line)),
            preferNodeFallback: TargetCombo.SelectedIndex != 0 || true);

        BtnRunNative.IsEnabled = true;
        BtnStopRun.IsEnabled = false;
        ExecutionStatusBadge.Text = exit == 0 ? $"✔ EXIT 0 ({ms:N0} ms)" : $"● EXIT {exit} ({ms:N0} ms)";
        AppendTerminal($"■ Finalizado en {ms:N0} ms (código {exit}).");
    }

    private void BtnStopRun_Click(object sender, RoutedEventArgs e)
    {
        _state.Engine.StopActiveProcess();
        AppendTerminal("■ Proceso detenido por el usuario.");
        ExecutionStatusBadge.Text = "■ DETENIDO";
        BtnRunNative.IsEnabled = true;
        BtnStopRun.IsEnabled = false;
    }

    private void BtnRunStage3D_Click(object sender, RoutedEventArgs e)
    {
        if (_state.ActiveTab != null)
        {
            _state.PendingStageCode = _state.ActiveTab.Content;
        }
        _state.RequestNavigate("stage");
    }

    private async void BtnCheck_Click(object sender, RoutedEventArgs e)
    {
        if (_state.ActiveTab == null) return;
        SaveActiveTab();
        RefreshInspector();
        var items = LoopingBuiltInAnalyzer.CheckCode(_state.ActiveTab.Content, _state.ActiveTab.Title);
        AppendTerminal($"🔍 [CHECK] Análisis estático para {_state.ActiveTab.Title}:");
        foreach (var d in items)
            AppendTerminal($"   [{d.Severity}] Línea {d.Line}: {d.Message}");

        await _state.Engine.RunLoopingCommandAsync(
            ["check", _state.ActiveTab.FilePath],
            _state.Workspace.WorkspaceRoot,
            line => DispatcherQueue.TryEnqueue(() => AppendTerminal(line)));
    }

    private async void BtnAst_Click(object sender, RoutedEventArgs e)
    {
        if (_state.ActiveTab == null) return;
        RefreshInspector();
        AppendTerminal($"🌳 [AST INSPECTOR Arch 3.0A] {_state.ActiveTab.Title}:");
        AppendTerminal(AstSummaryText.Text);
        if (File.Exists(_state.ActiveTab.FilePath))
        {
            await _state.Engine.RunLoopingCommandAsync(
                ["ast", _state.ActiveTab.FilePath],
                _state.Workspace.WorkspaceRoot,
                line => DispatcherQueue.TryEnqueue(() => AppendTerminal(line)));
        }
    }

    private void BtnFmt_Click(object sender, RoutedEventArgs e)
    {
        if (_state.ActiveTab == null) return;
        var formatted = LoopingBuiltInAnalyzer.FormatCode(_state.ActiveTab.Content);
        _state.ActiveTab.Content = formatted;
        _state.ActiveTab.IsDirty = true;
        LoadActiveTabIntoEditor();
        SyncTabsUi();
        RefreshInspector();
        AppendTerminal($"✨ [FMT] {_state.ActiveTab.Title} formateado según guía Arch 3.0A.");
    }

    private async void BtnInvis_Click(object sender, RoutedEventArgs e)
    {
        if (_state.ActiveTab == null) return;
        SaveActiveTab();
        var outLpbn = Path.ChangeExtension(_state.ActiveTab.FilePath, ".lpbn");
        AppendTerminal($"📦 [INVIS. COMPILE LPBN v3.0A] Empaquetando {_state.ActiveTab.Title} -> {Path.GetFileName(outLpbn)}");
        await _state.Engine.RunLoopingCommandAsync(
            ["invis", _state.ActiveTab.FilePath, "-o", outLpbn],
            _state.Workspace.WorkspaceRoot,
            line => DispatcherQueue.TryEnqueue(() => AppendTerminal(line)));
    }

    private void BtnRefreshTree_Click(object sender, RoutedEventArgs e) => RefreshWorkspaceTree();
    private void BtnRefreshInspector_Click(object sender, RoutedEventArgs e) => RefreshInspector();
    private void BtnClearTerminal_Click(object sender, RoutedEventArgs e)
    {
        _state.TerminalLogs.Clear();
        TerminalOutputBox.Text = string.Empty;
    }
    private void BtnOpenSmiledev_Click(object sender, RoutedEventArgs e) => _state.RequestNavigate("smiledev");
}
