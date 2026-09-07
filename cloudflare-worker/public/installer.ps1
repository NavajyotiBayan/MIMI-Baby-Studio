# MIMI Baby Studio one-command installer
# Usage:
#   irm https://mimibaby.navajyoti.online | iex
#
# This script downloads the current GitHub main branch, stages it in %TEMP%,
# then launches the existing MIMI setup script. The staging folder is NOT
# deleted until the elevated copy has had time to complete.

$ErrorActionPreference = 'Stop'

$MimiDownloadUrl = 'https://github.com/NavajyotiBayan/MIMI-Baby-Studio/archive/refs/heads/main.zip'
$InstallDir = 'C:\MIMI Baby Studio'
$TempRoot = Join-Path $env:TEMP ('MIMI-Baby-Studio-Installer-' + [guid]::NewGuid().ToString('N'))
$ZipPath = Join-Path $TempRoot 'mimi.zip'
$ExtractDir = Join-Path $TempRoot 'source'
$LogPath = Join-Path $TempRoot 'installer.log'

function Write-Step([string]$Message) {
    Write-Host "`n[MIMI] $Message" -ForegroundColor Cyan
}

function Fail([string]$Message) {
    Write-Host "`n[MIMI ERROR] $Message" -ForegroundColor Red
    Write-Host "Log: $LogPath" -ForegroundColor DarkGray
    exit 1
}

try {
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host '              MIMI BABY STUDIO INSTALLER' -ForegroundColor Magenta
    Write-Host '============================================================' -ForegroundColor Magenta

    Write-Step 'Preparing temporary installation files...'
    New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null

    Write-Step 'Downloading MIMI Baby Studio from GitHub...'
    Invoke-WebRequest -Uri $MimiDownloadUrl -OutFile $ZipPath -UseBasicParsing

    if (-not (Test-Path $ZipPath)) {
        Fail 'The MIMI package download failed.'
    }

    $zipInfo = Get-Item $ZipPath
    if ($zipInfo.Length -lt 10000) {
        Fail 'The downloaded package is unexpectedly small or invalid.'
    }

    Write-Step 'Extracting MIMI Baby Studio...'
    Expand-Archive -Path $ZipPath -DestinationPath $ExtractDir -Force

    $TopLevel = Get-ChildItem -Path $ExtractDir -Directory | Where-Object {
        Test-Path (Join-Path $_.FullName 'app.py') -and
        Test-Path (Join-Path $_.FullName 'start.bat') -and
        Test-Path (Join-Path $_.FullName 'requirements.txt')
    } | Select-Object -First 1

    if (-not $TopLevel) {
        Fail 'The downloaded GitHub archive does not contain a valid MIMI Baby Studio package.'
    }

    $StartBat = Join-Path $TopLevel.FullName 'start.bat'
    if (-not (Test-Path $StartBat)) {
        Fail 'start.bat was not found in the downloaded MIMI package.'
    }

    # Keep the staging directory alive while start.bat performs the elevated copy.
    # The existing start.bat is responsible for copying to C:\MIMI Baby Studio,
    # installing dependencies, configuring startup and launching the browser.
    Write-Step 'Starting the MIMI Baby Studio setup...'
    Write-Host '[MIMI] Windows may ask for Administrator permission.' -ForegroundColor Yellow

    $process = Start-Process -FilePath $StartBat `
        -WorkingDirectory $TopLevel.FullName `
        -PassThru

    # Give start.bat enough time to copy the package before this process exits.
    # We deliberately do not remove $TempRoot here; Windows can clean it later.
    Start-Sleep -Seconds 15

    if ($process.HasExited) {
        Write-Host '[MIMI] Initial setup launcher has finished.' -ForegroundColor DarkGray
    } else {
        Write-Host '[MIMI] Setup is continuing in its own window.' -ForegroundColor Green
    }

    Write-Step 'MIMI Baby Studio setup has been started.'
    Write-Host 'If Administrator permission was requested, approve it to continue.' -ForegroundColor Yellow
    Write-Host "Temporary files: $TempRoot" -ForegroundColor DarkGray
    Write-Host 'The setup will install dependencies and launch MIMI when ready.' -ForegroundColor Green
}
catch {
    try {
        $_ | Out-File -FilePath $LogPath -Append -Encoding utf8
    } catch {}
    Fail $_.Exception.Message
}
