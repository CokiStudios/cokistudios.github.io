#Requires -Version 5.1
<#
.SYNOPSIS
    Builds HiOP-Native-Setup.exe (installs hiOP Studio WinUI 3 to C:\Program Files\Coki Studios\HiOP-Native)
#>
[CmdletBinding()]
param(
    [switch]$SelfContainedInstaller,
    [switch]$SkipAppPublish
)

$ErrorActionPreference = "Stop"
$InstallerDir = $PSScriptRoot
$WebRepoRoot = Split-Path -Parent $InstallerDir
$AppProj = Join-Path $WebRepoRoot "HiOP.WinUI3\HiOP.WinUI3.csproj"
$InstallerProj = Join-Path $InstallerDir "HiOP.WinUI3.Installer.csproj"
$AppOutDir = Join-Path $WebRepoRoot "HiOP.WinUI3\bin\x64\Release\net8.0-windows10.0.26100.0\win-x64"
$StageDir = Join-Path $InstallerDir "staging\app"
$PayloadZip = Join-Path $InstallerDir "payload.zip"
$PublishDir = Join-Path $InstallerDir "publish"
$DistOut = Join-Path $WebRepoRoot "dist\HiOP-Native-Setup.exe"

if (-not $SkipAppPublish) {
    Write-Host "[1/4] Compilando y preparando HiOP.WinUI3 (Release win-x64)..." -ForegroundColor Cyan
    & dotnet publish $AppProj -c Release -p:Platform=x64 -r win-x64 --self-contained false
    if ($LASTEXITCODE -ne 0) { throw "dotnet publish HiOP.WinUI3 falló ($LASTEXITCODE)" }
}

if (-not (Test-Path (Join-Path $AppOutDir "HiOP.WinUI3.exe"))) {
    throw "No se encontró el build win-x64 en $AppOutDir"
}

if (Test-Path $StageDir) {
    Remove-Item $StageDir -Recurse -Force
}
New-Item -ItemType Directory -Path $StageDir -Force | Out-Null

# Copy full WinUI 3 output (.xbf, .pri, Assets, native DLLs, runtime projections)
Get-ChildItem -Path $AppOutDir -Force | Where-Object { $_.Name -ne "publish" } | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination (Join-Path $StageDir $_.Name) -Recurse -Force
}

# Bundle Looping Engine & smiledev CLI into app\bin
$EngineBinCandidates = @(
    (Join-Path (Split-Path -Parent $WebRepoRoot) "engine\bin"),
    (Join-Path $WebRepoRoot "bin")
)
$EngineBinSrc = $EngineBinCandidates | Where-Object { Test-Path (Join-Path $_ "looping.exe") } | Select-Object -First 1
if ($EngineBinSrc) {
    $StageBinDir = Join-Path $StageDir "bin"
    New-Item -ItemType Directory -Path $StageBinDir -Force | Out-Null
    foreach ($f in @("looping.exe", "ruuping.cmd", "smiledev", "smiledev.cmd", "smiledev.ps1")) {
        $src = Join-Path $EngineBinSrc $f
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination (Join-Path $StageBinDir $f) -Force
        }
    }
    Write-Host "[ok] Binarios Looping & smiledev incluidos desde $EngineBinSrc" -ForegroundColor Green
}

Write-Host "[2/4] Empaquetando payload.zip..." -ForegroundColor Cyan
if (Test-Path $PayloadZip) { Remove-Item $PayloadZip -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory(
    $StageDir,
    $PayloadZip,
    [System.IO.Compression.CompressionLevel]::Optimal,
    $false
)

Write-Host "[3/4] Compilando HiOP-Native-Setup.exe..." -ForegroundColor Cyan
if (Test-Path $PublishDir) { Remove-Item $PublishDir -Recurse -Force }
$scFlag = if ($SelfContainedInstaller) { "true" } else { "false" }
$compFlag = if ($SelfContainedInstaller) { "true" } else { "false" }
& dotnet publish $InstallerProj -c Release -r win-x64 --self-contained $scFlag -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -p:EnableCompressionInSingleFile=$compFlag -o $PublishDir
if ($LASTEXITCODE -ne 0) { throw "dotnet publish HiOP.WinUI3.Installer falló ($LASTEXITCODE)" }

$BuiltExe = Join-Path $PublishDir "HiOP-Native-Setup.exe"
if (-not (Test-Path $BuiltExe)) { throw "No se generó $BuiltExe" }

Write-Host "[4/4] Copiando a dist\HiOP-Native-Setup.exe..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path (Split-Path -Parent $DistOut) -Force | Out-Null
Copy-Item -Path $BuiltExe -Destination $DistOut -Force
$AppDistOut = Join-Path $WebRepoRoot "HiOP.WinUI3\dist\HiOP-Native-Setup.exe"
New-Item -ItemType Directory -Path (Split-Path -Parent $AppDistOut) -Force | Out-Null
Copy-Item -Path $BuiltExe -Destination $AppDistOut -Force

$sizeMb = [math]::Round((Get-Item $DistOut).Length / 1MB, 2)
Write-Host "[LISTO] Instalador generado: $DistOut ($sizeMb MB)" -ForegroundColor Green
