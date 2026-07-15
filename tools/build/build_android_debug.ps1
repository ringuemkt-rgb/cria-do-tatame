[CmdletBinding()]
param(
    [string]$GodotBin = $env:GODOT_BIN,
    [switch]$Install,
    [string]$DeviceSerial = ""
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$CheckScript = Join-Path $PSScriptRoot "check_environment.ps1"

function Resolve-GodotBinary {
    param([string]$Requested)
    $candidates = @()
    if ($Requested) { $candidates += $Requested }
    foreach ($name in @("godot4", "godot", "Godot_v4.3-stable_win64.exe", "Godot_v4.2.2-stable_win64.exe")) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) { $candidates += $cmd.Source }
    }
    $candidates += @(
        "$env:LOCALAPPDATA\Programs\Godot\Godot.exe",
        "$env:ProgramFiles\Godot\Godot.exe",
        "$env:USERPROFILE\Downloads\Godot_v4.3-stable_win64.exe"
    )
    foreach ($candidate in $candidates | Select-Object -Unique) {
        if ($candidate -and (Test-Path $candidate)) { return (Resolve-Path $candidate).Path }
    }
    throw "Godot não encontrado. Defina GODOT_BIN com o caminho do executável."
}

& $CheckScript -GodotBin $GodotBin
if ($LASTEXITCODE -ne 0) { throw "Auditoria de ambiente falhou." }

$Godot = Resolve-GodotBinary -Requested $GodotBin
$BuildDir = Join-Path $RepoRoot "builds/android"
$ReportDir = Join-Path $RepoRoot "reports/build"
$ApkPath = Join-Path $BuildDir "CriaDoTatame-debug.apk"
$LogPath = Join-Path $ReportDir "android_export.log"
$ReportPath = Join-Path $ReportDir "android_build_report.json"

New-Item -ItemType Directory -Force -Path $BuildDir, $ReportDir | Out-Null
if (Test-Path $ApkPath) { Remove-Item $ApkPath -Force }

Push-Location $RepoRoot
try {
    Write-Host "Importando e validando projeto no Godot headless..."
    & $Godot --headless --editor --path $RepoRoot --quit 2>&1 | Tee-Object -FilePath $LogPath
    if ($LASTEXITCODE -ne 0) { throw "Godot falhou ao importar/validar o projeto. Consulte $LogPath" }

    Write-Host "Exportando preset 'Android Debug'..."
    & $Godot --headless --path $RepoRoot --export-debug "Android Debug" $ApkPath 2>&1 | Tee-Object -FilePath $LogPath -Append
    if ($LASTEXITCODE -ne 0) { throw "Exportação Android falhou. Consulte $LogPath" }
} finally {
    Pop-Location
}

if (-not (Test-Path $ApkPath)) { throw "Godot terminou sem criar o APK esperado: $ApkPath" }
$file = Get-Item $ApkPath
if ($file.Length -lt 1024) { throw "APK criado, porém inválido ou vazio ($($file.Length) bytes)." }

$hash = (Get-FileHash -Algorithm SHA256 -Path $ApkPath).Hash.ToLowerInvariant()
$report = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    godot = $Godot
    preset = "Android Debug"
    apk = $ApkPath
    size_bytes = $file.Length
    sha256 = $hash
    installed = $false
    device = $null
}

if ($Install) {
    $adb = Get-Command adb -ErrorAction SilentlyContinue
    if (-not $adb) { throw "-Install solicitado, mas adb não está no PATH." }
    $args = @()
    if ($DeviceSerial) { $args += @("-s", $DeviceSerial); $report.device = $DeviceSerial }
    $args += @("install", "-r", $ApkPath)
    & adb @args
    if ($LASTEXITCODE -ne 0) { throw "APK gerado, mas a instalação via adb falhou." }
    $report.installed = $true
}

$report | ConvertTo-Json -Depth 5 | Set-Content -Path $ReportPath -Encoding UTF8
Set-Content -Path "$ApkPath.sha256.txt" -Value "$hash  $($file.Name)" -Encoding ASCII

Write-Host "APK validado: $ApkPath"
Write-Host "Tamanho: $($file.Length) bytes"
Write-Host "SHA-256: $hash"
Write-Host "Relatório: $ReportPath"
