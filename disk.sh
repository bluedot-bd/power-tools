#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

echo "Available disks:"
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

read -rp "Enter the disk to partition (e.g., /dev/sdb): " DISK

if [ ! -b "$DISK" ]; then
    echo "Error: Disk $DISK does not exist."
    exit 1
fi

DISK_SIZE_BYTES=$(lsblk -b -dn -o SIZE "$DISK")
DISK_SIZE_GB=$((DISK_SIZE_BYTES / 1024 / 1024 / 1024))

if [ "$DISK_SIZE_GB" -gt 1000 ]; then
    PARTITION_TABLE="gpt"
else
    PARTITION_TABLE="msdos"
fi

echo "Disk size: ${DISK_SIZE_GB}GB. Using partition table: $PARTITION_TABLE."

echo "WARNING: This will destroy all data on $DISK."
read -rp "Do you want to continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Operation cancelled."
    exit 1
fi

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

read -rp "Enter the mount point (e.g., /mnt/mydisk): " MOUNT_POINT

mkdir -p "$MOUNT_POINT"

echo "Mounting $PARTITION to $MOUNT_POINT..."
mount "$PARTITION" "$MOUNT_POINT"

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

UUID=$($BLKID_CMD -s UUID -o value "$PARTITION")

cp /etc/fstab /etc/fstab.bak

if ! grep -q "$UUID" /etc/fstab; then
    echo "Adding entry to /etc/fstab..."
    echo "UUID=$UUID    $MOUNT_POINT    ext4    defaults    0    2" >> /etc/fstab
else
    echo "An entry for $PARTITION already exists in /etc/fstab."
fi

echo "Disk $PARTITION successfully mounted at $MOUNT_POINT and configured to automount on boot."

df -m
