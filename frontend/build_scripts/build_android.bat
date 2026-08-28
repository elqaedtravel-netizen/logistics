@echo off
echo ===================================================
echo 🚀 Building Antigravity Logistics Android (.apk & .aab)
echo ===================================================

call flutter pub get

echo 📦 Building Splitted Release APKs...
call flutter build apk --release --split-per-abi

echo 📦 Building Android App Bundle (AAB)...
call flutter build appbundle --release

echo ===================================================
echo ✅ Android Build Finished!
echo APK Outputs: frontend/build/app/outputs/flutter-apk/
echo AAB Outputs: frontend/build/app/outputs/bundle/release/
echo ===================================================
