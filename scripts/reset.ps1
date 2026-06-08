# Kill browsers and apps first
taskkill /f /im firefox.exe 2>$null
taskkill /f /im chrome.exe 2>$null
taskkill /f /im msedge.exe 2>$null
taskkill /f /im scilab.exe 2>$null
taskkill /f /im WScilex.exe 2>$null
taskkill /f /im ccstudio.exe 2>$null
taskkill /f /im eclipse.exe 2>$null

# Get all user profiles except standard system ones
$excludedProfiles = @('Public', 'Administrator', 'Default', 'Default User', 'All Users')
$profiles = Get-ChildItem "C:\Users" -Directory -Force | Where-Object { $_.Name -notin $excludedProfiles }

foreach ($profile in $profiles) {
    $U = $profile.FullName

    # Wipe user visible files, recent items, and app history/caches
    $paths = @(
      "$U\Documents",
      "$U\Desktop\*",
      "$U\Downloads\*",
      "$U\Pictures\*",
      "$U\Videos\*",
      "$U\Music\*",
      "$U\3D Objects\*",
      "$U\Saved Games\*",
      "$U\Contacts\*",
      "$U\Favorites\*",
      "$U\Links\*",
      "$U\Searches\*",
      "$U\AppData\Local\Temp\*",
      "$U\AppData\Local\Programs\*",
      "$U\AppData\Roaming\Microsoft\Windows\Recent\*",
      "$U\AppData\Roaming\Scilab\*",
      "$U\AppData\Local\scilab\*",
      "$U\.Scilab\*",
      "$U\AppData\Local\Texas Instruments\CCS\*",
      "$U\.ti\*",
      "$U\.eclipse\*"
    )

    foreach ($p in $paths) {
        Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
    }


    # Clear Edge completely (profile, cache, cookies, history)
    Remove-Item "$U\AppData\Local\Microsoft\Edge\User Data\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$U\AppData\Roaming\Microsoft\Edge\*" -Recurse -Force -ErrorAction SilentlyContinue

    # Clear Firefox completely (profiles, cache, history, passwords, sessions)
    Remove-Item "$U\AppData\Roaming\Mozilla\Firefox\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$U\AppData\Local\Mozilla\Firefox\*" -Recurse -Force -ErrorAction SilentlyContinue
}

# ==========================================
# CLEANUP C:\Users\Public (CAREFULLY)
# ==========================================
$PublicPath = "C:\Users\Public"

# 1. Delete any non-standard folders/files dropped directly into C:\Users\Public
$PublicFoldersToKeep = @('Desktop', 'Documents', 'Downloads', 'Pictures', 'Videos', 'Music', 'AccountPictures', 'Libraries', 'OEM')
Get-ChildItem $PublicPath -Force -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -notin $PublicFoldersToKeep } | 
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# 2. Wipe the contents of the standard Public folders
$StandardPublic = @('Downloads', 'Pictures', 'Videos', 'Music', 'Documents')
foreach ($folder in $StandardPublic) {
    Remove-Item "$PublicPath\$folder\*" -Recurse -Force -ErrorAction SilentlyContinue
}

# 3. Clean Public Desktop but KEEP shortcuts (.lnk, .url) so apps don't disappear!
Get-ChildItem "$PublicPath\Desktop\*" -Force -ErrorAction SilentlyContinue | 
    Where-Object { $_.Extension -notin @('.lnk', '.url') } | 
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# Wipe all users' recycle bins on the C: drive (since this runs as SYSTEM)
Get-ChildItem -Path 'C:\$Recycle.Bin' -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Clear-RecycleBin -Force -ErrorAction SilentlyContinue