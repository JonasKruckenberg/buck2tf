fn main() {
    let n = 21;
    println!(
        "{} doubled is {}",
        n,
        rust_lib::format_int(rust_lib::double(n))
    );
}
