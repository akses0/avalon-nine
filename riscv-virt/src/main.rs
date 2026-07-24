#![no_main]
#![no_std]

extern crate kernel;

use core::panic::PanicInfo;

#[panic_handler]
#[inline(never)]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    loop {
        unsafe { core::arch::asm!("wfi") }
    }
}
