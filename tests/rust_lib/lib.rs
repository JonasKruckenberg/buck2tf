/// Doubles the given value.
///
/// ```
/// assert_eq!(rust_lib::double(3), 6);
/// ```
pub fn double(x: i32) -> i32 {
    x * 2
}

/// Formats `n` as a decimal string using the `itoa` crate.
///
/// ```
/// assert_eq!(rust_lib::format_int(42), "42");
/// ```
pub fn format_int(n: i32) -> String {
    itoa::Buffer::new().format(n).to_owned()
}

/// Creates a dangling pointer dereference that Miri will detect.
///
/// # Safety
///
/// This is intentionally unsound — it exists solely to verify that Miri
/// catches use-after-free.
pub unsafe fn use_after_free() -> i32 {
    let ptr = {
        let local = 42_i32;
        &local as *const i32
    };
    // Miri will flag this as UB: reading from a dangling pointer.
    unsafe { *ptr }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_double() {
        assert_eq!(double(0), 0);
        assert_eq!(double(5), 10);
        assert_eq!(double(-3), -6);
    }

    #[test]
    fn test_format_int() {
        assert_eq!(format_int(0), "0");
        assert_eq!(format_int(-1), "-1");
        assert_eq!(format_int(1234), "1234");
    }

    /// This test should PASS under normal `cargo test` / `buck2 test` but
    /// FAIL under Miri, proving the Miri sysroot works.
    #[test]
    fn test_miri_detects_ub() {
        let _ = unsafe { use_after_free() };
    }
}
