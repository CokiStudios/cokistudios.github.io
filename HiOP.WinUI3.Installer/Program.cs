using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using System.Windows.Forms;
using Microsoft.Win32;

namespace HiOP.WinUI3.Installer;

internal static class Program
{
    public const string DefaultInstallDir = @"C:\Program Files\Coki Studios\HiOP-Native";
    public const string AppDisplayName = "hiOP Studio Native";
    public const string AppVersion = "1.1.0";
    public const string Publisher = "Coki Studios";
    public const string UninstallRegKey = @"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\HiOP-Native";

    [STAThread]
    static int Main(string[] args)
    {
        bool silent = false;
        bool uninstall = false;
        string targetDir = DefaultInstallDir;

        foreach (var raw in args)
        {
            if (raw.Equals("--silent", StringComparison.OrdinalIgnoreCase) ||
                raw.Equals("/S", StringComparison.OrdinalIgnoreCase))
            {
                silent = true;
            }
            else if (raw.Equals("--uninstall", StringComparison.OrdinalIgnoreCase) ||
                     raw.Equals("/U", StringComparison.OrdinalIgnoreCase))
            {
                uninstall = true;
            }
            else if (raw.StartsWith("--dir=", StringComparison.OrdinalIgnoreCase))
            {
                targetDir = raw["--dir=".Length..].Trim('"');
            }
        }

        if (uninstall)
        {
            return RunUninstall(silent);
        }

        if (silent)
        {
            try
            {
                InstallCoreAsync(targetDir, createStartMenu: true, createDesktop: true, addBinToPath: false, null).GetAwaiter().GetResult();
                return 0;
            }
            catch
            {
                return 1;
            }
        }

        ApplicationConfiguration.Initialize();
        Application.Run(new InstallerForm(targetDir));
        return 0;
    }

    public static async Task InstallCoreAsync(
        string installDir,
        bool createStartMenu,
        bool createDesktop,
        bool addBinToPath,
        IProgress<(int Percent, string Status)>? progress)
    {
        installDir = Path.GetFullPath(installDir.Trim());
        progress?.Report((5, "Preparando destino de instalación..."));

        // Stop running HiOP.WinUI3 instances from the install folder before overwriting
        foreach (var proc in Process.GetProcessesByName("HiOP.WinUI3"))
        {
            try
            {
                var path = proc.MainModule?.FileName;
                if (!string.IsNullOrEmpty(path) &&
                    path.StartsWith(installDir, StringComparison.OrdinalIgnoreCase))
                {
                    proc.Kill(entireProcessTree: true);
                    proc.WaitForExit(4000);
                }
            }
            catch { }
        }

        Directory.CreateDirectory(installDir);

        progress?.Report((15, "Extrayendo archivos nativos de hiOP Studio..."));
        using var payloadStream = Assembly.GetExecutingAssembly().GetManifestResourceStream("payload.zip")
            ?? throw new InvalidOperationException("No se encontró el paquete embebido payload.zip.");

        using var archive = new ZipArchive(payloadStream, ZipArchiveMode.Read);
        int totalEntries = Math.Max(1, archive.Entries.Count);
        int idx = 0;

        await Task.Run(() =>
        {
            foreach (var entry in archive.Entries)
            {
                idx++;
                var relPath = entry.FullName.Replace('/', Path.DirectorySeparatorChar);
                var destPath = Path.GetFullPath(Path.Combine(installDir, relPath));
                if (!destPath.StartsWith(installDir, StringComparison.OrdinalIgnoreCase))
                    continue;

                if (string.IsNullOrEmpty(entry.Name))
                {
                    Directory.CreateDirectory(destPath);
                    continue;
                }

                Directory.CreateDirectory(Path.GetDirectoryName(destPath)!);
                entry.ExtractToFile(destPath, overwrite: true);

                if (idx % 6 == 0 || idx == totalEntries)
                {
                    int pct = 15 + (int)(idx * 65.0 / totalEntries);
                    progress?.Report((pct, $"Instalando {entry.Name} ({idx}/{totalEntries})..."));
                }
            }
        });

        progress?.Report((84, "Configurando desinstalador y registro de Windows..."));
        var selfExe = Environment.ProcessPath;
        var uninstallExe = Path.Combine(installDir, "Uninstall.exe");
        if (!string.IsNullOrEmpty(selfExe) && File.Exists(selfExe) &&
            !string.Equals(selfExe, uninstallExe, StringComparison.OrdinalIgnoreCase))
        {
            File.Copy(selfExe, uninstallExe, overwrite: true);
        }

        var mainExe = Path.Combine(installDir, "HiOP.WinUI3.exe");
        var iconFile = Path.Combine(installDir, "Assets", "AppIcon.ico");
        if (!File.Exists(iconFile)) iconFile = mainExe;

        if (createStartMenu)
        {
            progress?.Report((88, "Creando acceso directo en el Menú Inicio..."));
            var startDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonPrograms), "Coki Studios");
            Directory.CreateDirectory(startDir);
            CreateShortcut(Path.Combine(startDir, "hiOP Studio.lnk"), mainExe, installDir, iconFile, "hiOP Studio Native — Looping Arch 3.0A");
        }

        if (createDesktop)
        {
            progress?.Report((92, "Creando acceso directo en el Escritorio..."));
            var desktopDir = Environment.GetFolderPath(Environment.SpecialFolder.CommonDesktopDirectory);
            if (!Directory.Exists(desktopDir))
                desktopDir = Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory);
            CreateShortcut(Path.Combine(desktopDir, "hiOP Studio.lnk"), mainExe, installDir, iconFile, "hiOP Studio Native — Looping Arch 3.0A");
        }

        if (addBinToPath)
        {
            progress?.Report((95, "Añadiendo bin\\ al PATH de usuario..."));
            var binDir = Path.Combine(installDir, "bin");
            if (Directory.Exists(binDir))
            {
                var cur = Environment.GetEnvironmentVariable("Path", EnvironmentVariableTarget.User) ?? string.Empty;
                var parts = new List<string>(cur.Split(';', StringSplitOptions.RemoveEmptyEntries));
                if (!parts.Exists(p => string.Equals(p.Trim().TrimEnd('\\'), binDir, StringComparison.OrdinalIgnoreCase)))
                {
                    parts.Add(binDir);
                    Environment.SetEnvironmentVariable("Path", string.Join(';', parts), EnvironmentVariableTarget.User);
                }
            }
        }

        progress?.Report((97, "Registrando en Aplicaciones instaladas de Windows..."));
        using (var key = Registry.LocalMachine.CreateSubKey(UninstallRegKey))
        {
            key.SetValue("DisplayName", AppDisplayName);
            key.SetValue("DisplayVersion", AppVersion);
            key.SetValue("Publisher", Publisher);
            key.SetValue("InstallLocation", installDir);
            key.SetValue("DisplayIcon", iconFile);
            key.SetValue("UninstallString", $"\"{uninstallExe}\" --uninstall");
            key.SetValue("NoModify", 1, RegistryValueKind.DWord);
            key.SetValue("NoRepair", 1, RegistryValueKind.DWord);
        }

        progress?.Report((100, "¡Instalación completada con éxito!"));
    }

    private static int RunUninstall(bool silent)
    {
        if (!silent)
        {
            var ask = MessageBox.Show(
                $"¿Deseas desinstalar {AppDisplayName} de este equipo?",
                "Desinstalar hiOP Studio Native",
                MessageBoxButtons.YesNo,
                MessageBoxIcon.Question);
            if (ask != DialogResult.Yes) return 0;
        }

        string installDir = DefaultInstallDir;
        try
        {
            using var key = Registry.LocalMachine.OpenSubKey(UninstallRegKey);
            if (key?.GetValue("InstallLocation") is string loc && !string.IsNullOrWhiteSpace(loc))
                installDir = loc;
        }
        catch { }

        foreach (var proc in Process.GetProcessesByName("HiOP.WinUI3"))
        {
            try { proc.Kill(entireProcessTree: true); } catch { }
        }

        try
        {
            var startLnk = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonPrograms), "Coki Studios", "hiOP Studio.lnk");
            if (File.Exists(startLnk)) File.Delete(startLnk);

            var pubDeskLnk = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.CommonDesktopDirectory), "hiOP Studio.lnk");
            if (File.Exists(pubDeskLnk)) File.Delete(pubDeskLnk);

            var usrDeskLnk = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory), "hiOP Studio.lnk");
            if (File.Exists(usrDeskLnk)) File.Delete(usrDeskLnk);

            Registry.LocalMachine.DeleteSubKeyTree(UninstallRegKey, throwOnMissingSubKey: false);
        }
        catch { }

        if (Directory.Exists(installDir))
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = "cmd.exe",
                Arguments = $"/c ping -n 2 127.0.0.1 >nul & rd /s /q \"{installDir}\"",
                UseShellExecute = false,
                CreateNoWindow = true
            });
        }

        if (!silent)
        {
            MessageBox.Show($"{AppDisplayName} se ha desinstalado correctamente.", "Desinstalación completa", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
        return 0;
    }

    private static void CreateShortcut(string lnkPath, string targetExe, string workingDir, string iconPath, string description)
    {
        var shellType = Type.GetTypeFromProgID("WScript.Shell");
        if (shellType == null) return;
        dynamic? shell = Activator.CreateInstance(shellType);
        if (shell == null) return;
        try
        {
            dynamic sc = shell.CreateShortcut(lnkPath);
            sc.TargetPath = targetExe;
            sc.WorkingDirectory = workingDir;
            sc.IconLocation = iconPath;
            sc.Description = description;
            sc.Save();
            Marshal.FinalReleaseComObject(sc);
        }
        finally
        {
            Marshal.FinalReleaseComObject(shell);
        }
    }
}
