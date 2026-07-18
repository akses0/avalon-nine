fn main() {
    println!("cargo:rerun-if-changed=src/boot.riscv.S");

    unsafe{
        std::env::set_var("CRATE_CC_NO_DEFAULTS", "1");
    }
    cc::Build::new()
        .compiler("riscv64-linux-gnu-gcc")
        .flag("-march=rv64gc")
        .flag("-mabi=lp64d")
        .file("src/boot.riscv.S")
        .compile("boot");
}
