using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using HiOP.WinUI3.Models;
using HiOP.WinUI3.Services;
using Microsoft.UI;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Controls;
using Microsoft.UI.Xaml.Media;
using Windows.ApplicationModel.DataTransfer;
using Windows.UI;

namespace HiOP.WinUI3.Views;

public sealed partial class SmiledevPage : Page
{
    private readonly AppStateService _state = AppStateService.Current;
    private List<SmileModuleItem> _allRegistryModules = [];
    private List<InstalledModuleItem> _installedModules = [];
    private readonly StringBuilder _logs = new();

    public SmiledevPage()
    {
        InitializeComponent();
        Loaded += SmiledevPage_Loaded;
    }

    private async void SmiledevPage_Loaded(object sender, RoutedEventArgs e)
    {
        var ch = SmiledevService.GetChannelDisplay(_state.Smiledev.GetActiveChannel());
        SmileChannelBadge.Text = $"CANAL: {ch.Title.ToUpperInvariant()} (v{ch.VersionLabel})";

        UpdateCreatorManifestPreview();
        await RefreshAllDataAsync();
    }

    private void Log(string msg)
    {
        _logs.AppendLine(msg);
        SmileLogBox.Text = _logs.ToString();
        SmileLogScroll.ChangeView(null, SmileLogScroll.ScrollableHeight, null);
    }

    private async Task RefreshAllDataAsync()
    {
        RegistryStatusText.Text = "Consultando LoopModules (Supabase PostgreSQL) y repositorios locales...";
        var (mods, note) = await _state.Smiledev.LoadRegistryCatalogAsync();
        _allRegistryModules = mods;
        KpiRegistryCount.Text = _allRegistryModules.Count.ToString();
        RegistryStatusText.Text = $"Catálogo sincronizado: {note} + Catálogo Oficial Coki Studios";

        RefreshInstalledList();
        RefreshReposList();
        ApplyRegistryFilters();
    }

    private void RefreshInstalledList()
    {
        _installedModules = _state.Smiledev.ListInstalledModules();
        InstalledModulesList.ItemsSource = _installedModules;
        KpiInstalledCount.Text = _installedModules.Count.ToString();
    }

    private void RefreshReposList()
    {
        var list = new List<RepoSourceItem>
        {
            new()
            {
                Index = 1,
                Url = SmiledevService.SupabaseUrl,
                RepoType = "LoopModules (PostgreSQL Cloud)",
                IsDefault = true,
                StatusSummary = "● Predeterminado"
            }
        };

        int idx = 2;
        foreach (var r in _state.Smiledev.GetConfiguredRepos())
        {
            if (r.Contains("supabase.co", StringComparison.OrdinalIgnoreCase)) continue;
            string kind = Directory.Exists(r.Replace("file://", "")) ? "Directorio Local"
                : r.Contains("github.com", StringComparison.OrdinalIgnoreCase) ? "Repositorio Git"
                : "HTTP Registry";
            list.Add(new RepoSourceItem
            {
                Index = idx++,
                Url = r,
                RepoType = kind,
                IsDefault = false,
                StatusSummary = "● Activo"
            });
        }

        var localModulesDir = Path.Combine(_state.Workspace.WorkspaceRoot, "modules");
        if (Directory.Exists(localModulesDir))
        {
            list.Add(new RepoSourceItem
            {
                Index = idx++,
                Url = localModulesDir,
                RepoType = "Workspace Local Modules",
                IsDefault = true,
                StatusSummary = "● Auto-detectado"
            });
        }

        ReposListView.ItemsSource = list;
        KpiReposCount.Text = list.Count.ToString();
    }

    private void ApplyRegistryFilters()
    {
        var query = (SearchRegistryBox.Text ?? string.Empty).Trim().ToLowerInvariant();
        var langTag = (LanguageFilterCombo.SelectedItem as ComboBoxItem)?.Tag?.ToString() ?? "all";

        var filtered = _allRegistryModules.Where(m =>
        {
            if (langTag != "all" && !string.Equals(m.Language, langTag, StringComparison.OrdinalIgnoreCase))
                return false;
            if (!string.IsNullOrEmpty(query))
            {
                return m.Name.Contains(query, StringComparison.OrdinalIgnoreCase) ||
                       m.Description.Contains(query, StringComparison.OrdinalIgnoreCase) ||
                       m.AuthorName.Contains(query, StringComparison.OrdinalIgnoreCase);
            }
            return true;
        }).ToList();

        ModulesGridView.ItemsSource = filtered;
    }

    private async Task InstallPackageAsync(string moduleName, PackageSourceCandidate? chosenCandidate = null)
    {
        if (string.IsNullOrWhiteSpace(moduleName)) return;

        DownloadBanner.Visibility = Visibility.Visible;
        DownloadProgressBar.Value = 5;
        DownloadPercentText.Text = "5%";
        DownloadStatusText.Text = $"Preparando descarga de '{moduleName}'...";

        var progress = new Progress<(string Status, double Percent)>(p =>
        {
            DispatcherQueue.TryEnqueue(() =>
            {
                DownloadStatusText.Text = p.Status;
                DownloadProgressBar.Value = p.Percent;
                DownloadPercentText.Text = $"{p.Percent:N0}%";
            });
        });

        var (ok, message, logs) = await _state.Smiledev.DownloadAndInstallModuleAsync(moduleName.Trim(), false, chosenCandidate, progress);
        foreach (var l in logs) Log(l);
        Log(ok ? $"✔ {message}" : $"✘ {message}");

        await RefreshAllDataAsync();
        await Task.Delay(1200);
        DownloadBanner.Visibility = Visibility.Collapsed;
    }

    // ── Navigation Between Tabs ────────────────────────────────────────────────
    private void SwitchSection_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not Button btn || btn.Tag is not string tag) return;
        ExplorePanel.Visibility = tag == "explore" ? Visibility.Visible : Visibility.Collapsed;
        InstalledPanel.Visibility = tag == "installed" ? Visibility.Visible : Visibility.Collapsed;
        CreatorPanel.Visibility = tag == "creator" ? Visibility.Visible : Visibility.Collapsed;
        ReposPanel.Visibility = tag == "repos" ? Visibility.Visible : Visibility.Collapsed;

        var activeBorder = new SolidColorBrush(Color.FromArgb(255, 0, 245, 212));
        var clear = new SolidColorBrush(Colors.Transparent);
        TabBtnExplore.BorderBrush = tag == "explore" ? activeBorder : clear;
        TabBtnInstalled.BorderBrush = tag == "installed" ? activeBorder : clear;
        TabBtnCreator.BorderBrush = tag == "creator" ? activeBorder : clear;
        TabBtnRepos.BorderBrush = tag == "repos" ? activeBorder : clear;
    }

    // ── Explore Actions ────────────────────────────────────────────────────────
    private void SearchRegistryBox_TextChanged(object sender, TextChangedEventArgs e) => ApplyRegistryFilters();
    private void LanguageFilterCombo_SelectionChanged(object sender, SelectionChangedEventArgs e) => ApplyRegistryFilters();
    private async void BtnRefreshRegistry_Click(object sender, RoutedEventArgs e) => await RefreshAllDataAsync();

    private async void BtnDirectInstall_Click(object sender, RoutedEventArgs e)
    {
        if (!string.IsNullOrWhiteSpace(DirectInstallBox.Text))
            await InstallPackageAsync(DirectInstallBox.Text);
    }

    private async void BtnDownloadCard_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: string modName })
            await InstallPackageAsync(modName);
    }

    private void BtnCopyCliCard_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: string modName })
        {
            var dp = new DataPackage();
            dp.SetText($"smiledev install {modName}");
            Clipboard.SetContent(dp);
            Log($"📋 Copiado al portapapeles: smiledev install {modName}");
        }
    }

    private async void BtnInspectCard_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not Button { Tag: string modName }) return;
        var mod = _allRegistryModules.FirstOrDefault(m => string.Equals(m.Name, modName, StringComparison.OrdinalIgnoreCase));
        if (mod == null) return;

        var candidates = await _state.Smiledev.ResolveCandidatesAsync(mod.Name);
        var sourceCombo = new ComboBox
        {
            HorizontalAlignment = HorizontalAlignment.Stretch,
            Header = $"Orígenes encontrados ({candidates.Count}):"
        };
        foreach (var c in candidates)
            sourceCombo.Items.Add($"{c.SourceName} — v{c.Version}");
        if (sourceCombo.Items.Count > 0) sourceCombo.SelectedIndex = 0;

        var codePreview = new TextBox
        {
            Text = string.IsNullOrWhiteSpace(mod.CodePayload)
                ? $"// Paquete multi-archivo: {mod.EntryPoint}\n// Usa 'Descargar e Instalar' para obtener todos sus componentes en ./modules/{mod.Name}."
                : mod.CodePayload,
            IsReadOnly = true,
            AcceptsReturn = true,
            MaxHeight = 220,
            FontFamily = new FontFamily("Cascadia Code, Consolas"),
            FontSize = 11.5
        };

        var panel = new StackPanel { Spacing = 10, MinWidth = 460 };
        panel.Children.Add(new TextBlock { Text = $"{mod.Name} v{mod.Version} ({mod.LanguageLabel})", FontWeight = Microsoft.UI.Text.FontWeights.Bold, FontSize = 16 });
        panel.Children.Add(new TextBlock { Text = mod.Description, TextWrapping = TextWrapping.Wrap, Foreground = new SolidColorBrush(Color.FromArgb(255, 203, 213, 225)) });
        panel.Children.Add(new TextBlock { Text = $"Entrada: {mod.EntryPoint} • Licencia: {mod.License}", FontFamily = new FontFamily("Consolas"), FontSize = 11.5 });
        if (candidates.Count > 0) panel.Children.Add(sourceCombo);
        panel.Children.Add(codePreview);

        var dlg = new ContentDialog
        {
            Title = $"Inspección de Paquete — {mod.Name}",
            Content = panel,
            PrimaryButtonText = "⬇ Descargar de este origen",
            CloseButtonText = "Cerrar",
            XamlRoot = this.XamlRoot
        };

        if (await dlg.ShowAsync() == ContentDialogResult.Primary)
        {
            var selected = sourceCombo.SelectedIndex >= 0 && sourceCombo.SelectedIndex < candidates.Count
                ? candidates[sourceCombo.SelectedIndex]
                : null;
            await InstallPackageAsync(mod.Name, selected);
        }
    }

    // ── Installed Actions ──────────────────────────────────────────────────────
    private void BtnRefreshInstalled_Click(object sender, RoutedEventArgs e) => RefreshInstalledList();

    private async void BtnUpdateAllLocal_Click(object sender, RoutedEventArgs e)
    {
        var locals = _installedModules.Where(m => !m.IsGlobal).Select(m => m.Name).Distinct().ToList();
        if (locals.Count == 0)
        {
            Log("ℹ No hay módulos locales en ./modules para actualizar.");
            return;
        }
        foreach (var name in locals)
            await InstallPackageAsync(name);
    }

    private async void BtnUpdateSingleInstalled_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: string modName })
            await InstallPackageAsync(modName);
    }

    private void BtnOpenInstalledInIde_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not Button { Tag: string modDir }) return;
        var item = _installedModules.FirstOrDefault(m => string.Equals(m.InstallPath, modDir, StringComparison.OrdinalIgnoreCase));
        if (item == null) return;
        var entry = Path.Combine(modDir, item.EntryPoint);
        if (!File.Exists(entry))
            entry = Path.Combine(modDir, "smile.json");
        if (File.Exists(entry))
        {
            _state.OpenFileInTab(entry);
            _state.RequestNavigate("ide");
        }
    }

    private async void BtnPackInstalled_Click(object sender, RoutedEventArgs e)
    {
        if (sender is not Button { Tag: string modDir }) return;
        try
        {
            var (tarPath, sha) = await _state.Smiledev.PackModuleTarGzAsync(modDir);
            Log($"📦 Empaquetado .tar.gz: {tarPath}");
            Log($"   SHA-256: {sha}");
        }
        catch (Exception ex)
        {
            Log($"✘ Error empaquetando: {ex.Message}");
        }
    }

    private void BtnUninstallModule_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: string modName })
        {
            Log(_state.Smiledev.UninstallModule(modName, removeGlobalToo: true));
            RefreshInstalledList();
            ApplyRegistryFilters();
        }
    }

    // ── Creator / Publisher ────────────────────────────────────────────────────
    private void CreatorField_Changed(object sender, TextChangedEventArgs e) => UpdateCreatorManifestPreview();

    private void PubLangCombo_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (PubLangCombo == null || PubEntryBox == null) return;
        var lang = (PubLangCombo.SelectedItem as ComboBoxItem)?.Content?.ToString() ?? "loop";
        PubEntryBox.Text = lang switch
        {
            "cpp" => "main.hpp",
            "python" => "main.py",
            "node" => "index.js",
            "c2" => "main.c2",
            _ => "main.loop"
        };
        PubCodeBox.Text = SmiledevService.GetDefaultTemplateForLang(PubNameBox.Text, lang);
        UpdateCreatorManifestPreview();
    }

    private void UpdateCreatorManifestPreview()
    {
        if (PubNameBox == null || LiveManifestPreviewBox == null) return;
        var lang = (PubLangCombo.SelectedItem as ComboBoxItem)?.Content?.ToString() ?? "loop";
        var mfObj = new
        {
            name = (PubNameBox.Text ?? "").Trim(),
            version = (PubVersionBox.Text ?? "").Trim(),
            language = lang,
            entry_point = (PubEntryBox.Text ?? "").Trim(),
            author_name = (PubAuthorBox.Text ?? "").Trim(),
            description = (PubDescBox.Text ?? "").Trim(),
            license = (PubLicenseBox.Text ?? "MIT").Trim(),
            dependencies = new { }
        };
        var json = JsonSerializer.Serialize(mfObj, new JsonSerializerOptions { WriteIndented = true });
        LiveManifestPreviewBox.Text = json;

        var res = SmiledevService.ValidateManifestJson(json);
        if (res.IsValid)
        {
            CreatorValidBadgeText.Text = res.Warnings.Count == 0 ? "100% VÁLIDO ✔" : "VÁLIDO (CON NOTAS)";
            CreatorValidBadgeText.Foreground = new SolidColorBrush(Color.FromArgb(255, 16, 185, 129));
            ValidationResultText.Text = res.Warnings.Count == 0
                ? "✔ Todos los campos de smile.json cumplen con Looping & smiledev."
                : "✔ Válido con sugerencias:\n• " + string.Join("\n• ", res.Warnings);
        }
        else
        {
            CreatorValidBadgeText.Text = "REVISAR CAMPOS ✘";
            CreatorValidBadgeText.Foreground = new SolidColorBrush(Color.FromArgb(255, 244, 63, 94));
            ValidationResultText.Text = "✘ Errores:\n• " + string.Join("\n• ", res.Errors);
        }
    }

    private void BtnCreateLocalModule_Click(object sender, RoutedEventArgs e)
    {
        var lang = (PubLangCombo.SelectedItem as ComboBoxItem)?.Content?.ToString() ?? "loop";
        var dir = _state.Smiledev.InitNewModule(
            PubNameBox.Text.Trim(),
            lang,
            PubAuthorBox.Text.Trim(),
            PubDescBox.Text.Trim(),
            PubCodeBox.Text);
        Log($"📁 Módulo creado en disco: {dir}");
        RefreshInstalledList();
    }

    private async void BtnPublishModule_Click(object sender, RoutedEventArgs e)
    {
        var lang = (PubLangCombo.SelectedItem as ComboBoxItem)?.Content?.ToString() ?? "loop";
        var item = new SmileModuleItem
        {
            Name = PubNameBox.Text.Trim(),
            Version = PubVersionBox.Text.Trim(),
            Language = lang,
            EntryPoint = PubEntryBox.Text.Trim(),
            AuthorName = PubAuthorBox.Text.Trim(),
            License = PubLicenseBox.Text.Trim(),
            Description = PubDescBox.Text.Trim(),
            CodePayload = PubCodeBox.Text
        };

        var (_, msg) = await _state.Smiledev.PublishModuleToSupabaseAsync(item);
        Log(msg);
        await RefreshAllDataAsync();
    }

    // ── Repos & CLI ────────────────────────────────────────────────────────────
    private async void BtnAddRepo_Click(object sender, RoutedEventArgs e)
    {
        if (string.IsNullOrWhiteSpace(AddRepoBox.Text)) return;
        var (_, summary) = await _state.Smiledev.AddRepoAsync(AddRepoBox.Text);
        Log(summary);
        AddRepoBox.Text = string.Empty;
        RefreshReposList();
    }

    private void BtnRemoveRepo_Click(object sender, RoutedEventArgs e)
    {
        if (sender is Button { Tag: string url })
        {
            _state.Smiledev.RemoveRepo(url);
            Log($"🗑 Repositorio eliminado: {url}");
            RefreshReposList();
        }
    }

    private async void BtnRunCli_Click(object sender, RoutedEventArgs e)
    {
        var raw = (CliInputBox.Text ?? string.Empty).Trim();
        if (string.IsNullOrEmpty(raw)) return;
        var parts = raw.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        Log($"$ smiledev {raw}");

        if (parts.Length >= 2 && parts[0].Equals("install", StringComparison.OrdinalIgnoreCase))
        {
            await InstallPackageAsync(parts[1]);
            return;
        }
        if (parts[0].Equals("list", StringComparison.OrdinalIgnoreCase))
        {
            foreach (var m in _state.Smiledev.ListInstalledModules())
                Log($"  • {m.Name} v{m.Version} [{m.Language}] ({m.ScopeLabel})");
            return;
        }

        await _state.Engine.RunSmiledevCliAsync(
            parts,
            _state.Workspace.WorkspaceRoot,
            l => DispatcherQueue.TryEnqueue(() => Log(l)));
    }

    private void BtnClearSmileLogs_Click(object sender, RoutedEventArgs e)
    {
        _logs.Clear();
        SmileLogBox.Text = string.Empty;
    }
}
