# Windows Troubleshooting Guide

## File System Errors (errno -4094)

If you encounter errors like:
```
[Error: UNKNOWN: unknown error, open 'C:\...\.next\build-manifest.json']
```

This is a known Windows file system issue with Next.js, especially when accessing from network devices (like your phone). **The error may appear but the app might still work** - check if the page actually loads in your browser.

### ⚡ Quick Fix (Recommended)

Use the safe dev script that automatically handles errors:
```powershell
npm run dev:safe
```

This script will automatically clean and retry if errors occur.

### Quick Fix

1. **Stop the dev server** (Ctrl+C)
2. **Clean the build cache:**
   ```powershell
   npm run clean
   ```
3. **Restart the dev server:**
   ```powershell
   npm run dev
   ```

### Permanent Solutions

#### 1. Exclude `.next` from Antivirus Scanning

Add the `.next` directory to your antivirus exclusions:
- Windows Defender: Settings → Virus & threat protection → Exclusions
- Add folder: `C:\systemc\car\frontend-web\.next`

#### 2. Use Clean Dev Script

Use the clean dev script that automatically cleans before starting:
```powershell
npm run dev:clean
```

#### 3. Windows Long Path Support

Enable long path support in Windows (if paths are very long):
1. Open Group Policy Editor (gpedit.msc)
2. Navigate to: Computer Configuration → Administrative Templates → System → Filesystem
3. Enable "Enable Win32 long paths"

#### 4. Firewall Configuration

Ensure Windows Firewall allows port 3000:
```powershell
# Run as Administrator
New-NetFirewallRule -DisplayName "Next.js Dev Server" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
```

### Network Access from Phone

1. **Find your PC's IP address:**
   ```powershell
   ipconfig
   ```
   Look for IPv4 Address (e.g., 192.168.1.100)

2. **Access from phone:**
   ```
   http://<YOUR-PC-IP>:3000
   ```
   Example: `http://192.168.1.100:3000`

3. **Ensure same network:** Both devices must be on the same Wi-Fi network

### If Issues Persist

1. Check if another Next.js process is running
2. Restart your computer
3. Try running PowerShell as Administrator
4. Check Windows Event Viewer for file system errors

