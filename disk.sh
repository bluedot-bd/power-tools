#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

# Ask the user for the desired operation
echo "Choose an option:"
echo "1. Format and Mount"
echo "2. Just Mount"
read -rp "Enter your choice (1 or 2): " CHOICE

# Validate the choice
if [[ "$CHOICE" != "1" && "$CHOICE" != "2" ]]; then
    echo "Invalid choice. Exiting."
    exit 1
fi

# List available disks
echo "Available disks and partitions:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

# Prompt for the disk/partition
if [ "$CHOICE" -eq 1 ]; then
    read -rp "Enter the disk to format and partition (e.g., /dev/sdb): " DISK
    if [ ! -b "$DISK" ]; then
        echo "Error: Disk $DISK does not exist."
        exit 1
    fi
else
    read -rp "Enter the partition to mount (e.g., /dev/sdb1): " PARTITION
    if [ ! -b "$PARTITION" ]; then
        echo "Error: Partition $PARTITION does not exist."
        exit 1
    fi
fi

# Perform the chosen operation
if [ "$CHOICE" -eq 1 ]; then
    # Determine partition table type
    DISK_SIZE_BYTES=$(lsblk -b -dn -o SIZE "$DISK")
    DISK_SIZE_GB=$((DISK_SIZE_BYTES / 1024 / 1024 / 1024))

    if [ "$DISK_SIZE_GB" -gt 1000 ]; then
        PARTITION_TABLE="gpt"
    else
        PARTITION_TABLE="msdos"
    fi

    echo "Disk size: ${DISK_SIZE_GB}GB. Using partition table: $PARTITION_TABLE."

    # Confirm before proceeding
    echo "WARNING: This will destroy all data on $DISK."
    read -rp "Do you want to continue? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "Operation cancelled."
        exit 1
    fi

    # Partition and format the disk
    echo "Creating a new $PARTITION_TABLE partition on $DISK..."
    parted -s "$DISK" mklabel "$PARTITION_TABLE" mkpart primary ext4 0% 100%

    sleep 2

    if [ -b "${DISK}1" ]; then
        PARTITION="${DISK}1"
    elif [ -b "${DISK}p1" ]; then
        PARTITION="${DISK}p1"
    else
        echo "Error: Partition not found."
        exit 1
    fi

    echo "Formatting $PARTITION as ext4..."
    mkfs.ext4 -F "$PARTITION"
fi

# Mount the partition
read -rp "Enter the mount point (e.g., /mnt/mydisk): " MOUNT_POINT

mkdir -p "$MOUNT_POINT"

echo "Mounting $PARTITION to $MOUNT_POINT..."
mount "$PARTITION" "$MOUNT_POINT"

if [ $? -ne 0 ]; then
    echo "Error: Failed to mount $PARTITION."
    exit 1
fi

# Check for blkid availability
if ! command -v blkid &>/dev/null; then
    if [ -x "/usr/sbin/blkid" ]; then
        BLKID_CMD="/usr/sbin/blkid"
    else
        echo "Error: blkid not found. Please install util-linux."
        exit 1
    fi
else
    BLKID_CMD="blkid"
fi

# Get the UUID of the partition
UUID=$($BLKID_CMD -s UUID -o value "$PARTITION")

if [ -z "$UUID" ]; then
    echo "Error: Unable to determine UUID for $PARTITION."
    exit 1
fi

echo "UUID for $PARTITION is $UUID."

# Backup the fstab file
cp /etc/fstab /etc/fstab.bak

# Add entry to /etc/fstab if it doesn't already exist
if ! grep -q "$UUID" /etc/fstab; then
    echo "Adding entry to /etc/fstab..."
    echo "UUID=$UUID    $MOUNT_POINT    auto    defaults    0    2" >> /etc/fstab
else
    echo "An entry for $PARTITION already exists in /etc/fstab."
fi

echo "Partition $PARTITION successfully mounted at $MOUNT_POINT and configured to automount on boot."

# Display the current disk usage
df -m
