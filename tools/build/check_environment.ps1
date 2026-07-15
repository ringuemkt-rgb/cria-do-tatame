[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path

function Resolve-GodotBinary {
    param([string]$Requested)

    $candidates = @()
    if ($Requested) { $candidates += $Requested }
    foreach ($name in @("godot4", "godot", "Godot_v4.3-stable_win64.exe", "Godot_v4.2.2-stable_win64.exe")) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) { $candidates += $command.Source }
    }
    $candidates += @(
        "$env:LOCALAPPDATA\Programs\Godot\Godot.exe",
        "$env:ProgramFiles\Godot\Godot.exe",
        "$env:USERPROFILE\Downloads\Godot_v4.3-stable_win64.exe"
    )

    foreach ($candidate in $candidates | Select-Object -Unique) {
        if ($candidate -and (Test-Path $candidate)) {
            return (Resolve-Path $candidate).Path
        }
    }
    return $null
}

function Test-CommandAvailable {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

$report = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    repo_root = $RepoRoot
    project_godot = Test-Path (Join-Path $RepoRoot "project.godot")
    export_presets = Test-Path (Join-Path $RepoRoot "export_presets.cfg")
    godot = [ordered]@{ found = $false; path = $null; version = $null }
    java = [ordered]@{ found = $false; version = $null }
    android = [ordered]@{
        sdk_root = $env:ANDROID_SDK_ROOT
        android_home = $env:ANDROID_HOME
        adb = Test-CommandAvailable "adb"
        sdkmanager = Test-CommandAvailable "sdkmanager"
    }
    optional_tools = [ordered]@{
        python = Test-CommandAvailable "python"
        node = Test-CommandAvailable "node"
        ffmpeg = Test-CommandAvailable "ffmpeg"
        git = Test-CommandAvailable "git"
    }
    blockers = @()
    warnings = @()
}

$resolvedGodot = Resolve-GodotBinary -Requested $GodotBin
if ($resolvedGodot) {
    $report.godot.found = $true
    $report.godot.path = $resolvedGodot
    try { $report.godot.version = (& $resolvedGodot --version 2>&1 | Select-Object -First 1).ToString().Trim() }
    catch { $report.warnings += "Godot encontrado, mas a versão não pôde ser lida: $($_.Exception.Message)" }
} else {
    $report.blockers += "Godot não encontrado. Defina GODOT_BIN ou instale Godot 4.3+."
}

$java = Get-Command java -ErrorAction SilentlyContinue
if ($java) {
    $report.java.found = $true
    try { $report.java.version = (& java -version 2>&1 | Select-Object -First 1).ToString().Trim() }
    catch { $report.warnings += "Java encontrado, mas a versão não pôde ser lida." }
} else {
    $report.warnings += "Java não encontrado. Android export requer JDK 17 configurado no Godot."
}

if (-not $report.project_godot) { $report.blockers += "project.godot ausente na raiz." }
if (-not $report.export_presets) { $report.blockers += "export_presets.cfg ausente na raiz." }
if (-not ($env:ANDROID_SDK_ROOT -or $env:ANDROID_HOME)) {
    $report.warnings += "ANDROID_SDK_ROOT/ANDROID_HOME não definidos. O caminho também pode estar configurado no Editor Settings do Godot."
}
if (-not $report.android.adb) { $report.warnings += "adb não está no PATH; instalação automática no aparelho ficará indisponível." }

$ReportDir = Join-Path $RepoRoot "reports/build"
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
$ReportPath = Join-Path $ReportDir "environment_windows.json"
$report | ConvertTo-Json -Depth 8 | Set-Content -Path $ReportPath -Encoding UTF8

Write-Host "=== Cria do Tatame — Auditoria de ambiente ==="
Write-Host "Godot: $($report.godot.found) $($report.godot.version)"
Write-Host "Java:  $($report.java.found) $($report.java.version)"
Write-Host "ADB:   $($report.android.adb)"
Write-Host "Relatório: $ReportPath"

if ($report.blockers.Count -gt 0) {
    Write-Error ("Bloqueadores:`n- " + ($report.blockers -join "`n- "))
    exit 1
}

if ($report.warnings.Count -gt 0) {
    Write-Warning ("Avisos:`n- " + ($report.warnings -join "`n- "))
}

exit 0
