# ==================================================
# UTILITY & SCANNERS
# ==================================================
eval "
function $LAB_CMD_PREFIX-copy --argument n file dest
    set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
    echo \">>> Copying \$file to \$target_host:\$dest\"
    ssh $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\"
    scp -r \$file $LAB_USER@\$target_host:\"\$dest\"
    if test \$status -eq 0
        echo \"✅ Copy OK → \$target_host\"
    else
        echo \"❌ Copy FAILED → \$target_host\"
    end
end

function $LAB_CMD_PREFIX-copy-all --argument file dest
    for i in \$LAB_HOSTS
        set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
        echo \">>> Copying to \$target_host\"
        ssh $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\"
        scp -r \$file $LAB_USER@\$target_host:\"\$dest\" &
    end
    wait
    echo \"✅ Copy complete on all machines\"
end

function $LAB_CMD_PREFIX-mac-scan
    echo \"IDX  HOST            MAC ADDRESS\"
    echo \"---------------------------------------\"
    for i in \$LAB_HOSTS
        set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
        set mac (ssh -o ConnectTimeout=3 -o BatchMode=yes $LAB_USER@\$target_host \"powershell -Command \\\"(Get-NetAdapter | Where-Object {\\\$_.Status -eq 'Up'}).MacAddress\\\"\" 2>/dev/null)
        if test -z \"\$mac\"
            echo \"\$i   \$target_host   UNKNOWN\"
        else
            echo \"\$i   \$target_host   \$mac\"
        end
    end
end

function $LAB_CMD_PREFIX-vlsi-create
    echo \"[*] Creating VLSI folder in Documents on all machines...\"
    for i in \$LAB_HOSTS
        set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
        ssh -o ConnectTimeout=3 -o BatchMode=yes $LAB_USER@\$target_host \"mkdir C:\\\\Users\\\\$LAB_USER\\\\Documents\\\\VLSI 2>nul\" >/dev/null 2>&1 &
    end
    wait
    echo \"✅ VLSI folder created on all machines\"
end

function $LAB_CMD_PREFIX-hw-scan
    echo \"IDX  HOST            RAM/DISK\"
    echo \"----------------------------------------------\"
    for i in \$LAB_HOSTS
        set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
        ssh -o ConnectTimeout=3 -o BatchMode=yes $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\" >/dev/null 2>&1
        scp \$LAB_SCRIPTS_DIR/hw-scan.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/hw-scan.ps1\" >/dev/null 2>&1
        set result (ssh -o ConnectTimeout=3 -o BatchMode=yes $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\hw-scan.ps1\" 2>/dev/null)
        if test -z \"\$result\"
            printf \"%-4s %-15s OFFLINE\\n\" \$i \$target_host
        else
            printf \"%-4s %-15s %s\\n\" \$i \$target_host \$result
        end
    end
end

function $LAB_CMD_PREFIX-mb-scan
    echo \"IDX  HOST            MOTHERBOARD\"
    echo \"-------------------------------------------------------\"
    for i in \$LAB_HOSTS
        set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
        set result (ssh -o ConnectTimeout=3 -o BatchMode=yes $LAB_USER@\$target_host \"powershell -Command \\\"Get-CimInstance Win32_BaseBoard | ForEach-Object { Write-Output (\\\$_.Manufacturer + ' ' + \\\$_.Product + ' ' + \\\$_.SerialNumber) }\\\"\" 2>/dev/null)
        if test -z \"\$result\"
            printf \"%-4s %-15s OFFLINE\\n\" \$i \$target_host
        else
            printf \"%-4s %-15s %s\\n\" \$i \$target_host \$result
        end
    end
end
"
