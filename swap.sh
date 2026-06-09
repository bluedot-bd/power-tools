#!/bin/bash
echo "Size of swap file (GB):"
read size
sudo fallocate -l ${size}G /swapfile
ls -lh /swapfile
sudo chmod 600 /swapfile
ls -lh /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo swapon -s
free -m
echo "/swapfile   none    swap    sw    0   0" >> /etc/fstab
cat /proc/sys/vm/swappiness
sudo sysctl vm.swappiness=10
echo "vm.swappiness=10" >> /etc/sysctl.conf
cat /proc/sys/vm/vfs_cache_pressure
sudo sysctl vm.vfs_cache_pressure=50
echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
free -m
echo "Viola , Job Done !"
