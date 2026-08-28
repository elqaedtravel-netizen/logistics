@echo off
set "GIT_EXE=C:\Users\LENOVO\.gemini\antigravity\scratch\mingit\cmd\git.exe"
cd /d "C:\Users\LENOVO\.gemini\antigravity\scratch\logistics-ecommerce-platform"

echo ===============================================================
echo   Pushing project to https://github.com/elqaedtravel-netizen/logistics.git
echo ===============================================================
echo.

"%GIT_EXE%" push -u origin main

echo.
echo ===============================================================
echo Press any key to exit...
echo ===============================================================
pause >nul
