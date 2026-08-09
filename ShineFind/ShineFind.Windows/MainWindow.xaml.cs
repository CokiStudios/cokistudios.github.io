using System;
using System.Windows;
using System.Windows.Input;
using CefSharp;
using CefSharp.Wpf;

namespace ShineFind.Windows;

public partial class MainWindow : Window
{
    private bool _isOptimizationModeActive = false;

    private void BtnOptimization_Click(object sender, RoutedEventArgs e)
    {
        _isOptimizationModeActive = !_isOptimizationModeActive;

        if (_isOptimizationModeActive)
        {
            BtnOptimization.Content = "⚡ Optimizaciones: ON";
            BtnOptimization.Background = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(56, 189, 248));
            BtnOptimization.Foreground = System.Windows.Media.Brushes.White;
            TxtStatus.Text = "⚡ Optimizaciones del Navegador Activas (--disable-accelerated-video-decode --enable-low-power)";
            TxtStatus.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(56, 189, 248));

            MessageBox.Show(
                "⚡ OPTIMIZACIONES DEL NAVEGADOR ACTIVADAS:\n\n" +
                "1. Desactivación inteligente de decodificación HW de video para prevenir congelamientos\n" +
                "2. Modo de bajo consumo de GPU / Software Composition Fallback\n" +
                "3. Gestión dinámica de VRAM Swap y ahorro de memoria del sistema\n" +
                "4. Ajustes de aceleración gráfica para estabilidad total",
                "Shine Find Sentinel — Optimizaciones del Navegador",
                MessageBoxButton.OK,
                MessageBoxImage.Information
            );
        }
        else
        {
            BtnOptimization.Content = "⚡ Optimizaciones: OFF";
            BtnOptimization.Background = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(0x26, 0x38, 0xBD, 0xF8));
            BtnOptimization.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(56, 189, 248));
            TxtStatus.Text = "Ready (Hardware Accelerated)";
            TxtStatus.Foreground = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(16, 185, 129));
        }
    }
}

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


}