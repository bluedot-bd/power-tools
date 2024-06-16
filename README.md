# Power Tools
Welcome to the Power Tools repository! This collection is designed to offer system administrators quick and effective Bash scripts to handle tedious and complex tasks in seconds. Each tool is crafted to maximize efficiency and simplify the management of systems.

### Reset Iptables Tool
This script is designed for environments where a complete reset of the firewall to a default state (all traffic allowed) is necessary. It's ideal for development or testing scenarios. Use with extreme caution in production environments, as it removes all firewall protections.
#### Usage
Download and execute the iptables reset script with the following commands:
```bash
# Download the script
wget -O iptables-reset.sh https://raw.githubusercontent.com/bluedot-bd/power-tools/main/iptables-reset.sh

# Make the script executable
chmod +x iptables-reset.sh

# Run the script with administrative privileges
sudo ./iptables-reset.sh
```
#### Notice
**Caution:** This tool modifies kernel-level firewall settings. It is crucial to understand the implications of running this script:
1. **Review the Code:** Before execution, inspect the script to verify its actions and ensure it aligns with your security policies and expectations.
2. **Backup Access:** Set up a backup access method, such as VNC, before applying these changes to avoid being locked out from your system if network settings are disrupted.

## How to Contribute
Contributions to improve existing scripts or add new ones are welcome. Please submit pull requests or open issues to discuss new features or enhancements.
