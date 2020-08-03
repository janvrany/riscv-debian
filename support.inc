OPENSBI_IMAGE=opensbi/build/platform/qemu/virt/firmware/fw_jump.bin
OPENSBI_IMAGE_FOR_UNLEASHED=opensbi/build/platform/sifive/fu540/firmware/fw_payload.bin

KERNEL_IMAGE="riscv-linux/arch/riscv/boot/Image"
KERNEL_IMAGE_FOR_UNLEASHED="riscv-linux/arch/riscv/boot/Image"

function confirm ()  {
  echo  -n "$1 [y/n/Ctrl-C]? "
  read answer
  finish="-1"
  while [ "$finish" = '-1' ]
  do
    finish="1"
    if [ "$answer" = '' ];
    then
      answer=""
    else
      case $answer in
        y | Y | yes | YES ) return 0;;
        n | N | no | NO ) return 1;;
        *) finish="-1";
           echo -n 'Invalid response -- please reenter:';
           read answer;;
       esac
    fi
  done  
}

# Bind /proc /sys and so on into the $ROOT filesystem
function bind_filesystems() {
    if [ -z "$ROOT" ]; then
        echo "E: ROOT variable not set"
        return 1
    fi
    if [ ! -d "$ROOT" ]; then
        echo "E: ROOT is not a directory"
        return 1
    fi
    for fs in proc sys dev/pts dev/shm; do
        if [ -d "${ROOT}/$fs" ]; then
            echo "I: mounting /$fs into ${ROOT}/$fs"
            sudo mount --bind "/$fs" "${ROOT}/$fs"
        fi
    done
    trap unbind_filesystems EXIT
}

# Bind /proc /sys and so on into the $ROOT filesystem
function unbind_filesystems() {
    if [ -z "$ROOT" ]; then
        echo "E: ROOT variable not set"
        return 1
    fi
    if [ ! -d "$ROOT" ]; then
        echo "E: ROOT is not a directory"
        return 1
    fi
    for fs in proc sys dev/pts dev/shm; do
        if [ -d "${ROOT}/$fs" ]; then
            if mount | grep $(realpath "${ROOT}/$fs") > /dev/null; then
                echo "I: umounting '${ROOT}/$fs'"
                sudo umount $(realpath "${ROOT}/$fs")
            fi
        fi
    done
}


# Set ROOT variable to a full patch to Debian root
# filesystem.
#
# If the parameter is a directory, then this directory is returned.
#
# Returns 0 if ROOT directory has been set, 1 otherwise

function ensure_ROOT() {
    if [ -z "$1" ]; then
        echo "E: Invalid ROOT (no ROOT directory, device or file given)"
        return 1
    elif [ -d "$1" ]; then
        ROOT=$(realpath "$1")
        return 0
    elif [ \( \( -f "$1" \) -a \( -w "$1" \) \) -o \( -b "$1" \) ]; then
        ROOT=$(mktemp -d)
        mount_ROOT "$1"
        return 0
    else
        echo "E: Invalid ROOT (not a directory): $1"
        return 1
    fi
}

# Mounts Debian root filesystem on given device file
# (passed in $1) into directory in ROOT variable.
function mount_ROOT() {
    echo "I: mounting $1 into ${ROOT}"
    if [ -b "$1" ]; then
        sudo mount "$1" "${ROOT}"
    else
        sudo mount -o loop "$1" "${ROOT}"
    fi
    bind_filesystems

    # Fix name resolver...
    if [ -d "${ROOT}/etc" ]; then
        if [ -f "${ROOT}/etc/resolv.conf" ]; then
            sudo cp "${ROOT}/etc/resolv.conf" "${ROOT}/etc/resolv.conf.bak"
        fi
        sudo cp "/etc/resolv.conf" "${ROOT}/etc/resolv.conf"
    fi
    
    trap umount_ROOT EXIT
}

function umount_ROOT() {
    unbind_filesystems
    if [ -f "${ROOT}/etc/resolv.conf.bak" ]; then
        sudo cp "${ROOT}/etc/resolv.conf.bak" "${ROOT}/etc/resolv.conf"
    fi
    if grep "${ROOT}" /etc/mtab > /dev/null; then
        echo "I: umounting '${ROOT}'"
        sudo umount "$ROOT"
    fi
}