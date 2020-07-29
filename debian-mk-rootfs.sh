#/bin/bash

set -e

. $(dirname $0)/support.inc

if [ -z "$1" ]; then
    echo "usage: $(basename $0) <ROOT>"
    exit 1
fi

ensure_ROOT "$1"

# ensure_ROOT mount /proc, /sys, /dev/pts and /dev/shm in order to allow
# for easy chroot. However,`mmdebstrap` requires destination directory to
# be empty so umount them (if mounted)
unbind_filesystems


# mkfs.ext3 creates lost+found directory, but `mmdebstrap` requires
# destination directory to be empty. So, remove `lost+found` is it exists
# and if it's empty
if [ -d "${ROOT}/lost+found" ]; then
    if [ -z "$(ls -A ${ROOT}/lost+found)" ]; then
        sudo rmdir "${ROOT}/lost+found"
    fi
fi

# `mmdebstrap requires destination directory to be empty, check here
if [ ! -z "$(ls -A ${ROOT})" ]; then
    echo "Root directory is not empty: ${ROOT}"
    echo "Please remove all files an retry"
    exit 2
fi

sudo mmdebstrap \
    --variant=minbase --mode=sudo \
    --architectures=riscv64 --include="debian-ports-archive-keyring" \
    sid "$ROOT" \
    "deb http://deb.debian.org/debian-ports/ sid main" \
    "deb http://deb.debian.org/debian-ports/ unreleased main"

printf "Package: *\nPin: release a=experimental\nPin-Priority: 5\n" | sudo tee "${ROOT}/etc/apt/preferences.d/experimental.pref"
printf "deb http://deb.debian.org/debian-ports/ experimental main" | sudo tee "${ROOT}/etc/apt/sources.list.d/experimental.list"

bind_filesystems

sudo chroot "${ROOT}" /usr/bin/apt-get update
sudo chroot "${ROOT}" /usr/bin/apt-get -y install \
    isc-dhcp-client adduser apt base-files base-passwd bash bsdutils \
    coreutils dash debconf debian-archive-keyring debian-ports-archive-keyring \
    debianutils diffutils dpkg e2fsprogs fdisk findutils gpgv grep gzip \
    hostname init-system-helpers libbz2-1.0 libc-bin libc6 libffi7 libgcc1 \
    libgmp10 libgnutls30 liblz4-1 liblzma5 libncursesw5 libstdc++6 login mawk \
    mount ncurses-base ncurses-bin passwd perl-base sed systemd systemd-sysv tar \
    tzdata util-linux zlib1g nano wget busybox net-tools ifupdown \
    iputils-ping ntp lynx dialog ca-certificates less \
    build-essential apt-utils openssh-server openssh-client \
    nfs-client sudo bash-completion tmux adduser acl socat git vim ethtool \
    texinfo python3-dev flex bison libexpat1-dev libncurses-dev gawk \
    libncurses5-dev libncursesw5-dev procps udev locales zip unzip

# Following are needed for OMR / OpenJ9
sudo chroot "${ROOT}" /usr/bin/apt-get -y install \
    cmake \
    libdwarf-dev libelf-dev \
    libx11-dev libxext-dev libxrender-dev libxrandr-dev libxtst-dev libxt-dev \
    libasound2-dev

sudo chroot "${ROOT}" dpkg --configure -a


sudo sh -c "cat >${ROOT}/etc/fstab <<EOF
proc                /proc       proc    defaults            0       0
sysfs               /sys        sysfs   defaults,nofail     0       0
devpts              /dev/pts    devpts  defaults,nofail     0       0

#
# Uncomment and edit line below to mount home over NFS
#
#server:/export     /home       nfs4    noatime,async       0       0


EOF
"

sudo sh -c "cat >${ROOT}/etc/network/interfaces <<EOF
source-directory /etc/network/interfaces.d
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF
"

sudo chroot "${ROOT}" systemctl mask serial-getty@ttyS0.service
sudo chroot "${ROOT}" systemctl mask serial-getty@hvc0.service
sudo chroot "${ROOT}" systemctl unmask console-getty.service
sudo chroot "${ROOT}" systemctl enable console-getty.service

sudo sh -c "echo \"debian-sid-rv64\" > \"${ROOT}/etc/hostname\""

sudo chroot "${ROOT}" apt autoremove

# Download and install riscv.h and riscv-opc.h - these are needed for
# OMR RISC-V port and for Smalltalk/X
sudo wget "-O${ROOT}/usr/local/include/riscv.h" 'https://sourceware.org/git/gitweb.cgi?p=binutils-gdb.git;a=blob_plain;f=include/opcode/riscv.h;hb=HEAD'
sudo wget "-O${ROOT}/usr/local/include/riscv-opc.h" 'https://sourceware.org/git/gitweb.cgi?p=binutils-gdb.git;a=blob_plain;f=include/opcode/riscv-opc.h;hb=HEAD'

# This is workaround for CMake-based cross compilation
(cd "${ROOT}/usr/lib/riscv64-linux-gnu" && sudo ln -s ../../../lib/riscv64-linux-gnu/libz.so.1 .)

echo "Enter password for user 'root', i.e, \"sifive\" (no quotes):"
sudo chroot "${ROOT}" /usr/bin/passwd root

echo "Creating user $USER..."
sudo chroot "${ROOT}" useradd --create-home --uid $(id --user) $USER

echo "Enter password for user '$USER':"
sudo chroot "${ROOT}" /usr/bin/passwd $USER
sudo chroot "${ROOT}" /usr/bin/chsh -s /bin/bash $USER
sudo sh -c "cat >${ROOT}/etc/sudoers.d/$USER <<EOF
${USER}     ALL=(ALL:ALL) ALL
EOF
"

