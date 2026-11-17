using System;
using HiOP.WinUI3.Services;
using Microsoft.UI.Composition.SystemBackdrops;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.Storage.Pickers;
using WinRT.Interop;

namespace HiOP.WinUI3.Views;

public sealed partial class SettingsPage : Page
{
    private readonly AppStateService _state = AppStateService.Current;

    public SettingsPage()
    {
        InitializeComponent();
        Loaded += SettingsPage_Loaded;
    }

    private void SettingsPage_Loaded(object sender, RoutedEventArgs e)
    {
        WorkspacePathBox.Text = _state.Workspace.WorkspaceRoot;
        EngineRepoBox.Text = string.IsNullOrEmpty(_state.Workspace.EngineRepoRoot)
            ? "(No detectado)"
            : _state.Workspace.EngineRepoRoot;
        CustomLoopingPathBox.Text = _state.Engine.CustomLoopingExePath ?? string.Empty;
        RefreshSessionUi();
    }

    private void RefreshSessionUi()
    {
        var session = _state.Smiledev.GetSession();
        if (session != null)
        {
            CsIdStatusBadge.Text = $"● Conectado ({session.User})";
            CsIdNameBox.Text = session.User;
            CsIdEmailBox.Text = session.Email;
            CsIdFeedbackText.Text = $"Sesión activa en {_state.Smiledev.AuthFile} | Permisos: {string.Join(", ", session.Scopes)}";
        }
        else
        {
            CsIdStatusBadge.Text = "○ Sin sesión";
            CsIdFeedbackText.Text = "Inicia sesión con un Personal Access Token (cs_pat_...) para publicar módulos verificados.";
        }
    }

    private void BtnCsIdLogin_Click(object sender, RoutedEventArgs e)
    {
        var (_, msg) = _state.Smiledev.LoginWithPat(CsIdPatBox.Password, CsIdNameBox.Text, CsIdEmailBox.Text);
        CsIdFeedbackText.Text = msg;
        RefreshSessionUi();
        _state.NotifyChannelOrStatusChanged();
    }

    private void BtnCsIdLogout_Click(object sender, RoutedEventArgs e)
    {
        _state.Smiledev.Logout();
        CsIdPatBox.Password = string.Empty;
        RefreshSessionUi();
        _state.NotifyChannelOrStatusChanged();
    }

    private async void BtnBrowseWorkspace_Click(object sender, RoutedEventArgs e)
    {
        var picker = new FolderPicker();
        picker.FileTypeFilter.Add("*");
        if (App.MainAppWindow != null)
        {
            InitializeWithWindow.Initialize(picker, WindowNative.GetWindowHandle(App.MainAppWindow));
        }

        var folder = await picker.PickSingleFolderAsync();
        if (folder != null)
        {
            _state.Workspace.SetWorkspace(folder.Path);
            WorkspacePathBox.Text = _state.Workspace.WorkspaceRoot;
            EngineRepoBox.Text = _state.Workspace.EngineRepoRoot;
        }
    }

    private void BtnApplyCustomEngine_Click(object sender, RoutedEventArgs e)
    {
        _state.Engine.CustomLoopingExePath = string.IsNullOrWhiteSpace(CustomLoopingPathBox.Text)
            ? null
            : CustomLoopingPathBox.Text.Trim();
        _state.NotifyChannelOrStatusChanged();
    }

    private void BackdropCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (App.MainAppWindow == null || BackdropCombo.SelectedItem is not ComboBoxItem item) return;
        var tag = item.Tag?.ToString();
        try
        {
            App.MainAppWindow.SystemBackdrop = tag switch
            {
                "Mica" => new MicaBackdrop { Kind = MicaKind.Base },
                "Acrylic" => new DesktopAcrylicBackdrop(),
                _ => new MicaBackdrop { Kind = MicaKind.BaseAlt }
            };
        }
        catch { }
    }
}
