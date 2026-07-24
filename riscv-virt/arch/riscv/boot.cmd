# for QEMU
virtio scan
fatload virtio 0:1 0x80200000 avalon-nine

# kernel executable starts at the usual 0x80200000
# we dont have an initramfs so - ignores the parameter
# u-boot provides us with a FDT control address as `fdtcontroladdr`
booti 0x80200000 - ${fdtcontroladdr}