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

umount_ROOT