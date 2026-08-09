@echo off
setlocal
set "BASE=%~dp0"

if not exist "%BASE%SettingsGui.ps1" (
    echo ОШИБКА: рядом не найден SettingsGui.ps1
    pause
    exit /b 1
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -STA ^
    -WindowStyle Hidden ^
    -File "%BASE%SettingsGui.ps1" ^
    -SettingsFile "%BASE%settings.json"

exit /b %ERRORLEVEL%
