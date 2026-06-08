# ===============================
# RESTORE NETWORK
# ===============================

# Remove custom rules
netsh advfirewall firewall delete rule name="DSLAB-BLOCK-OUT" 2>$null
netsh advfirewall firewall delete rule name="DSLAB-ALLOW-LAN" 2>$null
netsh advfirewall firewall delete rule name="DSLAB-ALLOW-SSH" 2>$null
netsh advfirewall firewall delete rule name="DSLAB-ALLOW-DNS" 2>$null
netsh advfirewall firewall delete rule name="DSLAB-ALLOW-MDNS" 2>$null
netsh advfirewall firewall delete rule name="DSLAB-ALLOW-LLMNR" 2>$null

# Restore Default Outbound Policy to ALLOW
Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Allow

Write-Host "Internet RESTORED. Default Outbound Action is set to Allow."
