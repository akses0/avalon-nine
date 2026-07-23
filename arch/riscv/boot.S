//  Hi nerds
//  This 100% human generated slop was brought to you with <3 from akses
//  This doesn't mean AI wasn't involved, or can't be used to generate future slop in this project
//  But I thought you would like to know
//  Also check the LICENCE file, this is a copyleft project under the AGPL3
//  Copyright (c) 2026 J. 'akses' Burger

// Basic idea:
//
// 1. Provide a Linux Compatible RISC-V header
// 2. Jump to _kernel_start
// 3. Ensure linux compatible header is present
// 4. Zero the .bss section, which holds zero-initialized static storage.
// 5. Transfer control to kernel_main().

.option     norvc                           //  This disables generation of 16bit RV instructions
                                            //  this just keeps instructions at a predictable 32bit
                                            //  width, but not necessarily required

.section    .text.boot                      //  Place the code in an ELF section nameed .text.boot
                                            //  the linker script decides where this section actually lives

.globl      _start                          //  Make the _start symobl visible to the linker
                                            //  the linker script uses ENTRY(_start), making this the ELF entry point;
                                            //  the preceding firmware or bootloader transfers control here

_start:                                     //  the entrypoint for this program
    // START: linux compatible header

    // u32 code0;                /* Executable code */
    j .boot
    // u32 code1;                /* Executable code */
    nop
    // u64 text_offset;          /* Image load offset, little endian. Given we start at 0x80200000 and we allow 2MiB */
    .quad 0x00200000
    // u64 image_size;           /* Effective Image size, little endian. Use linker for this */
    .quad _image_end - _start
    // u64 flags;                /* kernel flags, little endian */
    .quad 0
    // u32 version;              /* Version of this header */
    .word 0
    // u32 res1 = 0;             /* Reserved */
    .word 0
    // u64 res2 = 0;             /* Reserved */
    .quad 0
    // u64 magic = 0x5643534952; /* Magic number, little endian, "RISCV" */
    .quad 0x0000005643534952
    // u32 magic2 = 0x05435352;  /* Magic number 2, little endian, "RSC\x05" */
    .word 0x05435352;
    // u32 res3;                 /* Reserved for PE COFF offset */
    .word 0

    // END: linux compatible header

    // START: Early boot
    .boot:
        la      sp, _stack_top                  //  loads linker defined _stack_top address into the Stack Pointer
        la      t0, _bss_start                  //  loads the start address of the .bss section into register t0
        la      t1, _bss_end                    //  loads the address immediately after .bss section into register t1
        bgeu    t0, t1, .after_bss              //  if the start is >= the end, we are done so skip clearing loop

    .clear_bss:                             //  lets zero out the BSS section, that's where global variables live
        sd      zero, 0(t0)                 //  store one 64-bit doubleword of zero at the address in t0
        addi    t0, t0, 8                   //  advance the current address by 8 bytes
        bltu    t0, t1, .clear_bss          //  continue while current address is below _bss_end

    // END: Early boot
    // START: Kernel boot
    .after_bss:
        call    kernel_main                     //  call the program entry function, `call` saves the return address
                                            //  into the `ra` register and hands off to kernel_main in main.rs
    .hang:
        wfi                                 //  wfi = 'wait for interrupt'. Does what it says on the tin
        j   .hang                           //  just keep looping back to .hang
    // END: Kernel boot