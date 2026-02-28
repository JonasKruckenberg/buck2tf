# How Rust Sysroots Are Built

This document describes how `rustup` constructs a sysroot from individual
component tarballs, how `rustc` and tools like `miri` expect the sysroot to be
laid out, and where the current `toolchain.bzl` rule in this repo diverges.

## Distribution format

Rust components are distributed as `.tar.xz` archives from
`https://static.rust-lang.org/dist/`. Each tarball has the structure:

```
<component>-<version>-<target>/
  install.sh                    # rust-installer script
  rust-installer-version        # always "3"
  components                    # newline-separated list of component short-names in this archive
  <component-short-name>/
    manifest.in                 # file list: one "file:<relative-path>" per line
    bin/...
    lib/...
    ...
```

The `<component-short-name>/` subtree mirrors the final sysroot layout. The
`manifest.in` file lists every file that belongs to the component, relative to
the component subdirectory.

For example, the `rustc` tarball contains:

```
rustc-nightly-aarch64-apple-darwin/
  install.sh
  rust-installer-version        # "3"
  components                    # "rustc"
  rustc/
    manifest.in
    bin/rustc
    bin/rustdoc
    bin/rust-gdb
    bin/rust-gdbgui
    bin/rust-lldb
    lib/librustc_driver-<hash>.dylib
    lib/librustc-nightly_rt.asan.dylib
    lib/librustc-nightly_rt.lsan.dylib
    lib/librustc-nightly_rt.tsan.dylib
    lib/librustc-nightly_rt.rtsan.dylib
    lib/rustlib/<host>/bin/rust-lld
    lib/rustlib/<host>/bin/rust-objcopy
    lib/rustlib/<host>/bin/wasm-component-ld
    lib/rustlib/<host>/bin/gcc-ld/{ld.lld,ld64.lld,lld-link,wasm-ld}
    lib/rustlib/etc/{gdb,lldb}_*.py
    libexec/rust-analyzer-proc-macro-srv
    share/man/man1/{rustc,rustdoc}.1
    share/doc/rust/...
```

And the `rust-std` tarball for the same target:

```
rust-std-nightly-aarch64-apple-darwin/
  install.sh
  rust-installer-version
  components                    # "rust-std-aarch64-apple-darwin"
  rust-std-aarch64-apple-darwin/
    manifest.in
    lib/rustlib/aarch64-apple-darwin/lib/
      libcore-<hash>.rlib
      libcore-<hash>.rmeta
      libstd-<hash>.rlib
      libstd-<hash>.rmeta
      libstd-<hash>.dylib
      libtest-<hash>.rlib
      libtest-<hash>.rmeta
      liballoc-<hash>.rlib
      libpanic_unwind-<hash>.rlib
      libpanic_abort-<hash>.rlib
      libcompiler_builtins-<hash>.rlib
      libproc_macro-<hash>.rlib
      ... (all standard library crates)
```

Tool components like `clippy`, `miri`, `rustfmt`, and `cargo` each add binaries
to `bin/` and documentation to `share/doc/`:

```
miri-preview-nightly-aarch64-apple-darwin/
  miri-preview/
    manifest.in
    bin/miri
    bin/cargo-miri
    share/doc/miri/...

clippy-preview-nightly-aarch64-apple-darwin/
  clippy-preview/
    manifest.in
    bin/clippy-driver
    bin/cargo-clippy
    share/doc/clippy/...
```

The `rust-src` component is target-independent (its tarball uses no target
triple) and provides the standard library source code:

```
rust-src-nightly/
  rust-src/
    manifest.in
    lib/rustlib/src/rust/library/
      Cargo.toml
      Cargo.lock
      core/...
      alloc/...
      std/...
      ...
```

## How rustup merges components into a sysroot

Each rustup toolchain (e.g. `~/.rustup/toolchains/nightly-aarch64-apple-darwin`)
is a **single merged directory tree**. When rustup installs a component, it
overlays the component's files directly into this tree. The installation process
is equivalent to:

```sh
# For each component in the profile:
tar -xJf <component>.tar.xz --strip-components=2 -C $SYSROOT <top-dir>/<component-short-name>/
```

That is, it strips the two-level prefix (`<archive-name>/<component-name>/`)
and copies everything into the sysroot root. Multiple components that contribute
files to the same directory (e.g. `lib/`) are simply overlaid — there is no
namespacing or isolation.

The only record of which files came from which component is the set of
`manifest-<component>` files stored in `$SYSROOT/lib/rustlib/`:

```
$SYSROOT/lib/rustlib/
  components                                    # list of installed component names
  rust-installer-version                        # "3"
  manifest-rustc-<target>                       # file list from rustc component
  manifest-rust-std-<target>                    # file list from rust-std component
  manifest-cargo-<target>                       # file list from cargo component
  manifest-clippy-preview-<target>              # file list from clippy component
  manifest-miri-preview-<target>                # file list from miri component
  manifest-rustfmt-preview-<target>             # file list from rustfmt component
  manifest-rust-src                             # file list from rust-src component
  multirust-channel-manifest.toml               # full upstream channel manifest
  multirust-config.toml                         # (usually empty)
```

## The resulting merged sysroot layout

After all components are merged, the sysroot looks like this:

```
$SYSROOT/
  bin/
    rustc                          # from rustc
    rustdoc                        # from rustc
    rust-gdb                       # from rustc
    rust-gdbgui                    # from rustc
    rust-lldb                      # from rustc
    cargo                          # from cargo
    clippy-driver                  # from clippy-preview
    cargo-clippy                   # from clippy-preview
    miri                           # from miri-preview
    cargo-miri                     # from miri-preview
    rustfmt                        # from rustfmt-preview
    cargo-fmt                      # from rustfmt-preview
  etc/
    bash_completion.d/cargo        # from cargo
  lib/
    librustc_driver-<hash>.dylib   # from rustc  (compiler runtime)
    librustc-*_rt.asan.dylib       # from rustc  (sanitizer runtimes)
    librustc-*_rt.lsan.dylib       # from rustc
    librustc-*_rt.tsan.dylib       # from rustc
    librustc-*_rt.rtsan.dylib      # from rustc
    rustlib/
      components                   # metadata: installed component list
      manifest-*                   # metadata: per-component file manifests
      etc/                         # debugger support scripts (from rustc)
        gdb_*.py
        lldb_*.py
        lldb_commands
        rust_types.py
      src/                         # from rust-src
        rust/
          library/
            Cargo.toml
            core/...
            std/...
            alloc/...
      <host-triple>/
        bin/                       # from rustc
          rust-lld
          rust-objcopy
          wasm-component-ld
          gcc-ld/
            ld.lld
            ld64.lld
            lld-link
            wasm-ld
        lib/                       # from rust-std-<host-triple>
          libcore-<hash>.rlib
          libstd-<hash>.rlib
          libstd-<hash>.dylib
          libtest-<hash>.rlib
          libtest-<hash>.dylib
          liballoc-<hash>.rlib
          libpanic_unwind-<hash>.rlib
          libpanic_abort-<hash>.rlib
          libproc_macro-<hash>.rlib
          libcompiler_builtins-<hash>.rlib
          librustc-*_rt.{asan,lsan,tsan,rtsan}.dylib  # from rust-std
          ...
      <cross-target>/              # from rust-std-<cross-target> (if installed)
        lib/
          libcore-<hash>.rlib
          libstd-<hash>.rlib
          ...
  libexec/
    rust-analyzer-proc-macro-srv   # from rustc
  share/
    doc/
      rust/...                     # from rustc
      cargo/...                    # from cargo
      clippy/...                   # from clippy-preview
      miri/...                     # from miri-preview
      rustfmt/...                  # from rustfmt-preview
    man/
      man1/
        rustc.1                    # from rustc
        rustdoc.1                  # from rustc
        cargo*.1                   # from cargo
    zsh/
      site-functions/_cargo        # from cargo
```

## How rustc and tools use the sysroot

### rustc

`rustc` determines its sysroot by walking up from its own binary location:

1. Find self at `$SYSROOT/bin/rustc`
2. Go up one level to `$SYSROOT/`
3. Look for standard library crates in `$SYSROOT/lib/rustlib/<target>/lib/`
4. Load its own runtime dylibs from `$SYSROOT/lib/` (e.g. `librustc_driver-<hash>.dylib`)

The critical invariant is that **`rustc`'s own dylibs in `lib/`** and the
**standard library in `lib/rustlib/<target>/lib/`** must coexist under the same
sysroot root. The `--sysroot` flag can override the auto-detected root, but
it must still point to a directory containing both `lib/*.dylib` (compiler
runtime) and `lib/rustlib/<target>/lib/` (standard library).

### miri

`miri` is particularly sensitive to sysroot layout. When invoked, it:

1. Locates itself at `$SYSROOT/bin/miri`
2. Determines the sysroot the same way as `rustc` (up one level from `bin/`)
3. Expects to find `rustc` at `$SYSROOT/bin/rustc`
4. Expects the standard library at `$SYSROOT/lib/rustlib/<target>/lib/`
5. Expects `rust-src` at `$SYSROOT/lib/rustlib/src/rust/library/` if it needs
   to build a custom libstd for Miri's interpreter (which it usually does via
   `cargo-miri setup`)
6. Needs the compiler's dylibs in `$SYSROOT/lib/` to function

In other words, miri requires a **complete, merged sysroot** with `rustc`,
`rust-std`, and `rust-src` all overlaid into the same tree. It cannot work
with a sysroot that only contains the standard library.

## What the current toolchain.bzl does wrong

The current `_rust_toolchain_impl` in `toolchain.bzl` constructs the sysroot
like this:

```python
sysroot_srcs = {}
# ...
if component_name == "rust-std":
    sysroot_srcs["lib"] = component.project(
        "rust-std-{}/lib".format(ctx.attrs.rustc_target_triple)
    )

sysroot = ctx.actions.symlinked_dir(sysroot_ident, sysroot_srcs)
```

This produces a sysroot containing **only**:

```
$SYSROOT/
  lib/
    rustlib/
      <target>/
        lib/
          libstd-<hash>.rlib
          ...
```

This is missing all of the following that a real sysroot requires:

1. **Compiler runtime dylibs** (`lib/librustc_driver-<hash>.dylib`,
   `lib/librustc-*_rt.*.dylib`) — from the `rustc` component. These are
   needed at runtime by `rustc` itself and by tools that link against the
   compiler.

2. **Binaries** (`bin/rustc`, `bin/miri`, `bin/cargo-miri`, etc.) — tools
   expect to find each other relative to the sysroot.

3. **Linker tools** (`lib/rustlib/<host>/bin/rust-lld`, etc.) — from the
   `rustc` component. Needed for linking.

4. **Debugger scripts** (`lib/rustlib/etc/*.py`) — from the `rustc` component.

5. **Rust source** (`lib/rustlib/src/rust/library/`) — from the `rust-src`
   component. Required by `miri` and `cargo-miri setup`.

6. **libexec** (`libexec/rust-analyzer-proc-macro-srv`) — from the `rustc`
   component.

### What a correct sysroot construction would need to do

Instead of only symlinking the `lib/` tree from `rust-std`, the rule needs to
merge files from **all** downloaded components into a single directory tree,
replicating what `rustup`'s `install.sh` does. Each component tarball is
extracted with `--strip-components=1` (stripping the archive top-level
directory), leaving a `<component-short-name>/` directory. The files under that
component short-name directory need to be overlaid into the sysroot.

Concretely, for a `default` profile, the sysroot should be built by merging:

| Component path | Sysroot destination |
|---|---|
| `rustc/bin/*` | `$SYSROOT/bin/*` |
| `rustc/lib/*` | `$SYSROOT/lib/*` |
| `rustc/libexec/*` | `$SYSROOT/libexec/*` |
| `rust-std-<target>/lib/*` | `$SYSROOT/lib/*` |
| `cargo/bin/*` | `$SYSROOT/bin/*` |
| `clippy-preview/bin/*` | `$SYSROOT/bin/*` |
| `rustfmt-preview/bin/*` | `$SYSROOT/bin/*` |

And for `miri` support (in the `complete` profile or when explicitly added):

| Component path | Sysroot destination |
|---|---|
| `miri-preview/bin/*` | `$SYSROOT/bin/*` |
| `rust-src/lib/*` | `$SYSROOT/lib/*` |

The key insight is that `ctx.actions.symlinked_dir` should receive entries for
**every file from every component**, not just the `lib/` subtree of `rust-std`.
Since `symlinked_dir` takes a flat mapping of `relative_path -> artifact`, you
would need to walk each component's `manifest.in` (or a hardcoded equivalent)
and collect all the `file:` entries, projecting each one from its extracted
component directory into the unified sysroot namespace.
