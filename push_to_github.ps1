# PowerShell Git Push Automation for Antigravity Logistics
$repoUrl = "https://github.com/elqaedtravel-netizen/logistics-ecommerce-platform.git"
$projectDir = "C:\Users\LENOVO\.gemini\antigravity\scratch\logistics-ecommerce-platform"
$gitExe = "C:\Users\LENOVO\.gemini\antigravity\scratch\mingit\cmd\git.exe"

if (-not (Test-Path $gitExe)) {
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) {
        $gitExe = $gitCmd.Source
    }
}

Write-Host "🚀 Using Git at: $gitExe" -ForegroundColor Cyan
Set-Location $projectDir

& $gitExe init
& $gitExe config user.name "Antigravity Dev"
& $gitExe config user.email "dev@antigravity.io"
& $gitExe checkout -B main
& $gitExe add .
& $gitExe commit -m "feat: complete Logistics & E-Commerce Platform with Backend, RTL Flutter UI, and GitHub Actions Cloud CI/CD"

& $gitExe remote remove origin 2>$null
& $gitExe remote add origin $repoUrl
Write-Host "📤 Pushing code to $repoUrl..." -ForegroundColor Yellow
& $gitExe push -u origin main
