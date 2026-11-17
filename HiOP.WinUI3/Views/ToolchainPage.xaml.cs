using System;
using System.IO;
using System.Text;
using HiOP.WinUI3.Services;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;

namespace HiOP.WinUI3.Views;

public sealed partial class ToolchainPage : Page
{
    private readonly AppStateService _state = AppStateService.Current;
    private readonly StringBuilder _output = new();

    public ToolchainPage()
    {
        InitializeComponent();
        Loaded += ToolchainPage_Loaded;
    }

    private async void ToolchainPage_Loaded(object sender, RoutedEventArgs e)
    {
        ActiveFileLabel.Text = _state.ActiveTab?.FilePath ?? "(Sin archivo abierto en IDE)";
        DoctorItemsControl.ItemsSource = await _state.Engine.RunHostDiagnosticsAsync();
    }

    private async void BtnRunDoctor_Click(object sender, RoutedEventArgs e)
        => DoctorItemsControl.ItemsSource = await _state.Engine.RunHostDiagnosticsAsync();

    private void AppendLine(string line)
    {
        _output.AppendLine(line);
        ToolchainOutputBox.Text = _output.ToString();
    }

    private void ClearAndHeader(string title)
    {
        _output.Clear();
        AppendLine($"═══ {title} ═══");
    }

    private async void BtnInvis_Click(object sender, RoutedEventArgs e)
    {
        if (_state.ActiveTab == null)
        {
            ClearAndHeader("Invis. Compile LPBN v3.0A");
            AppendLine("Abre primero un archivo .loop en el IDE Studio.");
            return;
        }
        Directory.CreateDirectory(Path.GetDirectoryName(_state.ActiveTab.FilePath)!);
        File.WriteAllText(_state.ActiveTab.FilePath, _state.ActiveTab.Content);
        var outPath = Path.ChangeExtension(_state.ActiveTab.FilePath, ".lpbn");

        ClearAndHeader($"Invis. Compile -> {Path.GetFileName(outPath)}");
        await _state.Engine.RunLoopingCommandAsync(
            ["invis", _state.ActiveTab.FilePath, "-o", outPath],
            _state.Workspace.WorkspaceRoot,
            l => DispatcherQueue.TryEnqueue(() => AppendLine(l)));
    }

    private async void BtnSwiftUiPreview_Click(object sender, RoutedEventArgs e)
    {
        var code = _state.ActiveTab?.Content ?? WorkspaceService.GetNewArch30ATemplates()[3].Code;
        ClearAndHeader("Transpilador Declarativo SwiftUI / Component 2");
        AppendLine(LoopingBuiltInAnalyzer.GenerateSwiftUiOrC2PreviewSummary(code));
        if (_state.ActiveTab != null && File.Exists(_state.ActiveTab.FilePath))
        {
            AppendLine("\n--- Salida del motor native preview ---");
            await _state.Engine.RunLoopingCommandAsync(
                ["preview", _state.ActiveTab.FilePath],
                _state.Workspace.WorkspaceRoot,
                l => DispatcherQueue.TryEnqueue(() => AppendLine(l)));
        }
    }

    private void BtnPolyglotInspect_Click(object sender, RoutedEventArgs e)
    {
        var code = _state.ActiveTab?.Content ?? WorkspaceService.GetNewArch30ATemplates()[1].Code;
        ClearAndHeader("Inspector Políglota (C# MonoBehaviour + Python PyLoop)");
        AppendLine(LoopingBuiltInAnalyzer.ExtractPolyglotSummary(code));
    }

    private async void BtnBench_Click(object sender, RoutedEventArgs e)
    {
        ClearAndHeader("Benchmark Looping Native VM");
        await _state.Engine.RunLoopingCommandAsync(
            ["bench"],
            _state.Workspace.WorkspaceRoot,
            l => DispatcherQueue.TryEnqueue(() => AppendLine(l)));
    }

    private async void BtnRunTestSuite_Click(object sender, RoutedEventArgs e)
    {
        ClearAndHeader("Suite de Verificación Looping C++17");
        await _state.Engine.RunLoopingCommandAsync(
            ["test"],
            _state.Workspace.WorkspaceRoot,
            l => DispatcherQueue.TryEnqueue(() => AppendLine(l)));
    }

    private async void BtnEngineDoctor_Click(object sender, RoutedEventArgs e)
    {
        ClearAndHeader("looping doctor");
        await _state.Engine.RunLoopingCommandAsync(
            ["doctor"],
            _state.Workspace.WorkspaceRoot,
            l => DispatcherQueue.TryEnqueue(() => AppendLine(l)));
    }

    private async void BtnCompileTarget_Click(object sender, RoutedEventArgs e)
    {
        if (_state.ActiveTab == null) return;
        File.WriteAllText(_state.ActiveTab.FilePath, _state.ActiveTab.Content);
        var profile = (ProfileCombo.SelectedItem as ComboBoxItem)?.Content?.ToString() ?? "shine_ui";
        ClearAndHeader($"Compilando {_state.ActiveTab.Title} -> perfil '{profile}'");
        await _state.Engine.RunLoopingCommandAsync(
            ["compile", _state.ActiveTab.FilePath, "--target", profile],
            _state.Workspace.WorkspaceRoot,
            l => DispatcherQueue.TryEnqueue(() => AppendLine(l)));
    }
}
