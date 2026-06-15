# ==================================================
# DEEP-FREEZE RESET DEPLOYER & CONTROLS
# ==================================================
eval "
function $LAB_CMD_PREFIX-reset-all --argument mode
    for i in \$LAB_HOSTS
        if contains \$i \$LAB_PROTECTED_HOSTS; and test \"\$mode\" != \"--all\"
            echo \">>> Skipping protected host $LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
            continue
        end

        set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
        echo \">>> Deploying reset to \$target_host\"

        ssh $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\"
        scp \$LAB_SCRIPTS_DIR/reset.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/reset.ps1\"
        or begin
            echo \"COPY FAIL \$target_host\"
            continue
        end

        ssh $LAB_USER@\$target_host \"schtasks /create /tn $LAB_CMD_PREFIX-RESET /sc onlogon /ru SYSTEM /rl HIGHEST /tr \\\"cmd /c start /min powershell -NoProfile -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\reset.ps1\\\" /f\"
        or begin
            echo \"TASK FAIL \$target_host\"
            continue
        end

        echo \"OK  \$target_host\"
    end
end
"

for i in $LAB_HOSTS
    eval "
    function $LAB_CMD_PREFIX-reset-$i
        set target_host \"$LAB_HOST_PREFIX$i$LAB_HOST_SUFFIX\"
        echo \">>> Deploying reset to \$target_host\"

        ssh $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\"
        scp \$LAB_SCRIPTS_DIR/reset.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/reset.ps1\"
        or begin
            echo \"COPY FAIL \$target_host\"
            return
        end

        ssh $LAB_USER@\$target_host \"schtasks /delete /tn $LAB_CMD_PREFIX-RESET /f 2>nul\"
        ssh $LAB_USER@\$target_host \"schtasks /create /tn $LAB_CMD_PREFIX-RESET /sc onlogon /ru SYSTEM /rl HIGHEST /tr \\\"cmd /c start /min powershell -NoProfile -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\reset.ps1\\\" /f\"
        or begin
            echo \"TASK FAIL \$target_host\"
            return
        end

        echo \"OK  \$target_host\"
    end
    "
end

eval "
function $LAB_CMD_PREFIX-reset-off --argument n
    set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
    ssh $LAB_USER@\$target_host \"schtasks /change /tn $LAB_CMD_PREFIX-RESET /disable\"
    echo \"Reset DISABLED on \$target_host\"
end

function $LAB_CMD_PREFIX-reset-on --argument n
    set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
    ssh $LAB_USER@\$target_host \"schtasks /change /tn $LAB_CMD_PREFIX-RESET /enable\"
    echo \"Reset ENABLED on \$target_host\"
end

function $LAB_CMD_PREFIX-reset-all-off
    for i in \$LAB_HOSTS
        set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
        ssh $LAB_USER@\$target_host \"schtasks /change /tn $LAB_CMD_PREFIX-RESET /disable\" &
    end
    wait
    echo \"Reset DISABLED on ALL machines\"
end

function $LAB_CMD_PREFIX-reset-all-on
    for i in \$LAB_HOSTS
        set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
        ssh $LAB_USER@\$target_host \"schtasks /change /tn $LAB_CMD_PREFIX-RESET /enable\" &
    end
    wait
    echo \"Reset ENABLED on ALL machines\"
end
"
