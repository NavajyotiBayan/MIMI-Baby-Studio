# MIMI Baby Studio one-command installer
# Usage:
#   irm navajyoti.online/mimibaby | iex

$ErrorActionPreference = 'Stop'

# CHANGE THIS ONE VALUE after you create/push the GitHub repository.
# Example: https://github.com/YourUser/MIMI-Baby-Studio/archive/refs/heads/main.zip
$MimiDownloadUrl = 'https://github.com/NavajyotiBayan/MIMI-Baby-Studio/archive/refs/heads/main.zip'

$InstallDir = 'C:\MIMI Baby Studio'
$TempRoot = Join-Path $env:TEMP 'MIMI-Baby-Studio-Installer'
$ZipPath = Join-Path $TempRoot 'mimi.zip'
$ExtractDir = Join-Path $TempRoot 'source'

function Write-Step([string]$Message) {
    Write-Host "`n[MIMI] $Message" -ForegroundColor Cyan
}

function Fail([string]$Message) {
    Write-Host "`n[MIMI ERROR] $Message" -ForegroundColor Red
    exit 1
}

try {
    Write-Host '============================================================' -ForegroundColor Magenta
    Write-Host '              MIMI BABY STUDIO INSTALLER' -ForegroundColor Magenta
    Write-Host '============================================================' -ForegroundColor Magenta

    if ($MimiDownloadUrl -like '*CHANGE-ME*') {
        Fail 'The GitHub download URL is not configured yet. Update $MimiDownloadUrl in installer.ps1.'
    }

    Write-Step 'Preparing temporary installation files...'
    if (Test-Path $TempRoot) { Remove-Item $TempRoot -Recurse -Force -ErrorAction SilentlyContinue }
    New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null

    Write-Step 'Downloading the latest MIMI Baby Studio package...'
    Invoke-WebRequest -Uri $MimiDownloadUrl -OutFile $ZipPath -UseBasicParsing

    if (-not (Test-Path $ZipPath)) { Fail 'The MIMI package download failed.' }

    Write-Step 'Extracting MIMI Baby Studio...'
    Expand-Archive -Path $ZipPath -DestinationPath $ExtractDir -Force

    $TopLevel = Get-ChildItem -Path $ExtractDir -Directory | Select-Object -First 1
    if (-not $TopLevel) { Fail 'The downloaded GitHub archive does not contain a project folder.' }

    $StartBat = Join-Path $TopLevel.FullName 'start.bat'
    if (-not (Test-Path $StartBat)) { Fail 'start.bat was not found in the downloaded MIMI package.' }

    Write-Step 'Launching the MIMI Baby Studio setup...'
    # start.bat handles Administrator elevation, installation to C:\MIMI Baby Studio,
    # Python/FFmpeg setup, background startup, and browser launch.
    Start-Process -FilePath $StartBat -WorkingDirectory $TopLevel.FullName

    Write-Step 'MIMI Baby Studio setup has been started.'
    Write-Host 'Windows may ask for Administrator permission.' -ForegroundColor Yellow
    Write-Host 'After setup completes, MIMI Baby Studio will launch automatically.' -ForegroundColor Green

    Start-Sleep -Seconds 2
    Remove-Item $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Fail $_.Exception.Message
}
