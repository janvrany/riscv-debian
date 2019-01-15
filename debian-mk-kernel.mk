#!/usr/bin/make -f

ROOT := $(shell pwd)

.PHONY: all
all:  bbl-q bbl-u
	@echo "To install linux kernel image to SD card, execute:"
	@echo 
	@echo "    sudo dd if=$(ROOT)/bbl-u of=/dev/ABCD bs=4096"
	@echo 

riscv-linux/vmlinux: riscv-linux/.config riscv-linux/Makefile riscv-linux
	$(MAKE) -C riscv-linux ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- vmlinux

riscv-linux/.config: riscv-linux-config.txt riscv-linux/Makefile
	#$(MAKE) -C riscv-linux ARCH=riscv defconfig
	#cat $< >> $@
	cp $< $@
	$(MAKE) -C riscv-linux ARCH=riscv olddefconfig

bbl-q: riscv-linux/vmlinux	
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
	riscv64-linux-gnu-objcopy -S -O binary --change-addresses -0x80000000 $< $@
