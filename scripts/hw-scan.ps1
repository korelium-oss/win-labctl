$ram=[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB)

$typeCode=(Get-CimInstance Win32_PhysicalMemory | Select -First 1 SMBIOSMemoryType).SMBIOSMemoryType
$type=switch($typeCode){
21 {"DDR2"}
24 {"DDR3"}
26 {"DDR4"}
34 {"DDR5"}
default {"UNK"}
}

$disk=Get-PhysicalDisk | Select -First 1 MediaType,BusType,Size
$diskSize=[math]::Round($disk.Size/1GB)

Write-Output "$ram GB $type | $diskSize GB $($disk.MediaType) $($disk.BusType)"
