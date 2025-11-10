#!/usr/bin/env python3
"""
DriveOn Icon Resizer
Resizes a source image to all required Android icon sizes
"""

import sys
import os
from PIL import Image

def resize_icon(source_path, output_dir="frontend/android/app/src/main/res"):
    """Resize source image to all required Android icon sizes"""
    
    # Check if source image exists
    if not os.path.exists(source_path):
        print(f"❌ Error: Source image not found: {source_path}")
        return False
    
    print(f"📁 Source image: {source_path}")
    print(f"📂 Output directory: {output_dir}")
    print()
    
    # Define the required sizes and their directories
    icon_sizes = [
        {"size": 48, "dir": "mipmap-mdpi", "name": "ic_launcher.png"},
        {"size": 72, "dir": "mipmap-hdpi", "name": "ic_launcher.png"},
        {"size": 96, "dir": "mipmap-xhdpi", "name": "ic_launcher.png"},
        {"size": 144, "dir": "mipmap-xxhdpi", "name": "ic_launcher.png"},
        {"size": 192, "dir": "mipmap-xxxhdpi", "name": "ic_launcher.png"}
    ]
    
    print("🔄 Resizing icons...")
    print()
    
    try:
        # Load the source image
        source_image = Image.open(source_path)
        print(f"📏 Original image size: {source_image.size}")
        
        for icon in icon_sizes:
            target_dir = os.path.join(output_dir, icon["dir"])
            target_file = os.path.join(target_dir, icon["name"])
            
            print(f"Creating {icon['dir']} ({icon['size']}x{icon['size']}px)...")
            
            # Create directory if it doesn't exist
            os.makedirs(target_dir, exist_ok=True)
            
            # Backup original if it exists
            if os.path.exists(target_file):
                backup_file = f"{target_file}.backup"
                if os.path.exists(backup_file):
                    os.remove(backup_file)  # Remove existing backup
                os.rename(target_file, backup_file)
                print(f"   Backed up original: {backup_file}")
            
            # Resize the image
            resized_image = source_image.resize((icon["size"], icon["size"]), Image.Resampling.LANCZOS)
            
            # Save as PNG
            resized_image.save(target_file, "PNG")
            
            # Get file size for verification
            file_size = os.path.getsize(target_file)
            print(f"   Created: {target_file} ({file_size} bytes)")
        
        # Also create Play Store 512x512 icon
        print("\n🎯 Creating Play Store 512x512 app icon...")
        playstore_dir = os.path.join("playstore-assets")
        os.makedirs(playstore_dir, exist_ok=True)
        app_icon_512 = os.path.join(playstore_dir, "app_icon_512.png")
        icon_512 = source_image.resize((512, 512), Image.Resampling.LANCZOS)
        icon_512.save(app_icon_512, "PNG")
        file_size_512 = os.path.getsize(app_icon_512)
        print(f"   Created: {app_icon_512} ({file_size_512} bytes)")
        
        print()
        print("✅ Icon resize complete!")
        print()
        print("Next steps:")
        print("1. Upload playstore-assets/app_icon_512.png as the Play Console App icon (512×512)")
        print("2. Test launcher icons: cd frontend; flutter build apk --debug")
        print("3. Install on device/emulator to verify launcher icon looks correct")
        
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python resize_icons.py <source_image_path> [output_dir]")
        print("Example: python resize_icons.py assets/images/logo.png")
        sys.exit(1)
    
    source_path = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else "frontend/android/app/src/main/res"
    
    success = resize_icon(source_path, output_dir)
    sys.exit(0 if success else 1)
