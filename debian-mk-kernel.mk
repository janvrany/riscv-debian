#!/usr/bin/make -f


ROOT := $(shell pwd)

ISA ?= rv64imafdc
ABI ?= lp64d

LINUX=riscv-linux
LINUX_CONFIG=riscv-linux-config.txt

export CROSS_COMPILE := riscv64-linux-gnu-

all: bbl

$(LINUX)/vmlinux: $(LINUX)/.config	
	$(MAKE) -C $(LINUX) ARCH=riscv vmlinux

$(LINUX)/.config: $(LINUX_CONFIG) $(LINUX)/Makefile		
	cp $(LINUX_CONFIG) $@
	$(MAKE) -C $(LINUX) ARCH=riscv olddefconfig

bbl: bbl-q-vmlinux-4.19_rv64 bbl-u-vmlinux-4.19_rv64

bbl-q-vmlinux-4.19_rv64: $(LINUX)/vmlinux
	rm -f $@
	rm -rf riscv-pk/build
	mkdir -p riscv-pk/build
	cd riscv-pk/build && \
	../configure \
	    --prefix=/tmp \
	    --host=riscv64-linux-gnu \
	    --with-payload=$(ROOT)/$<
	CFLAGS="-mabi=$(ABI) -march=$(ISA)" $(MAKE) -C riscv-pk/build
	mv riscv-pk/build/bbl $@

bbl-u-vmlinux-4.19_rv64: bbl-q-vmlinux-4.19_rv64
	$(CROSS_COMPILE)objcopy -S -O binary --change-addresses -0x80000000 $< $@

.PHONY: all bbl 