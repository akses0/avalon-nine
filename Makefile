TARGET := riscv64gc-unknown-none-elf

.PHONY: build check check-all fmt fmt-check lint test doc clean-all ci pre-commit dev help \
        create-boot image-clean image-create image-update virt

# --- Quality Gates ---

fmt:
	cargo fmt --all

fmt-check:
	cargo fmt --all -- --check

lint:
	cargo clippy --workspace --all-targets -- -D warnings

check:
	cargo check -p riscv-virt -Zbuild-std=core --target $(TARGET)

check-all:
	cargo check --workspace -Zbuild-std=core --target $(TARGET)

test:
	cargo test --workspace

doc:
	cargo doc --no-deps --document-private-items

clean-all:
	cargo clean
	rm -f boot.img boot.scr avalon-nine.bin

ci: fmt-check lint check-all test
	@echo "All checks passed."

pre-commit: ci

# --- Build ---

build:
	@echo "building..."
	cargo build -p riscv-virt -Zbuild-std=core --target $(TARGET) --verbose
	riscv64-linux-gnu-objcopy \
		-O binary \
		target/$(TARGET)/debug/avalon-nine \
		target/$(TARGET)/debug/avalon-nine.bin

# --- Deploy ---

create-boot:
	@echo "creating boot script..."
	mkimage -T script -A riscv -O linux -C none -n "Avalon 9 Kernel Boot Script" -d ./riscv-virt/arch/riscv/boot.cmd ./riscv-virt/arch/riscv/boot.scr

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
	mcopy -i ./boot.img@@1M -o ./target/$(TARGET)/debug/avalon-nine.bin ::avalon-nine
	mcopy -i ./boot.img@@1M -o ./riscv-virt/arch/riscv/boot.scr ::boot.scr

virt: build create-boot image-update
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

# --- Dev ---

dev: fmt check-all
	@$(MAKE) --no-print-directory virt

# --- Help ---

help:
	@echo "Available targets:"
	@echo ""
	@echo "Quality Gates:"
	@echo "  fmt          Format code"
	@echo "  fmt-check    Check code formatting"
	@echo "  lint         Run clippy with -D warnings"
	@echo "  check        Fast type-check (kernel crate)"
	@echo "  check-all    Type-check all workspace crates"
	@echo "  test         Run all tests"
	@echo "  doc          Build documentation"
	@echo "  clean-all    Clean build artifacts and generated files"
	@echo "  ci           Run all quality checks (fmt-check, lint, check-all, test)"
	@echo "  pre-commit   Alias for ci"
	@echo ""
	@echo "Build & Deploy:"
	@echo "  build        Build kernel binary"
	@echo "  create-boot  Create U-Boot boot script"
	@echo "  image-create Create QEMU disk image"
	@echo "  image-update Update disk image with new kernel"
	@echo "  image-clean  Detach boot images"
	@echo "  virt         Build and run in QEMU"
	@echo ""
	@echo "Dev:"
	@echo "  dev          Format, check, and run in QEMU"
	@echo ""
	@echo "Other:"
	@echo "  help         Show this help message"
