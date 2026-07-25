use crate::memory::memory_region::MemoryRegion;
use fdt;

const MAX_MEMORY_REGIONS: usize = 32;

pub struct BootInfo {
    pub model: &'static str,
    pub cpu_count: usize,
    pub cpu_clock: usize,
    pub dtb_ptr: usize,
    pub boot_hart: usize,
    pub first_memory_region: MemoryRegion,
    pub memory_regions: &'static [MemoryRegion],
    pub bootargs: Option<&'static str>,
    pub stdout: Option<&'static str>,
}

impl BootInfo {
    pub fn parse(hart_id: usize, dtb_ptr: usize) -> Self {
        unsafe {
            let f = fdt::Fdt::from_ptr(dtb_ptr as *const u8)
                .expect("expected a valid device tree BLOB ptr");

            let model = f.root().model();
            let cpu_count = f.cpus().count();
            let cpu = f.cpus().next();
            let mut cpu_clock = 0;
            if let Some(c) = cpu {
                cpu_clock = c.timebase_frequency();
            }

            let mut memory_start = 0;
            let mut memory_size = None;

            static mut BUF: [MemoryRegion; MAX_MEMORY_REGIONS] =
                [MemoryRegion { start: 0, size: 0 }; MAX_MEMORY_REGIONS];
            let mut count = 0;

            for fdt_region in f.memory().regions() {
                let mr = MemoryRegion {
                    start: fdt_region.starting_address as usize,
                    size: fdt_region.size.unwrap_or(0),
                };
                if count == 0 {
                    memory_start = mr.start;
                    memory_size = Some(mr.size);
                }
                if count < MAX_MEMORY_REGIONS {
                    BUF[count] = mr;
                    count += 1;
                }
            }

            let memory_regions: &'static [MemoryRegion] = &BUF[..count];

            let chosen = f.chosen();
            let bootargs = chosen.bootargs();
            let stdout = chosen.stdout().map(|s| s.name);

            BootInfo {
                model,
                cpu_count,
                cpu_clock,
                dtb_ptr,
                boot_hart: hart_id,
                first_memory_region: MemoryRegion {
                    start: memory_start,
                    size: memory_size.expect("Expected: memory size"),
                },
                memory_regions,
                bootargs,
                stdout,
            }
        }
    }
}
