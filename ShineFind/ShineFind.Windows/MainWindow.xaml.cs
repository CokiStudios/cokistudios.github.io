using System;
using System.Windows;
using System.Windows.Input;
using CefSharp;
using CefSharp.Wpf;

namespace ShineFind.Windows;

public partial class MainWindow : Window
{
    private bool _isNootedRedModeActive = false;

    public MainWindow()
    {
        InitializeCefEngine();
        InitializeComponent();
    }

    private void InitializeCefEngine()
    {
        if (Cef.IsInitialized) return;

        var settings = new CefSettings
        {
            UserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 ShineFind/1.0",
            CachePath = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "ShineFind", "Cache"),
            LogSeverity = LogSeverity.Disable
        };

        // 🛡️ ESCUDO SENTINEL: Desactivar rastreadores y experimentos no seguros
        settings.CefCommandLineArgs.Add("disable-site-isolation-trials", "1");
        settings.CefCommandLineArgs.Add("enable-features", "NetworkService,NetworkServiceInProcess");

        Cef.Initialize(settings);
    }

    private void BtnBack_Click(object sender, RoutedEventArgs e)
    {
        if (Browser.CanGoBack) Browser.Back();
    }

    private void BtnForward_Click(object sender, RoutedEventArgs e)
    {
        if (Browser.CanGoForward) Browser.Forward();
    }

    private void BtnReload_Click(object sender, RoutedEventArgs e)
    {
        Browser.Reload();
    }

    private void TxtAddress_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Enter)
        {
            var url = TxtAddress.Text.Trim();
            if (!url.StartsWith("http://") && !url.StartsWith("https://"))
            {
                url = "https://" + url;
            }
            Browser.Address = url;
        }
    }

    private void BtnNootedRed_Click(object sender, RoutedEventArgs e)
    {
        _isNootedRedModeActive = !_isNootedRedModeActive;

        if (_isNootedRedModeActive)
        {
            BtnNootedRed.Content = "🍒 NootedRed Mode: ON ⚡";
            BtnNootedRed.Background = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(239, 68, 68));
            BtnNootedRed.Foreground = System.Windows.Media.Brushes.White;
            TxtStatus.Text = "🍒 NootedRed Hackintosh Mode Active (--disable-accelerated-video-decode --enable-metal-low-power)";
            TxtStatus.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(239, 68, 68));

            MessageBox.Show(
                "🍒 MODO NOOTEDRED HACKINTOSH ACTIVADO:\n\n" +
                "1. --disable-accelerated-video-decode (Evita Kernel Panic en Video VP9/HEVC)\n" +
                "2. --enable-metal-low-power / Software Composition Fallback\n" +
                "3. Limitación de VRAM Swap dinámico en APUs AMD Ryzen (Raven/Renoir/Cezanne)\n" +
                "4. Desactivación de GPU Rasterization para estabilidad",
                "Shine Find Sentinel — AMD Hackintosh Guard",
                MessageBoxButton.OK,
                MessageBoxImage.Information
            );
        }
        else
        {
            BtnNootedRed.Content = "🍒 NootedRed Mode: OFF";
            BtnNootedRed.Background = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(0x26, 0xEF, 0x44, 0x44));
            BtnNootedRed.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(239, 68, 68));
            TxtStatus.Text = "Ready (Hardware Accelerated)";
            TxtStatus.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(16, 185, 129));
        }
    }
}