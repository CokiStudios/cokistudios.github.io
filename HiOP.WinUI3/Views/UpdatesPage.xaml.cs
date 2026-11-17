using System;
using System.Text;
using System.Threading.Tasks;
using HiOP.WinUI3.Models;
using HiOP.WinUI3.Services;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.UI;

namespace HiOP.WinUI3.Views;

public sealed partial class UpdatesPage : Page
{
    private readonly AppStateService _state = AppStateService.Current;
    private UpdateCheckResult? _lastResult;
    private readonly StringBuilder _log = new();

    public UpdatesPage()
    {
        InitializeComponent();
        Loaded += UpdatesPage_Loaded;
    }

    private async void UpdatesPage_Loaded(object sender, RoutedEventArgs e)
    {
        HighlightChannelButton();
        await CheckNowAsync();
    }

    private void AppendLog(string msg)
    {
        _log.AppendLine(msg);
        UpdateLogBox.Text = _log.ToString();
    }

    private void HighlightChannelButton()
    {
        var ch = _state.Smiledev.GetActiveChannel();
        var info = SmiledevService.GetChannelDisplay(ch);
        ActiveChannelLabel.Text = $"{info.Title} ({info.Tier} • v{info.VersionLabel})";

        var active = new SolidColorBrush(Color.FromArgb(255, 0, 245, 212));
        var clear = new SolidColorBrush(Colors.Transparent);
        BtnChanProd.BorderBrush = ch == "prod" ? active : clear;
        BtnChanOmega.BorderBrush = ch == "omega" ? active : clear;
        BtnChanAlpha.BorderBrush = ch == "alpha" ? active : clear;
    }

    private async Task CheckNowAsync()
    {
        BtnCheckUpdates.IsEnabled = false;
        AppVersionText.Text = $"Versión actual: v{UpdateService.GetCurrentAppVersion()}";
        EngineRemoteText.Text = "Consultando latest.json y GitHub Releases...";

        try
        {
            var res = await _state.Updates.CheckForUpdatesAsync();
            _lastResult = res;
            _state.PublishUpdateCheck(res);

            EngineInstalledText.Text = $"Motor detectado: {res.InstalledEngineVersion}";
            EngineRemoteText.Text = $"Canal [{res.ChannelTitle}] -> v{res.RemoteChannelVersion} (Arch {res.RemoteArchVersion})";

            if (res.AppUpdateAvailable && !string.IsNullOrEmpty(res.AppPackageUrl))
            {
                AppRemoteText.Text = $"Disponible v{res.RemoteAppVersion}: {res.AppPackageName}";
                BtnSelfUpdateApp.IsEnabled = true;
            }
            else if (res.GitHubReleases.Count > 0)
            {
                var topRel = res.GitHubReleases[0];
                AppRemoteText.Text = $"Al día ✔ (Último release GitHub: {topRel.TagName} • {topRel.Name})";
                BtnSelfUpdateApp.IsEnabled = !string.IsNullOrEmpty(res.AppPackageUrl);
            }
            else
            {
                AppRemoteText.Text = "Al día ✔ (v" + res.CurrentAppVersion + ")";
                BtnSelfUpdateApp.IsEnabled = false;
            }

            ReleaseNotesText.Text = string.IsNullOrWhiteSpace(res.ReleaseNotes) ? "Sin notas." : res.ReleaseNotes;
            MirrorUsedText.Text = $"Fuente: {res.SourceMirror}";
            TimelineList.ItemsSource = res.ArchitectureTimeline;

            AppendLog($"✔ Comprobación completada desde {res.SourceMirror}. Canal: {res.ActiveChannel} v{res.RemoteChannelVersion}");
        }
        catch (Exception ex)
        {
            AppendLog($"✘ Error comprobando actualizaciones: {ex.Message}");
        }
        finally
        {
            BtnCheckUpdates.IsEnabled = true;
        }
    }

    private async void BtnCheckUpdates_Click(object sender, RoutedEventArgs e) => await CheckNowAsync();

    private async void BtnSelectChannel_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: string channel })
        {
            _state.Smiledev.SetActiveChannel(channel);
            HighlightChannelButton();
            _state.NotifyChannelOrStatusChanged();
            AppendLog($"🔀 Canal cambiado a: {channel}");
            await CheckNowAsync();
        }
    }

    private async void BtnUpdateEngine_Click(object sender, RoutedEventArgs e)
    {
        _lastResult ??= await _state.Updates.CheckForUpdatesAsync();
        UpdateProgressCard.Visibility = Visibility.Visible;
        BtnUpdateEngine.IsEnabled = false;

        var prog = new Progress<(string Status, double Percent)>(p =>
        {
            DispatcherQueue.TryEnqueue(() =>
            {
                UpdateProgressLabel.Text = p.Status;
                UpdateProgressBar.Value = p.Percent;
                UpdateProgressPct.Text = $"{p.Percent:N0}%";
            });
        });

        var (_, logs) = await _state.Updates.ApplyEngineAndWebCoreUpdateAsync(_lastResult, prog);
        foreach (var l in logs) AppendLog(l);
        BtnUpdateEngine.IsEnabled = true;
        await CheckNowAsync();
    }

    private async void BtnSelfUpdateApp_Click(object sender, RoutedEventArgs e)
    {
        if (_lastResult == null || string.IsNullOrEmpty(_lastResult.AppPackageUrl))
        {
            AppendLog("ℹ No hay paquete Windows de actualización publicado para reemplazar el binario actual.");
            return;
        }

        UpdateProgressCard.Visibility = Visibility.Visible;
        BtnSelfUpdateApp.IsEnabled = false;

        var prog = new Progress<(string Status, double Percent)>(p =>
        {
            DispatcherQueue.TryEnqueue(() =>
            {
                UpdateProgressLabel.Text = p.Status;
                UpdateProgressBar.Value = p.Percent;
                UpdateProgressPct.Text = $"{p.Percent:N0}%";
            });
        });

        var (ok, msg) = await _state.Updates.DownloadAndLaunchAppSelfUpdateAsync(
            _lastResult.AppPackageUrl,
            _lastResult.AppExpectedSha256,
            prog);
        AppendLog(msg);

        if (ok && _lastResult.AppPackageUrl.EndsWith(".zip", StringComparison.OrdinalIgnoreCase))
        {
            await Task.Delay(1200);
            Application.Current.Exit();
        }
        else
        {
            BtnSelfUpdateApp.IsEnabled = true;
        }
    }
}
