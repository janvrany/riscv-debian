#!/bin/bash

set -e

. $(dirname $0)/support.inc

if [ -z "$1" ]; then    
    echo "usage: $(basename $0) <DEBIAN_IMAGE>"
    exit 1
fi

DEBIAN_IMAGE=$1
QEMU=/home/jv/bin/qemu-system-riscv64

if [ ! \( -b "$DEBIAN_IMAGE" -o -f "$DEBIAN_IMAGE" \) ]; then
    echo "E: Invalid DEBIAN_IMAGE (not a block device or file): $DEBIAN_IMAGE"
    exit 1
fi 

if [ ! -f "$KERNEL_IMAGE" ]; then
    echo "E: Invalid KERNEL_IMAGE (no such file): $KERNEL_IMAGE"
    echo 
    echo "I: Did you forgot to run 'debian-mk-kernel.mk' script?"
    exit 2
fi

echo "To (SSH) connect to running Debian, do"
echo 
echo "    ssh localhost -p 5555"
echo 
if ! confirm "Continue"; then
    exit 0
fi

${QEMU} -nographic -machine virt \
    -kernel "$KERNEL_IMAGE" -append "earlyprintk rw root=/dev/vda" \
    -drive file=${DEBIAN_IMAGE},format=raw,id=hd0 -device virtio-blk-device,drive=hd0 \
    -netdev user,id=net0,hostfwd=tcp::5555-:22 -device virtio-net-device,netdev=net0

