@echo off
setlocal
cd /d "%~dp0"
title MP4 to PDF - Repair Dependencies

echo.
echo MP4 TO PDF - DEPENDENCY REPAIR
echo.

where winget >nul 2>&1
if errorlevel 1 (
  echo WinGet is not available.
  pause
  exit /b 1
)

echo Installing/updating Python...
winget install --id Python.Python.3.13 -e --accept-source-agreements --accept-package-agreements

echo.
echo Installing/updating FFmpeg...
winget install --id Gyan.FFmpeg -e --accept-source-agreements --accept-package-agreements

echo.
where py >nul 2>&1
if not errorlevel 1 (
  py -m pip install --upgrade --user -r requirements.txt
) else (
  python -m pip install --upgrade --user -r requirements.txt
)

echo.
echo Repair complete. Run start.bat.
pause
endlocal
