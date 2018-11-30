#/bin/bash

set -e

. $(dirname $0)/riscv-debian.inc

if [ -z "$1" ]; then    
    echo "usage: $(basename $0) <ROOT>"
    exit 1
fi

ensure_ROOT "$1"


# if [ -z 'xxx' ]; then

for fs in proc sys dev/pts dev/shm; do
    if [ -d "${ROOT}/$fs" ]; then
        if mount | grep $(realpath "${ROOT}/$fs") > /dev/null; then
            sudo umount $(realpath "${ROOT}/$fs")
        fi
    fi
done


# mkfs.ext3 creates lost+found directory, but `mmdebstrap` requires
# destination directory to be empty. So, remove `lost+found` is it exists
# and if it's empty
if [ -d "${ROOT}/lost+found" ]; then
    if [ -z "$(ls -A ${ROOT}/lost+found)" ]; then
        sudo rmdir "${ROOT}/lost+found"
    fi
fi

# # `mmdebstrap requires destination directory to be empty, check here
# if [ ! -z "$(ls -A ${ROOT})" ]; then
#     echo "Root directory is not empty: ${ROOT}"
#     echo "Please remove all files an retry"
#     exit 2
# fi

# sudo mmdebstrap \
#     --variant=minbase --mode=sudo \
#     --architectures=riscv64 --include="debian-ports-archive-keyring,pump" \
#     sid "$ROOT" \
#     "deb http://deb.debian.org/debian-ports/ sid main" \
#     "deb http://deb.debian.org/debian-ports/ unreleased main"



sudo chroot "${ROOT}" /usr/bin/apt-get update
sudo chroot "${ROOT}" /usr/bin/apt-get -y install \
    adduser apt base-files base-passwd bash bsdutils coreutils dash debconf \
    debian-archive-keyring debian-ports-archive-keyring debianutils diffutils \
    dpkg e2fsprogs fdisk findutils gcc-8-base gpgv grep gzip hostname \
    init-system-helpers libacl1 libapt-pkg5.0 libattr1 libaudit-common \
    libaudit1 libblkid1 libbz2-1.0 libc-bin libc6 libcap-ng0 libcom-err2 \
    libdb5.3 libdebconfclient0 libext2fs2 libfdisk1 libffi7 libgcc1 libgcrypt20 \
    libgmp10 libgnutls30 libgpg-error0 libhogweed4 libidn2-0 liblz4-1 liblzma5 \
    libmount1 libncursesw5 libnettle6 libp11-kit0 libpam-modules \
    libpam-modules-bin libpam-runtime libpam0g libpcre3 libselinux1 \
    libsemanage-common libsemanage1 libsepol1 libsmartcols1 libss2 libstdc++6 \
    libsystemd0 libtasn1-6 libtinfo5 libudev1 libunistring2 libuuid1 login mawk \
    mount ncurses-base ncurses-bin passwd perl-base sed sysvinit-core sysvinit-utils tar \
    tzdata util-linux zlib1g nano wget busybox net-tools ifupdown \
    iputils-ping ntp lynx whiptail dialog ca-certificates less \
    build-essential apt-utils dropbear-run dropbear-bin openssh-client \
    nfs-client sudo bash-completion tmux


sudo chroot "${ROOT}" dpkg --configure -a


sudo sh -c "cat >${ROOT}/etc/fstab <<EOF
proc    /proc   proc    defaults        0       0
sysfs   /sys    sysfs   defaults,nofail 0       0
devpts  /dev/pts        devpts  defaults,nofail 0       0
EOF
"

sudo sh -c "cat >${ROOT}/etc/network/interfaces <<EOF
source-directory /etc/network/interfaces.d
auto lo
iface lo inet loopback

allow-hotplug eth0
iface eth0 inet dhcp
EOF
"

sudo sh -c "echo \"con:23:respawn:/sbin/getty -L console 115200 vt102\" >> \"${ROOT}/etc/inittab\""
sudo sed -i -e  's/^\([1-6].*tty[1-6]\)$/# \1/g' "${ROOT}/etc/inittab"

sudo sh -c "echo \"debian-sid-rv64\" > \"${ROOT}/etc/hostname\""

sudo chroot "${ROOT}" update-rc.d checkroot.sh enable S
sudo chroot "${ROOT}" apt autoremove

echo "Enter password for user 'root', i.e, \"sifive\" (no quotes):"
sudo chroot "${ROOT}" /usr/bin/passwd root

echo "Creating user $USER..."
sudo chroot "${ROOT}" useradd --uid $(id --user) $USER

echo "Enter password for user '$USER':"
sudo chroot "${ROOT}" /usr/bin/passwd $USER

