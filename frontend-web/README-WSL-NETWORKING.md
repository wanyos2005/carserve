# WSL Networking Setup for Phone Testing

## Quick Setup (Run as Administrator)

1. **Open Windows PowerShell as Administrator**
   - Right-click PowerShell → "Run as Administrator"

2. **Run the port forwarding script:**
   ```powershell
   cd C:\systemc\car\frontend-web
   .\start-dev-wsl.ps1
   ```

3. **In WSL, start the dev server:**
   ```bash
   npm run dev
   ```

4. **Access from your phone:**
   ```
   http://192.168.0.105:3000
   ```

## Alternative: Install Node.js on Windows

If you prefer not to use port forwarding:

1. Download Node.js: https://nodejs.org/
2. Install the LTS version
3. Restart PowerShell
4. Run `npm run dev` directly in PowerShell (not WSL)

## Troubleshooting

If port forwarding doesn't work:
- Make sure Windows Firewall allows port 3000
- Check that WSL IP hasn't changed (run `wsl hostname -I` to verify)
- Re-run the port forwarding script if WSL restarts

