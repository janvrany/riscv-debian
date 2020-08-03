#!/usr/bin/make -f

ROOT := $(shell pwd)

KERNEL_IMAGE=riscv-linux/arch/riscv/boot/Image
CROSS_COMPILE ?= /opt/riscv/bin/riscv64-unknown-linux-gnu-

.PHONY: all
all:  $(KERNEL_IMAGE) qemu fu540

$(KERNEL_IMAGE): riscv-linux/.config riscv-linux/Makefile riscv-linux
	$(MAKE) -C riscv-linux ARCH=riscv CROSS_COMPILE=$(CROSS_COMPILE) Image

riscv-linux/arch/riscv/boot/dts/sifive/hifive-unleashed-a00.dtb: riscv-linux/.config riscv-linux/Makefile $(KERNEL_IMAGE)
	$(MAKE) -C riscv-linux ARCH=riscv CROSS_COMPILE=$(CROSS_COMPILE) dtbs

riscv-linux/.config: riscv-linux-config.txt riscv-linux/Makefile
	cp $< $@
	$(MAKE) -C riscv-linux ARCH=riscv olddefconfig

opensbi/build/platform/qemu/virt/firmware/fw_jump.bin:
	CROSS_COMPILE=$(CROSS_COMPILE) $(MAKE) -C opensbi \
		PLATFORM=qemu/virt

qemu: opensbi/build/platform/qemu/virt/firmware/fw_jump.bin

opensbi/build/platform/sifive/fu540/firmware/fw_payload.bin: $(KERNEL_IMAGE) riscv-linux/arch/riscv/boot/dts/sifive/hifive-unleashed-a00.dtb
	CROSS_COMPILE=$(CROSS_COMPILE) $(MAKE) -C opensbi \
		PLATFORM=sifive/fu540 \
		FW_PAYLOAD_FDT_PATH=../riscv-linux/arch/riscv/boot/dts/sifive/hifive-unleashed-a00.dtb \
		FW_PAYLOAD_PATH=../$<

fu540: opensbi/build/platform/sifive/fu540/firmware/fw_payload.bin
