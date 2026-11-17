using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

namespace HiOP.WinUI3.Installer;

internal sealed class InstallerForm : Form
{
    private readonly TextBox _dirBox;
    private readonly CheckBox _chkStartMenu;
    private readonly CheckBox _chkDesktop;
    private readonly CheckBox _chkPath;
    private readonly CheckBox _chkLaunchAfter;
    private readonly ProgressBar _progress;
    private readonly Label _statusLabel;
    private readonly Button _btnBrowse;
    private readonly Button _btnInstall;
    private readonly Button _btnClose;

    private bool _installed;

    public InstallerForm(string initialDir)
    {
        Text = "Instalador — hiOP Studio Native (WinUI 3)";
        ClientSize = new Size(580, 400);
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = Color.FromArgb(11, 17, 30);
        ForeColor = Color.FromArgb(241, 245, 249);
        Font = new Font("Segoe UI", 9.5f);

        try
        {
            using var iconStream = Assembly.GetExecutingAssembly().GetManifestResourceStream("AppIcon.ico");
            if (iconStream != null)
                Icon = new Icon(iconStream);
        }
        catch { }

        var title = new Label
        {
            Text = "hiOP Studio Native — Looping v1.1 (Arch 3.0A)",
            Font = new Font("Segoe UI", 14f, FontStyle.Bold),
            ForeColor = Color.FromArgb(0, 245, 212),
            Location = new Point(24, 20),
            Size = new Size(530, 30)
        };

        var subtitle = new Label
        {
            Text = "IDE Nativo WinUI 3 • Quantum 3D Z-Buffer C++17 (Zero WebView) • Smiledev",
            Font = new Font("Segoe UI", 9.5f),
            ForeColor = Color.FromArgb(148, 163, 184),
            Location = new Point(24, 52),
            Size = new Size(530, 22)
        };

        var dirLabel = new Label
        {
            Text = "Carpeta de instalación:",
            Location = new Point(24, 92),
            Size = new Size(300, 20),
            ForeColor = Color.FromArgb(203, 213, 225)
        };

        _dirBox = new TextBox
        {
            Text = initialDir,
            Location = new Point(24, 116),
            Size = new Size(432, 26),
            BackColor = Color.FromArgb(17, 25, 43),
            ForeColor = Color.White,
            BorderStyle = BorderStyle.FixedSingle
        };

        _btnBrowse = new Button
        {
            Text = "Examinar...",
            Location = new Point(464, 115),
            Size = new Size(90, 28),
            FlatStyle = FlatStyle.Flat,
            BackColor = Color.FromArgb(30, 41, 59),
            ForeColor = Color.White
        };
        _btnBrowse.FlatAppearance.BorderColor = Color.FromArgb(56, 189, 248);
        _btnBrowse.Click += (_, _) =>
        {
            using var dlg = new FolderBrowserDialog { SelectedPath = _dirBox.Text };
            if (dlg.ShowDialog(this) == DialogResult.OK)
                _dirBox.Text = dlg.SelectedPath;
        };

        _chkStartMenu = new CheckBox
        {
            Text = "Crear acceso directo en el Menú Inicio",
            Checked = true,
            Location = new Point(24, 160),
            Size = new Size(500, 24)
        };

        _chkDesktop = new CheckBox
        {
            Text = "Crear acceso directo en el Escritorio",
            Checked = true,
            Location = new Point(24, 188),
            Size = new Size(500, 24)
        };

        _chkPath = new CheckBox
        {
            Text = "Añadir carpeta bin\\ (looping.exe y smiledev) al PATH del usuario",
            Checked = false,
            Location = new Point(24, 216),
            Size = new Size(520, 24)
        };

        _chkLaunchAfter = new CheckBox
        {
            Text = "Ejecutar hiOP Studio Native al completar",
            Checked = true,
            Location = new Point(24, 244),
            Size = new Size(500, 24)
        };

        _statusLabel = new Label
        {
            Text = "Listo para instalar en C:\\Program Files\\Coki Studios\\HiOP-Native",
            Location = new Point(24, 284),
            Size = new Size(530, 20),
            ForeColor = Color.FromArgb(56, 189, 248)
        };

        _progress = new ProgressBar
        {
            Location = new Point(24, 310),
            Size = new Size(530, 18),
            Minimum = 0,
            Maximum = 100,
            Value = 0
        };

        _btnInstall = new Button
        {
            Text = "Instalar",
            Location = new Point(358, 346),
            Size = new Size(100, 34),
            FlatStyle = FlatStyle.Flat,
            BackColor = Color.FromArgb(0, 245, 212),
            ForeColor = Color.FromArgb(3, 5, 8),
            Font = new Font("Segoe UI", 9.5f, FontStyle.Bold)
        };
        _btnInstall.FlatAppearance.BorderSize = 0;
        _btnInstall.Click += BtnInstall_Click;

        _btnClose = new Button
        {
            Text = "Cancelar",
            Location = new Point(464, 346),
            Size = new Size(90, 34),
            FlatStyle = FlatStyle.Flat,
            BackColor = Color.FromArgb(30, 41, 59),
            ForeColor = Color.White
        };
        _btnClose.FlatAppearance.BorderColor = Color.FromArgb(71, 85, 105);
        _btnClose.Click += (_, _) => Close();

        Controls.AddRange([title, subtitle, dirLabel, _dirBox, _btnBrowse, _chkStartMenu, _chkDesktop, _chkPath, _chkLaunchAfter, _statusLabel, _progress, _btnInstall, _btnClose]);
    }

    private async void BtnInstall_Click(object? sender, EventArgs e)
    {
        if (_installed)
        {
            Close();
            return;
        }

        _btnInstall.Enabled = false;
        _btnBrowse.Enabled = false;
        _dirBox.Enabled = false;
        _btnClose.Enabled = false;

        var targetDir = _dirBox.Text.Trim();
        var progress = new Progress<(int Percent, string Status)>(p =>
        {
            _progress.Value = Math.Clamp(p.Percent, 0, 100);
            _statusLabel.Text = p.Status;
        });

        try
        {
            await Program.InstallCoreAsync(
                targetDir,
                _chkStartMenu.Checked,
                _chkDesktop.Checked,
                _chkPath.Checked,
                progress);

            _installed = true;
            _btnInstall.Text = "Finalizar";
            _btnInstall.Enabled = true;
            _btnClose.Visible = false;

            if (_chkLaunchAfter.Checked)
            {
                var exe = Path.Combine(targetDir, "HiOP.WinUI3.exe");
                if (File.Exists(exe))
                {
                    Process.Start(new ProcessStartInfo(exe)
                    {
                        WorkingDirectory = targetDir,
                        UseShellExecute = true
                    });
                }
            }
        }
        catch (Exception ex)
        {
            _statusLabel.ForeColor = Color.FromArgb(244, 63, 94);
            _statusLabel.Text = $"Error: {ex.Message}";
            MessageBox.Show(this, ex.ToString(), "Error de instalación", MessageBoxButtons.OK, MessageBoxIcon.Error);
            _btnInstall.Enabled = true;
            _btnBrowse.Enabled = true;
            _dirBox.Enabled = true;
            _btnClose.Enabled = true;
        }
    }
}
