# ===============================
# LAB EXAM MODE (SAFE)
# Keeps .local + SSH working
# ===============================

# Remove old rules to ensure clean slate
netsh advfirewall firewall delete rule name="LAB-BLOCK-OUT" 2>$null
netsh advfirewall firewall delete rule name="LAB-ALLOW-LAN" 2>$null
netsh advfirewall firewall delete rule name="LAB-ALLOW-SSH" 2>$null
netsh advfirewall firewall delete rule name="LAB-ALLOW-DNS" 2>$null
netsh advfirewall firewall delete rule name="LAB-ALLOW-MDNS" 2>$null
netsh advfirewall firewall delete rule name="LAB-ALLOW-LLMNR" 2>$null

# Change Default Outbound Policy to BLOCK
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Block

# Allow LAN Outbound (crucial for SSH responses, file shares, and control)
netsh advfirewall firewall add rule name="LAB-ALLOW-LAN" `
    dir=out action=allow `
    remoteip=LocalSubnet profile=any

# Allow DNS Outbound (so machine can resolve local hostnames)
netsh advfirewall firewall add rule name="LAB-ALLOW-DNS" `
    dir=out action=allow `
    protocol=UDP remoteport=53 profile=any

# Allow mDNS (.local)
netsh advfirewall firewall add rule name="LAB-ALLOW-MDNS" `
    dir=out action=allow `
    protocol=UDP remoteport=5353 profile=any

# Allow LLMNR
netsh advfirewall firewall add rule name="LAB-ALLOW-LLMNR" `
    dir=out action=allow `
    protocol=UDP remoteport=5355 profile=any

# Allow SSH Outbound Explicitly (Fail-safe for active connections)
netsh advfirewall firewall add rule name="LAB-ALLOW-SSH" `
    dir=out action=allow `
    protocol=TCP localport=22 profile=any

Write-Host "Internet BLOCKED. Default Outbound Action is set to Block."
