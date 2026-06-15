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

    # ==================================================
    # AUTO SHUTDOWN CONTROL
    # ==================================================
    eval "
    function $LAB_CMD_PREFIX-autoshutdown-all-on
        read -P \"Enter shutdown time (HH:MM, 24h format): \" stime
        for i in \$LAB_HOSTS
            set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
            echo \">>> Setting auto shutdown on \$target_host at \$stime\"
            ssh $LAB_USER@\$target_host \"schtasks /create /tn LAB-AUTO-SHUTDOWN /sc daily /st \$stime /ru SYSTEM /tr \\\"shutdown /s /f /t 0\\\" /f\" &
        end
        wait
        echo \"Auto shutdown ENABLED on all machines at \$stime\"
    end

    function $LAB_CMD_PREFIX-autoshutdown-off --argument n
        set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
        ssh $LAB_USER@\$target_host \"schtasks /delete /tn LAB-AUTO-SHUTDOWN /f\"
        echo \"Auto shutdown DISABLED on \$target_host\"
    end

    function $LAB_CMD_PREFIX-autoshutdown-all-off
        for i in \$LAB_HOSTS
            set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
            ssh $LAB_USER@\$target_host \"schtasks /delete /tn LAB-AUTO-SHUTDOWN /f\" &
        end
        wait
        echo \"Auto shutdown DISABLED on ALL machines\"
    end

    function $LAB_CMD_PREFIX-autoshutdown2-all-on
        read -P \"Enter second shutdown time (HH:MM, 24h): \" stime
        for i in \$LAB_HOSTS
            set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
            echo \">>> Setting SECOND shutdown on \$target_host at \$stime\"
            ssh $LAB_USER@\$target_host \"schtasks /create /tn LAB-AUTO-SHUTDOWN-2 /sc daily /st \$stime /ru SYSTEM /tr \\\"shutdown /s /f /t 0\\\" /f\" &
        end
        wait
        echo \"Second auto shutdown ENABLED on all machines at \$stime\"
    end

    function $LAB_CMD_PREFIX-autoshutdown2-all-off
        for i in \$LAB_HOSTS
            set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
            ssh $LAB_USER@\$target_host \"schtasks /delete /tn LAB-AUTO-SHUTDOWN-2 /f\" &
        end
        wait
        echo \"Second auto shutdown DISABLED on ALL machines\"
    end
    "

    # ==================================================
    # INSTALLER LOCK / UNLOCK
    # ==================================================
    eval "
    function $LAB_CMD_PREFIX-lock-installers
        for i in \$LAB_HOSTS
            set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
            echo \">>> Locking installers on \$target_host\"
            ssh $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
            scp \$LAB_SCRIPTS_DIR/installer-lock.ps1 $LAB_USER@\$target_host:\"C:/LAB/lock.ps1\"
            ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\LAB\\\\lock.ps1\"
        end
        echo \"🔒 Installers BLOCKED on all machines\"
    end

    function $LAB_CMD_PREFIX-unlock-installers
        for i in \$LAB_HOSTS
            set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
            echo \">>> Unlocking installers on \$target_host\"
            ssh $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
            scp \$LAB_SCRIPTS_DIR/installer-unlock.ps1 $LAB_USER@\$target_host:\"C:/LAB/unlock.ps1\"
            ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\LAB\\\\unlock.ps1\"
        end
        echo \"🔓 Installers ENABLED on all machines\"
    end

    function $LAB_CMD_PREFIX-lock-inst --argument n
        set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
        echo \">>> Locking installers on \$target_host\"
        ssh $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
        scp \$LAB_SCRIPTS_DIR/installer-lock.ps1 $LAB_USER@\$target_host:\"C:/LAB/lock.ps1\"
        ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\LAB\\\\lock.ps1\"
        echo \"🔒 Installers LOCKED on \$target_host\"
    end

    function $LAB_CMD_PREFIX-unlock-inst --argument n
        set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
        echo \">>> Unlocking installers on \$target_host\"
        ssh $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
        scp \$LAB_SCRIPTS_DIR/installer-unlock.ps1 $LAB_USER@\$target_host:\"C:/LAB/unlock.ps1\"
        ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\LAB\\\\unlock.ps1\"
        echo \"🔓 Installers UNLOCKED on \$target_host\"
    end
    "

    # ==================================================
    # MICROSOFT STORE LOCK / UNLOCK
    # ==================================================
    eval "
    function $LAB_CMD_PREFIX-lock-store
        for i in \$LAB_HOSTS
            set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
            echo \">>> Blocking Store on \$target_host\"
            ssh $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
            scp \$LAB_SCRIPTS_DIR/store-lock.ps1 $LAB_USER@\$target_host:\"C:/LAB/store-lock.ps1\"
            ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\LAB\\\\store-lock.ps1\"
        end
        echo \"🚫 Microsoft Store BLOCKED on all machines\"
    end

    function $LAB_CMD_PREFIX-unlock-store
        for i in \$LAB_HOSTS
            set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
            echo \">>> Restoring Store on \$target_host\"
            ssh $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
            scp \$LAB_SCRIPTS_DIR/store-unlock.ps1 $LAB_USER@\$target_host:\"C:/LAB/store-unlock.ps1\"
            ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\LAB\\\\store-unlock.ps1\"
        end
        echo \"✅ Microsoft Store RESTORED on all machines\"
    end

    function $LAB_CMD_PREFIX-lock-store-one --argument n
        set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
        echo \">>> Blocking Store on \$target_host\"
        ssh $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
        scp \$LAB_SCRIPTS_DIR/store-lock.ps1 $LAB_USER@\$target_host:\"C:/LAB/store-lock.ps1\"
        ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\LAB\\\\store-lock.ps1\"
        echo \"🚫 Microsoft Store BLOCKED on \$target_host\"
    end

    function $LAB_CMD_PREFIX-unlock-store-one --argument n
        set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
        echo \">>> Restoring Store on \$target_host\"
        ssh $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
        scp \$LAB_SCRIPTS_DIR/store-unlock.ps1 $LAB_USER@\$target_host:\"C:/LAB/store-unlock.ps1\"
        ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\LAB\\\\store-unlock.ps1\"
        echo \"✅ Microsoft Store RESTORED on \$target_host\"
    end
    "

    # ==================================================
    # EDGE BROWSER CONTROLS
    # ==================================================
    eval "
    function $LAB_CMD_PREFIX-edge-remove --argument n
        set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
        echo \">>> Removing Edge on \$target_host\"
        ssh $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
        scp \$LAB_SCRIPTS_DIR/edge-remove.ps1 $LAB_USER@\$target_host:\"C:/LAB/edge-remove.ps1\"
        or begin
            echo \"COPY FAIL \$target_host\"
            return
        end
        ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\LAB\\\\edge-remove.ps1\"
        or begin
            echo \"EXEC FAIL \$target_host\"
            return
        end
        echo \"✅ Edge removed on \$target_host\"
    end

    function $LAB_CMD_PREFIX-edge-remove-all
        echo \"[*] Removing Edge on all machines...\"
        for i in \$LAB_HOSTS
            set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
            echo \">>> Removing Edge on \$target_host\"
            ssh -o ConnectTimeout=5 -o BatchMode=yes $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
            scp \$LAB_SCRIPTS_DIR/edge-remove.ps1 $LAB_USER@\$target_host:\"C:/LAB/edge-remove.ps1\"
            if test \$status -ne 0
                echo \"COPY FAIL \$target_host\"
                continue
            end
            ssh -o ConnectTimeout=5 -o BatchMode=yes $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\LAB\\\\edge-remove.ps1\"
            if test \$status -ne 0
                echo \"EXEC FAIL \$target_host\"
                continue
            end
            echo \"OK  \$target_host\"
        end
        echo \"[✓] Edge removal finished.\"
    end

    function $LAB_CMD_PREFIX-edge-restore --argument n
        set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
        echo \">>> Restoring Edge on \$target_host\"
        ssh $LAB_USER@\$target_host \"
            powershell -ExecutionPolicy Bypass -Command \\\"
            \$ErrorActionPreference='SilentlyContinue'
            Remove-Item 'C:\\\\Program Files (x86)\\\\Microsoft\\\\Edge' -Recurse -Force
            New-Item -Path C:\\\\LAB -ItemType Directory -Force | Out-Null
            \$url = 'https://go.microsoft.com/fwlink/?linkid=2069324'
            \$out = 'C:\\\\LAB\\\\edge.exe'
            Invoke-WebRequest -Uri \$url -OutFile \$out
            Start-Process \$out -ArgumentList '/silent','/install' -Wait
            if (Test-Path 'C:\\\\Program Files (x86)\\\\Microsoft\\\\Edge\\\\Application') {
                Write-Output 'EDGE_OK'
            } else {
                Write-Output 'EDGE_FAIL'
                exit 1
            }
            \\\"
        \"
        if test \$status -eq 0
            echo \"✅ Edge restored on \$target_host\"
        else
            echo \"❌ Edge restore FAILED on \$target_host\"
        end
    end
    "

    # ==================================================
    # GLOBAL RESET AND NET MODIFIERS
    # ==================================================
    eval "
    function $LAB_CMD_PREFIX-reset-all-off
        for i in \$LAB_HOSTS
            set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
            ssh $LAB_USER@\$target_host \"schtasks /change /tn LAB-RESET /disable\" &
        end
        wait
        echo \"Reset DISABLED on ALL machines\"
    end

    function $LAB_CMD_PREFIX-reset-all-on
        for i in \$LAB_HOSTS
            set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
            ssh $LAB_USER@\$target_host \"schtasks /change /tn LAB-RESET /enable\" &
        end
        wait
        echo \"Reset ENABLED on ALL machines\"
    end

    function $LAB_CMD_PREFIX-net-off-all
        echo \"[*] Blocking internet on all machines (parallel)...\"
        for i in \$LAB_HOSTS
            set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
            begin
                ssh -q -o ConnectTimeout=3 -o BatchMode=yes $LAB_USER@\$target_host exit >/dev/null 2>&1
                if test \$status -eq 0
                    ssh -q -o ConnectTimeout=3 -o BatchMode=yes $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\" >/dev/null 2>&1
                    scp -q -o ConnectTimeout=3 -o BatchMode=yes \$LAB_SCRIPTS_DIR/net-off.ps1 $LAB_USER@\$target_host:\"C:/LAB/net-off.ps1\" >/dev/null 2>&1
                    ssh -q -o ConnectTimeout=5 -o BatchMode=yes $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\LAB\\\\net-off.ps1\" >/dev/null 2>&1
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
                    ssh -q -o ConnectTimeout=3 -o BatchMode=yes $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\" >/dev/null 2>&1
                    scp -q -o ConnectTimeout=3 -o BatchMode=yes \$LAB_SCRIPTS_DIR/net-on.ps1 $LAB_USER@\$target_host:\"C:/LAB/net-on.ps1\" >/dev/null 2>&1
                    ssh -q -o ConnectTimeout=5 -o BatchMode=yes $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\LAB\\\\net-on.ps1\" >/dev/null 2>&1
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

    # ==================================================
    # UTILITY & SCANNERS
    # ==================================================
    eval "
    function $LAB_CMD_PREFIX-copy --argument n file dest
        set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
        echo \">>> Copying \$file to \$target_host:\$dest\"
        ssh $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
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
            ssh $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\"
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
            set mac (ssh -o ConnectTimeout=3 -o BatchMode=yes $LAB_USER@\$target_host \"powershell -Command \\\"(\\$_.Status -eq 'Up' -and \\$_.MacAddress) | Select-Object -ExpandProperty MacAddress\\\"\" 2>/dev/null)
            # Actually I should use the correct script for mac scan, let me copy the original literal
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
            ssh -o ConnectTimeout=3 -o BatchMode=yes $LAB_USER@\$target_host \"mkdir C:\\\\LAB 2>nul\" >/dev/null 2>&1
            scp \$LAB_SCRIPTS_DIR/hw-scan.ps1 $LAB_USER@\$target_host:\"C:/LAB/hw-scan.ps1\" >/dev/null 2>&1
            set result (ssh -o ConnectTimeout=3 -o BatchMode=yes $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\LAB\\\\hw-scan.ps1\" 2>/dev/null)
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
