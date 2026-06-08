# Template Configuration File
# Copy this to lab_vars.fish and edit with your details

# The command prefix for all generated functions (e.g. if 'labctl', commands become 'labctl-all')
set -g LAB_CMD_PREFIX "labctl"

# The SSH username for all lab machines
set -g LAB_USER "admin"

# The hostname prefix and suffix.
set -g LAB_HOST_PREFIX "pc-"
set -g LAB_HOST_SUFFIX ".lan"

# List of all host numbers in your lab
set -g LAB_HOSTS 1 2 3 4 5

# Protected hosts (e.g., teacher PC)
set -g LAB_PROTECTED_HOSTS 1

# Path to the scripts directory
set -g LAB_SCRIPTS_DIR (status dirname)/scripts
