# DriveOn App Icon Replacement Script
# Simple version without emoji characters

param(
    [Parameter(Mandatory=$true)]
    [string]$IconPath,
    
    [Parameter(Mandatory=$false)]
    [string]$IconName = "ic_launcher"
)

Write-Host "DriveOn App Icon Replacement Script" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# Check if we're in the right directory
if (-not (Test-Path "android/app/src/main/res")) {
    Write-Host "Error: Please run this script from the frontend directory" -ForegroundColor Red
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Yellow
    Write-Host "Expected: frontend directory with android/app/src/main/res folder" -ForegroundColor Yellow
    exit 1
}

# Check if icon file exists
if (-not (Test-Path $IconPath)) {
    Write-Host "Error: Icon file not found: $IconPath" -ForegroundColor Red
    Write-Host "Please provide the full path to your icon file" -ForegroundColor Yellow
    exit 1
}

Write-Host "Icon file found: $IconPath" -ForegroundColor Green
Write-Host "Icon name: $IconName" -ForegroundColor Green
Write-Host ""

# Define the mipmap directories and their required sizes
$mipmapDirs = @(
    @{Name="mipmap-mdpi"; Size=48},
    @{Name="mipmap-hdpi"; Size=72},
    @{Name="mipmap-xhdpi"; Size=96},
    @{Name="mipmap-xxhdpi"; Size=144},
    @{Name="mipmap-xxxhdpi"; Size=192}
)

Write-Host "Replacing app icons..." -ForegroundColor Blue
Write-Host ""

foreach ($dir in $mipmapDirs) {
    $targetDir = "android/app/src/main/res/$($dir.Name)"
    $targetFile = "$targetDir/$IconName.png"
    
    $sizeText = "$($dir.Size)x$($dir.Size)px"
    Write-Host "Processing $($dir.Name) ($sizeText)..." -ForegroundColor Cyan
    
    # Create directory if it doesn't exist
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Write-Host "   Created directory: $targetDir" -ForegroundColor Gray
    }
    
    # Backup original icon if it exists
    $backupFile = "$targetFile.backup"
    if (Test-Path $targetFile) {
        Copy-Item $targetFile $backupFile -Force
        Write-Host "   Backed up original: $backupFile" -ForegroundColor Gray
    }
    
    # Copy new icon
    Copy-Item $IconPath $targetFile -Force
    Write-Host "   Replaced: $targetFile" -ForegroundColor Green
}

Write-Host ""
Write-Host "Icon replacement complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Test the icons: flutter build apk --debug" -ForegroundColor White
Write-Host "2. Install on device/emulator to verify" -ForegroundColor White
Write-Host "3. Check icon appears correctly on home screen" -ForegroundColor White
Write-Host ""
Write-Host "Tips:" -ForegroundColor Cyan
Write-Host "- Icons should be PNG format with transparent background" -ForegroundColor White
Write-Host "- Test visibility at small sizes (48x48px)" -ForegroundColor White
Write-Host "- Ensure high contrast for visibility" -ForegroundColor White
