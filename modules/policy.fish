# ==================================================
# POLICY: INSTALLER LOCK / UNLOCK
# ==================================================
eval "
function $LAB_CMD_PREFIX-lock-installers
    for i in \$LAB_HOSTS
        set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
        echo \">>> Locking installers on \$target_host\"
        ssh $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\"
        scp \$LAB_SCRIPTS_DIR/installer-lock.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/lock.ps1\"
        ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\lock.ps1\"
    end
    echo \"🔒 Installers BLOCKED on all machines\"
end

function $LAB_CMD_PREFIX-unlock-installers
    for i in \$LAB_HOSTS
        set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
        echo \">>> Unlocking installers on \$target_host\"
        ssh $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\"
        scp \$LAB_SCRIPTS_DIR/installer-unlock.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/unlock.ps1\"
        ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\unlock.ps1\"
    end
    echo \"🔓 Installers ENABLED on all machines\"
end

function $LAB_CMD_PREFIX-lock-inst --argument n
    set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
    echo \">>> Locking installers on \$target_host\"
    ssh $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\"
    scp \$LAB_SCRIPTS_DIR/installer-lock.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/lock.ps1\"
    ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\lock.ps1\"
    echo \"🔒 Installers LOCKED on \$target_host\"
end

function $LAB_CMD_PREFIX-unlock-inst --argument n
    set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
    echo \">>> Unlocking installers on \$target_host\"
    ssh $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\"
    scp \$LAB_SCRIPTS_DIR/installer-unlock.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/unlock.ps1\"
    ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\unlock.ps1\"
    echo \"🔓 Installers UNLOCKED on \$target_host\"
end
"

# ==================================================
# POLICY: MICROSOFT STORE LOCK / UNLOCK
# ==================================================
eval "
function $LAB_CMD_PREFIX-lock-store
    for i in \$LAB_HOSTS
        set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
        echo \">>> Blocking Store on \$target_host\"
        ssh $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\"
        scp \$LAB_SCRIPTS_DIR/store-lock.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/store-lock.ps1\"
        ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\store-lock.ps1\"
    end
    echo \"🚫 Microsoft Store BLOCKED on all machines\"
end

function $LAB_CMD_PREFIX-unlock-store
    for i in \$LAB_HOSTS
        set target_host \"$LAB_HOST_PREFIX\$i$LAB_HOST_SUFFIX\"
        echo \">>> Restoring Store on \$target_host\"
        ssh $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\"
        scp \$LAB_SCRIPTS_DIR/store-unlock.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/store-unlock.ps1\"
        ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\store-unlock.ps1\"
    end
    echo \"✅ Microsoft Store RESTORED on all machines\"
end

function $LAB_CMD_PREFIX-lock-store-one --argument n
    set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
    echo \">>> Blocking Store on \$target_host\"
    ssh $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\"
    scp \$LAB_SCRIPTS_DIR/store-lock.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/store-lock.ps1\"
    ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\store-lock.ps1\"
    echo \"🚫 Microsoft Store BLOCKED on \$target_host\"
end

function $LAB_CMD_PREFIX-unlock-store-one --argument n
    set target_host \"$LAB_HOST_PREFIX\$n$LAB_HOST_SUFFIX\"
    echo \">>> Restoring Store on \$target_host\"
    ssh $LAB_USER@\$target_host \"mkdir C:\\\\$LAB_CMD_PREFIX 2>nul\"
    scp \$LAB_SCRIPTS_DIR/store-unlock.ps1 $LAB_USER@\$target_host:\"C:/$LAB_CMD_PREFIX/store-unlock.ps1\"
    ssh $LAB_USER@\$target_host \"powershell -ExecutionPolicy Bypass -File C:\\\\$LAB_CMD_PREFIX\\\\store-unlock.ps1\"
    echo \"✅ Microsoft Store RESTORED on \$target_host\"
end
"
