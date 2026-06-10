# Download Python (official)
$url = "https://www.python.org/ftp/python/3.12.2/python-3.12.2-amd64.exe"
$out = "C:\DSLAB\python_$(Get-Random).exe"

Invoke-WebRequest -Uri $url -OutFile $out

# Install silently (VERY IMPORTANT FLAGS)
Start-Process $out -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0" -Wait

# Verify install
if (Test-Path "C:\Program Files\Python312\python.exe") {
    Write-Output "PYTHON_OK"
} else {
    Write-Output "PYTHON_FAIL"
    exit 1
}

