#requires -Version 5.1
<#
MIMI Baby Studio - One-Command Windows Installer
Usage:
    irm https://mimibaby.navajyoti.online | iex

The Cloudflare Worker should return this file as plain text.
#>

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$AppName = 'MIMI Baby Studio'
$InstallDir = 'C:\MIMI Baby Studio'
$PackageUrl = 'https://github.com/NavajyotiBayan/MIMI-Baby-Studio/archive/refs/heads/main.zip'
$InstallerUrl = 'https://raw.githubusercontent.com/NavajyotiBayan/MIMI-Baby-Studio/main/install.ps1'
$TempRoot = Join-Path $env:TEMP ("MIMI-Baby-Studio-Installer-" + [guid]::NewGuid().ToString('N'))
$LogFile = Join-Path $TempRoot 'installer.log'

New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null
Start-Transcript -Path $LogFile -Force | Out-Null

function Write-Step([string]$Message) {
    Write-Host "`n[MIMI] $Message" -ForegroundColor Cyan
}
function Write-Ok([string]$Message) {
    Write-Host "[MIMI OK] $Message" -ForegroundColor Green
}
function Write-Warn([string]$Message) {
    Write-Host "[MIMI WARNING] $Message" -ForegroundColor Yellow
}
function Fail([string]$Message) {
    Write-Host "`n[MIMI ERROR] $Message" -ForegroundColor Red
    Write-Host "Log: $LogFile" -ForegroundColor DarkGray
    try { Stop-Transcript | Out-Null } catch {}
    exit 1
}

try {
    Write-Host "============================================================"
    Write-Host "              MIMI BABY STUDIO INSTALLER"
    Write-Host "============================================================"

    # The original script may arrive through irm | iex, so it has no file path.
    # Download a known copy of this installer and elevate that copy.
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Step "Administrator permission is required..."
        $elevatedScript = Join-Path $TempRoot 'install-elevated.ps1'
        Invoke-WebRequest -Uri $InstallerUrl -OutFile $elevatedScript -UseBasicParsing
        Write-Ok "Installer downloaded for elevation."

        $proc = Start-Process -FilePath 'powershell.exe' `
            -Verb RunAs `
            -Wait `
            -PassThru `
            -ArgumentList @(
                '-NoProfile',
                '-ExecutionPolicy', 'Bypass',
                '-File', "`"$elevatedScript`""
            )

        if ($proc.ExitCode -ne 0) {
            Fail "Elevated installer exited with code $($proc.ExitCode)."
        }

        try { Stop-Transcript | Out-Null } catch {}
        exit 0
    }

    Write-Step "Preparing temporary installation files..."
    $DownloadZip = Join-Path $TempRoot 'MIMI-Baby-Studio.zip'
    $ExtractDir = Join-Path $TempRoot 'extracted'
    New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null

    Write-Step "Downloading MIMI Baby Studio from GitHub..."
    Invoke-WebRequest -Uri $PackageUrl -OutFile $DownloadZip -UseBasicParsing
    if (-not (Test-Path $DownloadZip)) {
        Fail "MIMI Baby Studio package was not downloaded."
    }
    Write-Ok "Download complete."

    Write-Step "Extracting MIMI Baby Studio..."
    Expand-Archive -Path $DownloadZip -DestinationPath $ExtractDir -Force

    # Find the actual application root regardless of GitHub's archive folder name.
    $AppRoot = Get-ChildItem -Path $ExtractDir -Directory -Recurse -ErrorAction SilentlyContinue |
        Where-Object {
            (Test-Path (Join-Path $_.FullName 'app.py')) -and
            (Test-Path (Join-Path $_.FullName 'start.bat')) -and
            (Test-Path (Join-Path $_.FullName 'requirements.txt')) -and
            (Test-Path (Join-Path $_.FullName 'templates'))
        } |
        Select-Object -First 1

    if (-not $AppRoot) {
        Fail "The downloaded package does not contain a valid MIMI Baby Studio application."
    }

    Write-Ok "Application package verified."

    Write-Step "Installing MIMI Baby Studio to $InstallDir..."
    if (Test-Path $InstallDir) {
        Write-Host "[MIMI] Existing installation found. Updating files..."
    } else {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    # Copy only the application package. Do not bring the Git metadata or installer
    # build/development files into the installed application.
    $robocopy = Join-Path $env:SystemRoot 'System32\robocopy.exe'
    & $robocopy $AppRoot.FullName $InstallDir /E /COPY:DAT /DCOPY:DAT /XJ /R:2 /W:1 `
        /XD '.git' '__pycache__' 'cloudflare-worker' 'temp' `
        /XF '*.log' 'setup.log' 'server.log' |
        Out-Host

    $rc = $LASTEXITCODE
    if ($rc -ge 8) {
        Fail "Application copy failed. Robocopy returned $rc."
    }
    Write-Ok "MIMI Baby Studio installed."

    # Make sure the installed setup starts from the final location.
    $StartBat = Join-Path $InstallDir 'start.bat'
    if (-not (Test-Path $StartBat)) {
        Fail "Installed start.bat was not found."
    }

    Write-Step "Starting MIMI Baby Studio setup..."
    $setup = Start-Process -FilePath 'cmd.exe' `
        -ArgumentList @('/c', "`"$StartBat`"") `
        -WorkingDirectory $InstallDir `
        -Wait `
        -PassThru

    if ($setup.ExitCode -ne 0) {
        Fail "MIMI Baby Studio setup exited with code $($setup.ExitCode)."
    }

    Write-Ok "MIMI Baby Studio setup completed."
    Write-Host "`n[MIMI] Installation finished successfully." -ForegroundColor Green
}
catch {
    Fail $_.Exception.Message
}
finally {
    try { Stop-Transcript | Out-Null } catch {}
    # Keep the log directory for troubleshooting. It can be removed manually later.
}
