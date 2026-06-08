# Disable Microsoft Store via Registry (Policy Level)

reg add "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" `
 /v RemoveWindowsStore /t REG_DWORD /d 1 /f

# Kill Store if running
taskkill /f /im WinStore.App.exe 2>$null

# Remove Store App (for all users)
Get-AppxPackage -allusers Microsoft.WindowsStore |
Remove-AppxPackage -ErrorAction SilentlyContinue

# Get-AppxProvisionedPackage -online |
# Where-Object DisplayName -eq "Microsoft.WindowsStore" |
# Remove-AppxProvisionedPackage -online |
# Remove-AppxProvisionedPackage -online


$pkg = Get-AppxProvisionedPackage -Online |
Where-Object DisplayName -eq "Microsoft.WindowsStore"

if ($pkg) {
    $pkg | Remove-AppxProvisionedPackage -Online
}


Write-Output "Microsoft Store BLOCKED"
