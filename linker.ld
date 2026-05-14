OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY {
    RAM : ORIGIN = 0x80200000, LENGTH = 8M
}

SECTIONS {
    .text.boot : { *(.text.boot) } > RAM
    .text      : { *(.text .text.*) } > RAM
    .rodata    : ALIGN(4096) { *(.rodata) } > RAM
    .data      : ALIGN(4096) { *(.data) } > RAM
    .bss       : ALIGN(4096)
    {
        _bss_start = .;
        *(.bss)
        _bss_end = .;
    } > RAM
    .stack     : ALIGN(16)
    {
        _stack_bottom = .;
        . += 0x2000;
         _stack_top = .;
    } > RAM /* 8KB, stack grows down from top */
}
