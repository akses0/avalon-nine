.option     norvc                           //  this disables generation of 16bit RV instructions
                                            //  this just keeps instructions at a predictable 32bit
                                            //  width, but not necessarily required

.section    .text.boot                      //  place the code in an ELF section nameed .text.boot
                                            //  the linker script decides where this section actually lives
.globl      _start                          //  make the _start symobl visible to the linker
                                            //  the linker script uses ENTRY(_start) and U-Boot jumps to this address
                                            //  establishing the program entrypoint

// basic idea:
// 1. set the stack pointer to the address of the top of the stack as defined by the linker
// 2. identify the start and end of the .bss section, which holds zero-initialized static storage
// 3. zero out the .bss memory range
// 4. call kernel_main to start the program

_start:                                     //  the entrypoint for this program
    la      sp, _stack_top                  //  loads linker defined _stack_top address into the Stack Pointer
    la      t0, _bss_start                  //  loads the start address of the .bss section into register t0
    la      t1, _bss_end                    //  loads the address immediately after .bss section into register t1
    bgeu    t0, t1, .after_bss              //  if the start is >= the end, we are done so skip clearing loop

    .clear_bss:                             //  lets zero out the BSS section, that's where global variables live
        sd      zero, 0(t0)                 //  store one 64-bit doubleword of zero at the address in t0
        addi    t0, t0, 8                   //  advance the current address by 8 bytes
        bltu    t0, t1, .clear_bss          //  continue while current address is below _bss_end

    .after_bss:
    call    kernel_main                     //  call the program entry function, `call` saves the return address
                                            //  into the `ra` register and hands off to kernel_main in main.rs

    .hang:
        wfi                                 //  wfi = 'wait for interrupt'. Does what it says on the tin
        j   .hang                           //  just keep looping back to .hang