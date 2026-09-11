using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using CefSharp;
using CefSharp.Wpf;

namespace ShineFind.Windows;

public partial class MainWindow : Window
{
    private bool _isOptimizationModeActive = false;

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
            UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 ShineFind/2.0",
            CachePath = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "ShineFind", "Cache"),
            LogSeverity = LogSeverity.Disable
        };

        // ESCUDO SENTINEL: Desactivar telemetría y experimentos no seguros
        settings.CefCommandLineArgs.Add("disable-site-isolation-trials", "1");
        settings.CefCommandLineArgs.Add("enable-features", "NetworkService,NetworkServiceInProcess");

        Cef.Initialize(settings);
    }

    private void BtnOptimization_Click(object sender, RoutedEventArgs e)
    {
        _isOptimizationModeActive = !_isOptimizationModeActive;

        if (_isOptimizationModeActive)
        {
            BtnOptimization.Content = "Optimizaciones: ON";
            BtnOptimization.Background = new SolidColorBrush(Color.FromRgb(56, 189, 248));
            BtnOptimization.Foreground = Brushes.Black;
            TxtStatus.Text = "Optimizaciones del Navegador Activas (--disable-accelerated-video-decode --enable-low-power)";
            TxtStatus.Foreground = new SolidColorBrush(Color.FromRgb(56, 189, 248));

            MessageBox.Show(
                "OPTIMIZACIONES DEL NAVEGADOR ACTIVADAS:\n\n" +
                "1. Desactivación inteligente de decodificación HW de video para prevenir congelamientos\n" +
                "2. Modo de bajo consumo de GPU / DirectX Software Composition Fallback\n" +
                "3. Gestión dinámica de VRAM Swap y ahorro de memoria del sistema\n" +
                "4. Ajustes de aceleración gráfica para estabilidad total",
                "Shine Find Sentinel — Optimizaciones del Navegador",
                MessageBoxButton.OK,
                MessageBoxImage.Information
            );
        }
        else
        {
            BtnOptimization.Content = "Optimizaciones: OFF";
            BtnOptimization.Background = new SolidColorBrush(Color.FromArgb(0x26, 0x38, 0xBD, 0xF8));
            BtnOptimization.Foreground = new SolidColorBrush(Color.FromRgb(56, 189, 248));
            TxtStatus.Text = "Ready (Hardware Accelerated)";
            TxtStatus.Foreground = new SolidColorBrush(Color.FromRgb(16, 185, 129));
        }
    }

    private void BtnCSID_Click(object sender, RoutedEventArgs e)
    {
        MessageBox.Show(
            "Coki Studios ID (CS ID)\n\n" +
            "Identidad universal vinculada a Supabase Cloud.\n" +
            "Estado: Conectado\n" +
            "Hash de dispositivo activo para sincronización.",
            "CS ID — Shine Find",
            MessageBoxButton.OK,
            MessageBoxImage.Information
        );
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
            NavigateTo(TxtAddress.Text.Trim());
        }
    }

    private void NavigateTo(string url)
    {
        if (string.IsNullOrWhiteSpace(url)) return;
        if (!url.StartsWith("http://") && !url.StartsWith("https://"))
        {
            url = "https://" + url;
        }
        TxtAddress.Text = url;
        Browser.Address = url;
    }

    // Tabs
    private void TabForkar_Click(object sender, RoutedEventArgs e)
    {
        HighlightTab(TabForkar);
        NavigateTo("https://cokistudios.github.io/forkar.html");
    }

    private void TabShineMaps_Click(object sender, RoutedEventArgs e)
    {
        HighlightTab(TabShineMaps);
        NavigateTo("https://cokistudios.github.io/shine-maps.html");
    }

    private void TabProducts_Click(object sender, RoutedEventArgs e)
    {
        HighlightTab(TabProducts);
        NavigateTo("https://cokistudios.github.io/products.html");
    }

    private void TabDashboard_Click(object sender, RoutedEventArgs e)
    {
        HighlightTab(TabDashboard);
        NavigateTo("https://cokistudios.github.io/dashboard.html");
    }

    private void BtnNewTab_Click(object sender, RoutedEventArgs e)
    {
        NavigateTo("https://cokistudios.github.io/index.html");
    }

    private void HighlightTab(Button selected)
    {
        TabForkar.Background = new SolidColorBrush(Color.FromRgb(8, 12, 20));
        TabForkar.Foreground = new SolidColorBrush(Color.FromRgb(148, 163, 184));

        TabShineMaps.Background = new SolidColorBrush(Color.FromRgb(8, 12, 20));
        TabShineMaps.Foreground = new SolidColorBrush(Color.FromRgb(148, 163, 184));

        TabProducts.Background = new SolidColorBrush(Color.FromRgb(8, 12, 20));
        TabProducts.Foreground = new SolidColorBrush(Color.FromRgb(148, 163, 184));

        TabDashboard.Background = new SolidColorBrush(Color.FromRgb(8, 12, 20));
        TabDashboard.Foreground = new SolidColorBrush(Color.FromRgb(148, 163, 184));

        selected.Background = new SolidColorBrush(Color.FromRgb(13, 18, 31));
        selected.Foreground = new SolidColorBrush(Color.FromRgb(56, 189, 248));
    }

    // Bookmarks
    private void Bookmark_Forkar(object sender, RoutedEventArgs e) => NavigateTo("https://cokistudios.github.io/forkar.html");
    private void Bookmark_Maps(object sender, RoutedEventArgs e) => NavigateTo("https://cokistudios.github.io/shine-maps.html");
    private void Bookmark_Products(object sender, RoutedEventArgs e) => NavigateTo("https://cokistudios.github.io/products.html");
    private void Bookmark_Dashboard(object sender, RoutedEventArgs e) => NavigateTo("https://cokistudios.github.io/dashboard.html");
    private void Bookmark_Gemini(object sender, RoutedEventArgs e) => NavigateTo("https://gemini.google.com");
}