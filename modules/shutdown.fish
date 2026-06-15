# ==================================================
# AUTO SHUTDOWN CONTROL
# ==================================================
eval "
function $LAB_CMD_PREFIX-autoshutdown-all-on
    read -P \"Enter shutdown time (HH:MM, 24h format): \" stime
    for i in \$LAB_HOSTS
        set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
        echo \">>> Setting auto shutdown on \$target_host at \$stime\"
        ssh $LAB_USER@\$target_host \"schtasks /create /tn $LAB_CMD_PREFIX-AUTO-SHUTDOWN /sc daily /st \$stime /ru SYSTEM /tr \\\"shutdown /s /f /t 0\\\" /f\" &
    end
    wait
    echo \"Auto shutdown ENABLED on all machines at \$stime\"
end

function $LAB_CMD_PREFIX-autoshutdown-off --argument n
    set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
    ssh $LAB_USER@\$target_host \"schtasks /delete /tn $LAB_CMD_PREFIX-AUTO-SHUTDOWN /f\"
    echo \"Auto shutdown DISABLED on \$target_host\"
end

function $LAB_CMD_PREFIX-autoshutdown-all-off
    for i in \$LAB_HOSTS
        set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
        ssh $LAB_USER@\$target_host \"schtasks /delete /tn $LAB_CMD_PREFIX-AUTO-SHUTDOWN /f\" &
    end
    wait
    echo \"Auto shutdown DISABLED on ALL machines\"
end

function $LAB_CMD_PREFIX-autoshutdown2-all-on
    read -P \"Enter second shutdown time (HH:MM, 24h): \" stime
    for i in \$LAB_HOSTS
        set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
        echo \">>> Setting SECOND shutdown on \$target_host at \$stime\"
        ssh $LAB_USER@\$target_host \"schtasks /create /tn $LAB_CMD_PREFIX-AUTO-SHUTDOWN-2 /sc daily /st \$stime /ru SYSTEM /tr \\\"shutdown /s /f /t 0\\\" /f\" &
    end
    wait
    echo \"Second auto shutdown ENABLED on all machines at \$stime\"
end

function $LAB_CMD_PREFIX-autoshutdown2-all-off
    for i in \$LAB_HOSTS
        set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
        ssh $LAB_USER@\$target_host \"schtasks /delete /tn $LAB_CMD_PREFIX-AUTO-SHUTDOWN-2 /f\" &
    end
    wait
    echo \"Second auto shutdown DISABLED on ALL machines\"
end
"
