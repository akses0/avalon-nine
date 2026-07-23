fn main() {
    println!("cargo:rerun-if-changed=arch/riscv/boot.riscv.S");

    unsafe{
        std::env::set_var("CRATE_CC_NO_DEFAULTS", "1");
    }
    cc::Build::new()
        .compiler("riscv64-linux-gnu-gcc")
        .flag("-march=rv64gc")
        .flag("-mabi=lp64d")
        .file("arch/riscv/boot.S")
        .compile("boot");
}
