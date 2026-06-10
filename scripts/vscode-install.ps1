# Download VS Code
$url = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
$out = "C:\LAB\vscode_$(Get-Random).exe"

Invoke-WebRequest -Uri $url -OutFile $out

# Install silently
Start-Process $out -ArgumentList "/silent", "/mergetasks=!runcode" -Wait

# Verify install
if (Test-Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe") {
    Write-Output "VSCODE_OK"
} else {
    Write-Output "VSCODE_FAIL"
    exit 1
}
