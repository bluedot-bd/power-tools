#!/bin/bash

# This script will first disable UFW, then reset the iptables and ip6tables rules to their default state, allowing all traffic.

# Disable UFW
echo "Disabling UFW..."
sudo ufw disable

# Define the tables to clear for both IPv4 and IPv6
TABLES=("filter" "nat" "mangle")

# Loop through each specified table for iptables (IPv4)
for TABLE in "${TABLES[@]}"
do
    echo "Flushing and deleting chains in table: $TABLE (IPv4)"
    # Flush all rules in the table
    sudo iptables -t $TABLE -F
    # Delete all user-defined chains in the table
    sudo iptables -t $TABLE -X
    # Reset the default policies in the table to ACCEPT
    sudo iptables -t $TABLE -P INPUT ACCEPT
    sudo iptables -t $TABLE -P FORWARD ACCEPT
    sudo iptables -t $TABLE -P OUTPUT ACCEPT
done

# Loop through each specified table for ip6tables (IPv6)
for TABLE in "${TABLES[@]}"
do
    echo "Flushing and deleting chains in table: $TABLE (IPv6)"
    # Flush all rules in the table
    sudo ip6tables -t $TABLE -F
    # Delete all user-defined chains in the table
    sudo ip6tables -t $TABLE -X
    # Reset the default policies in the table to ACCEPT
    sudo ip6tables -t $TABLE -P INPUT ACCEPT
    sudo ip6tables -t $TABLE -P FORWARD ACCEPT
    sudo ip6tables -t $TABLE -P OUTPUT ACCEPT
done

# Additional reset for the nat table (only applicable for iptables/IPv4)
sudo iptables -t nat -P PREROUTING ACCEPT
sudo iptables -t nat -P POSTROUTING ACCEPT
sudo iptables -t nat -P OUTPUT ACCEPT

echo "All iptables and ip6tables rules have been reset to default (ACCEPT)."

# Save the settings for both iptables and ip6tables (uncomment the following lines if you have iptables-persistent installed)
# sudo netfilter-persistent save
# sudo ip6tables-save | sudo tee /etc/iptables/rules.v6 > /dev/null

# Uncomment the following lines if you need to manually save to specific files
# sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
# sudo ip6tables-save | sudo tee /etc/iptables/rules.v6 > /dev/null

echo "iptables and ip6tables rules reset and saved."
