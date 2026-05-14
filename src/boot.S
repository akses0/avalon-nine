.option     norvc
.section    .text.boot
.globl      _start
_start:
    la      sp, _stack_top
    la      t0, _bss_start
    la      t1, _bss_end
.clear_bss:
    sd      zero, 0(t0)
    addi    t0, t0, 8
    blt t0, t1, .clear_bss

    call    kernel_main
    .hang:
        wfi
        j   .hang
