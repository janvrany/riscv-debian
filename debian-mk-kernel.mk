#!/usr/bin/make -f

sdkdir := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))freedom-u-sdk
wrkdir := $(sdkdir)/work
bbl := $(wrkdir)/riscv-pk/bbl
bin := $(wrkdir)/bbl.bin

bbl := freedom-u-sdk

.PHONY: all
all:  bbl bin
	@echo "To install linux kernel image to SD card, execute:"
	@echo 
	@echo "    sudo dd if=$(bin) of=/dev/ABCD bs=4096"
	@echo 



bbl:	
	$(MAKE) -j4 -C $(sdkdir) \
		linux_srcdir=../riscv-linux \
		linux_defconfig=$(sdkdir)/conf/linux_distro_defconfig \
		bbl

bin:	bbl
	$(MAKE) -C $(sdkdir) \
		linux_srcdir=../riscv-linux \
		linux_defconfig=$(sdkdir)/conf/linux_distro_defconfig \
		$(bin)
