#![no_main]
#![no_std]

use core::panic::PanicInfo;

#[unsafe(no_mangle)]
pub extern "C" fn kernel_main(hart_id: usize, dtb_ptr: usize) -> ! {
    loop {
        unsafe { core::arch::asm!("wfi") }
    }
}


#[panic_handler]
#[inline(never)]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    loop {
        unsafe { core::arch::asm!("wfi") }
    }
}
