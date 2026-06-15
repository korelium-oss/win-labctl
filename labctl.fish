# ==================================================
# LABCTL ROUTER
# ==================================================
set -g LAB_BASE_DIR (status dirname)
set config_file $LAB_BASE_DIR/lab_vars.fish

if test -f $config_file
    source $config_file
else
    echo "⚠️ LABCTL: Configuration file not found at $config_file"
    echo "Please copy lab_vars.template.fish to lab_vars.fish and configure it."
    return
end

# Load all modules dynamically
for module in $LAB_BASE_DIR/modules/*.fish
    source $module
end
