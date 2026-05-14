#![no_main]
#![no_std]

use core::panic::PanicInfo;
use core::fmt::Write;

struct Console;

#[unsafe(no_mangle)]
pub extern "C" fn kernel_main(hart_id: usize, dtb_ptr: usize) -> ! {
    let mut console = Console;
    let version = env!("CARGO_PKG_VERSION");
    write!(console, ".: Avalon 9 Kernel {} :.\n.:  with <3 from akses  :.\n==========================\nHart ID: {}\nDTB: {:#x}\n", version, hart_id, dtb_ptr).ok();
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
