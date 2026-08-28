# PowerShell Automated Windows Desktop Build Script
Write-Host "🚀 Building Antigravity Logistics Windows Release (.exe)..." -ForegroundColor Cyan

# 1. Ensure Flutter is on PATH and dependencies are up to date
flutter pub get

# 2. Compile Windows Native x64 Executable
flutter build windows --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Windows Build Succeeded!" -ForegroundColor Green
    Write-Host "📁 Output Directory: frontend/build/windows/x64/runner/Release" -ForegroundColor Yellow
} else {
    Write-Host "❌ Windows Build Failed." -ForegroundColor Red
    exit 1
}
