pub mod info;

use core::fmt;
use core::fmt::Write;
use info::BootInfo;

pub fn print_banner(console: &mut impl fmt::Write, _hart_id: usize, _dtb_ptr: usize) {
    let version = env!("CARGO_PKG_VERSION");
    centre_align(console, "A-9 'Avalon' Kernel", 46);
    centre_align(console, version, 46);
    centre_align(console, "Copyright © 2026", 46);
    centre_align(console, "J. Burger, trapdoorsec.com", 46);
    centre_align(console, "All Rights Reserved.", 46);
    write!(console, "\n").ok();
}

fn centre_align(console: &mut impl fmt::Write, message: &str, target_len: usize) {
    write!(console,".:{message:^target_len$}:.\n").ok();
}

pub fn print_hardware_info(console: &mut impl fmt::Write, info: &BootInfo) {
    write!(console, "{:-<48}\n", "").ok();
    write!(console, "{:<16} {:#024}\n", "Model", info.model).ok();
    write!(console, "{:<16} {}\n", "CPU Count", info.cpu_count).ok();
    write!(console, "{:<16} {} GHz\n", "CPU Clock Freq", info.cpu_clock / 1000 / 1000 / 1000).ok();
    write!(console, "{:<16} {:#08X}\n", "DTB Pointer", info.dtb_ptr).ok();
    write!(console, "{:<16} {}\n", "Hart ID", info.boot_hart).ok();
    write!(console, "{:<16} {:#08X}\n", "Memory start", info.first_memory_region.start).ok();
    write!(console, "{:<16} {} MiB\n", "Memory size", info.first_memory_region.size / 1024 / 1024).ok();
    write!(console, "{:-<48}\n", "").ok();

    if let Some(bootargs) = info.bootargs {
        write!(console, "Boot args: {:?}\n", bootargs).ok();
    } else {
        write!(console, "No bootargs\n").ok();
    }
    if let Some(stdout) = info.stdout {
        write!(console, "stdout: {}\n", stdout).ok();
    }
    write!(console, "{:-<48}\n", "").ok();
}

const TABLE_WIDTH: usize = 67;
fn write_region_table_header(
    output: &mut impl Write,
) -> fmt::Result {
    writeln!(
        output,
        "{:<12} {:>18} {:>18} {:>15}",
        "Region", "Start", "End", "Size"
    )?;

    writeln!(output, "{:-<TABLE_WIDTH$}", "")
}

fn write_region(
    output: &mut impl Write,
    name: &str,
    start: usize,
    end: usize,
) -> fmt::Result {
    let size = end
        .checked_sub(start)
        .expect("memory region ends before it starts");

    writeln!(
        output,
        "{:<12} {:#018X} {:#018X} {:>11} KiB",
        name,
        start,
        end,
        size / 1024,
    )
}
