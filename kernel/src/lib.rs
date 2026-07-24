#![no_std]

pub mod boot;
pub mod memory;

use boot::info::BootInfo;
use hardware::Console;

#[unsafe(no_mangle)]
pub extern "C" fn kernel_main(hart_id: usize, dtb_ptr: usize) -> ! {
    let mut console = Console;
    boot::print_banner(&mut console, hart_id, dtb_ptr);
    let info = BootInfo::parse(hart_id, dtb_ptr);
    boot::print_hardware_info(&mut console, &info);
    loop {
        unsafe {
            core::arch::asm!("wfi")
        }
    }
}
