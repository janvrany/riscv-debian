#!/bin/bash

set -e

. $(dirname $0)/support.inc

if [ -z "$1" ]; then
    echo "usage: $(basename $0) <DEBIAN_IMAGE>"
    echo "       QEMU=/path/to/qemu-system-riscv64 $(basename $0) <DEBIAN_IMAGE>"
    exit 1
fi

DEBIAN_IMAGE=$1
if [ -z "$QEMU" ]; then
    QEMU=/opt/riscv/bin/qemu-system-riscv64
    if [ ! -f "$QEMU" ]; then
        QEMU=$(which qemu-system-riscv64)
        if [ -f "$QEMU" ]; then
            echo "W: Using system QEMU, may hang. Please check README.md"
        fi
    fi
fi

if [ ! -f "$QEMU" ]; then
    echo "E: Invalid QEMU (no such file): $QEMU"
    exit 1
fi

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
echo "Local port 7000 is forwarded to running Debian, port 7000,"
echo "you may use this for example for remote debugging using"
echo "gdbserver:"
echo 
echo "    (gdb) target remote localhost:7000"
echo 
if ! confirm "Continue"; then
    exit 0
fi

${QEMU} -nographic -machine virt \
    -m 2G \
    -bios none \
    -kernel "$KERNEL_IMAGE" -append "earlyprintk=keep rw root=/dev/vda" \
    -drive file=${DEBIAN_IMAGE},format=raw,id=hd0 -device virtio-blk-device,drive=hd0 \
    -netdev user,id=net0,hostfwd=tcp::5555-:22,hostfwd=tcp::7000-:7000 -device virtio-net-device,netdev=net0

