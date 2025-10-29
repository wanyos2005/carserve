#!/bin/bash

# DriveOn Icon Resizer - Bash Version
# Resizes a source image to all required Android icon sizes

set -e

SOURCE_IMAGE="$1"
OUTPUT_DIR="${2:-frontend/android/app/src/main/res}"

echo "🎨 DriveOn Icon Resizer (Bash)"
echo "=============================="
echo ""

# Check if source image exists
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "❌ Error: Source image not found: $SOURCE_IMAGE"
    echo "Usage: $0 <source_image_path> [output_dir]"
    echo "Example: $0 frontend/assets/images/logo.png"
    exit 1
fi

echo "📁 Source image: $SOURCE_IMAGE"
echo "📂 Output directory: $OUTPUT_DIR"
echo ""

# Check if ImageMagick is available
if command -v convert >/dev/null 2>&1; then
    echo "✅ ImageMagick found - using convert command"
    USE_IMAGEMAGICK=true
elif command -v magick >/dev/null 2>&1; then
    echo "✅ ImageMagick found - using magick command"
    USE_IMAGEMAGICK=true
    CONVERT_CMD="magick convert"
else
    echo "⚠️  ImageMagick not found - will use online tools"
    USE_IMAGEMAGICK=false
fi

# Define the required sizes and their directories
declare -A icon_sizes=(
    ["mipmap-mdpi"]="48"
    ["mipmap-hdpi"]="72"
    ["mipmap-xhdpi"]="96"
    ["mipmap-xxhdpi"]="144"
    ["mipmap-xxxhdpi"]="192"
)

echo "🔄 Resizing icons..."
echo ""

if [ "$USE_IMAGEMAGICK" = true ]; then
    # Use ImageMagick to resize
    for dir in "${!icon_sizes[@]}"; do
        size="${icon_sizes[$dir]}"
        target_dir="$OUTPUT_DIR/$dir"
        target_file="$target_dir/ic_launcher.png"
        
        echo "Creating $dir (${size}x${size}px)..."
        
        # Create directory if it doesn't exist
        mkdir -p "$target_dir"
        
        # Backup original if it exists
        if [ -f "$target_file" ]; then
            cp "$target_file" "$target_file.backup"
            echo "   Backed up original: $target_file.backup"
        fi
        
        # Resize using ImageMagick
        if [ -n "$CONVERT_CMD" ]; then
            $CONVERT_CMD "$SOURCE_IMAGE" -resize "${size}x${size}" "$target_file"
        else
            convert "$SOURCE_IMAGE" -resize "${size}x${size}" "$target_file"
        fi
        
        # Get file size for verification
        file_size=$(stat -c%s "$target_file" 2>/dev/null || stat -f%z "$target_file" 2>/dev/null || echo "unknown")
        echo "   Created: $target_file ($file_size bytes)"
    done
else
    # Provide instructions for manual resizing
    echo "📋 Manual Resizing Required"
    echo "=========================="
    echo ""
    echo "Since ImageMagick is not available, please use one of these online tools:"
    echo ""
    echo "1. 🌐 App Icon Generator (Recommended):"
    echo "   https://appicon.co/"
    echo "   - Upload your logo.png"
    echo "   - Download Android icons"
    echo "   - Extract and place in appropriate directories"
    echo ""
    echo "2. 🌐 Canva:"
    echo "   https://canva.com"
    echo "   - Create custom graphics"
    echo "   - Export in required sizes"
    echo ""
    echo "3. 🌐 Online Convert:"
    echo "   https://online-convert.com"
    echo "   - Convert and resize images"
    echo ""
    echo "📁 Required directories and sizes:"
    for dir in "${!icon_sizes[@]}"; do
        size="${icon_sizes[$dir]}"
        echo "   $OUTPUT_DIR/$dir/ic_launcher.png (${size}x${size}px)"
    done
    echo ""
    echo "After creating the icons, place them in the correct directories above."
fi

echo ""
echo "✅ Icon resize process complete!"
echo ""
echo "Next steps:"
echo "1. Test the icons: cd frontend; flutter build apk --debug"
echo "2. Install on device/emulator to verify"
echo "3. Check icon appears correctly on home screen"
echo ""
echo "If you used online tools, make sure to place the resized icons in:"
echo "   $OUTPUT_DIR/mipmap-*/ic_launcher.png"
