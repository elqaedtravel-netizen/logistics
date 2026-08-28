# 📦 Antigravity Logistics Release Artifacts & Output Paths

This document specifies the exact local paths where your production release executables and mobile packages are generated upon running `flutter build`.

---

## 🖥️ 1. Windows Admin Panel Executable (.exe)
- **Compilation Command**:
  ```powershell
  cd C:\Users\LENOVO\.gemini\antigravity\scratch\logistics-ecommerce-platform\frontend
  flutter build windows --release
  ```
- **Exact Absolute Location**:
  `C:\Users\LENOVO\.gemini\antigravity\scratch\logistics-ecommerce-platform\frontend\build\windows\x64\runner\Release\antigravity_logistics_app.exe`
- **Required Accompanying Files** (in same folder):
  - `flutter_windows.dll`
  - `data/` folder (assets, fonts, icudtl.dat)
- **Deployment**:
  Copy the entire `Release/` directory or zip it to distribute the standalone Windows Desktop application.

---

## 📱 2. Driver Mobile Application APK (.apk)
- **Compilation Command**:
  ```bash
  cd C:\Users\LENOVO\.gemini\antigravity\scratch\logistics-ecommerce-platform\frontend
  flutter build apk --release --split-per-abi
  ```
- **Exact Absolute Locations**:
  - **Universal Release APK**:
    `C:\Users\LENOVO\.gemini\antigravity\scratch\logistics-ecommerce-platform\frontend\build\app\outputs\flutter-apk\app-release.apk`
  - **ARM64 (Modern Android Phones)**:
    `C:\Users\LENOVO\.gemini\antigravity\scratch\logistics-ecommerce-platform\frontend\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk`
  - **ARM v7a (Older Android Devices)**:
    `C:\Users\LENOVO\.gemini\antigravity\scratch\logistics-ecommerce-platform\frontend\build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk`

---

## 🚀 3. Automated One-Click Compilation
Run the automated build script on any development terminal with Flutter:
- **PowerShell**:
  ```powershell
  .\frontend\build_all.ps1
  ```
- **Batch Script**:
  ```cmd
  frontend\build_all.bat
  ```
