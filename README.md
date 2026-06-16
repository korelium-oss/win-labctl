# win-labctl

A Fish shell CLI to manage a Windows lab over SSH. Same idea as labctl (for macOS), but this one targets Windows machines running OpenSSH with PowerShell.

It lets you control your whole Windows lab from your terminal — reboot machines, deploy software, lock down the internet, reset student data — all in parallel without physically touching each PC.

---

## Why I built this

I wasn't just managing a Mac lab. I was managing a mixed lab — some Macs, some Windows machines. Same problems, different OS.

Once labctl was working, the Macs were a breeze. I could reset or lock down 33 Macs in seconds without standing up. But the Windows PCs? I was still running around the room like a madman, machine by machine, clicking through Windows settings, resetting accounts, dragging USB drives around to install software. It was stupid. I'd sit at my desk, look at the fully automated Macs, and then look at the Windows PCs and just dread the next exam. It felt half-done and it drove me crazy.

So I built this to stop the running around. The approach here is different because Windows doesn't have the same native SSH tooling as macOS, so everything works through PowerShell scripts pushed over SSH. The Fish shell on my admin Mac orchestrates the commands, and PowerShell handles the actual execution on the Windows side.

There's a one-time setup to get OpenSSH running on each Windows machine. After that, it scales the same way labctl does — configure your lab variables once, and you can control the entire room from your terminal.

---

## What it does

| What | Single machine | All machines |
|---|---|---|
| Power | `labctl7 reboot` | `labctl-all reboot` |
| Status | `labctl-all status` | — |
| Reset student data | `labctl-reset-7` | `labctl-reset-all` |
| Lock internet | `labctl-net-off 7` | `labctl-net-off-all` |
| Unlock internet | `labctl-net-on 7` | `labctl-net-on-all` |
| Block installers | `labctl-lock-inst 7` | `labctl-lock-installers` |
| Install VS Code | `labctl-code-install` | — |
| Install Python | `labctl-python-install` | — |
| Wake machine | `labctl-all wake` | — |
| Scan MAC addresses | `labctl-mac-scan` | — |
| Check disk / RAM | `labctl-hw-scan` | — |

The number in the command is the machine number — so `labctl7` maps to your 7th Windows PC.

---

## How the reset works

There's no DeepFreeze license needed. The `reset.ps1` script is deployed to each machine and scheduled to run at logon. It wipes the student profile back to a clean state. You can toggle it on or off per machine or for the whole lab.

---

## Requirements

- Fish Shell on your admin machine (Mac or Linux)
- OpenSSH running on all Windows PCs
- SSH access from your machine to all lab PCs
- All lab PCs should share the same admin username

---

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/korelium-oss/win-labctl.git
cd win-labctl
```

### 2. Configure your lab

```bash
cp lab_vars.template.fish lab_vars.fish
```

Edit `lab_vars.fish` with your SSH username, host prefix, and command prefix.

### 3. Set up Wake-on-LAN (optional)

```bash
cp macs.template.txt macs.txt
```

Fill in the MAC addresses of your machines.

### 4. Load into Fish

Add this to `~/.config/fish/config.fish`:

```fish
source ~/win-labctl/labctl.fish
```

### 5. Reload your shell

Open a new terminal and you're ready.

---

## Project structure

```
win-labctl/
├── labctl.fish              # Entry point — loads modules
├── lab_vars.template.fish   # Copy this to lab_vars.fish and edit it
├── macs.template.txt        # Copy this to macs.txt and add MAC addresses
└── modules/
    ├── core.fish            # SSH, status, power commands
    ├── reset.fish           # Student data wipe (DeepFreeze alternative)
    ├── policy.fish          # Block/allow installers and Microsoft Store
    ├── network.fish         # Internet on/off per machine or lab-wide
    ├── software.fish        # Remote software deployment
    └── utility.fish         # File copy, hardware scan, etc.
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.
