build:
	cargo build -Zjson-target-spec -Zbuild-std=core
	riscv64-linux-gnu-objcopy \
    -O binary \
    target/riscv64-avalon-nine/debug/avalon-nine \
    target/riscv64-avalon-nine/debug/avalon-nine.bin

image-create:
	dd if=/dev/zero of=./boot.img bs=1M count=32
	parted ./boot.img --script mklabel msdos mkpart primary fat32 1MiB 100%
	sudo losetup -fP ./boot.img && \
	free=$$(sudo losetup -j ./boot.img | cut -d: -f1) && \
	sudo mkfs.vfat -F 32 $${free}p1 && \
	sudo losetup -d $$free

image-update:
    mcopy -i ./boot.img@@1M ./target/riscv64-avalon-nine/debug/avalon-nine.bin ::avalon-nine

virt: build image-update
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