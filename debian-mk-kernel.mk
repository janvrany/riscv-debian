#!/usr/bin/make -f

ROOT := $(shell pwd)

KERNEL_IMAGE=riscv-linux/vmlinux
CROSS_COMPILE ?= /opt/riscv/bin/riscv64-unknown-linux-gnu-

.PHONY: all
all:  bbl-q bbl-u
	@echo "To install linux kernel image to SD card, execute:"
	@echo
	@echo "    sudo dd if=$(ROOT)/bbl-u of=/dev/ABCD bs=4096"
	@echo

$(KERNEL_IMAGE): riscv-linux/.config riscv-linux/Makefile riscv-linux
	$(MAKE) -C riscv-linux ARCH=riscv vmlinux

riscv-linux/.config: riscv-linux-config.txt riscv-linux/Makefile
	cp $< $@
	$(MAKE) -C riscv-linux ARCH=riscv olddefconfig

bbl-q: $(KERNEL_IMAGE)
	rm -f $@
	rm -rf riscv-pk/build
	mkdir -p riscv-pk/build
	cd riscv-pk/build && \
	../configure \
	    --host=riscv64-linux-gnu \
	    --enable-print-device-tree \
	    --with-payload=$(ROOT)/$< \
	    --enable-logo
	cd riscv-pk/build && \
	$(MAKE)
	cp riscv-pk/build/bbl $@

bbl-u: bbl-q
	$(CROSS_COMPILE)objcopy -S -O binary --change-addresses -0x80000000 $< $@
