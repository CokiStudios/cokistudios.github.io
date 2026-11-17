using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using HiOP.WinUI3.Services;
using HiOP.WinUI3.Views;
using Microsoft.UI.Composition.SystemBackdrops;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;

namespace HiOP.WinUI3;

public sealed partial class MainWindow : Window
{
    private readonly AppStateService _state = AppStateService.Current;

    public MainWindow()
    {
        InitializeComponent();

        ConfigureBackdropAndTitleBar();
        _state.NavigateRequested += OnNavigateRequested;
        _state.ChannelOrStatusChanged += OnChannelOrStatusChanged;
        _state.UpdateBannerReady += res => DispatcherQueue.TryEnqueue(() =>
        {
            if (res.EngineUpdateAvailable || res.AppUpdateAvailable)
            {
                TitleUpdatePillBtn.Visibility = Visibility.Visible;
                UpdatesNavBadge.Visibility = Visibility.Visible;
            }
        });

        OnChannelOrStatusChanged();
        NavView.SelectedItem = NavView.MenuItems[0];
        NavigateToTag("ide");

        _ = CheckUpdatesInBackgroundAsync();
    }

    private void ConfigureBackdropAndTitleBar()
    {
        try
        {
            SystemBackdrop = new MicaBackdrop { Kind = MicaKind.BaseAlt };
        }
        catch
        {
            try { SystemBackdrop = new DesktopAcrylicBackdrop(); } catch { }
        }

        ExtendsContentIntoTitleBar = true;
        SetTitleBar(AppTitleBar);

        try
        {
            var iconPath = Path.Combine(AppContext.BaseDirectory, "Assets", "AppIcon.ico");
            if (File.Exists(iconPath))
                AppWindow.SetIcon(iconPath);

            AppWindow.Resize(new Windows.Graphics.SizeInt32(1380, 860));
        }
        catch { }
    }

    private async Task CheckUpdatesInBackgroundAsync()
    {
        if (!_state.AutoCheckUpdatesOnStartup) return;
        try
        {
            var res = await _state.Updates.CheckForUpdatesAsync();
            _state.PublishUpdateCheck(res);
        }
        catch { }
    }

    private void OnChannelOrStatusChanged()
    {
        DispatcherQueue.TryEnqueue(() =>
        {
            var ch = SmiledevService.GetChannelDisplay(_state.Smiledev.GetActiveChannel());
            TitleChannelPill.Text = $"{ch.Title} v{ch.VersionLabel} • Arch {(_state.Smiledev.GetActiveChannel() == "alpha" ? "1.1A/3.0A" : "3.0A")}";

            var session = _state.Smiledev.GetSession();
            TitleCsIdText.Text = session != null ? $"CS ID: {session.User}" : "CS ID: Sin sesión";
        });
    }

    private void OnNavigateRequested(string tag)
    {
        DispatcherQueue.TryEnqueue(() =>
        {
            var match = NavView.MenuItems.OfType<NavigationViewItem>().FirstOrDefault(i => i.Tag?.ToString() == tag);
            if (match != null)
                NavView.SelectedItem = match;
            else
                NavigateToTag(tag);
        });
    }

    private void NavView_SelectionChanged(NavigationView sender, NavigationViewSelectionChangedEventArgs args)
    {
        if (args.IsSettingsSelected)
        {
            NavigateToTag("settings");
        }
        else if (args.SelectedItemContainer?.Tag is string tag)
        {
            NavigateToTag(tag);
        }
    }

    private void NavigateToTag(string tag)
    {
        var pageType = tag switch
        {
            "stage" => typeof(QuantumStagePage),
            "toolchain" => typeof(ToolchainPage),
            "smiledev" => typeof(SmiledevPage),
            "updates" => typeof(UpdatesPage),
            "settings" => typeof(SettingsPage),
            _ => typeof(IdeStudioPage)
        };

        if (ContentFrame.CurrentSourcePageType != pageType)
            ContentFrame.Navigate(pageType);
    }

    private void TitleUpdatePillBtn_Click(object sender, RoutedEventArgs e)
        => OnNavigateRequested("updates");
}
