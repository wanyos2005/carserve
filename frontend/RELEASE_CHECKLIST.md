# Release Checklist for Google Play Store Closed Testing

## Step 1: Update Version Number ✅
- Version updated in `pubspec.yaml`: `1.0.3+9`
- Format: `VERSION_NAME+BUILD_NUMBER`
  - `1.0.3` = Version name (visible to users)
  - `9` = Build number (must increment for each upload)

## Step 2: Build the App Bundle

### Option A: Using Flutter CLI (Recommended)
```bash
cd frontend

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release app bundle (for Play Store)
flutter build appbundle --release

# The output will be at:
# frontend/build/app/outputs/bundle/release/app-release.aab
```

### Option B: Using Android Studio
1. Open project in Android Studio
2. Go to **Build** → **Flutter** → **Build App Bundle**
3. Or use **Build** → **Generate Signed Bundle / APK** → Select **Android App Bundle**

## Step 3: Upload to Google Play Console

1. **Go to Google Play Console**
   - Navigate to: https://play.google.com/console
   - Select your app: **DriveOn Car Platform**

2. **Navigate to Testing Track**
   - Go to **Testing** → **Closed testing** (or **Internal testing**)
   - Select your testing track

3. **Create New Release**
   - Click **Create new release**
   - Enter release name: `1.0.3` (or descriptive name like "UI Theme Updates")
   - Enter release notes (what's new):
     ```
     ✨ What's New in v1.0.3:
     - Enhanced dark mode support across all pages
     - Improved theme consistency throughout the app
     - Better color contrast and readability
     - UI improvements for vehicle list and insurance dashboard
     ```

4. **Upload App Bundle**
   - Click **Upload** or drag and drop
   - Select: `frontend/build/app/outputs/bundle/release/app-release.aab`
   - Wait for upload and processing to complete

5. **Review Release**
   - Check that version code matches (should be 9)
   - Review release notes
   - Ensure all required checks pass

6. **Save and Rollout**
   - Click **Save**
   - Click **Review release**
   - Review everything one more time
   - Click **Start rollout to Closed testing**

## Step 4: Notify Testers (Optional)

Testers will be notified automatically if you have notifications enabled, or you can:
- Go to **Testers** tab
- Share the testing link if needed
- Send email notification

## Important Notes:

⚠️ **Version Code Rules:**
- Each new upload MUST have a higher build number than the previous one
- Current build number: `9` → Next release should be `10` or higher
- You CANNOT upload a bundle with the same or lower build number

⚠️ **Version Name:**
- Version name (1.0.3) can be any string, but should follow semantic versioning
- Same version name with different build numbers is allowed
- Users see the version name in the Play Store

⚠️ **Testing Timeframe:**
- Internal testing: Usually available within minutes
- Closed testing: Can take a few hours to propagate
- Open testing/Production: Requires review (can take days)

## Quick Version Bump Commands

For future releases, increment the build number:

```bash
# Edit pubspec.yaml manually, or use sed (Linux/Mac):
sed -i 's/version:.*+/version: 1.0.3+10/' pubspec.yaml

# Then build:
flutter clean && flutter pub get && flutter build appbundle --release
```

## Troubleshooting

**Issue: "Version code already used"**
- Solution: Increment the build number in `pubspec.yaml`

**Issue: Bundle too large**
- Check: `flutter build appbundle --release --analyze-size`
- Consider splitting by ABI or enabling app size optimization

**Issue: Signing errors**
- Ensure your `key.properties` file is configured correctly
- Check that your keystore file exists and is accessible

## Release History Template

```
v1.0.3+9 - Current
- Dark mode improvements
- Theme consistency updates
- UI enhancements

v1.0.2+8 - Previous release
- [Previous features]
```

