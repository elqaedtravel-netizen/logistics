@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
echo ===============================================================
echo   🚀 Antigravity Logistics: GitHub Cloud Build Setup
echo ===============================================================
echo.

:: 1. Check Git
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [!] Git is not found in your PATH.
    echo [*] Attempting automated installation via Windows Package Manager (winget)...
    winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements
    if %errorlevel% neq 0 (
        echo [X] Could not install Git automatically.
        echo Please download and install Git from: https://git-scm.com/download/win
        echo After installing, restart this script.
        pause
        exit /b 1
    )
    echo [✓] Git installed successfully! Refreshing PATH...
    set "PATH=C:\Program Files\Git\cmd;%PATH%"
)

:: 2. Initialize Git
echo [*] Initializing Git repository...
git init
git config user.name "Antigravity Dev"
git config user.email "dev@antigravity.io"
git checkout -B main

:: 3. Stage and Commit
echo [*] Staging all project files...
git add .
git commit -m "feat: complete Logistics & E-Commerce Platform with Backend, Arabic RTL Flutter UI, and GitHub Actions Cloud CI/CD"

echo.
echo ===============================================================
echo   [✓] Local repository committed successfully!
echo ===============================================================
echo.
echo Please create a new free private repository on https://github.com/new
echo (e.g. named: logistics-platform)
echo.
set /p REPO_URL="Enter your GitHub Repository URL (e.g. https://github.com/YOUR_USER/logistics-platform.git): "

if "!REPO_URL!"=="" (
    echo [!] No URL entered. You can push manually later with:
    echo     git remote add origin YOUR_URL
    echo     git push -u origin main
    pause
    exit /b 0
)

echo [*] Adding remote origin and pushing to GitHub...
git remote remove origin >nul 2>nul
git remote add origin !REPO_URL!
git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo ===============================================================
    echo   🎉 SUCCESS! Code pushed to GitHub!
    echo   The GitHub Actions Cloud Build has started automatically.
    echo   Go to the "Actions" tab on your GitHub repository to download:
    echo   - Admin-Panel-Windows-x64-Release (.exe)
    echo   - Driver-App-Android-APKs (.apk)
    echo ===============================================================
) else (
    echo [X] Push failed. Please check your GitHub credentials or repository URL.
)

pause
