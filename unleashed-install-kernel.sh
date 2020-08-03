#!/bin/bash

set -e

. $(dirname $0)/support.inc

if [ -z "$1" ]; then
    echo "usage: $(basename $0) <SDCARD_PARTITION_1>"
    exit 1
elif [ ! -b "$1" ]; then
    echo "E: Invalid SDCARD_PARTITION_1: $1"
    exit 1
fi
SDCARD_PARTITION_1=$1

if [ ! -f "$OPENSBI_IMAGE_FOR_UNLEASHED" ]; then
    echo "E: Invalid OPENSBI_IMAGE_FOR_UNLEASHED (no such file): $OPENSBI_IMAGE_FOR_UNLEASHED"
    echo
    echo "I: Did you forgot to run 'debian-mk-kernel.mk' script?"
    exit 2
fi

if ! confirm "Really install kernel to device $SDCARD_PARTITION_1"; then
    exit 0
fi

echo "I: Copying kernel image, please wait..."
sudo dd "if=$OPENSBI_IMAGE_FOR_UNLEASHED" "of=${SDCARD_PARTITION_1}" bs=4096
echo "I: Done"

echo "I: Syncing..."
sync
echo "I: Done"
