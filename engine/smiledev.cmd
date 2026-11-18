@echo off
setlocal
set "SCRIPT_DIR=%~dp0"

if exist "C:\Program Files\Git\bin\bash.exe" (
    "C:\Program Files\Git\bin\bash.exe" "%SCRIPT_DIR%smiledev" %*
    exit /b %ERRORLEVEL%
)
if exist "C:\Program Files (x86)\Git\bin\bash.exe" (
    "C:\Program Files (x86)\Git\bin\bash.exe" "%SCRIPT_DIR%smiledev" %*
    exit /b %ERRORLEVEL%
)
if exist "C:\msys64\usr\bin\bash.exe" (
    "C:\msys64\usr\bin\bash.exe" "%SCRIPT_DIR%smiledev" %*
    exit /b %ERRORLEVEL%
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%smiledev.ps1" %*
exit /b %ERRORLEVEL%
