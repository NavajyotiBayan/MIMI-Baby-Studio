@echo off
setlocal
cd /d "%~dp0"
set "PY="
where py >nul 2>&1 && set "PY=py -3"
if not defined PY where python >nul 2>&1 && set "PY=python"
if not defined PY (
  echo Python was not found.
  pause
  exit /b 1
)
echo Starting server in diagnostic mode...
echo Keep this window open while testing http://127.0.0.1:5000
%PY% app.py
pause
