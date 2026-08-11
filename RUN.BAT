@echo off
chcp 65001 >nul
setlocal

set "BASE=%~dp0"
set "SCRIPT=%BASE%SquarePhotos.ps1"
set "SETTINGS=%BASE%settings.json"
set "SETTINGS_LAUNCHER=%BASE%Settings.bat"

if not exist "%SCRIPT%" (
    echo ОШИБКА: рядом не найден SquarePhotos.ps1
    pause
    exit /b 1
)

if not exist "%SETTINGS_LAUNCHER%" (
    echo ОШИБКА: рядом не найден Settings.bat
    pause
    exit /b 1
)

if not exist "%SETTINGS%" (
    echo Настройки ещё не созданы.
    echo Сейчас откроется окно настроек.
    call "%SETTINGS_LAUNCHER%"
)

if not exist "%SETTINGS%" (
    echo.
    echo ОШИБКА: настройки не были сохранены.
    pause
    exit /b 1
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass ^
    -File "%SCRIPT%" ^
    -SettingsFile "%SETTINGS%"

set "CODE=%ERRORLEVEL%"

echo.
if "%CODE%"=="0" (
    echo Обработка завершена.
) else (
    echo Обработка завершена с ошибкой. Код: %CODE%
)

pause
exit /b %CODE%
