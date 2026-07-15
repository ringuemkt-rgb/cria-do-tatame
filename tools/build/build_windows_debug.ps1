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

$Godot = Resolve-GodotBinary -Requested $GodotBin
$BuildDir = Join-Path $RepoRoot "builds/windows"
$ReportDir = Join-Path $RepoRoot "reports/build"
$ExePath = Join-Path $BuildDir "CriaDoTatame.exe"
$LogPath = Join-Path $ReportDir "windows_export.log"
$ReportPath = Join-Path $ReportDir "windows_build_report.json"

New-Item -ItemType Directory -Force -Path $BuildDir, $ReportDir | Out-Null
if (Test-Path $ExePath) { Remove-Item $ExePath -Force }

Push-Location $RepoRoot
try {
    & $Godot --headless --editor --path $RepoRoot --quit 2>&1 | Tee-Object -FilePath $LogPath
    if ($LASTEXITCODE -ne 0) { throw "Godot falhou ao importar/validar o projeto." }

    & $Godot --headless --path $RepoRoot --export-debug "Windows Desktop Debug" $ExePath 2>&1 | Tee-Object -FilePath $LogPath -Append
    if ($LASTEXITCODE -ne 0) { throw "Exportação Windows falhou. Consulte $LogPath" }
} finally {
    Pop-Location
}

if (-not (Test-Path $ExePath)) { throw "Executável não foi criado: $ExePath" }
$file = Get-Item $ExePath
if ($file.Length -lt 1024) { throw "Executável criado, porém inválido ou vazio." }

$hash = (Get-FileHash -Algorithm SHA256 -Path $ExePath).Hash.ToLowerInvariant()
$report = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    godot = $Godot
    preset = "Windows Desktop Debug"
    executable = $ExePath
    size_bytes = $file.Length
    sha256 = $hash
}
$report | ConvertTo-Json -Depth 5 | Set-Content -Path $ReportPath -Encoding UTF8
Set-Content -Path "$ExePath.sha256.txt" -Value "$hash  $($file.Name)" -Encoding ASCII

Write-Host "Build Windows validada: $ExePath"
Write-Host "SHA-256: $hash"
Write-Host "Relatório: $ReportPath"
