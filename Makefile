.PHONY: build create-boot image-create image-update virt

build:
	@echo "building..."
	cargo build -Zjson-target-spec -Zbuild-std=core --target ./riscv64-avalon-nine.json --verbose
	riscv64-linux-gnu-objcopy \
    -O binary \
    target/riscv64-avalon-nine/debug/avalon-nine \
    target/riscv64-avalon-nine/debug/avalon-nine.bin

create-boot:
	@echo "creating boot script..."
	mkimage -T script -A riscv -O linux -C none -n "Avalon 9 Kernel Boot Script" -d ./boot.cmd ./boot.scr

image-clean:
	bin/detach-boot-images.sh

image-create: build
	@echo "creating image..."
	rm -f ./boot.img
	dd if=/dev/zero of=./boot.img bs=1M count=32 status=progress
	parted ./boot.img --script \
		mklabel msdos \
		mkpart primary fat16 1MiB 100%
	@set -eu; \
	loopdev=$$(sudo losetup --find --show --partscan ./boot.img); \
	echo "using loop device $$loopdev"; \
	cleanup() { \
		echo "detaching $$loopdev"; \
		sudo losetup --detach "$$loopdev" 2>/dev/null || true; \
	}; \
	trap cleanup EXIT INT TERM; \
	sudo udevadm settle; \
	partition="$${loopdev}p1"; \
	attempts=0; \
	while [ ! -b "$$partition" ]; do \
		attempts=$$((attempts + 1)); \
		if [ "$$attempts" -ge 50 ]; then \
			echo "partition device did not appear: $$partition" >&2; \
			exit 1; \
		fi; \
		sleep 0.1; \
	done; \
	sudo mkfs.vfat -F 16 "$$partition"
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
