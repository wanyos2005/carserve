# 🚀 Google Play Store Setup Script for DriveOn Car Platform (PowerShell)
# This script helps automate the initial setup process on Windows

Write-Host "🚀 Starting Google Play Store Setup for DriveOn Car Platform..." -ForegroundColor Green
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "frontend/pubspec.yaml")) {
    Write-Host "❌ Error: Please run this script from the project root directory" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Phase 1: App Identity & Branding" -ForegroundColor Yellow
Write-Host "==================================" -ForegroundColor Yellow

# Backup original files
Write-Host "📦 Creating backups..." -ForegroundColor Blue
Copy-Item "frontend/android/app/build.gradle.kts" "frontend/android/app/build.gradle.kts.backup"
Copy-Item "frontend/android/app/src/main/AndroidManifest.xml" "frontend/android/app/src/main/AndroidManifest.xml.backup"
Copy-Item "frontend/pubspec.yaml" "frontend/pubspec.yaml.backup"

Write-Host "✅ Backups created" -ForegroundColor Green

# Update application ID
Write-Host "🔧 Updating application ID..." -ForegroundColor Blue
$buildGradleContent = Get-Content "frontend/android/app/build.gradle.kts" -Raw
$buildGradleContent = $buildGradleContent -replace 'applicationId = "com.example.car_platform"', 'applicationId = "com.driveon.carplatform"'
Set-Content "frontend/android/app/build.gradle.kts" $buildGradleContent

# Update app label
Write-Host "🏷️  Updating app label..." -ForegroundColor Blue
$manifestContent = Get-Content "frontend/android/app/src/main/AndroidManifest.xml" -Raw
$manifestContent = $manifestContent -replace 'android:label="car_platform"', 'android:label="DriveOn"'
Set-Content "frontend/android/app/src/main/AndroidManifest.xml" $manifestContent

# Update pubspec.yaml
Write-Host "📝 Updating pubspec.yaml..." -ForegroundColor Blue
$pubspecContent = @"
name: driveon_car_platform
description: "DriveOn - Your comprehensive car service platform. Book services, manage insurance, track expenses, and connect with the automotive community."
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.9.2

dependencies:
  flutter:
    sdk: flutter
  http: ^1.5.0
  shared_preferences: ^2.5.3
  palette_generator: ^0.3.3
  marquee: ^2.2.3
  cupertino_icons: ^1.0.8
  intl: ^0.19.0
  url_launcher: ^6.3.1
  geolocator: ^12.0.0
  permission_handler: ^11.3.1
  image_picker: ^1.1.2
  web_socket_channel: ^2.4.0
  firebase_messaging: ^15.1.3
  firebase_core: ^3.6.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true

  assets:
    - assets/fonts/
    - assets/images/
    - assets/car_models.json

  fonts:
    - family: Poppins
      fonts:
        - asset: assets/fonts/Poppins-Regular.ttf
        - asset: assets/fonts/Poppins-Medium.ttf
          weight: 500
        - asset: assets/fonts/Poppins-Bold.ttf
          weight: 700
"@
Set-Content "frontend/pubspec.yaml" $pubspecContent

Write-Host "✅ App identity updated" -ForegroundColor Green

Write-Host ""
Write-Host "📋 Phase 2: Build Configuration" -ForegroundColor Yellow
Write-Host "===============================" -ForegroundColor Yellow

# Create key.properties template
Write-Host "🔑 Creating key.properties template..." -ForegroundColor Blue
$keyPropertiesContent = @"
# Replace these values with your actual keystore information
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=driveon-key-alias
storeFile=../driveon-release-key.keystore
"@
Set-Content "frontend/android/key.properties" $keyPropertiesContent

# Create ProGuard rules
Write-Host "🛡️  Creating ProGuard rules..." -ForegroundColor Blue
$proguardContent = @"
# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep your app's specific classes
-keep class com.driveon.carplatform.** { *; }
"@
Set-Content "frontend/android/app/proguard-rules.pro" $proguardContent

Write-Host "✅ Build configuration files created" -ForegroundColor Green

Write-Host ""
Write-Host "📋 Phase 3: Firebase Setup Instructions" -ForegroundColor Yellow
Write-Host "======================================" -ForegroundColor Yellow
Write-Host "🔥 Firebase Setup Required:" -ForegroundColor Red
Write-Host "1. Go to https://console.firebase.google.com/" -ForegroundColor White
Write-Host "2. Create new project: 'DriveOn Car Platform'" -ForegroundColor White
Write-Host "3. Add Android app with package: com.driveon.carplatform" -ForegroundColor White
Write-Host "4. Download google-services.json" -ForegroundColor White
Write-Host "5. Place it in: frontend/android/app/google-services.json" -ForegroundColor White
Write-Host ""

Write-Host "📋 Phase 4: Next Steps" -ForegroundColor Yellow
Write-Host "=====================" -ForegroundColor Yellow
Write-Host "✅ Completed:" -ForegroundColor Green
Write-Host "   - App identity updated" -ForegroundColor White
Write-Host "   - Build configuration prepared" -ForegroundColor White
Write-Host "   - Backup files created" -ForegroundColor White
Write-Host ""
Write-Host "🔄 Manual Steps Required:" -ForegroundColor Yellow
Write-Host "   1. Generate release keystore (see GOOGLE_PLAY_STORE_READINESS_GUIDE.md)" -ForegroundColor White
Write-Host "   2. Update key.properties with actual values" -ForegroundColor White
Write-Host "   3. Set up Firebase project and download google-services.json" -ForegroundColor White
Write-Host "   4. Create custom app icons" -ForegroundColor White
Write-Host "   5. Create privacy policy" -ForegroundColor White
Write-Host "   6. Take app screenshots" -ForegroundColor White
Write-Host ""
Write-Host "📖 For detailed instructions, see: GOOGLE_PLAY_STORE_READINESS_GUIDE.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎉 Initial setup complete! Follow the guide for remaining steps." -ForegroundColor Green
