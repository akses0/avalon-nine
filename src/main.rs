#![no_main]
#![no_std]

use core::panic::PanicInfo;
use core::fmt::{Write};
use fdt;

struct Console;

#[unsafe(no_mangle)]
pub extern "C" fn kernel_main(hart_id: usize, dtb_ptr: usize) -> ! {
    let mut console = Console;
    let version = env!("CARGO_PKG_VERSION");
    let f = unsafe { fdt::Fdt::from_ptr(dtb_ptr as *const u8) }.unwrap();

    write!(console, ".: Avalon 9 Kernel {} :.\n==========================\nHart ID: {}\nDTB: {:#x}\n==========================\n", version, hart_id, dtb_ptr).ok();
    write!(console, "Model: {}\n", f.root().model()).expect("expected FDT root model.");
    write!(console, "CPU Count: {}\n", f.cpus().count()).expect("expected FDT cpus.");
    write!(console, "Memory: {:?}\n", f.memory()).expect("expected FDT memory.");

    loop {
        unsafe {
            core::arch::asm!("wfi")
        }
    }
}


fn sbi_put_char(c: u8) {
    unsafe {
        core::arch::asm!(
            "ecall",
            in("a7") 0x01usize,
            in("a0") c as usize,
        )
    }
}

impl core::fmt::Write for Console {
    fn write_str(&mut self, s: &str) -> core::fmt::Result {
        for c in s.bytes() {
            sbi_put_char(c);
        }
        Ok(())
    }
}

#[panic_handler]
#[inline(never)]
fn panic(_panic: &PanicInfo<'_>) -> ! {
    loop {
        unsafe { core::arch::asm!("wfi") }
    }
}
