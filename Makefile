.PHONY: build create-boot image-create image-update virt

build:
	@echo "building..."
	cargo build -Zjson-target-spec -Zbuild-std=core
	riscv64-linux-gnu-objcopy \
    -O binary \
    target/riscv64-avalon-nine/debug/avalon-nine \
    target/riscv64-avalon-nine/debug/avalon-nine.bin

create-boot:
	@echo "creating boot script..."
	mkimage -T script -A riscv -O linux -C none -n "Avalon 9 Kernel Boot Script" -d ./boot.cmd ./boot.scr

image-create: build
	@echo "creating image..."
	dd if=/dev/zero of=./boot.img bs=1M count=32
	parted ./boot.img --script mklabel msdos mkpart primary fat32 1MiB 100%
	sudo losetup -fP ./boot.img && \
	free=$$(sudo losetup -j ./boot.img | cut -d: -f1) && \
	sudo mkfs.vfat -F 32 $${free}p1 && \
	sudo losetup -d $$free

image-update: create-boot
	@echo "updating image for qemu..."
	mcopy -i ./boot.img@@1M -o ./target/riscv64-avalon-nine/debug/avalon-nine.bin ::avalon-nine
	mcopy -i ./boot.img@@1M -o ./boot.scr ::boot.scr

virt: build  create-boot image-update
	@echo "starting qemu virtual environment..."
	qemu-system-riscv64 \
	  -machine virt \
	  -cpu rv64 \
	  -smp 1 \
	  -m 256M \
	  -nographic \
	  -bios ~/src/opensbi/build/platform/generic/firmware/fw_dynamic.bin \
	  -kernel ~/src/u-boot/u-boot.bin \
	  -drive file=/home/akses/src/avalon-nine/boot.img,format=raw,id=hd0,if=none \
	  -device virtio-blk-device,drive=hd0