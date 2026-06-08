# Disable MSI
reg add "HKLM\Software\Policies\Microsoft\Windows\Installer" /v DisableMSI /t REG_DWORD /d 2 /f

# Enable SRP
reg add "HKLM\Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /v TransparentEnabled /t REG_DWORD /d 1 /f
reg add "HKLM\Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /v DefaultLevel /t REG_DWORD /d 0x40000 /f

$paths = @(
  "C:\Users\*\Downloads\*.exe",
  "C:\Users\*\Desktop\*.exe",
  "C:\Users\*\AppData\Local\Temp\*.exe",
  "C:\Users\*\Downloads\*.msi",
  "C:\Users\*\Desktop\*.msi",
  "C:\Users\*\AppData\Local\Temp\*.msi"
)

$base = "HKLM\Software\Policies\Microsoft\Windows\Safer\CodeIdentifiers\0\Paths"
$i = 1
foreach ($p in $paths) {
    $k = "$base\{00000000-0000-0000-0000-00000000000$i}"
    reg add $k /v ItemData /t REG_SZ /d $p /f
    reg add $k /v SaferFlags /t REG_DWORD /d 0 /f
    $i++
}

# Reload group policies
gpupdate /force
Write-Output "Policy refreshed"
