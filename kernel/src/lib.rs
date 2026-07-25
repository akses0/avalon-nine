#![no_std]

pub mod boot;
pub mod memory;

use boot::info::BootInfo;
use hardware::logger::{ActionState, Severity};
use hardware::{Console, klog};

#[unsafe(no_mangle)]
pub extern "C" fn kernel_main(hart_id: usize, dtb_ptr: usize) -> ! {
    let mut console = Console;
    boot::print_banner(&mut console, hart_id, dtb_ptr);
    let info = BootInfo::parse(hart_id, dtb_ptr);
    boot::print_hardware_info(&mut console, &info);
    klog!(
        console,
        Severity::Info,
        ActionState::Ok,
        "boot sequence completed."
    );
    loop {
        unsafe { core::arch::asm!("wfi") }
    }
}
