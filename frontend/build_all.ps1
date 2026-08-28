# PowerShell Production Build Script for Antigravity Logistics Platform
# Author: Antigravity Multi-Agent Development Team

Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host " 🚀 Antigravity Logistics: Full Production Build Pipeline" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan

$frontendDir = "$PSScriptRoot"
Set-Location $frontendDir

# 1. Check Flutter installation
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCmd) {
    Write-Host "⚠️ Flutter CLI not found in current PATH." -ForegroundColor Yellow
    Write-Host "Please ensure Flutter SDK is installed and added to PATH (e.g. C:\src\flutter\bin)." -ForegroundColor Yellow
    Write-Host "You can download Flutter from: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
    exit 1
}

Write-Host "📦 Step 1: Resolving Flutter Dependencies..." -ForegroundColor Green
flutter pub get

# 2. Build Windows .exe Release
Write-Host "🖥️ Step 2: Compiling Windows Desktop Release (.exe)..." -ForegroundColor Green
flutter config --enable-windows-desktop
flutter build windows --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Windows .exe built successfully!" -ForegroundColor Green
    Write-Host "📍 Absolute Path: $frontendDir\build\windows\x64\runner\Release\antigravity_logistics_app.exe" -ForegroundColor Yellow
} else {
    Write-Host "❌ Windows build failed." -ForegroundColor Red
}

# 3. Build Android .apk Release
Write-Host "📱 Step 3: Compiling Android Mobile Release (.apk)..." -ForegroundColor Green
flutter build apk --release --split-per-abi

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Android APK built successfully!" -ForegroundColor Green
    Write-Host "📍 Absolute Path: $frontendDir\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk" -ForegroundColor Yellow
    Write-Host "📍 Universal APK: $frontendDir\build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Yellow
} else {
    Write-Host "❌ Android APK build failed." -ForegroundColor Red
}

Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host " ✨ Production Build Process Completed!" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
