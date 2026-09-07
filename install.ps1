#requires -Version 5.1
<#
MIMI Baby Studio - One-command Windows installer
Usage:
    irm https://mimibaby.navajyoti.online | iex

This script is intentionally small so a Cloudflare Worker can serve it as plain text.
It downloads the latest published Setup.exe from the GitHub Releases page and starts it.
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Repo = 'NavajyotiBayan/MIMI-Baby-Studio'
$ApiUrl = "https://api.github.com/repos/$Repo/releases/latest"
$TempDir = Join-Path $env:TEMP ("MIMI-Baby-Studio-" + [guid]::NewGuid().ToString('N'))
$Installer = Join-Path $TempDir 'MIMI-Baby-Studio-Setup.exe'

New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host '              MIMI BABY STUDIO INSTALLER' -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '[MIMI] Checking latest GitHub release...' -ForegroundColor Cyan

    $headers = @{
        'Accept' = 'application/vnd.github+json'
        'User-Agent' = 'MIMI-Baby-Studio-Installer'
    }
    $release = Invoke-RestMethod -Uri $ApiUrl -Headers $headers -Method Get
    $asset = $release.assets | Where-Object { $_.name -match '^MIMI-Baby-Studio-.*-Setup\.exe$' } | Select-Object -First 1

    if (-not $asset) {
        throw 'No MIMI Baby Studio Setup.exe was found in the latest GitHub release.'
    }

    Write-Host "[MIMI] Latest release: $($release.tag_name)" -ForegroundColor Green
    Write-Host "[MIMI] Downloading $($asset.name)..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $Installer -UseBasicParsing

    if (-not (Test-Path $Installer)) {
        throw 'The MIMI Baby Studio installer download failed.'
    }

    Write-Host '[MIMI] Starting Windows installer...' -ForegroundColor Cyan
    $proc = Start-Process -FilePath $Installer -Wait -PassThru
    if ($proc.ExitCode -ne 0) {
        throw "MIMI Baby Studio installer exited with code $($proc.ExitCode)."
    }

    Write-Host '[MIMI OK] MIMI Baby Studio installation completed.' -ForegroundColor Green
}
catch {
    Write-Host "`n[MIMI ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
finally {
    if (Test-Path $TempDir) {
        Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
