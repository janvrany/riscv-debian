# Debian on RISC-V

A set of scripts to build a working Debian image for RISC-V. This includes usable GDB!

## Setting up host build environment

**Disclaimer:** following recipe is (semi-regularly) tested on Debian Testing (Bullseye at the time of writing). Debian 10 (Buster) is known to work too - but see comment below! If you have some other Debian-based distro, e.g, Ubuntu, this recipe may or may not work!

* Compile and install RISC-V GNU toolchain. See [RISC-V GNU toolchain README][15] on how to do so - in short following should do it:

      sudo apt-get install autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev
      git clone https://github.com/riscv/riscv-gnu-toolchain
      cd riscv-gnu-toolchain
      git submodule update --init --recursive
      ./configure --prefix=/opt/riscv --enable-linux
      make linux

  This toolchain is needed to compile the kernel. As of 2020-07-27, the Debian-provided RISC-V cross toolchain is not able to link Linux kernel and fails with link error.

* (Optional) Install recent QEMU:

      https://git.qemu.org/git/qemu.git
      cd qemu
      ./configure --target-list=riscv64-linux-user,riscv64-softmmu --prefix=/opt/riscv
      make
      make install

  This QEMU is needed to run installed Debian in QEMU. As of 2020-07-27, the Debian-provided QEMU hangs in early initialization.

* Add Debian Unstable (Sid) repositories to your system:

      printf "Package: *\nPin: release a=unstable\nPin-Priority: 10\n" | sudo tee /etc/apt/preferences.d/unstable.pref
      printf "deb http://ftp.debian.org/debian unstable main\ndeb-src http://ftp.debian.org/debian unstable main\n" | sudo tee /etc/apt/sources.list.d/unstable.list
      apt-get update

* Install QEMU and `mmdebstrap` and repository keys (req'd to build root filesystem and run installed system):

      sudo apt-get install mmdebstrap qemu-user-static qemu-system-misc binfmt-support debian-ports-archive-keyring gcc-riscv64-linux-gnu rsync

**For Debian 10 (Buster) users**: Debian 10 has old *debian-ports* repository keys (2018.12.27) which are no longer valid (at the time of writing - 2020-05-14). You need to [download][13] and install most recent version of package [debian-ports-archive-keyring][14]:

    wget http://ftp.debian.org/debian/pool/main/d/debian-ports-archive-keyring/debian-ports-archive-keyring_2019.11.05_all.deb
    sudo dpkg -i debian-ports-archive-keyring_2019.11.05_all.deb

## Checking out source code

```
git clone https://github.com/janvrany/riscv-debian.git
git -C riscv-debian submodule update --init --recursive
```

## !!! BIG FAT WARNING !!!

Scripts below do use sudo quite a lot. *IF THERE"S A BUG, IT MAY WIPE OUT 
YOUR SYSTEM*. *DO NOT RUN THESE SCRIPTS WITHOUT READING THEM CAREFULLY FIRST*. 

They're provided for convenience. Use at your own risk.

## Creating RISC-V Debian Image

### 1. Building Linux kernel image

* Run:

  ```
  ./debian-mk-kernel.mk
  ```

  This will leave QEMU bootable kernel image (BBL + kernel image) in `bbl-q`.
  The image for *HiFive Unleashed* is `bbl-u`, *QEMU image simply won't boot*
  !!!

### 2. Building Debian filesystem image

* Create a file containing Debian root filesystem. This is optional, you may use
  directly a device (say `/dev/mmcblk0p2`) or ZFS zvolume (`/dev/zvol/...`). You
  will need at least 4GB of space but for development, use 8G (or more). C++
  object files with full debug info can be pretty big.

  To make plain file image:

  ```
  truncate -s 8G debian.img
  /sbin/mkfs.ext3 debian.img
  ```

* Install Debian into that image:

  ```
  ./debian-mk-rootfs.sh debian.img

  ```

  Please note, that Rebian repository for RISC-V arch is really shaky, at times
  `apt-get` may fail because unsatisfiable dependencies. In that case, either
  wait or fiddle about somehow.

### 3. Install GDB (optional)

You may want to install GDB in order to debug programs. To install GDB that, 
run

```
./debian-mk-gdb.sh debian.img
```

Note, that this may (will) take a lot, lot of time when using QEMU. If you
intend to use Debian on real hardware, e.g., *HiFive Unleashed*, you may want to
compile GDB manually there. To do so, follow the steps in `./debian-mk-gdb.sh`
script.

### 4. Install Jenkins build slave support (optional)

If you want to run RISC-V [Jenkins][11] build slave, run

```
./debian-mk-jenkins.sh debian.img /path/to/jenkins.id_rsa.pub
```

You need to provide a path to *PUBLIC* SSH RSA key that Jenkins master would use
to connect to the slave.

On Jenkins master, use [SSH][12] to connect to the slave, username is `jenkins` and use
the corresponding key.

### 5. Creating SD Card for HiFive Unleashed (optional)

Following steps assumes the SD card (say `/dev/mmcblk0`) is properly partioned.
If not, please follow steps at the bottom of in [freedom-u-sdk/Makefile][5].
In short:

```
sgdisk --clear                                                                                            \
       --new=1:2048:67583  --change-name=1:bootloader --typecode=1:2E54B353-1271-4842-806F-E436D6AF6985   \
       --new=2:264192:     --change-name=2:root       --typecode=2:0FC63DAF-8483-4772-8E79-3D69D8477DE4   \
       /dev/mmcblk0
```

Then:

* To install kernel on SD card:

  ```
  ./unleashed-install-kernel.sh /dev/mmcblk0p1
  ```

* To install Debian root filesystem on SD card (say `/dev/mmcblk0`)

  ```
  ./unleashed-install-rootfs.sh debian.img /dev/mmcblk0p2
  ```
Now take your SD card, insert it into *Unleashed* and hope for the best.

You can connect to *Unleashed* serial console by using `screen`:
```
sudo screen /dev/ttyUSB1 115200
```

## Run RISC-V Debian Image in QEMU

```
./qemu-fire.sh
```

## Other comments

### How to fix missing `/var/lib/dpkg/available`

Sometimes it happened to me that `/var/lib/dpkg/available` disappeared.
This prevents `dpkg` / `apt` from removing packages. Following command
fixed this for me:

```
sudo dpkg --clear-avail && sudo apt-get update
```

## References
* [https://wiki.debian.org/RISC-V][1]
* [https://github.com/jim-wilson/riscv-linux-native-gdb/blob/jimw-riscv-linux-gdb/README.md][2]
* [https://groups.google.com/a/groups.riscv.org/forum/#!msg/sw-dev/jTOOXRXyZoY/BibnmSTOAAAJ][3]
* [https://wiki.debian.org/InstallingDebianOn/SiFive/HiFiveUnleashed#Building_a_Kernel][4]
* [https://github.com/sifive/freedom-u-sdk/issues/44][6]
* [https://github.com/rwmjones/fedora-riscv-kernel][7]
* [https://github.com/andreas-schwab/linux][8]
* [https://forums.sifive.com/t/linux-4-20-on-hifive-unleashed/1955][9]
* [SiFive HiFive Unleashed Getting Started Guide][10]

[1]: https://wiki.debian.org/RISC-V
[2]: https://github.com/jim-wilson/riscv-linux-native-gdb/blob/jimw-riscv-linux-gdb/README.md
[3]: https://groups.google.com/a/groups.riscv.org/forum/#!msg/sw-dev/jTOOXRXyZoY/BibnmSTOAAAJ
[4]: https://wiki.debian.org/InstallingDebianOn/SiFive/HiFiveUnleashed#Building_a_Kernel
[5]: https://github.com/sifive/freedom-u-sdk/blob/a938cf74b958cee13bdd2f9c9945297f744a2109/Makefile#L228
[6]: https://github.com/sifive/freedom-u-sdk/issues/44
[7]: https://github.com/rwmjones/fedora-riscv-kernel
[8]: https://github.com/andreas-schwab/linux
[9]: https://forums.sifive.com/t/linux-4-20-on-hifive-unleashed/1955
[10]: https://sifive.cdn.prismic.io/sifive%2Ffa3a584a-a02f-4fda-b758-a2def05f49f9_hifive-unleashed-getting-started-guide-v1p1.pdf
[11]: https://jenkins.io/
[12]: https://wiki.jenkins.io/display/JENKINS/SSH+Slaves+plugin
[13]: https://packages.debian.org/testing/all/debian-ports-archive-keyring/download
[14]: https://packages.debian.org/testing/debian-ports-archive-keyring
[15]: https://github.com/riscv/riscv-gnu-toolchain/blob/master/README.md
