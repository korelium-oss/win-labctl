reg delete "HKLM\Software\Policies\Microsoft\Windows\Installer" /v DisableMSI /f
reg delete "HKLM\Software\Policies\Microsoft\Windows\Safer" /f

# Reload group policies
gpupdate /force
Write-Output "Policy refreshed"
