# MIMI Baby Studio v2.0.0 - Windows release builder
# Creates a self-contained Windows Setup.exe and Portable.exe.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

$PythonVersion = '3.13.15'
$PythonZip = "python-$PythonVersion-embed-amd64.zip"
$PythonUrl = "https://www.python.org/ftp/python/$PythonVersion/$PythonZip"
$FfmpegUrl = 'https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-win64-gpl.zip'
$Runtime = Join-Path $Root 'runtime'
$PythonRoot = Join-Path $Runtime 'python'
$FfmpegRoot = Join-Path $Runtime 'ffmpeg'
$Cache = Join-Path $env:TEMP 'mimi-baby-studio-build'
$PipScript = Join-Path $Cache 'get-pip.py'
$PythonArchive = Join-Path $Cache $PythonZip
$FfmpegArchive = Join-Path $Cache 'ffmpeg-win64-gpl.zip'

function Step([string]$Text) { Write-Host "`n[MIMI] $Text" -ForegroundColor Cyan }
function Ok([string]$Text) { Write-Host "[OK] $Text" -ForegroundColor Green }

New-Item -ItemType Directory -Path $Cache -Force | Out-Null

Step 'Checking Node.js and npm...'
node --version
npm --version

Step 'Preparing bundled Python runtime...'
if (Test-Path $PythonRoot) { Remove-Item $PythonRoot -Recurse -Force }
New-Item -ItemType Directory -Path $PythonRoot -Force | Out-Null
if (-not (Test-Path $PythonArchive)) {
  Invoke-WebRequest -Uri $PythonUrl -OutFile $PythonArchive -UseBasicParsing
}
Expand-Archive -Path $PythonArchive -DestinationPath $PythonRoot -Force
$PythonExe = Join-Path $PythonRoot 'python.exe'
if (-not (Test-Path $PythonExe)) { throw 'Bundled Python executable was not found after extraction.' }

$Pth = Get-ChildItem $PythonRoot -Filter '*._pth' | Select-Object -First 1
if (-not $Pth) { throw 'Python embedded ._pth file was not found.' }
$pthLines = Get-Content $Pth.FullName
$pthLines = @($pthLines | Where-Object { $_ -notmatch '^import site\s*$' })
if (-not ($pthLines -contains 'Lib\site-packages')) { $pthLines += 'Lib\site-packages' }
$pthLines += 'import site'
Set-Content -Path $Pth.FullName -Value $pthLines -Encoding ASCII

if (-not (Test-Path $PipScript)) {
  Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile $PipScript -UseBasicParsing
}
& $PythonExe $PipScript --no-warn-script-location
$SitePackages = Join-Path $PythonRoot 'Lib\site-packages'
New-Item -ItemType Directory -Path $SitePackages -Force | Out-Null
& $PythonExe -m pip install --disable-pip-version-check --no-cache-dir --target $SitePackages -r (Join-Path $Root 'requirements.txt')
& $PythonExe -c "import flask, PIL; print('Bundled Python dependencies OK')"
Ok 'Bundled Python runtime ready.'

Step 'Preparing bundled FFmpeg runtime...'
if (Test-Path $FfmpegRoot) { Remove-Item $FfmpegRoot -Recurse -Force }
New-Item -ItemType Directory -Path $FfmpegRoot -Force | Out-Null
if (-not (Test-Path $FfmpegArchive)) {
  Invoke-WebRequest -Uri $FfmpegUrl -OutFile $FfmpegArchive -UseBasicParsing
}
$FfmpegExtract = Join-Path $Cache 'ffmpeg-extract'
if (Test-Path $FfmpegExtract) { Remove-Item $FfmpegExtract -Recurse -Force }
New-Item -ItemType Directory -Path $FfmpegExtract -Force | Out-Null
Expand-Archive -Path $FfmpegArchive -DestinationPath $FfmpegExtract -Force
$FfmpegExe = Get-ChildItem $FfmpegExtract -Recurse -Filter 'ffmpeg.exe' | Select-Object -First 1
if (-not $FfmpegExe) { throw 'FFmpeg executable was not found in the downloaded archive.' }
$FfmpegBin = Join-Path $FfmpegRoot 'bin'
New-Item -ItemType Directory -Path $FfmpegBin -Force | Out-Null
Copy-Item -Path (Join-Path $FfmpegExe.DirectoryName '*') -Destination $FfmpegBin -Recurse -Force
& (Join-Path $FfmpegBin 'ffmpeg.exe') -version *> $null
if ($LASTEXITCODE -ne 0) { throw 'Bundled FFmpeg failed its version check.' }
Ok 'Bundled FFmpeg runtime ready.'

Step 'Installing npm dependencies...'
npm install

Step 'Building Windows Setup.exe and Portable.exe...'
npm run dist

Ok 'MIMI Baby Studio Windows build completed.'
Write-Host "`nArtifacts are in: $Root\dist" -ForegroundColor Green
