#!/bin/bash

set -e

. $(dirname $0)/support.inc

if [ -z "$1" -o -z "$2" ]; then    
    echo "usage: $(basename $0) <ROOT> <SDCARD_PARTITION_2>"
    exit 1
elif [ ! -b "$2" ]; then
    echo "E: Invalid SDCARD_PARTITION_2: $2"
    exit 1
fi

ensure_ROOT "$1"
SDCARD_PARTITION_2=$2

if ! confirm "Format $SDCARD_PARTITION_2 - all data will be lost"; then
    exit 0
fi

echo "I: Formatting $SDCARD_PARTITION_2"
sudo /sbin/mkfs.ext4 "$SDCARD_PARTITION_2"

SRC="$ROOT"
DST=$(mktemp -d)

echo "I: Mounting $SDCARD_PARTITION_2 into $DST"
sudo mount "$SDCARD_PARTITION_2" "$DST"
trap "sudo umount $DST" EXIT

echo "I: Copying files from $SRC to $DST"
sudo rsync -xaHAXv "$SRC/" "$DST/"
echo "I: Done"

# See https://forums.sifive.com/t/linux-4-20-on-hifive-unleashed/1955
echo "I: Fixing eth0 ring buffer sizes"
echo "	up sleep 5; ethtool -G eth0 rx 8192; ethtool -G eth0 tx 4096" | sudo tee -a "${DST}/etc/network/interfaces"

echo "I: Use tmpfs for /tmp"
echo "tmpfs   /tmp    tmpfs   defaults        0       0"  | sudo tee -a "${DST}/etc/fstab"

echo "I: Setting hostname to 'unleashed'"
echo "unleashed" | sudo tee "${DST}/etc/hostname"

umount_ROOT