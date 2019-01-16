#/bin/bash

set -e

. $(dirname $0)/support.inc

if [ -z "$1" ]; then    
    echo "usage: $(basename $0) <ROOT>"
    exit 1
fi

ensure_ROOT "$1"

# See https://bitbucket.org/janvrany/jv-libgdbs/src/tip/doc/GDB.md
git clone binutils-gdb "${ROOT}/tmp/binutils-gdb"

sudo chroot "${ROOT}" /usr/bin/apt-get -y install texinfo python3-dev flex bison libexpat1-dev libncurses-dev gawk libncurses5-dev  libncursesw5-dev
sudo chroot "${ROOT}" /usr/bin/apt-get clean
sudo chroot "${ROOT}" /bin/bash -c "cd /tmp/binutils-gdb && ./configure --disable-werror --enable-tui --with-guile=no -with-python=/usr/bin/python3"
sudo chroot "${ROOT}" /bin/bash -c "cd /tmp/binutils-gdb && make -j4"
sudo chroot "${ROOT}" /bin/bash -c "cd /tmp/binutils-gdb && make install"
sudo rm -rf "${ROOT}/tmp/binutils-gdb"

