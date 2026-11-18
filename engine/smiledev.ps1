#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SmileBash = Join-Path $ScriptDir "smiledev"

# Force pure PowerShell fallback with LOOPING_SMILEDEV_PWSH=1, otherwise prefer Git Bash for full 1:1 CLI parity
if ($env:LOOPING_SMILEDEV_PWSH -ne "1" -and (Test-Path $SmileBash)) {
    $GitBashCandidates = @(
        "C:\Program Files\Git\bin\bash.exe",
        "C:\Program Files\Git\usr\bin\bash.exe",
        "C:\Program Files (x86)\Git\bin\bash.exe",
        "C:\msys64\usr\bin\bash.exe"
    )
    foreach ($bashExe in $GitBashCandidates) {
        if (Test-Path $bashExe) {
            & $bashExe $SmileBash @args
            exit $LASTEXITCODE
        }
    }
}

$SmileVersion = "1.1.3"
$SmileAlphaVersion = "1.1.3A"
$SmileArchVersion = "3.1A"
$ConfigDir = Join-Path $env:USERPROFILE ".smiledev"
$ModulesDir = Join-Path $ConfigDir "modules"
$ChannelFile = Join-Path $ConfigDir "channel"
$Channel = if ($env:LOOPING_CHANNEL) { $env:LOOPING_CHANNEL } elseif (Test-Path $ChannelFile) { (Get-Content $ChannelFile -Raw).Trim() } else { "prod" }

$Positional = New-Object System.Collections.Generic.List[string]
foreach ($a in $args) {
    if ($a -like "--channel=*") { $Channel = $a.Substring(10) }
    elseif ($a -in @("--alpha", "--alpha!", "--1.1a", "--1.1A", "--1.1.2a", "--1.1.2A", "--1.1.3a", "--1.1.3A")) { $Channel = "alpha" }
    elseif ($a -in @("--omega", "--rc")) { $Channel = "omega" }
    elseif ($a -in @("--prod", "--stable")) { $Channel = "prod" }
    else { [void]$Positional.Add($a) }
}

$ChTitle = "Looping"
$ChTier = "Production Release"
$ChVer = $SmileVersion
switch -Regex ($Channel.ToLower()) {
    "^(alpha|alpha!|1\.1a|1\.1\.2a|1\.1\.3a|experimental)" {
        $ChTitle = "Alpha! SmileDev"
        $ChTier = "Super Experimental"
        $ChVer = $SmileAlphaVersion
    }
    "^(omega|rc)" {
        $ChTitle = "Omega Looping"
        $ChTier = "Release Candidate (RC)"
        $ChVer = "$SmileVersion-omega"
    }
}

function Find-LoopingExe {
    $cands = @(
        (Join-Path $ScriptDir "looping.exe"),
        (Join-Path $ConfigDir "bin\looping.exe")
    )
    foreach ($c in $cands) { if (Test-Path $c) { return $c } }
    $cmd = Get-Command looping.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

$cmd = if ($Positional.Count -gt 0) { $Positional[0] } else { "help" }
$restArgs = if ($Positional.Count -gt 1) { @($Positional[1..($Positional.Count - 1)]) } else { @() }

switch ($cmd) {
    { $_ -in @("version", "-v", "--version") } {
        Write-Output "smiledev v$ChVer ($ChTitle -- $ChTier / Arch $SmileArchVersion / Looping Universal Package Manager)"
        exit 0
    }
    "list" {
        if (-not (Test-Path $ModulesDir)) {
            Write-Output "No modules directory found ($ModulesDir)."
            exit 0
        }
        $mods = Get-ChildItem $ModulesDir -Directory -ErrorAction SilentlyContinue
        if (-not $mods) {
            Write-Output "No modules installed in $ModulesDir."
        } else {
            Write-Output "Installed LoopModules ($ModulesDir):"
            foreach ($m in $mods) { Write-Output "  - $($m.Name)" }
        }
        exit 0
    }
    "doctor" {
        Write-Output "=== smiledev Windows Diagnostic ($ChTitle v$ChVer / Arch $SmileArchVersion) ==="
        $lp = Find-LoopingExe
        Write-Output ("Looping Native Binary : " + $(if ($lp) { $lp } else { "MISSING" }))
        Write-Output ("PowerShell            : $($PSVersionTable.PSVersion)")
        foreach ($tool in @("cl.exe", "g++", "clang++", "node", "python", "dotnet", "csc", "git", "wsl")) {
            $found = Get-Command $tool -ErrorAction SilentlyContinue
            Write-Output ("{0,-22}: {1}" -f $tool, $(if ($found) { $found.Source } else { "not found" }))
        }
        exit 0
    }
    "run" {
        $lp = Find-LoopingExe
        if (-not $lp) { Write-Error "looping.exe not found. Run install.ps1 first."; exit 1 }
        & $lp @restArgs
        exit $LASTEXITCODE
    }
    "test" {
        $lp = Find-LoopingExe
        if (-not $lp) { Write-Error "looping.exe not found."; exit 1 }
        & $lp test
        exit $LASTEXITCODE
    }
    "init" {
        $projName = if ($restArgs.Count -gt 0) { $restArgs[0] } else { "looping-app" }
        New-Item -ItemType Directory -Force -Path $projName | Out-Null
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        $mainLoop = Join-Path $projName "main.loop"
        if (-not (Test-Path $mainLoop)) {
            $loopContent = @(
                "# Looping v1.1.3 Project: $projName",
                "define app `"$projName`" version 1.1.3:",
                "    say(`"Hello from $projName on Looping Arch 3.1A!`")"
            ) -join "`n"
            [System.IO.File]::WriteAllText((Join-Path (Resolve-Path $projName).Path "main.loop"), $loopContent, $utf8NoBom)
        }
        $jsonContent = @(
            "{",
            "  `"name`": `"$projName`",",
            "  `"version`": `"1.0.0`",",
            "  `"entry`": `"main.loop`",",
            "  `"engine`": `"1.1.3`",",
            "  `"arch`": `"3.1A`"",
            "}"
        ) -join "`n"
        $jsonContent = $jsonContent -replace '"3.1A",', '"3.1A"'
        [System.IO.File]::WriteAllText((Join-Path (Resolve-Path $projName).Path "smile.json"), $jsonContent, $utf8NoBom)
        Write-Output "[ok] Initialized Looping project in ./$projName"
        exit 0
    }
    { $_ -in @("upgrade", "update") } {
        try {
            $tlsFlags = [Net.SecurityProtocolType]::Tls12
            try { $tlsFlags = $tlsFlags -bor 12288 } catch {}
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor $tlsFlags
        } catch {}
        $env:LOOPING_CHANNEL = $Channel
        $installerScript = $null
        foreach ($u in @("https://engine.cokistudios.com/install.ps1", "https://repo.cokistudios.com/engine/install.ps1", "https://cokistudios.github.io/engine/install.ps1")) {
            try {
                $installerScript = Invoke-RestMethod -Uri $u -UseBasicParsing
                if ($installerScript) { break }
            } catch {}
        }
        if (-not $installerScript) {
            Write-Error "Unable to fetch Windows installer from engine.cokistudios.com."
            exit 1
        }
        Invoke-Expression $installerScript
        exit 0
    }
    "clean" {
        foreach ($d in @("build", ".smiledev")) {
            if (Test-Path $d) { Remove-Item -Recurse -Force $d }
        }
        Write-Output "[ok] Cleaned local build artifacts."
        exit 0
    }
    default {
        Write-Output "smiledev v$ChVer ($ChTitle -- $ChTier / Arch $SmileArchVersion)"
        Write-Output "Usage: smiledev <version|list|doctor|run|test|init|clean|install|uninstall|update|search|view|pack|link|validate|upgrade|help>"
        exit 0
    }
}
