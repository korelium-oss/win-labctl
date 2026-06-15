# ==================================================
# CORE COMMANDS & WRAPPERS
# ==================================================

# Generate per-machine commands (e.g. labctl7 reboot)
for i in $LAB_HOSTS
    eval "
    function $LAB_CMD_PREFIX$i --argument action
        set target_host \"$LAB_HOST_PREFIX$i$LAB_HOST_SUFFIX\"
        
        if test -z \"\$action\"
            ssh $LAB_USER@\$target_host
            return
        end 

        switch \$action
            case down shutdown
                ssh $LAB_USER@\$target_host \"shutdown /s /t 0\"
            case reboot restart
                ssh $LAB_USER@\$target_host \"shutdown /r /t 0\"
            case lock
                ssh $LAB_USER@\$target_host \"rundll32.exe user32.dll,LockWorkStation\"
            case wake
                set mac_file $LAB_BASE_DIR/macs.txt
                if test -f \$mac_file
                    set mac (grep -i \"\$target_host\" \$mac_file | grep -v '^#' | awk '{print \$1}')
                    if test -n \"\$mac\"
                        wakeonlan \$mac
                        echo \"Waking \$target_host (\$mac)\"
                    else
                        echo \"MAC address for \$target_host not found in \$mac_file\"
                    end
                else
                    echo \"⚠️ MAC address file not found: \$mac_file\"
                end
            case '*'
                echo \"Usage: $LAB_CMD_PREFIX$i [down|reboot|lock|wake]\"
        end
    end
    "
end

# ALL-IN-ONE COMMAND (status, reboot, down, wake)
eval "
function $LAB_CMD_PREFIX-all --argument action
    switch \$action
        case status
            set tmp (mktemp)
            set total 0
            set online 0
            set offline 0
            set green (set_color green)
            set red (set_color red)
            set reset (set_color normal)

            echo \"IDX  HOST            STATE\"
            echo \"--------------------------------\"

            for i in \$LAB_HOSTS
                set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
                set total (math \$total + 1)

                begin
                    ssh -o ConnectTimeout=3 -o ConnectionAttempts=1 -o BatchMode=yes -o StrictHostKeyChecking=no $LAB_USER@\$target_host exit >/dev/null 2>&1

                    if test \$status -eq 0
                        echo (printf \"%-4s %-15s %sONLINE%s\" \$i \$target_host \$green \$reset)
                        echo online >> \$tmp.count
                    else
                        echo (printf \"%-4s %-15s %sOFFLINE%s\" \$i \$target_host \$red \$reset)
                        echo offline >> \$tmp.count
                    end
                end >> \$tmp &
            end

            wait
            cat \$tmp | sort -n

            if test -f \$tmp.count
                set online (count (grep -x online \$tmp.count))
                set offline (count (grep -x offline \$tmp.count))
                rm \$tmp.count
            end

            echo \"--------------------------------\"
            echo \"TOTAL   : \$total\"
            echo \"\$green ONLINE  : \$online \$reset\"
            echo \"\$red OFFLINE : \$offline \$reset\"
            rm \$tmp

        case reboot
            echo \"[*] Rebooting all machines (parallel)...\"
            for i in \$LAB_HOSTS
                set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
                ssh -o ConnectTimeout=10 $LAB_USER@\$target_host \"shutdown /r /t 0\" >/dev/null 2>&1 &
            end
            wait
            echo \"[*] Reboot commands sent.\"

        case down shutdown
            echo \"[*] Shutting down all machines (parallel)...\"
            for i in \$LAB_HOSTS
                set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
                ssh -o ConnectTimeout=20 $LAB_USER@\$target_host \"shutdown /s /t 0\" >/dev/null 2>&1 &
            end
            wait
            echo \"[*] Shutdown commands sent.\"

        case wake
            echo \"[*] Sending Wake-on-LAN packets...\"
            set mac_file $LAB_BASE_DIR/macs.txt
            if test -f \$mac_file
                grep -v '^#' \$mac_file | awk '{print \$1}' | while read -l mac
                    wakeonlan \$mac
                end
            else
                echo \"⚠️ MAC address file not found: \$mac_file\"
            end
            echo \"[*] Magic packets sent.\"

        case '*'
            echo \"Usage:\"
            echo \"  $LAB_CMD_PREFIX-all status\"
            echo \"  $LAB_CMD_PREFIX-all reboot\"
            echo \"  $LAB_CMD_PREFIX-all down\"
            echo \"  $LAB_CMD_PREFIX-all wake\"
    end
end
"
