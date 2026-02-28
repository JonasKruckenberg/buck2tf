buck2 build //tests/rust_lib:rust_lib
buck2 build //tests/rust_bin:rust_bin
buck2 test //tests/rust_lib:rust_lib_test
buck2 build '//tests/rust_lib:rust_lib[check]'
buck2 build '//tests/rust_lib:rust_lib[clippy.txt]'
buck2 build '//tests/rust_lib:rust_lib[doc]'
# buck2 build '//tests/rust_lib:rust_lib[miri]'
