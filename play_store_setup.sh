#!/bin/bash

# 🚀 Google Play Store Setup Script for DriveOn Car Platform
# This script helps automate the initial setup process

echo "🚀 Starting Google Play Store Setup for DriveOn Car Platform..."
echo ""

# Check if we're in the right directory
if [ ! -f "frontend/pubspec.yaml" ]; then
    echo "❌ Error: Please run this script from the project root directory"
    exit 1
fi

echo "📋 Phase 1: App Identity & Branding"
echo "=================================="

# Backup original files
echo "📦 Creating backups..."
cp frontend/android/app/build.gradle.kts frontend/android/app/build.gradle.kts.backup
cp frontend/android/app/src/main/AndroidManifest.xml frontend/android/app/src/main/AndroidManifest.xml.backup
cp frontend/pubspec.yaml frontend/pubspec.yaml.backup

echo "✅ Backups created"

# Update application ID
echo "🔧 Updating application ID..."
sed -i 's/applicationId = "com.example.car_platform"/applicationId = "com.driveon.carplatform"/' frontend/android/app/build.gradle.kts

# Update app label
echo "🏷️  Updating app label..."
sed -i 's/android:label="car_platform"/android:label="DriveOn"/' frontend/android/app/src/main/AndroidManifest.xml

# Update pubspec.yaml
echo "📝 Updating pubspec.yaml..."
cat > frontend/pubspec.yaml << 'EOF'
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
EOF

echo "✅ App identity updated"

echo ""
echo "📋 Phase 2: Build Configuration"
echo "==============================="

# Create key.properties template
echo "🔑 Creating key.properties template..."
cat > frontend/android/key.properties << 'EOF'
# Replace these values with your actual keystore information
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=driveon-key-alias
storeFile=../driveon-release-key.keystore
EOF

# Create ProGuard rules
echo "🛡️  Creating ProGuard rules..."
cat > frontend/android/app/proguard-rules.pro << 'EOF'
# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep your app's specific classes
-keep class com.driveon.carplatform.** { *; }
EOF

echo "✅ Build configuration files created"

echo ""
echo "📋 Phase 3: Firebase Setup Instructions"
echo "======================================"
echo "🔥 Firebase Setup Required:"
echo "1. Go to https://console.firebase.google.com/"
echo "2. Create new project: 'DriveOn Car Platform'"
echo "3. Add Android app with package: com.driveon.carplatform"
echo "4. Download google-services.json"
echo "5. Place it in: frontend/android/app/google-services.json"
echo ""

echo "📋 Phase 4: Next Steps"
echo "====================="
echo "✅ Completed:"
echo "   - App identity updated"
echo "   - Build configuration prepared"
echo "   - Backup files created"
echo ""
echo "🔄 Manual Steps Required:"
echo "   1. Generate release keystore (see GOOGLE_PLAY_STORE_READINESS_GUIDE.md)"
echo "   2. Update key.properties with actual values"
echo "   3. Set up Firebase project and download google-services.json"
echo "   4. Create custom app icons"
echo "   5. Create privacy policy"
echo "   6. Take app screenshots"
echo ""
echo "📖 For detailed instructions, see: GOOGLE_PLAY_STORE_READINESS_GUIDE.md"
echo ""
echo "🎉 Initial setup complete! Follow the guide for remaining steps."
