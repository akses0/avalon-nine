fn main() {
    println!("cargo:rerun-if-changed=src/boot.S");

    cc::Build::new()
        .compiler("riscv64-linux-gnu-gcc")
        .flag("-march=rv64gc")
        .flag("-mabi=lp64d")
        .file("src/boot.S")
        .compile("boot");
}
