#/bin/bash

set -e

. $(dirname $0)/support.inc

if [ -z "$1" ]; then
    echo "usage: $(basename $0) <ROOT>"
    exit 1
fi

ensure_ROOT "$1"

sudo chroot "${ROOT}" /bin/bash