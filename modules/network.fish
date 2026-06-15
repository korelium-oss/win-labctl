# ==================================================
# NETWORK CONTROLS
# ==================================================
eval "
function $LAB_CMD_PREFIX-net-off --argument n
    set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
    echo \">>> Blocking internet on \$target_host\"
    ssh $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\"
    scp \$LAB_SCRIPTS_DIR/net-off.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/net-off.ps1\"
    ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\net-off.ps1\"
    echo \"🚫 Internet DISABLED on \$target_host\"
end

function $LAB_CMD_PREFIX-net-on --argument n
    set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
    echo \">>> Restoring internet on \$target_host\"
    ssh $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\"
    scp \$LAB_SCRIPTS_DIR/net-on.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/net-on.ps1\"
    ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\net-on.ps1\"
    echo \"✅ Internet ENABLED on \$target_host\"
end

function $LAB_CMD_PREFIX-net-off-all
    echo \"[*] Blocking internet on all machines (parallel)...\"
    for i in \$LAB_HOSTS
        set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
        begin
            ssh -q -o ConnectTimeout=3 -o BatchMode=yes $LAB_USER@\$target_host exit >/dev/null 2>&1
            if test \$status -eq 0
                ssh -q -o ConnectTimeout=3 -o BatchMode=yes $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\" >/dev/null 2>&1
                scp -q -o ConnectTimeout=3 -o BatchMode=yes \$LAB_SCRIPTS_DIR/net-off.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/net-off.ps1\" >/dev/null 2>&1
                ssh -q -o ConnectTimeout=5 -o BatchMode=yes $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\net-off.ps1\" >/dev/null 2>&1
                echo \"✅ Blocked : \$target_host\"
            else
                echo \"❌ Offline : \$target_host\"
            end
        end &
    end
    wait
    echo \"🚫 Internet DISABLED on ALL machines\"
end

function $LAB_CMD_PREFIX-net-on-all
    echo \"[*] Restoring internet on all machines (parallel)...\"
    for i in \$LAB_HOSTS
        set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
        begin
            ssh -q -o ConnectTimeout=3 -o BatchMode=yes $LAB_USER@\$target_host exit >/dev/null 2>&1
            if test \$status -eq 0
                ssh -q -o ConnectTimeout=3 -o BatchMode=yes $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\" >/dev/null 2>&1
                scp -q -o ConnectTimeout=3 -o BatchMode=yes \$LAB_SCRIPTS_DIR/net-on.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/net-on.ps1\" >/dev/null 2>&1
                ssh -q -o ConnectTimeout=5 -o BatchMode=yes $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\net-on.ps1\" >/dev/null 2>&1
                echo \"✅ Restored: \$target_host\"
            else
                echo \"❌ Offline : \$target_host\"
            end
        end &
    end
    wait
    echo \"✅ Internet ENABLED on ALL machines\"
end
"
