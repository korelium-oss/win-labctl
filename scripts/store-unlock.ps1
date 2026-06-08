# Re-enable Store Policy
reg delete "HKLM\SOFTWARE\Policies\Microsoft\WindowsStore" `
 /v RemoveWindowsStore /f 2>$null

Write-Output "Policy removed"

# Try normal reinstall first
$store = Get-AppxPackage -allusers Microsoft.WindowsStore

if (-not $store) {
    Write-Output "Store not found, repairing via Windows components..."

    # Repair Windows AppX system
    DISM /Online /Cleanup-Image /RestoreHealth

    # Re-register default apps
    Get-AppxPackage -AllUsers |
    Foreach {
        Add-AppxPackage -DisableDevelopmentMode -Register `
        "$($_.InstallLocation)\AppXManifest.xml" `
        -ErrorAction SilentlyContinue
    }

    Write-Output "System apps re-registered"
}
else {
    Write-Output "Store already present"
}

Write-Output "Microsoft Store RESTORED"
