# PowerShell script to forward WSL port to Windows
# Run this in Windows PowerShell (as Administrator)

$wslIp = (wsl hostname -I).Trim()
$windowsPort = 3000
$wslPort = 3000

Write-Host "WSL IP: $wslIp" -ForegroundColor Green
Write-Host "Forwarding Windows port $windowsPort to WSL port $wslPort" -ForegroundColor Yellow

# Remove existing rule if any
netsh interface portproxy delete v4tov4 listenport=$windowsPort listenaddress=0.0.0.0 2>$null

# Add port forwarding rule
netsh interface portproxy add v4tov4 listenport=$windowsPort listenaddress=0.0.0.0 connectport=$wslPort connectaddress=$wslIp

Write-Host "Port forwarding configured!" -ForegroundColor Green
Write-Host "Now start the dev server in WSL: npm run dev" -ForegroundColor Yellow
Write-Host "Then access from your phone: http://192.168.0.105:3000" -ForegroundColor Cyan

