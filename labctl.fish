# Load Configuration
    set -g LAB_BASE_DIR (status dirname)
    set config_file $LAB_BASE_DIR/lab_vars.fish
    if test -f $config_file
        source $config_file
    else
        echo "⚠️ LABCTL: Configuration file not found at $config_file"
        echo "Please copy lab_vars.template.fish to lab_vars.fish and configure it."
        return
    end

    # ==================================================
    # PER-MACHINE SMART COMMANDS (e.g. labctl7 reboot)
    # ==================================================
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
                case install-code
                    echo \">>> Installing VSCode on \$target_host\"
                    ssh $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
                    scp \$LAB_SCRIPTS_DIR/vscode-install.ps1 $LAB_USER@\$target_host:\"C:/LAB/vscode-install.ps1\"
                    ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\LAB\\\\vscode-install.ps1\"
                    echo \"✅ VSCode installation finished on \$target_host\"
                case install-python
                    echo \">>> Installing Python on \$target_host\"
                    ssh $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
                    scp \$LAB_SCRIPTS_DIR/python-install.ps1 $LAB_USER@\$target_host:\"C:/LAB/python-install.ps1\"
                    ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\LAB\\\\python-install.ps1\"
                    echo \"✅ Python installation finished on \$target_host\"
                case '*'
                    echo \"Usage: $LAB_CMD_PREFIX$i [down|reboot|lock|wake|install-code|install-python]\"
            end
        end
        "
    end

    # ==================================================
    # ALL-IN-ONE COMMAND (status, reboot, down)
    # ==================================================
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
                echo \"  $LAB_CMD_PREFIX-reset-all\"
        end
    end
    "

    # ==================================================
    # RESET DEPLOYER & CONTROLS
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

            ssh $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
            scp \$LAB_SCRIPTS_DIR/reset.ps1 $LAB_USER@\$target_host:\"C:/LAB/reset.ps1\"
            or begin
                echo \"COPY FAIL \$target_host\"
                continue
            end

            ssh $LAB_USER@\$target_host \"schtasks /create /tn LAB-RESET /sc onlogon /ru SYSTEM /rl HIGHEST /tr \\\"cmd /c start /min powershell -NoProfile -ExecutionPolicy Bypass -File C:\\\\LAB\\\\reset.ps1\\\" /f\"
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

            ssh $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
            scp \$LAB_SCRIPTS_DIR/reset.ps1 $LAB_USER@\$target_host:\"C:/LAB/reset.ps1\"
            or begin
                echo \"COPY FAIL \$target_host\"
                return
            end

            ssh $LAB_USER@\$target_host \"schtasks /delete /tn LAB-RESET /f 2>nul\"
            ssh $LAB_USER@\$target_host \"schtasks /create /tn LAB-RESET /sc onlogon /ru SYSTEM /rl HIGHEST /tr \\\"cmd /c start /min powershell -NoProfile -ExecutionPolicy Bypass -File C:\\\\LAB\\\\reset.ps1\\\" /f\"
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
        ssh $LAB_USER@\$target_host \"schtasks /change /tn LAB-RESET /disable\"
        echo \"Reset DISABLED on \$target_host\"
    end

    function $LAB_CMD_PREFIX-reset-on --argument n
        set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
        ssh $LAB_USER@\$target_host \"schtasks /change /tn LAB-RESET /enable\"
        echo \"Reset ENABLED on \$target_host\"
    end
    "

    # ==================================================
    # NET CONTROLS
    # ==================================================
    eval "
    function $LAB_CMD_PREFIX-net-off --argument n
        set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
        echo \">>> Blocking internet on \$target_host\"
        ssh $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
        scp \$LAB_SCRIPTS_DIR/net-off.ps1 $LAB_USER@\$target_host:\"C:/LAB/net-off.ps1\"
        ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\LAB\\\\net-off.ps1\"
        echo \"🚫 Internet DISABLED on \$target_host\"
    end

    function $LAB_CMD_PREFIX-net-on --argument n
        set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
        echo \">>> Restoring internet on \$target_host\"
        ssh $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
        scp \$LAB_SCRIPTS_DIR/net-on.ps1 $LAB_USER@\$target_host:\"C:/LAB/net-on.ps1\"
        ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\LAB\\\\net-on.ps1\"
        echo \"✅ Internet ENABLED on \$target_host\"
    end
    "

    # ==================================================
    # SOFTWARE INSTALLATION CONTROLS
    # ==================================================
    eval "
    function $LAB_CMD_PREFIX-code-install --argument n
        if test -n \"\$n\"
            set target_hosts \$n
        else
            set target_hosts \$LAB_HOSTS
        end

        for i in \$target_hosts
            set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
            echo \">>> Installing VSCode on \$target_host\"
            ssh $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
            scp \$LAB_SCRIPTS_DIR/vscode-install.ps1 $LAB_USER@\$target_host:\"C:/LAB/vscode-install.ps1\"
            ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\LAB\\\\vscode-install.ps1\"
            echo \"✅ VSCode installation finished on \$target_host\"
        end
    end

    function $LAB_CMD_PREFIX-python-install --argument n
        if test -n \"\$n\"
            set target_hosts \$n
        else
            set target_hosts \$LAB_HOSTS
        end

        for i in \$target_hosts
            set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
            echo \">>> Installing Python on \$target_host\"
            ssh $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
            scp \$LAB_SCRIPTS_DIR/python-install.ps1 $LAB_USER@\$target_host:\"C:/LAB/python-install.ps1\"
            ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\LAB\\\\python-install.ps1\"
            echo \"✅ Python installation finished on \$target_host\"
        end
    end
    "
