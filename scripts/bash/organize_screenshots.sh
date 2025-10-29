#!/bin/bash

# organize_screenshots.sh
# Bash script to help organize screenshots for Play Store submission

echo "📸 DriveOn Screenshots Organizer"
echo "================================="

# Get screenshot counts
PHONE_COUNT=$(ls frontend/screenshots/phone/*.jpg 2>/dev/null | wc -l)
TABLET_COUNT=$(ls frontend/screenshots/tablet/*.jpg 2>/dev/null | wc -l)

echo ""
echo "📱 Phone Screenshots Found: $PHONE_COUNT"
echo "📱 Tablet Screenshots Found: $TABLET_COUNT"

# Show phone screenshots with timestamps
echo ""
echo "📋 Current Phone Screenshots:"
ls -la frontend/screenshots/phone/*.jpg | awk '{print "  - " $9 " (" $6 " " $7 " " $8 ")"}'

# Show tablet screenshots if any
if [ $TABLET_COUNT -gt 0 ]; then
    echo ""
    echo "📋 Current Tablet Screenshots:"
    ls -la frontend/screenshots/tablet/*.jpg | awk '{print "  - " $9 " (" $6 " " $7 " " $8 ")"}'
fi

echo ""
echo "🎯 Required Screenshot Sequence:"
echo "1. 01_welcome_login.png - Welcome/Login Screen"
echo "2. 02_home_dashboard.png - Home Dashboard"
echo "3. 03_service_booking.png - Service Booking Flow"
echo "4. 04_insurance_marketplace.png - Insurance Marketplace"
echo "5. 05_social_hub.png - Social Hub"
echo "6. 06_provider_details.png - Provider Details"
echo "7. 07_vehicle_management.png - Vehicle Management"
echo "8. 08_expense_tracking.png - Expense Tracking"

echo ""
echo "💡 Next Steps:"
echo "1. Review your screenshots and identify which ones match each required screen"
echo "2. Rename them to match the required naming convention"
echo "3. Convert to PNG format if needed"
echo "4. Ensure they meet Google Play Store requirements"

echo ""
echo "📖 For detailed requirements, see: SCREENSHOTS_GUIDE.md"

# Create organized directories
mkdir -p frontend/screenshots/organized/phone
mkdir -p frontend/screenshots/organized/tablet

echo ""
echo "✅ Created organized directories:"
echo "   - frontend/screenshots/organized/phone/"
echo "   - frontend/screenshots/organized/tablet/"

echo ""
echo "🔧 Helper Commands:"
echo "   # Convert JPG to PNG:"
echo "   convert frontend/screenshots/phone/Screenshot_20251026_191353.jpg frontend/screenshots/organized/phone/01_welcome_login.png"
echo ""
echo "   # Rename and organize:"
echo "   cp frontend/screenshots/phone/Screenshot_20251026_191353.jpg frontend/screenshots/organized/phone/01_welcome_login.jpg"
echo ""
echo "   # Batch convert all JPG to PNG:"
echo "   for file in frontend/screenshots/phone/*.jpg; do"
echo "     filename=\$(basename \"\$file\" .jpg)"
echo "     convert \"\$file\" \"frontend/screenshots/organized/phone/\${filename}.png\""
echo "   done"
