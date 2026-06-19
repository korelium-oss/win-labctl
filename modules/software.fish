# ==================================================
# SOFTWARE DEPLOYMENT & BROWSER CONTROLS
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
        ssh $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\"
        scp \$LAB_SCRIPTS_DIR/vscode-install.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/vscode-install.ps1\"
        ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\vscode-install.ps1\"
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
        ssh $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\"
        scp \$LAB_SCRIPTS_DIR/python-install.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/python-install.ps1\"
        ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\python-install.ps1\"
        echo \"✅ Python installation finished on \$target_host\"
    end
end

function $LAB_CMD_PREFIX-python-libs-install --argument n
    if test -n \"\$n\"
        set target_hosts \$n
    else
        set target_hosts \$LAB_HOSTS
    end

    for i in \$target_hosts
        set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
        echo \">>> Installing Python Libraries on \$target_host\"
        ssh $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\"
        scp \$LAB_SCRIPTS_DIR/python-libs-install.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/python-libs-install.ps1\"
        ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\python-libs-install.ps1\"
        echo \"✅ Python libraries installation finished on \$target_host\"
    end
end

function $LAB_CMD_PREFIX-edge-remove --argument n
    set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
    echo \">>> Removing Edge on \$target_host\"
    ssh $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\"
    scp \$LAB_SCRIPTS_DIR/edge-remove.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/edge-remove.ps1\"
    or begin
        echo \"COPY FAIL \$target_host\"
        return
    end
    ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\edge-remove.ps1\"
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
        ssh -o ConnectTimeout=5 -o BatchMode=yes $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\"
        scp \$LAB_SCRIPTS_DIR/edge-remove.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/edge-remove.ps1\"
        if test \$status -ne 0
            echo \"COPY FAIL \$target_host\"
            continue
        end
        ssh -o ConnectTimeout=5 -o BatchMode=yes $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\edge-remove.ps1\"
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
        New-Item -Path C:\\\\$LAB_CMD_PREFIX -ItemType Directory -Force | Out-Null
        \$url = 'https://go.microsoft.com/fwlink/?linkid=2069324'
        \$out = 'C:\\\\$LAB_CMD_PREFIX\\\\edge.exe'
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
