@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "INSTALL_DIR=C:\MIMI Baby Studio"
set "CURRENT_DIR=%~dp0"

:: ------------------------------------------------------------
:: MIMI Baby Studio v2 - automatic first-run installer
:: Source = the folder containing this BAT file.
:: Destination = C:\MIMI Baby Studio.
:: The installer self-elevates through the normal Windows UAC
:: prompt; no administrator password is stored or required.
:: ------------------------------------------------------------

:: If already running from the fixed install directory, skip copying.
if /I "%CURRENT_DIR:~0,-1%"=="%INSTALL_DIR%" goto SETUP

:: Always elevate before touching C:\MIMI Baby Studio.
:: This avoids a non-admin Robocopy attempt and prevents broken
:: quote handling when the source path contains spaces.
if /I not "%~1"=="--elevated" goto ELEVATE

goto INSTALL_TO_ROOT

:ELEVATE
echo.
echo ============================================================
echo                 MIMI BABY STUDIO v2
echo ============================================================
echo.
echo Installing the studio to:
echo   %INSTALL_DIR%
echo.
echo Requesting Windows Administrator permission...
echo.

set "MIMI_BAT=%~f0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$bat=$env:MIMI_BAT; $arg='/d /c ""' + $bat + '" --elevated"'; $p=Start-Process -FilePath $env:ComSpec -ArgumentList $arg -Verb RunAs -Wait -PassThru; exit $p.ExitCode"
if errorlevel 1 (
  echo [ERROR] Administrator permission was cancelled or failed.
  echo Please click Yes on the Windows UAC prompt and try again.
  echo.
  pause
  exit /b 1
)
endlocal
exit /b 0

:INSTALL_TO_ROOT
:: At this point this BAT is running elevated.
set "SOURCE_DIR=%~dp0"
set "SOURCE_DIR=%SOURCE_DIR:~0,-1%"

if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%" >nul 2>&1
if not exist "%INSTALL_DIR%" (
  echo [ERROR] Could not create "%INSTALL_DIR%" even with Administrator access.
  pause
  exit /b 1
)

:: Stop an existing MIMI server before updating the installed files.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$p=Get-NetTCPConnection -LocalPort 5000 -State Listen -ErrorAction SilentlyContinue; if($p){$p.OwningProcess | Sort-Object -Unique | ForEach-Object {Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue}}" >nul 2>&1
timeout /t 1 /nobreak >nul

:: Robocopy uses the exact BAT-derived source and fixed C: destination.
:: Do not use a PowerShell-expanded path here; that was the source of the
:: previous malformed Source/Destination error.
robocopy "%SOURCE_DIR%" "%INSTALL_DIR%" /E /COPY:DAT /DCOPY:DAT /XJ /R:2 /W:1 /XD "temp" "__pycache__" ".git" /XF "*.log" "setup.log" "server.log" >nul
set "COPY_RC=%ERRORLEVEL%"

:: Robocopy codes 0-7 are successful/non-fatal. 8+ means failure.
if %COPY_RC% GEQ 8 (
  echo.
  echo [ERROR] Studio copy failed. Robocopy returned %COPY_RC%.
  echo.
  echo Source:
  echo   "%SOURCE_DIR%"
  echo Destination:
  echo   "%INSTALL_DIR%"
  echo.
  echo Detailed Robocopy output:
  echo ------------------------------------------------------------------------
  robocopy "%SOURCE_DIR%" "%INSTALL_DIR%" /E /COPY:DAT /DCOPY:DAT /XJ /R:1 /W:1 /XD "temp" "__pycache__" ".git" /XF "*.log" "setup.log" "server.log"
  echo ------------------------------------------------------------------------
  echo.
  pause
  exit /b 1
)

echo [OK] MIMI Baby Studio copied to:
echo   %INSTALL_DIR%
echo.
echo Starting the installed copy...
timeout /t 1 /nobreak >nul
start "" "%INSTALL_DIR%\start.bat"
endlocal
exit /b 0

:SETUP
cd /d "%INSTALL_DIR%"
title MIMI Baby Studio - Setup
set "LOG=%INSTALL_DIR%\setup.log"
echo [INFO] MIMI Baby Studio v2 setup started. > "%LOG%"

echo.
echo ============================================================
echo                 MIMI BABY STUDIO v2
echo              Automatic Dependency Setup
echo ============================================================
echo.
echo Install location: %INSTALL_DIR%
echo.

:: 1. Python
 echo [1/6] Checking Python...
set "PYEXE="
for /f "delims=" %%P in ('where.exe python.exe 2^>nul') do if not defined PYEXE if /I not "%%~fP"=="%LOCALAPPDATA%\Microsoft\WindowsApps\python.exe" set "PYEXE=%%~fP"
if not defined PYEXE (
  echo [!] Python not found. Installing Python 3.13...
  where winget.exe >nul 2>&1 || (echo [ERROR] WinGet is unavailable.& pause& exit /b 1)
  winget install --id Python.Python.3.13 -e --accept-source-agreements --accept-package-agreements
  if errorlevel 1 (echo [ERROR] Python installation failed.& pause& exit /b 1)
  timeout /t 2 /nobreak >nul
  for /f "delims=" %%P in ('where.exe python.exe 2^>nul') do if not defined PYEXE if /I not "%%~fP"=="%LOCALAPPDATA%\Microsoft\WindowsApps\python.exe" set "PYEXE=%%~fP"
)
if not defined PYEXE (
  if exist "%LOCALAPPDATA%\Programs\Python\Python313\python.exe" set "PYEXE=%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
)
if not defined PYEXE (
  if exist "C:\Program Files\Python313\python.exe" set "PYEXE=C:\Program Files\Python313\python.exe"
)
if not defined PYEXE (echo [ERROR] Could not locate a usable python.exe.& echo See setup.log.& pause& exit /b 1)
echo [OK] Python: %PYEXE%

:: 2. pip
 echo.
echo [2/6] Checking pip and Python packages...
"%PYEXE%" -m pip --version >nul 2>&1 || "%PYEXE%" -m ensurepip --upgrade
"%PYEXE%" -m pip install --disable-pip-version-check --user -r requirements.txt
if errorlevel 1 (echo [ERROR] Python dependencies failed.& pause& exit /b 1)
"%PYEXE%" -c "import flask, PIL; print('[OK] Flask and Pillow are available.')"
if errorlevel 1 (echo [ERROR] Dependency verification failed.& pause& exit /b 1)

:: 3. FFmpeg locate/install
 echo.
echo [3/6] Checking FFmpeg...
set "FFMPEG_EXE="
for /f "delims=" %%F in ('where.exe ffmpeg.exe 2^>nul') do if not defined FFMPEG_EXE set "FFMPEG_EXE=%%~fF"
if not defined FFMPEG_EXE if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\ffmpeg.exe" set "FFMPEG_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Links\ffmpeg.exe"
if not defined FFMPEG_EXE if exist "%LOCALAPPDATA%\Microsoft\WinGet\Packages" for /f "delims=" %%F in ('where.exe /r "%LOCALAPPDATA%\Microsoft\WinGet\Packages" ffmpeg.exe 2^>nul') do if not defined FFMPEG_EXE set "FFMPEG_EXE=%%~fF"
if not defined FFMPEG_EXE if exist "C:\ffmpeg\bin\ffmpeg.exe" set "FFMPEG_EXE=C:\ffmpeg\bin\ffmpeg.exe"
if not defined FFMPEG_EXE (
  echo [!] FFmpeg not found. Installing Gyan.FFmpeg...
  where winget.exe >nul 2>&1 || (echo [ERROR] WinGet is unavailable.& pause& exit /b 1)
  winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements
  if errorlevel 1 (echo [ERROR] FFmpeg installation failed.& pause& exit /b 1)
  timeout /t 2 /nobreak >nul
  for /f "delims=" %%F in ('where.exe ffmpeg.exe 2^>nul') do if not defined FFMPEG_EXE set "FFMPEG_EXE=%%~fF"
  if not defined FFMPEG_EXE if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\ffmpeg.exe" set "FFMPEG_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Links\ffmpeg.exe"
  if not defined FFMPEG_EXE if exist "%LOCALAPPDATA%\Microsoft\WinGet\Packages" for /f "delims=" %%F in ('where.exe /r "%LOCALAPPDATA%\Microsoft\WinGet\Packages" ffmpeg.exe 2^>nul') do if not defined FFMPEG_EXE set "FFMPEG_EXE=%%~fF"
)
if not defined FFMPEG_EXE (echo [ERROR] FFmpeg executable could not be located.& pause& exit /b 1)
for %%F in ("%FFMPEG_EXE%") do set "FFMPEG_DIR=%%~dpF"
set "PATH=%FFMPEG_DIR%;%PATH%"
"%FFMPEG_EXE%" -version >nul 2>&1
if errorlevel 1 (echo [ERROR] FFmpeg was found but could not be executed.& echo %FFMPEG_EXE%& pause& exit /b 1)
echo [OK] FFmpeg: %FFMPEG_EXE%

:: 4. Folders
 echo.
echo [4/6] Preparing application folders...
if not exist "%INSTALL_DIR%\temp" mkdir "%INSTALL_DIR%\temp"

:: 5. Launcher protocol + Windows startup
 echo [5/6] Registering background launcher...
set "VBS=%INSTALL_DIR%\launch_silent.vbs"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$k='HKCU:\Software\Classes\mimibaby'; $v='%VBS%'; New-Item -Path $k -Force | Out-Null; New-ItemProperty -Path $k -Name '(Default)' -Value 'URL:MIMI Baby Studio Launcher' -Force | Out-Null; New-ItemProperty -Path $k -Name 'URL Protocol' -Value '' -Force | Out-Null; New-Item -Path ($k+'\shell\open\command') -Force | Out-Null; New-ItemProperty -Path ($k+'\shell\open\command') -Name '(Default)' -Value ('wscript.exe ' + [char]34 + $v + [char]34) -Force | Out-Null" >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "$startup=[Environment]::GetFolderPath('Startup'); $w=New-Object -ComObject WScript.Shell; $s=$w.CreateShortcut((Join-Path $startup 'MIMI Baby Studio.lnk')); $s.TargetPath='wscript.exe'; $s.Arguments=([char]34)+'%VBS%'+[char]34; $s.WorkingDirectory='%INSTALL_DIR%'; $s.IconLocation='%SystemRoot%\System32\SHELL32.dll,70'; $s.Save()" >nul 2>&1

:: 6. Start + wait + browser
 echo [6/6] Starting MIMI Baby Studio silently...
if exist "%INSTALL_DIR%\server.log" del /q "%INSTALL_DIR%\server.log" >nul 2>&1
start "" /b wscript.exe "%VBS%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ok=$false; 1..40 | %% { try { $c=New-Object Net.Sockets.TcpClient; $c.Connect('127.0.0.1',5000); $c.Close(); $ok=$true; break } catch {}; Start-Sleep -Milliseconds 500 }; if(-not $ok){ exit 1 }"
if errorlevel 1 (
  echo [!] Silent launcher did not respond. Trying direct hidden Python...
  powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command "$p='%PYEXE%'; Start-Process -FilePath $p -ArgumentList 'app.py' -WorkingDirectory '%INSTALL_DIR%' -WindowStyle Hidden"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$ok=$false; 1..30 | %% { try { $c=New-Object Net.Sockets.TcpClient; $c.Connect('127.0.0.1',5000); $c.Close(); $ok=$true; break } catch {}; Start-Sleep -Milliseconds 500 }; if(-not $ok){ exit 1 }"
  if errorlevel 1 (echo [ERROR] MIMI Baby Studio server did not start. Run debug_server.bat.& pause& exit /b 1)
)
start "" "http://127.0.0.1:5000"
echo.
echo ============================================================
echo  MIMI Baby Studio v2 is ready.
echo  Installed at: %INSTALL_DIR%
echo ============================================================
echo.
timeout /t 2 /nobreak >nul
endlocal
exit /b 0
