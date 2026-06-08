# ================================
# EDGE COMPLETE REMOVAL (LAB SAFE)
# ================================

Write-Host "Stopping Edge..."

Stop-Process -Name msedge -Force -ErrorAction SilentlyContinue
Stop-Process -Name msedgewebview2 -Force -ErrorAction SilentlyContinue

# Try official uninstall first
$edge = Get-ChildItem "C:\Program Files (x86)\Microsoft\Edge\Application" -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        Select-Object -First 1

if ($edge) {
    $setup = "$($edge.FullName)\Installer\setup.exe"
    if (Test-Path $setup) {
        Write-Host "Running Microsoft uninstall..."
        Start-Process $setup -ArgumentList "--uninstall --system-level --force-uninstall --verbose-logging" -Wait
    }
}

# Take ownership and remove leftovers
Write-Host "Removing remaining files..."

takeown /f "C:\Program Files (x86)\Microsoft\Edge" /r /d y 2>$null
icacls "C:\Program Files (x86)\Microsoft\Edge" /grant Administrators:F /t 2>$null

Remove-Item "C:\Program Files (x86)\Microsoft\Edge" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Program Files\Microsoft\Edge" -Recurse -Force -ErrorAction SilentlyContinue

# Block reinstall
Write-Host "Blocking reinstall..."

New-Item "C:\Program Files (x86)\Microsoft\Edge" -ItemType Directory -Force | Out-Null
New-Item "C:\Program Files (x86)\Microsoft\Edge\BLOCKED.txt" -ItemType File -Force | Out-Null

Write-Host "Edge removal complete."
