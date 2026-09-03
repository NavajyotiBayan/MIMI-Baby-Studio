@echo off
setlocal EnableExtensions

set "APP_DIR=%~dp0"
set "APP_DIR=%APP_DIR:~0,-1%"
set "VBS=%APP_DIR%\launch_silent.vbs"
set "STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "LINK=%STARTUP%\MIMI Baby Studio.lnk"

echo ============================================================
echo                 MIMI BABY STUDIO v2
echo ============================================================
echo.
echo Setting up background server startup...
echo.

if not exist "%VBS%" (
    echo [ERROR] launch_silent.vbs was not found.
    echo.
    echo This BAT must be placed inside the MIMI Baby Studio folder:
    echo %APP_DIR%
    echo.
    pause
    exit /b 1
)

if not exist "%STARTUP%" mkdir "%STARTUP%" >nul 2>&1

REM Create a hidden Startup shortcut directly to wscript.exe.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ws=New-Object -ComObject WScript.Shell; $s=$ws.CreateShortcut($env:LINK); $s.TargetPath=$env:WINDIR+'\System32\wscript.exe'; $s.Arguments='//B //NoLogo ""'+$env:VBS+'""'; $s.WorkingDirectory=$env:APP_DIR; $s.WindowStyle=1; $s.Description='MIMI Baby Studio background server'; $s.Save()" >nul 2>&1

if not exist "%LINK%" (
    echo [WARNING] Could not create the automatic startup shortcut.
    echo The server can still be started manually.
    echo.
) else (
    echo [OK] Automatic background startup configured.
    echo.
)

REM Check whether the server is already running.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "try { $r=Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:5000/health' -TimeoutSec 2; if($r.StatusCode -eq 200){exit 0}else{exit 1} } catch { exit 1 }"

if not errorlevel 1 (
    echo [OK] Server is already running.
    start "" "http://127.0.0.1:5000"
    exit /b 0
)

REM Start the server silently now.
echo Starting MIMI Baby Studio server in background...
"%WINDIR%\System32\wscript.exe" //B //NoLogo "%VBS%"

REM Wait for the server.
for /l %%N in (1,1,30) do (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
     "try { $r=Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:5000/health' -TimeoutSec 1; if($r.StatusCode -eq 200){exit 0}else{exit 1} } catch { exit 1 }"
    if not errorlevel 1 (
        echo [OK] Server is running.
        echo [OK] Browser opening...
        start "" "http://127.0.0.1:5000"
        echo.
        echo Future Windows restarts will start MIMI Baby Studio silently
        echo in the background.
        exit /b 0
    )
    timeout /t 1 /nobreak >nul
)

echo.
echo [ERROR] Server did not start.
echo Run debug_server.bat to diagnose the problem.
echo.
pause
exit /b 1
