@echo off
setlocal
echo ===============================================================
echo   Antigravity Logistics: Automated Production Build Pipeline
echo ===============================================================

where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [!] Flutter CLI was not detected in your PATH environment variable.
    echo Please install Flutter SDK from https://docs.flutter.dev/get-started/install/windows
    echo and add your flutter\bin folder to PATH (e.g. C:\src\flutter\bin).
    exit /b 1
)

echo.
echo [1/3] Resolving dependencies with flutter pub get...
call flutter pub get

echo.
echo [2/3] Compiling Windows Native Release Executable (.exe)...
call flutter config --enable-windows-desktop
call flutter build windows --release

echo.
echo [3/3] Compiling Android Release APKs (.apk)...
call flutter build apk --release --split-per-abi

echo.
echo ===============================================================
echo   Build Pipeline Completed Successfully!
echo   Windows EXE: %~dp0build\windows\x64\runner\Release\antigravity_logistics_app.exe
echo   Android APK: %~dp0build\app\outputs\flutter-apk\app-release.apk
echo ===============================================================
