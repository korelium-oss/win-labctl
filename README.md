# Labctl: Windows Lab Automation via SSH 🚀

Labctl is a modular, open-source Fish shell environment designed to effortlessly manage, monitor, and automate an entire fleet of Windows computers remotely using OpenSSH and PowerShell.

Instead of running around your lab installing software or locking down computers, Labctl lets you manage your entire lab right from your terminal.

## ✨ Features

- **Modular Design**: Broken down into specific modules (Network, Policy, Reset, Software, etc.) for easy maintenance.
- **DeepFreeze Alternative**: A custom `Reset` module runs a local PowerShell script on startup to wipe student data and restore the machine to a pristine state.
- **Software Deployment**: Push installations (like Python, VS Code) remotely with zero interaction.
- **Dynamic Addressing**: Configure the username, base hostname, and custom prefixes in one single `lab_vars.fish` file. The tool dynamically maps to everything.
- **Wake-on-LAN**: Wake the entire lab using a simple `macs.txt` file and magic packets.
- **Instant Parallel Execution**: Commands meant for the whole lab execute concurrently via background SSH tasks for lightning-fast speeds.

## 🛠 Setup & Installation

1. **Clone the repository** to your machine (e.g., `~/labctl`).
2. **Configure your Lab:**
   Copy the `lab_vars.template.fish` to `lab_vars.fish`:
   ```bash
   cp lab_vars.template.fish lab_vars.fish
   ```
   Edit `lab_vars.fish` to specify your lab's SSH user, host prefix, and command prefix. (Default prefix is `labctl`).
3. **Configure Wake-on-LAN (Optional):**
   Copy `macs.template.txt` to `macs.txt` and populate it with the MAC addresses of your machines.
4. **Source the Router:**
   Add this line to your `~/.config/fish/config.fish` file:
   ```bash
   source ~/labctl/labctl.fish
   ```
5. **Reload your shell** or open a new terminal, and you are good to go!

## 📚 Command Reference

All commands dynamically use your configured `$LAB_CMD_PREFIX` (default is `labctl`). You can use Fish's built-in tab completion by typing `labctl-` and hitting **Tab**!

### Core Commands (`modules/core.fish`)
* `labctl<N> [action]` - Perform an action on a specific host (e.g. `labctl7 reboot`). Actions: `down`, `reboot`, `lock`, `wake`. If no action is passed, opens an interactive SSH shell.
* `labctl-all status` - Prints a beautifully formatted table showing the ONLINE/OFFLINE status of the entire lab.
* `labctl-all reboot` / `down` / `wake` - Reboots, shuts down, or sends Wake-on-LAN packets to the entire lab in parallel.

### DeepFreeze / Reset (`modules/reset.fish`)
* `labctl-reset-all` - Deploys and schedules the wipe script (`reset.ps1`) to run on all student machines at logon.
* `labctl-reset-<N>` - Deploys the wipe script to a specific host.
* `labctl-reset-all-off` / `labctl-reset-all-on` - Globally disables or enables the scheduled reset task.
* `labctl-reset-off <N>` / `labctl-reset-on <N>` - Toggles the reset task for a specific host.

### Policy & Lockdown (`modules/policy.fish`)
* `labctl-lock-installers` / `labctl-unlock-installers` - Blocks or unblocks MSI/EXE execution globally.
* `labctl-lock-inst <N>` / `labctl-unlock-inst <N>` - Blocks/unblocks installers on a specific host.
* `labctl-lock-store` / `labctl-unlock-store` - Globally disables or enables the Microsoft Store.

### Network Controls (`modules/network.fish`)
* `labctl-net-off-all` / `labctl-net-on-all` - Globally blocks or restores external internet access while preserving local SSH management rules.
* `labctl-net-off <N>` / `labctl-net-on <N>` - Toggles internet for a specific host.

### Software Deployment (`modules/software.fish`)
* `labctl-code-install` / `labctl-python-install` - Installs VS Code or Python system-wide.
* `labctl-edge-remove-all` / `labctl-edge-remove <N>` - Forcibly uninstalls Microsoft Edge.
* `labctl-edge-restore <N>` - Re-installs Microsoft Edge using the official bootstrapper.

### Utilities (`modules/utility.fish`)
* `labctl-copy-all <file> <dest>` - Securely copies a local file to a specific destination path across the entire lab in parallel.
* `labctl-copy <N> <file> <dest>` - Securely copies a file to a specific host.
* `labctl-vlsi-create` - Quickly creates a specific folder (e.g., VLSI) in the Documents folder of all lab profiles.
* **Hardware Scanners:**
    * `labctl-mac-scan` - Connects to every machine and extracts the MAC address of its active network interface.
    * `labctl-hw-scan` - Scans and reports disk/RAM usage.
    * `labctl-mb-scan` - Scans and reports Motherboard Serial Numbers (useful for inventory).

---
*Built with ❤️ for hassle-free lab management.*
