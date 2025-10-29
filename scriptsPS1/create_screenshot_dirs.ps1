# create_screenshot_dirs.ps1
# PowerShell script to create screenshot directories and provide guidance

Write-Host "📸 DriveOn Screenshots Setup" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

# Create directories
New-Item -ItemType Directory -Path "screenshots/phone" -Force | Out-Null
New-Item -ItemType Directory -Path "screenshots/tablet" -Force | Out-Null

Write-Host "✅ Screenshot directories created!" -ForegroundColor Green
Write-Host "📁 Phone screenshots: frontend/screenshots/phone/" -ForegroundColor Yellow
Write-Host "📁 Tablet screenshots: frontend/screenshots/tablet/" -ForegroundColor Yellow

Write-Host "`n📋 Required Screenshots:" -ForegroundColor Cyan
Write-Host "1. Welcome/Login Screen" -ForegroundColor White
Write-Host "2. Home Dashboard" -ForegroundColor White
Write-Host "3. Service Booking Flow" -ForegroundColor White
Write-Host "4. Insurance Marketplace" -ForegroundColor White
Write-Host "5. Social Hub" -ForegroundColor White
Write-Host "6. Provider Details" -ForegroundColor White
Write-Host "7. Vehicle Management" -ForegroundColor White
Write-Host "8. Expense Tracking" -ForegroundColor White

Write-Host "`n🚀 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Run the app: flutter run" -ForegroundColor White
Write-Host "2. Navigate to each screen" -ForegroundColor White
Write-Host "3. Take screenshots (Power + Volume Down on device)" -ForegroundColor White
Write-Host "4. Save to appropriate directories" -ForegroundColor White

Write-Host "`nFor detailed instructions, see: SCREENSHOTS_GUIDE.md" -ForegroundColor Yellow
