#!/usr/bin/make -f

ROOT := $(shell pwd)

KERNEL_IMAGE=riscv-linux/vmlinux
CROSS_COMPILE ?= /opt/riscv/bin/riscv64-unknown-linux-gnu-
KERNEL_HOST=$(notdir $(CROSS_COMPILE:-=))
CROSS_COMPILE_DIR=$(abspath $(dir $(CROSS_COMPILE)))

.PHONY: all
all:  bbl-q bbl-u
	@echo "To install linux kernel image to SD card, execute:"
	@echo
	@echo "    sudo dd if=$(ROOT)/bbl-u of=/dev/ABCD bs=4096"
	@echo

$(KERNEL_IMAGE): riscv-linux/.config riscv-linux/Makefile riscv-linux
	$(MAKE) -C riscv-linux ARCH=riscv CROSS_COMPILE=$(CROSS_COMPILE) vmlinux

riscv-linux/.config: riscv-linux-config.txt riscv-linux/Makefile
	cp $< $@
	$(MAKE) -C riscv-linux ARCH=riscv CROSS_COMPILE=$(CROSS_COMPILE) olddefconfig

bbl-q: $(KERNEL_IMAGE)
	rm -f $@
	rm -rf riscv-pk/build
	mkdir -p riscv-pk/build
	cd riscv-pk/build && \
	PATH="$(CROSS_COMPILE_DIR):${PATH}" \
	../configure \
	    --host=${KERNEL_HOST} \
	    --enable-print-device-tree \
	    --with-payload=$(ROOT)/$< \
	    --enable-logo
	cd riscv-pk/build && \
	PATH="$(CROSS_COMPILE_DIR):${PATH}" \
	$(MAKE)
	cp riscv-pk/build/bbl $@

bbl-u: bbl-q
	$(CROSS_COMPILE)objcopy -S -O binary --change-addresses -0x80000000 $< $@
