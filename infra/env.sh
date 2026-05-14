#!/usr/bin/env bash

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