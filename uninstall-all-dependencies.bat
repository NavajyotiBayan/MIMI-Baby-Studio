@echo off
setlocal EnableExtensions
set "INSTALL_DIR=C:\MIMI Baby Studio"
cd /d "%~dp0"
title MIMI Baby Studio - Clean Test Reset

echo.
echo ============================================================
echo        MIMI BABY STUDIO v2 - CLEAN TEST RESET
echo ============================================================
echo.
echo This will stop the server, remove Flask/Pillow, uninstall
 echo FFmpeg and Python 3.13 if installed by WinGet, remove
 echo startup/launcher registration, and clear temporary files.
echo It will NOT delete C:\MIMI Baby Studio itself.
echo.
set /p "CONFIRM=Continue? Type YES to continue: "
if /I not "%CONFIRM%"=="YES" (echo Cancelled.& pause& exit /b 0)

echo [1/5] Stopping MIMI Baby Studio...
for /f "tokens=5" %%P in ('netstat -ano ^| findstr ":5000" ^| findstr "LISTENING"') do taskkill /F /PID %%P >nul 2>&1

echo [2/5] Removing Flask and Pillow...
where python.exe >nul 2>&1 && python.exe -m pip uninstall -y Flask Pillow >nul 2>&1

echo [3/5] Removing FFmpeg and Python 3.13 installed by WinGet...
where winget.exe >nul 2>&1 && winget uninstall --id Gyan.FFmpeg -e --silent --accept-source-agreements >nul 2>&1
where winget.exe >nul 2>&1 && winget uninstall --id Python.Python.3.13 -e --silent --accept-source-agreements >nul 2>&1

echo [4/5] Removing startup and launcher registration...
if exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\MIMI Baby Studio.lnk" del /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\MIMI Baby Studio.lnk" >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "Remove-Item -Path 'HKCU:\Software\Classes\mimibaby' -Recurse -Force -ErrorAction SilentlyContinue" >nul 2>&1

echo [5/5] Clearing temporary files and logs...
if exist "%INSTALL_DIR%\temp" rmdir /s /q "%INSTALL_DIR%\temp" >nul 2>&1
if exist "%INSTALL_DIR%\__pycache__" rmdir /s /q "%INSTALL_DIR%\__pycache__" >nul 2>&1
if exist "%INSTALL_DIR%\server.log" del /q "%INSTALL_DIR%\server.log" >nul 2>&1
if exist "%INSTALL_DIR%\setup.log" del /q "%INSTALL_DIR%\setup.log" >nul 2>&1

 echo.
echo ============================================================
echo                 CLEAN RESET COMPLETE
echo ============================================================
echo.
echo The application folder remains at:
echo   %INSTALL_DIR%
echo.
echo Run start.bat to perform a fresh dependency setup.
echo.
pause
endlocal
