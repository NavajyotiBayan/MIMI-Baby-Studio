@echo off
setlocal EnableExtensions

set "INSTALL_DIR=C:\MIMI Baby Studio"
set "SOURCE_DIR=%~dp0"
set "SOURCE_DIR=%SOURCE_DIR:~0,-1%"
set "MIMI_START_BAT=%~f0"

echo ============================================================
echo                 MIMI BABY STUDIO v2
echo ============================================================
echo.
echo Source:
echo   %SOURCE_DIR%
echo.
echo Destination:
echo   %INSTALL_DIR%
echo.

REM If this is the installed copy, do not copy again.
if /I "%SOURCE_DIR%"=="%INSTALL_DIR%" goto SETUP

REM Self-elevate this exact BAT directly. This avoids cmd.exe
REM argument/quote parsing problems with paths containing spaces.
if /I not "%~1"=="--elevated" (
    echo Requesting Windows Administrator permission...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
      "$bat=$env:MIMI_START_BAT; Start-Process -FilePath $bat -Verb RunAs -ArgumentList '--elevated'"
    if errorlevel 1 (
        echo.
        echo [ERROR] Windows could not start the Administrator installer.
        echo Right-click start.bat and choose ^"Run as administrator^".
        echo.
        pause
        exit /b 1
    )
    exit /b 0
)

REM Export the BAT path for the PowerShell elevation command.
REM (The parent process supplies this variable before reaching here.)
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%" >nul 2>&1
if not exist "%INSTALL_DIR%" (
    echo [ERROR] Cannot create:
    echo   %INSTALL_DIR%
    echo.
    pause
    exit /b 1
)

echo Copying MIMI Baby Studio...
robocopy "%SOURCE_DIR%" "%INSTALL_DIR%" /E /COPY:DAT /DCOPY:DAT /XJ /R:2 /W:1 /XD temp __pycache__ .git /XF *.log setup.log server.log
set "RC=%ERRORLEVEL%"

if %RC% GEQ 8 (
    echo.
    echo [ERROR] Copy failed. Robocopy returned %RC%.
    echo.
    echo Source:
    echo   "%SOURCE_DIR%"
    echo Destination:
    echo   "%INSTALL_DIR%"
    echo.
    pause
    exit /b 1
)

echo.
echo [OK] MIMI Baby Studio copied successfully.
echo.
echo Starting the installed setup...
timeout /t 1 /nobreak >nul
start "" "%INSTALL_DIR%\start.bat"
exit /b 0

:SETUP
cd /d "%INSTALL_DIR%"
title MIMI Baby Studio - Setup

echo ============================================================
echo                 MIMI BABY STUDIO v2
echo              Automatic Dependency Setup
echo ============================================================
echo.
echo Install location:
echo   %INSTALL_DIR%
echo.

REM Python
echo [1/6] Checking Python...
set "PYEXE="
for /f "delims=" %%P in ('where.exe python.exe 2^>nul') do (
    if not defined PYEXE if /I not "%%~fP"=="%LOCALAPPDATA%\Microsoft\WindowsApps\python.exe" set "PYEXE=%%~fP"
)
if not defined PYEXE if exist "%LOCALAPPDATA%\Programs\Python\Python313\python.exe" set "PYEXE=%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
if not defined PYEXE if exist "C:\Program Files\Python313\python.exe" set "PYEXE=C:\Program Files\Python313\python.exe"

if not defined PYEXE (
    echo [!] Python not found. Installing Python 3.13...
    where winget.exe >nul 2>&1 || (
        echo [ERROR] WinGet is unavailable.
        pause
        exit /b 1
    )
    winget install --id Python.Python.3.13 -e --accept-source-agreements --accept-package-agreements
    if errorlevel 1 (
        echo [ERROR] Python installation failed.
        pause
        exit /b 1
    )
    timeout /t 3 /nobreak >nul
    if exist "%LOCALAPPDATA%\Programs\Python\Python313\python.exe" set "PYEXE=%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
    if not defined PYEXE if exist "C:\Program Files\Python313\python.exe" set "PYEXE=C:\Program Files\Python313\python.exe"
)

if not defined PYEXE (
    echo [ERROR] Could not locate python.exe.
    pause
    exit /b 1
)
echo [OK] Python: %PYEXE%

REM Python dependencies
echo.
echo [2/6] Installing Python dependencies...
"%PYEXE%" -m pip --version >nul 2>&1
if errorlevel 1 "%PYEXE%" -m ensurepip --upgrade
"%PYEXE%" -m pip install --disable-pip-version-check --user -r requirements.txt
if errorlevel 1 (
    echo [ERROR] Python dependencies failed.
    pause
    exit /b 1
)
"%PYEXE%" -c "import flask, PIL" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flask/Pillow verification failed.
    pause
    exit /b 1
)
echo [OK] Python dependencies ready.

REM FFmpeg
echo.
echo [3/6] Checking FFmpeg...
set "FFMPEG_EXE="
for /f "delims=" %%F in ('where.exe ffmpeg.exe 2^>nul') do if not defined FFMPEG_EXE set "FFMPEG_EXE=%%~fF"
if not defined FFMPEG_EXE if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\ffmpeg.exe" set "FFMPEG_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Links\ffmpeg.exe"
if not defined FFMPEG_EXE if exist "%LOCALAPPDATA%\Microsoft\WinGet\Packages" (
    for /f "delims=" %%F in ('where.exe /r "%LOCALAPPDATA%\Microsoft\WinGet\Packages" ffmpeg.exe 2^>nul') do if not defined FFMPEG_EXE set "FFMPEG_EXE=%%~fF"
)
if not defined FFMPEG_EXE if exist "C:\ffmpeg\bin\ffmpeg.exe" set "FFMPEG_EXE=C:\ffmpeg\bin\ffmpeg.exe"

if not defined FFMPEG_EXE (
    echo [!] FFmpeg not found. Installing...
    where winget.exe >nul 2>&1 || (
        echo [ERROR] WinGet is unavailable.
        pause
        exit /b 1
    )
    winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements
    if errorlevel 1 (
        echo [ERROR] FFmpeg installation failed.
        pause
        exit /b 1
    )
    timeout /t 3 /nobreak >nul
    for /f "delims=" %%F in ('where.exe /r "%LOCALAPPDATA%\Microsoft\WinGet\Packages" ffmpeg.exe 2^>nul') do if not defined FFMPEG_EXE set "FFMPEG_EXE=%%~fF"
    if not defined FFMPEG_EXE if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\ffmpeg.exe" set "FFMPEG_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Links\ffmpeg.exe"
)

if not defined FFMPEG_EXE (
    echo [ERROR] FFmpeg executable could not be located.
    pause
    exit /b 1
)
"%FFMPEG_EXE%" -version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] FFmpeg was found but could not be executed.
    echo %FFMPEG_EXE%
    pause
    exit /b 1
)
echo [OK] FFmpeg: %FFMPEG_EXE%

REM App folders
echo.
echo [4/6] Preparing application folders...
if not exist "%INSTALL_DIR%\temp" mkdir "%INSTALL_DIR%\temp"

REM Background startup
echo.
echo [5/6] Configuring background startup...
set "MIMI_VBS=%INSTALL_DIR%\launch_silent.vbs"
set "MIMI_INSTALL=%INSTALL_DIR%"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$startup=[Environment]::GetFolderPath('Startup'); $ws=New-Object -ComObject WScript.Shell; $lnk=$ws.CreateShortcut((Join-Path $startup 'MIMI Baby Studio.lnk')); $lnk.TargetPath=Join-Path $env:SystemRoot 'System32\wscript.exe'; $lnk.Arguments='//B //NoLogo ""'+$env:MIMI_VBS+'""'; $lnk.WorkingDirectory=$env:MIMI_INSTALL; $lnk.WindowStyle=7; $lnk.Description='MIMI Baby Studio background server'; $lnk.Save()" >nul 2>&1

if exist "%STARTUP%\MIMI Baby Studio.lnk" (
    echo [OK] Background startup configured.
) else (
    echo [WARNING] Could not create the startup shortcut.
)

REM Start server
echo.
echo [6/6] Starting MIMI Baby Studio...
if exist "%INSTALL_DIR%\server.log" del /q "%INSTALL_DIR%\server.log" >nul 2>&1
"%WINDIR%\System32\wscript.exe" //B //NoLogo "%MIMI_VBS%"

for /l %%N in (1,1,40) do (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
      "try{$c=New-Object Net.Sockets.TcpClient;$c.Connect('127.0.0.1',5000);$c.Close();exit 0}catch{exit 1}"
    if not errorlevel 1 goto READY
    timeout /t 1 /nobreak >nul
)

echo.
echo [ERROR] MIMI Baby Studio server did not start.
echo Check:
echo   %INSTALL_DIR%\server.log
echo.
pause
exit /b 1

:READY
echo.
echo [OK] Server is running.
start "" "http://127.0.0.1:5000"
echo.
echo MIMI Baby Studio is ready.
timeout /t 2 /nobreak >nul
exit /b 0
