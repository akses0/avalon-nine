#![no_std]

pub mod console;
pub mod logger;

use core::fmt;

fn sbi_put_char(c: u8) {
    unsafe {
        core::arch::asm!(
            "ecall",
            in("a7") 0x01usize,
            in("a0") c as usize,
        )
    }
}

pub struct Console;

impl fmt::Write for Console {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        for c in s.bytes() {
            sbi_put_char(c);
        }
        Ok(())
    }
}
