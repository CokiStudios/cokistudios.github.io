#Requires -Version 5.1
<#
.SYNOPSIS
    Looping Engine & smiledev CLI - Official Windows Installer (v1.1.2 / Arch 3.1A)
.DESCRIPTION
    Works identically in Windows PowerShell 5.1 and PowerShell 7+ both locally and via:
      irm https://engine.cokistudios.com/install.ps1 | iex
      irm https://repo.cokistudios.com/engine/install.ps1 | iex
#>
[CmdletBinding()]
param(
    [string]$Prefix = "",
    [switch]$FromSource,
    [switch]$NoPath,
    [switch]$Verify
)

function Install-LoopingEngine {
    [CmdletBinding()]
    param(
        [string]$Prefix = "",
        [switch]$FromSource,
        [switch]$NoPath,
        [switch]$Verify
    )

    $prevErrorAction = $ErrorActionPreference
    $prevProgress = $ProgressPreference
    $ErrorActionPreference = "Stop"

    try {
        # Enable TLS 1.2 (and TLS 1.3 when available) for Windows PowerShell 5.1
        try {
            $tlsFlags = [Net.SecurityProtocolType]::Tls12
            try { $tlsFlags = $tlsFlags -bor 12288 } catch {}
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsFlags
        } catch {}

        $ProgressPreference = "SilentlyContinue"

        if ([string]::IsNullOrWhiteSpace($Prefix)) {
            if (-not [string]::IsNullOrWhiteSpace($env:LOOPING_PREFIX)) {
                $Prefix = $env:LOOPING_PREFIX
            } else {
                $Prefix = Join-Path $env:USERPROFILE ".smiledev"
            }
        }
        if (-not $NoPath -and ($env:LOOPING_NO_PATH -eq "1")) { $NoPath = $true }
        if (-not $Verify -and ($env:LOOPING_VERIFY -eq "1")) { $Verify = $true }
        if (-not $FromSource -and ($env:LOOPING_FROM_SOURCE -eq "1")) { $FromSource = $true }

        $IsLocalScript = -not [string]::IsNullOrWhiteSpace($PSScriptRoot)
        $RepoRoot = if ($IsLocalScript) { $PSScriptRoot } else { "" }
        $BinSrc = if ($IsLocalScript) { Join-Path $RepoRoot "bin" } else { "" }
        $BinDest = Join-Path $Prefix "bin"

        Write-Host ""
        Write-Host "  ================================================================" -ForegroundColor Cyan
        Write-Host "   Looping Engine v1.1.2 (Arch 3.1A) & smiledev - Windows Setup" -ForegroundColor Cyan
        Write-Host "   PowerShell $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))" -ForegroundColor DarkCyan
        Write-Host "  ================================================================" -ForegroundColor Cyan
        Write-Host ""

        $Dirs = @(
            $Prefix,
            $BinDest,
            (Join-Path $Prefix "config"),
            (Join-Path $Prefix "cache"),
            (Join-Path $Prefix "modules"),
            (Join-Path $Prefix "projects"),
            (Join-Path $Prefix "templates")
        )
        foreach ($d in $Dirs) {
            if (-not (Test-Path -LiteralPath $d)) {
                New-Item -ItemType Directory -Path $d -Force | Out-Null
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($env:LOOPING_CHANNEL)) {
            $chFile = Join-Path $Prefix "channel"
            [System.IO.File]::WriteAllText($chFile, $env:LOOPING_CHANNEL.Trim(), (New-Object System.Text.UTF8Encoding($false)))
        }

        $ExeSrc = if ($IsLocalScript) { Join-Path $BinSrc "looping.exe" } else { "" }
        $BuildScript = if ($IsLocalScript) { Join-Path $RepoRoot "scripts\build-windows.ps1" } else { "" }
        $DownloadedTempDir = $null

        if ($FromSource -and $IsLocalScript -and (Test-Path -LiteralPath $BuildScript)) {
            Write-Host "[build] Compiling Looping C++17 Engine from local source..." -ForegroundColor Yellow
            & $BuildScript
        } elseif ((-not $IsLocalScript) -or (-not (Test-Path -LiteralPath $ExeSrc))) {
            if ($IsLocalScript -and (Test-Path -LiteralPath $BuildScript) -and (-not (Test-Path -LiteralPath $ExeSrc))) {
                Write-Host "[build] Compiling Looping C++17 Engine from local source..." -ForegroundColor Yellow
                & $BuildScript
            } else {
                $ExpectedSha = "bcad860e466586264c541b4e82cf1b6441d9de04156f5e764b7e877036b8186d"
                $ZipUrls = @(
                    "https://engine.cokistudios.com/looping-v1.1.2-windows-x64.zip",
                    "https://repo.cokistudios.com/engine/looping-v1.1.2-windows-x64.zip",
                    "https://cokistudios.github.io/engine/looping-v1.1.2-windows-x64.zip",
                    "https://github.com/CokiStudios/engine/raw/main/dist/looping-v1.1.2-windows-x64.zip"
                )
                $DownloadedTempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("looping-win-" + [Guid]::NewGuid().ToString("N"))
                New-Item -ItemType Directory -Path $DownloadedTempDir -Force | Out-Null
                $ZipFile = Join-Path $DownloadedTempDir "looping-v1.1.2-windows-x64.zip"

                $downloadedOk = $false
                $lastErr = $null
                foreach ($u in $ZipUrls) {
                    try {
                        Write-Host "[download] Fetching $u ..." -ForegroundColor Yellow
                        Invoke-WebRequest -Uri $u -OutFile $ZipFile -UseBasicParsing
                        if ((Test-Path -LiteralPath $ZipFile) -and ((Get-Item -LiteralPath $ZipFile).Length -gt 10000)) {
                            $downloadedOk = $true
                            break
                        }
                    } catch {
                        $lastErr = $_
                    }
                }
                if (-not $downloadedOk) {
                    throw "Failed to download Looping Windows x64 archive. Last error: $lastErr"
                }

                try {
                    $actualSha = (Get-FileHash -LiteralPath $ZipFile -Algorithm SHA256).Hash.ToLowerInvariant()
                    if ($actualSha -eq $ExpectedSha) {
                        Write-Host "[ok] SHA-256 verified ($actualSha)" -ForegroundColor Green
                    } else {
                        Write-Host "[info] Archive SHA-256: $actualSha" -ForegroundColor DarkGray
                    }
                } catch {}

                $ExtractDir = Join-Path $DownloadedTempDir "unpacked"
                New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null
                Expand-Archive -LiteralPath $ZipFile -DestinationPath $ExtractDir -Force

                $foundExe = Get-ChildItem -Path $ExtractDir -Filter "looping.exe" -Recurse | Select-Object -First 1
                if ($foundExe) {
                    $BinSrc = $foundExe.DirectoryName
                } else {
                    $BinSrc = $ExtractDir
                }
            }
        }

        $FilesToCopy = @(
            "looping.exe",
            "ruuping.cmd",
            "smiledev",
            "smiledev.cmd",
            "smiledev.ps1"
        )
        foreach ($f in $FilesToCopy) {
            $srcPath = Join-Path $BinSrc $f
            if (Test-Path -LiteralPath $srcPath) {
                Copy-Item -LiteralPath $srcPath -Destination (Join-Path $BinDest $f) -Force
                Write-Host "[ok] Installed $f -> $BinDest" -ForegroundColor Green
            } else {
                Write-Host "[skip] Optional file not present: $f" -ForegroundColor DarkGray
            }
        }

        if ($DownloadedTempDir -and (Test-Path -LiteralPath $DownloadedTempDir)) {
            Remove-Item -LiteralPath $DownloadedTempDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        if ($IsLocalScript) {
            $ModulesSrc = Join-Path $RepoRoot "modules"
            if (Test-Path -LiteralPath $ModulesSrc) {
                $ModDest = Join-Path $Prefix "modules"
                Copy-Item -Path (Join-Path $ModulesSrc "*") -Destination $ModDest -Recurse -Force
                Write-Host "[ok] Bundled modules synced to $ModDest" -ForegroundColor Green
            }
        }

        if (-not $NoPath) {
            $CurrentUserPath = [Environment]::GetEnvironmentVariable("Path", "User")
            $Parts = @()
            if (-not [string]::IsNullOrEmpty($CurrentUserPath)) {
                $Parts = ($CurrentUserPath -split ";") | Where-Object { $_ -and ($_.Trim() -ne "") }
            }
            $CleanDest = $BinDest.TrimEnd("\")
            $AlreadyInPath = $false
            foreach ($p in $Parts) {
                if ($p.TrimEnd("\") -ieq $CleanDest) {
                    $AlreadyInPath = $true
                    break
                }
            }
            if (-not $AlreadyInPath) {
                $NewPath = if ([string]::IsNullOrEmpty($CurrentUserPath)) { $BinDest } else { "$CurrentUserPath;$BinDest" }
                [Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
                Write-Host "[ok] Added $BinDest to User PATH" -ForegroundColor Green
            } else {
                Write-Host "[ok] $BinDest is already in User PATH" -ForegroundColor Green
            }

            $SessionParts = ($env:PATH -split ";") | Where-Object { $_ -and ($_.Trim() -ne "") }
            $InSession = $false
            foreach ($sp in $SessionParts) {
                if ($sp.TrimEnd("\") -ieq $CleanDest) {
                    $InSession = $true
                    break
                }
            }
            if (-not $InSession) {
                $env:PATH = "$BinDest;$env:PATH"
            }
        }

        if ($Verify) {
            $InstalledLooping = Join-Path $BinDest "looping.exe"
            if (Test-Path -LiteralPath $InstalledLooping) {
                Write-Host "[verify] Running looping.exe --version & test..." -ForegroundColor Cyan
                & $InstalledLooping --version
                & $InstalledLooping test
            }
            $InstalledSmile = Join-Path $BinDest "smiledev.ps1"
            if (Test-Path -LiteralPath $InstalledSmile) {
                & $InstalledSmile version
            }
        }

        Write-Host ""
        Write-Host "Installation complete! Open a new PowerShell/Terminal (or run right here) and try:" -ForegroundColor Cyan
        Write-Host "  looping --version"
        Write-Host "  looping doctor"
        Write-Host "  smiledev help"
        Write-Host ""
    }
    finally {
        $ProgressPreference = $prevProgress
        $ErrorActionPreference = $prevErrorAction
    }
}

Install-LoopingEngine -Prefix $Prefix -FromSource:$FromSource -NoPath:$NoPath -Verify:$Verify
