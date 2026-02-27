load("@prelude//cxx/preprocessor.bzl", "CPreprocessorInfo")

bindgen_toolchain_attrs = {
    # The Rust bindgen CLI (bindgen-cli)
    "bindgen": provider_field(RunInfo | None, default = None),
}

BindgenToolchainInfo = provider(fields = bindgen_toolchain_attrs)

def _bindgen_toolchain_impl(
    ctx: AnalysisContext,
) -> list[Provider]:
    return [
        DefaultInfo(),
        BindgenToolchainInfo(
            bindgen = ctx.attrs.bindgen[RunInfo]
        )
    ]

bindgen_toolchain = rule(
    impl = _bindgen_toolchain_impl,
    attrs = {
        "bindgen": attrs.exec_dep(providers = [RunInfo]),
    },
    is_toolchain_rule = True,
)

def rust_bindgen_impl(ctx: AnalysisContext) -> list[Provider]:
    headers = ctx.actions.declare_output("__headers.h")
    ctx.actions.write(
        headers,
        cmd_args(ctx.attrs.headers,
            format = "#include \"{}\"",
            relative_to = (headers, 1)
        ),
        allow_args = True,
    )

    bindings = ctx.actions.declare_output("bindings.rs")
    bindgen_cmd = cmd_args(
        ctx.attrs._bindgen_toolchain[BindgenToolchainInfo].bindgen,
        headers,
        delimiter = " "
    )

    # -- Output options (managed by the rule) --
    bindgen_cmd.add("-o", "\"$@\"")

    # -- Enum style options --
    if ctx.attrs.default_enum_style:
        bindgen_cmd.add("--default-enum-style", ctx.attrs.default_enum_style)
    for r in ctx.attrs.bitfield_enum:
        bindgen_cmd.add("--bitfield-enum", r)
    for r in ctx.attrs.newtype_enum:
        bindgen_cmd.add("--newtype-enum", r)
    for r in ctx.attrs.newtype_global_enum:
        bindgen_cmd.add("--newtype-global-enum", r)
    for r in ctx.attrs.rustified_enum:
        bindgen_cmd.add("--rustified-enum", r)
    for r in ctx.attrs.rustified_non_exhaustive_enum:
        bindgen_cmd.add("--rustified-non-exhaustive-enum", r)
    for r in ctx.attrs.constified_enum:
        bindgen_cmd.add("--constified-enum", r)
    for r in ctx.attrs.constified_enum_module:
        bindgen_cmd.add("--constified-enum-module", r)
    if ctx.attrs.default_macro_constant_type:
        bindgen_cmd.add("--default-macro-constant-type", ctx.attrs.default_macro_constant_type)
    if ctx.attrs.translate_enum_integer_types:
        bindgen_cmd.add("--translate-enum-integer-types")
    if ctx.attrs.no_prepend_enum_name:
        bindgen_cmd.add("--no-prepend-enum-name")

    # -- Typedef/alias style options --
    if ctx.attrs.default_alias_style:
        bindgen_cmd.add("--default-alias-style", ctx.attrs.default_alias_style)
    for r in ctx.attrs.normal_alias:
        bindgen_cmd.add("--normal-alias", r)
    for r in ctx.attrs.new_type_alias:
        bindgen_cmd.add("--new-type-alias", r)
    for r in ctx.attrs.new_type_alias_deref:
        bindgen_cmd.add("--new-type-alias-deref", r)

    # -- Union style options --
    if ctx.attrs.default_non_copy_union_style:
        bindgen_cmd.add("--default-non-copy-union-style", ctx.attrs.default_non_copy_union_style)
    for r in ctx.attrs.bindgen_wrapper_unions:
        bindgen_cmd.add("--bindgen-wrapper-union", r)
    for r in ctx.attrs.manually_drop_unions:
        bindgen_cmd.add("--manually-drop-union", r)

    # -- Blocklist options --
    for r in ctx.attrs.blocklist_types:
        bindgen_cmd.add("--blocklist-type", r)
    for r in ctx.attrs.blocklist_functions:
        bindgen_cmd.add("--blocklist-function", r)
    for r in ctx.attrs.blocklist_items:
        bindgen_cmd.add("--blocklist-item", r)
    for r in ctx.attrs.blocklist_files:
        bindgen_cmd.add("--blocklist-file", r)
    for r in ctx.attrs.blocklist_vars:
        bindgen_cmd.add("--blocklist-var", r)

    # -- Allowlist options --
    for r in ctx.attrs.allowlist_functions:
        bindgen_cmd.add("--allowlist-function", r)
    for r in ctx.attrs.allowlist_types:
        bindgen_cmd.add("--allowlist-type", r)
    for r in ctx.attrs.allowlist_vars:
        bindgen_cmd.add("--allowlist-var", r)
    for r in ctx.attrs.allowlist_files:
        bindgen_cmd.add("--allowlist-file", r)
    for r in ctx.attrs.allowlist_items:
        bindgen_cmd.add("--allowlist-item", r)
    if ctx.attrs.no_recursive_allowlist:
        bindgen_cmd.add("--no-recursive-allowlist")

    # -- Derive options --
    if ctx.attrs.no_derive_copy:
        bindgen_cmd.add("--no-derive-copy")
    if ctx.attrs.no_derive_debug:
        bindgen_cmd.add("--no-derive-debug")
    if ctx.attrs.with_derive_default:
        bindgen_cmd.add("--with-derive-default")
    if ctx.attrs.with_derive_hash:
        bindgen_cmd.add("--with-derive-hash")
    if ctx.attrs.with_derive_partialeq:
        bindgen_cmd.add("--with-derive-partialeq")
    if ctx.attrs.with_derive_partialord:
        bindgen_cmd.add("--with-derive-partialord")
    if ctx.attrs.with_derive_eq:
        bindgen_cmd.add("--with-derive-eq")
    if ctx.attrs.with_derive_ord:
        bindgen_cmd.add("--with-derive-ord")
    if ctx.attrs.impl_debug:
        bindgen_cmd.add("--impl-debug")
    if ctx.attrs.impl_partialeq:
        bindgen_cmd.add("--impl-partialeq")
    for r in ctx.attrs.no_partialeq:
        bindgen_cmd.add("--no-partialeq", r)
    for r in ctx.attrs.no_copy:
        bindgen_cmd.add("--no-copy", r)
    for r in ctx.attrs.no_debug:
        bindgen_cmd.add("--no-debug", r)
    for r in ctx.attrs.no_default:
        bindgen_cmd.add("--no-default", r)
    for r in ctx.attrs.no_hash:
        bindgen_cmd.add("--no-hash", r)
    for r in ctx.attrs.must_use_type:
        bindgen_cmd.add("--must-use-type", r)

    # -- Custom derive/attribute options --
    for r in ctx.attrs.with_derive_custom:
        bindgen_cmd.add("--with-derive-custom", r)
    for r in ctx.attrs.with_derive_custom_struct:
        bindgen_cmd.add("--with-derive-custom-struct", r)
    for r in ctx.attrs.with_derive_custom_enum:
        bindgen_cmd.add("--with-derive-custom-enum", r)
    for r in ctx.attrs.with_derive_custom_union:
        bindgen_cmd.add("--with-derive-custom-union", r)
    for r in ctx.attrs.with_attribute_custom:
        bindgen_cmd.add("--with-attribute-custom", r)
    for r in ctx.attrs.with_attribute_custom_struct:
        bindgen_cmd.add("--with-attribute-custom-struct", r)
    for r in ctx.attrs.with_attribute_custom_enum:
        bindgen_cmd.add("--with-attribute-custom-enum", r)
    for r in ctx.attrs.with_attribute_custom_union:
        bindgen_cmd.add("--with-attribute-custom-union", r)

    # -- Layout and type options --
    if ctx.attrs.no_layout_tests:
        bindgen_cmd.add("--no-layout-tests")
    for r in ctx.attrs.opaque_type:
        bindgen_cmd.add("--opaque-type", r)
    if ctx.attrs.no_convert_floats:
        bindgen_cmd.add("--no-convert-floats")
    if ctx.attrs.no_size_t_is_usize:
        bindgen_cmd.add("--no-size_t-is-usize")
    if ctx.attrs.fit_macro_constant_types:
        bindgen_cmd.add("--fit-macro-constant-types")
    if ctx.attrs.use_array_pointers_in_arguments:
        bindgen_cmd.add("--use-array-pointers-in-arguments")
    if ctx.attrs.explicit_padding:
        bindgen_cmd.add("--explicit-padding")
    if ctx.attrs.flexarray_dst:
        bindgen_cmd.add("--flexarray-dst")

    # -- Code generation options --
    if ctx.attrs.generate:
        bindgen_cmd.add("--generate", ctx.attrs.generate)
    if ctx.attrs.ignore_functions:
        bindgen_cmd.add("--ignore-functions")
    if ctx.attrs.ignore_methods:
        bindgen_cmd.add("--ignore-methods")
    if ctx.attrs.generate_inline_functions:
        bindgen_cmd.add("--generate-inline-functions")
    if ctx.attrs.generate_block:
        bindgen_cmd.add("--generate-block")
    if ctx.attrs.generate_cstr:
        bindgen_cmd.add("--generate-cstr")
    if ctx.attrs.no_doc_comments:
        bindgen_cmd.add("--no-doc-comments")
    if ctx.attrs.disable_header_comment:
        bindgen_cmd.add("--disable-header-comment")
    if ctx.attrs.sort_semantically:
        bindgen_cmd.add("--sort-semantically")
    if ctx.attrs.merge_extern_blocks:
        bindgen_cmd.add("--merge-extern-blocks")
    if ctx.attrs.wrap_unsafe_ops:
        bindgen_cmd.add("--wrap-unsafe-ops")

    # -- Raw lines --
    for line in ctx.attrs.raw_line:
        bindgen_cmd.add("--raw-line", line)
    for entry in ctx.attrs.module_raw_line:
        bindgen_cmd.add("--module-raw-line", entry[0], entry[1])

    # -- Rust target options --
    if ctx.attrs.rust_target:
        bindgen_cmd.add("--rust-target", ctx.attrs.rust_target)
    if ctx.attrs.rust_edition:
        bindgen_cmd.add("--rust-edition", ctx.attrs.rust_edition)
    if ctx.attrs.use_core:
        bindgen_cmd.add("--use-core")
    if ctx.attrs.ctypes_prefix:
        bindgen_cmd.add("--ctypes-prefix", ctx.attrs.ctypes_prefix)
    if ctx.attrs.anon_fields_prefix:
        bindgen_cmd.add("--anon-fields-prefix", ctx.attrs.anon_fields_prefix)

    # -- Formatting options --
    if ctx.attrs.formatter:
        bindgen_cmd.add("--formatter", ctx.attrs.formatter)
    if ctx.attrs.rustfmt_configuration_file:
        bindgen_cmd.add("--rustfmt-configuration-file", ctx.attrs.rustfmt_configuration_file)
    if ctx.attrs.default_visibility:
        bindgen_cmd.add("--default-visibility", ctx.attrs.default_visibility)

    # -- C++ options --
    if ctx.attrs.enable_cxx_namespaces:
        bindgen_cmd.add("--enable-cxx-namespaces")
    if ctx.attrs.disable_name_namespacing:
        bindgen_cmd.add("--disable-name-namespacing")
    if ctx.attrs.disable_nested_struct_naming:
        bindgen_cmd.add("--disable-nested-struct-naming")
    if ctx.attrs.disable_untagged_union:
        bindgen_cmd.add("--disable-untagged-union")
    if ctx.attrs.conservative_inline_namespaces:
        bindgen_cmd.add("--conservative-inline-namespaces")
    if ctx.attrs.respect_cxx_access_specs:
        bindgen_cmd.add("--respect-cxx-access-specs")
    if ctx.attrs.use_specific_virtual_function_receiver:
        bindgen_cmd.add("--use-specific-virtual-function-receiver")
    if ctx.attrs.use_distinct_char16_t:
        bindgen_cmd.add("--use-distinct-char16-t")
    if ctx.attrs.represent_cxx_operators:
        bindgen_cmd.add("--represent-cxx-operators")
    if ctx.attrs.vtable_generation:
        bindgen_cmd.add("--vtable-generation")
    if ctx.attrs.generate_deleted_functions:
        bindgen_cmd.add("--generate-deleted-functions")
    if ctx.attrs.generate_pure_virtual_functions:
        bindgen_cmd.add("--generate-pure-virtual-functions")
    if ctx.attrs.generate_private_functions:
        bindgen_cmd.add("--generate-private-functions")

    # -- Dynamic loading --
    if ctx.attrs.dynamic_loading:
        bindgen_cmd.add("--dynamic-loading", ctx.attrs.dynamic_loading)
    if ctx.attrs.dynamic_link_require_all:
        bindgen_cmd.add("--dynamic-link-require-all")

    # -- Static function wrapping --
    if ctx.attrs.wrap_static_fns:
        bindgen_cmd.add("--wrap-static-fns")
    if ctx.attrs.wrap_static_fns_path:
        bindgen_cmd.add("--wrap-static-fns-path", ctx.attrs.wrap_static_fns_path)
    if ctx.attrs.wrap_static_fns_suffix:
        bindgen_cmd.add("--wrap-static-fns-suffix", ctx.attrs.wrap_static_fns_suffix)

    # -- ABI overrides --
    for r in ctx.attrs.override_abi:
        bindgen_cmd.add("--override-abi", r)

    # -- Misc options --
    if ctx.attrs.builtins:
        bindgen_cmd.add("--builtins")
    if ctx.attrs.distrust_clang_mangling:
        bindgen_cmd.add("--distrust-clang-mangling")
    if ctx.attrs.no_include_path_detection:
        bindgen_cmd.add("--no-include-path-detection")
    if ctx.attrs.no_record_matches:
        bindgen_cmd.add("--no-record-matches")
    if ctx.attrs.c_naming:
        bindgen_cmd.add("--c-naming")
    if ctx.attrs.clang_macro_fallback:
        bindgen_cmd.add("--clang-macro-fallback")
    if ctx.attrs.clang_macro_fallback_build_dir:
        bindgen_cmd.add("--clang-macro-fallback-build-dir", ctx.attrs.clang_macro_fallback_build_dir)
    if ctx.attrs.prefix_link_name:
        bindgen_cmd.add("--prefix-link-name", ctx.attrs.prefix_link_name)
    if ctx.attrs.wasm_import_module_name:
        bindgen_cmd.add("--wasm-import-module-name", ctx.attrs.wasm_import_module_name)
    if ctx.attrs.enable_function_attribute_detection:
        bindgen_cmd.add("--enable-function-attribute-detection")
    if ctx.attrs.objc_extern_crate:
        bindgen_cmd.add("--objc-extern-crate")
    if ctx.attrs.block_extern_crate:
        bindgen_cmd.add("--block-extern-crate")
    if ctx.attrs.emit_diagnostics:
        bindgen_cmd.add("--emit-diagnostics")
    if ctx.attrs.experimental:
        bindgen_cmd.add("--experimental")

    # -- Clang args separator and args --
    bindgen_cmd.add("--")
    bindgen_cmd.add(cmd_args(ctx.attrs.include_directories, format = "-I{}"))
    bindgen_cmd.add(ctx.attrs.extra_clang_args)

    for dep in ctx.attrs.deps:
        preprocessor_info = dep[CPreprocessorInfo]
        for preprocessors in preprocessor_info.set.traverse():
            for preprocessor in preprocessors:
                bindgen_cmd.add(preprocessor.args.args)

    bindgen_cmd, _ = ctx.actions.write(
        ctx.actions.declare_output("__bindgen.sh"),
        [
            "#!/usr/bin/env bash",
            bindgen_cmd
        ],
        is_executable = True,
        allow_args = True,
    )

    ctx.actions.run([bindgen_cmd, bindings.as_output()], category = "rust_bindgen")

    return [DefaultInfo(default_output = bindings)]

rust_bindgen = rule(
    impl = rust_bindgen_impl,
    attrs = {
        # -- Input --
        "headers": attrs.list(attrs.source(), doc = "C or C++ header files to generate bindings for."),
        "deps": attrs.list(attrs.dep(), doc = "Dependencies that provide preprocessor information (include paths, defines, etc.)."),
        "include_directories": attrs.list(attrs.string(), default = [], doc = "Additional include directories passed to clang via -I flags."),
        "extra_clang_args": attrs.list(attrs.string(), default = [], doc = "Arguments to be passed straight through to clang."),

        # -- Enum style --
        "default_enum_style": attrs.option(attrs.string(), default = None, doc = "The default style of code used to generate enums."),
        "bitfield_enum": attrs.list(attrs.string(), default = [], doc = "Mark any enum whose name matches the regex as a set of bitfield flags."),
        "newtype_enum": attrs.list(attrs.string(), default = [], doc = "Mark any enum whose name matches the regex as a newtype."),
        "newtype_global_enum": attrs.list(attrs.string(), default = [], doc = "Mark any enum whose name matches the regex as a global newtype."),
        "rustified_enum": attrs.list(attrs.string(), default = [], doc = "Mark any enum whose name matches the regex as a Rust enum."),
        "rustified_non_exhaustive_enum": attrs.list(attrs.string(), default = [], doc = "Mark any enum whose name matches the regex as a non-exhaustive Rust enum."),
        "constified_enum": attrs.list(attrs.string(), default = [], doc = "Mark any enum whose name matches the regex as a series of constants."),
        "constified_enum_module": attrs.list(attrs.string(), default = [], doc = "Mark any enum whose name matches the regex as a module of constants."),
        "default_macro_constant_type": attrs.option(attrs.string(), default = None, doc = "The default signed/unsigned type for C macro constants."),
        "translate_enum_integer_types": attrs.bool(default = False, doc = "Always translate enum integer types to native Rust integer types."),
        "no_prepend_enum_name": attrs.bool(default = False, doc = "Do not prepend the enum name to constant or newtype variants."),

        # -- Typedef/alias style --
        "default_alias_style": attrs.option(attrs.string(), default = None, doc = "The default style of code used to generate typedefs."),
        "normal_alias": attrs.list(attrs.string(), default = [], doc = "Mark any typedef alias whose name matches the regex to use normal type aliasing."),
        "new_type_alias": attrs.list(attrs.string(), default = [], doc = "Mark any typedef alias whose name matches the regex to have a new type generated for it."),
        "new_type_alias_deref": attrs.list(attrs.string(), default = [], doc = "Mark any typedef alias whose name matches the regex to have a new type with Deref and DerefMut to the inner type."),

        # -- Union style --
        "default_non_copy_union_style": attrs.option(attrs.string(), default = None, doc = "The default style of code used to generate unions with non-Copy members. Note that ManuallyDrop was first stabilized in Rust 1.20.0."),
        "bindgen_wrapper_unions": attrs.list(attrs.string(), default = [], doc = "Mark any union whose name matches the regex and who has a non-Copy member to use a bindgen-generated wrapper for fields."),
        "manually_drop_unions": attrs.list(attrs.string(), default = [], doc = "Mark any union whose name matches the regex and who has a non-Copy member to use ManuallyDrop (stabilized in Rust 1.20.0) for fields."),

        # -- Blocklist --
        "blocklist_types": attrs.list(attrs.string(), default = [], doc = "Mark type as hidden."),
        "blocklist_functions": attrs.list(attrs.string(), default = [], doc = "Mark function as hidden."),
        "blocklist_items": attrs.list(attrs.string(), default = [], doc = "Mark item as hidden."),
        "blocklist_files": attrs.list(attrs.string(), default = [], doc = "Mark file as hidden."),
        "blocklist_vars": attrs.list(attrs.string(), default = [], doc = "Mark variable as hidden."),

        # -- Allowlist --
        "allowlist_functions": attrs.list(attrs.string(), default = [], doc = "Allowlist all the free-standing functions matching the regex. Other non-allowlisted functions will not be generated."),
        "allowlist_types": attrs.list(attrs.string(), default = [], doc = "Only generate types matching the regex. Other non-allowlisted types will not be generated."),
        "allowlist_vars": attrs.list(attrs.string(), default = [], doc = "Allowlist all the free-standing variables matching the regex. Other non-allowlisted variables will not be generated."),
        "allowlist_files": attrs.list(attrs.string(), default = [], doc = "Allowlist all contents of the given path."),
        "allowlist_items": attrs.list(attrs.string(), default = [], doc = "Allowlist all items matching the regex. Other non-allowlisted items will not be generated."),
        "no_recursive_allowlist": attrs.bool(default = False, doc = "Disable allowlisting types recursively. This will cause bindgen to emit Rust code that won't compile!"),

        # -- Derive --
        "no_derive_copy": attrs.bool(default = False, doc = "Avoid deriving Copy on any type."),
        "no_derive_debug": attrs.bool(default = False, doc = "Avoid deriving Debug on any type."),
        "with_derive_default": attrs.bool(default = False, doc = "Derive Default on any type."),
        "with_derive_hash": attrs.bool(default = False, doc = "Derive Hash on any type."),
        "with_derive_partialeq": attrs.bool(default = False, doc = "Derive PartialEq on any type."),
        "with_derive_partialord": attrs.bool(default = False, doc = "Derive PartialOrd on any type."),
        "with_derive_eq": attrs.bool(default = False, doc = "Derive Eq on any type."),
        "with_derive_ord": attrs.bool(default = False, doc = "Derive Ord on any type."),
        "impl_debug": attrs.bool(default = False, doc = "Create a Debug implementation if it cannot be derived automatically."),
        "impl_partialeq": attrs.bool(default = False, doc = "Create a PartialEq implementation if it cannot be derived automatically."),
        "no_partialeq": attrs.list(attrs.string(), default = [], doc = "Avoid deriving PartialEq for types matching the regex."),
        "no_copy": attrs.list(attrs.string(), default = [], doc = "Avoid deriving Copy and Clone for types matching the regex."),
        "no_debug": attrs.list(attrs.string(), default = [], doc = "Avoid deriving Debug for types matching the regex."),
        "no_default": attrs.list(attrs.string(), default = [], doc = "Avoid deriving/implementing Default for types matching the regex."),
        "no_hash": attrs.list(attrs.string(), default = [], doc = "Avoid deriving Hash for types matching the regex."),
        "must_use_type": attrs.list(attrs.string(), default = [], doc = "Add #[must_use] annotation to types matching the regex."),

        # -- Custom derive/attribute --
        "with_derive_custom": attrs.list(attrs.string(), default = [], doc = "Derive custom traits on any kind of type. The value must be of the shape REGEX=DERIVE where DERIVE is a comma-separated list of derive macros."),
        "with_derive_custom_struct": attrs.list(attrs.string(), default = [], doc = "Derive custom traits on a struct. The value must be of the shape REGEX=DERIVE where DERIVE is a comma-separated list of derive macros."),
        "with_derive_custom_enum": attrs.list(attrs.string(), default = [], doc = "Derive custom traits on an enum. The value must be of the shape REGEX=DERIVE where DERIVE is a comma-separated list of derive macros."),
        "with_derive_custom_union": attrs.list(attrs.string(), default = [], doc = "Derive custom traits on a union. The value must be of the shape REGEX=DERIVE where DERIVE is a comma-separated list of derive macros."),
        "with_attribute_custom": attrs.list(attrs.string(), default = [], doc = "Add custom attributes on any kind of type. The value must be of the shape REGEX=ATTRIBUTE where ATTRIBUTE is a comma-separated list of attributes."),
        "with_attribute_custom_struct": attrs.list(attrs.string(), default = [], doc = "Add custom attributes on a struct. The value must be of the shape REGEX=ATTRIBUTE where ATTRIBUTE is a comma-separated list of attributes."),
        "with_attribute_custom_enum": attrs.list(attrs.string(), default = [], doc = "Add custom attributes on an enum. The value must be of the shape REGEX=ATTRIBUTE where ATTRIBUTE is a comma-separated list of attributes."),
        "with_attribute_custom_union": attrs.list(attrs.string(), default = [], doc = "Add custom attributes on a union. The value must be of the shape REGEX=ATTRIBUTE where ATTRIBUTE is a comma-separated list of attributes."),

        # -- Layout and type --
        "no_layout_tests": attrs.bool(default = False, doc = "Avoid generating layout tests for any type."),
        "opaque_type": attrs.list(attrs.string(), default = [], doc = "Mark type as opaque."),
        "no_convert_floats": attrs.bool(default = False, doc = "Do not automatically convert floats to f32/f64."),
        "no_size_t_is_usize": attrs.bool(default = False, doc = "Do not bind size_t as usize (useful on platforms where those types are incompatible)."),
        "fit_macro_constant_types": attrs.bool(default = False, doc = "Try to fit macro constants into types smaller than u32/i32."),
        "use_array_pointers_in_arguments": attrs.bool(default = False, doc = "Use *const [T; size] instead of *const T for C arrays."),
        "explicit_padding": attrs.bool(default = False, doc = "Always output explicit padding fields."),
        "flexarray_dst": attrs.bool(default = False, doc = "Use DSTs to represent structures with flexible array members."),

        # -- Code generation --
        "generate": attrs.option(attrs.string(), default = None, doc = "Generate only given items, split by commas. Valid values are functions, types, vars, methods, constructors and destructors."),
        "ignore_functions": attrs.bool(default = False, doc = "Do not generate bindings for functions or methods. This is useful when you only care about struct layouts."),
        "ignore_methods": attrs.bool(default = False, doc = "Do not generate bindings for methods."),
        "generate_inline_functions": attrs.bool(default = False, doc = "Generate inline functions."),
        "generate_block": attrs.bool(default = False, doc = "Generate block signatures instead of void pointers."),
        "generate_cstr": attrs.bool(default = False, doc = "Generate string constants as &CStr instead of &[u8]."),
        "no_doc_comments": attrs.bool(default = False, doc = "Avoid including doc comments in the output."),
        "disable_header_comment": attrs.bool(default = False, doc = "Suppress insertion of bindgen's version identifier into generated bindings."),
        "sort_semantically": attrs.bool(default = False, doc = "Enables sorting of code generation in a predefined manner."),
        "merge_extern_blocks": attrs.bool(default = False, doc = "Deduplicates extern blocks."),
        "wrap_unsafe_ops": attrs.bool(default = False, doc = "Wrap unsafe operations in unsafe blocks."),

        # -- Raw lines --
        "raw_line": attrs.list(attrs.string(), default = [], doc = "Add a raw line of Rust code at the beginning of output."),
        "module_raw_line": attrs.list(attrs.tuple(attrs.string(), attrs.string()), default = [], doc = "Add a raw line of Rust code to a given module. Each entry is a (module_name, raw_line) tuple."),

        # -- Rust target --
        "rust_target": attrs.option(attrs.string(), default = None, doc = "Version of the Rust compiler to target. Any Rust version after 1.33.0 is supported. Defaults to 1.82.0."),
        "rust_edition": attrs.option(attrs.string(), default = None, doc = "Rust edition to target. Defaults to the latest edition supported by the chosen Rust target. Possible values: 2018, 2021, 2024."),
        "use_core": attrs.bool(default = False, doc = "Use types from Rust core instead of std."),
        "ctypes_prefix": attrs.option(attrs.string(), default = None, doc = "Use the given prefix before raw types instead of ::std::os::raw."),
        "anon_fields_prefix": attrs.option(attrs.string(), default = None, doc = "Use the given prefix for anonymous fields."),

        # -- Formatting --
        "formatter": attrs.option(attrs.string(), default = None, doc = "Which formatter should be used for the bindings."),
        "rustfmt_configuration_file": attrs.option(attrs.string(), default = None, doc = "The absolute path to the rustfmt configuration file. The configuration file will be used for formatting the bindings. This parameter sets formatter to rustfmt."),
        "default_visibility": attrs.option(attrs.string(), default = None, doc = "Set the default visibility of fields, including bitfields and accessor methods for bitfields. This flag is ignored if the respect_cxx_access_specs flag is used."),

        # -- C++ --
        "enable_cxx_namespaces": attrs.bool(default = False, doc = "Enable support for C++ namespaces."),
        "disable_name_namespacing": attrs.bool(default = False, doc = "Disable namespacing via mangling, causing bindgen to generate names like Baz instead of foo_bar_Baz for an input name foo::bar::Baz."),
        "disable_nested_struct_naming": attrs.bool(default = False, doc = "Disable nested struct naming, causing bindgen to generate names like bar instead of foo_bar for a nested definition struct foo { struct bar { } b; }."),
        "disable_untagged_union": attrs.bool(default = False, doc = "Disable support for native Rust unions."),
        "conservative_inline_namespaces": attrs.bool(default = False, doc = "Conservatively generate inline namespaces to avoid name conflicts."),
        "respect_cxx_access_specs": attrs.bool(default = False, doc = "Makes generated bindings pub only for items if the items are publicly accessible in C++."),
        "use_specific_virtual_function_receiver": attrs.bool(default = False, doc = "Always be specific about the receiver of a virtual function."),
        "use_distinct_char16_t": attrs.bool(default = False, doc = "Use distinct char16_t."),
        "represent_cxx_operators": attrs.bool(default = False, doc = "Output C++ overloaded operators."),
        "vtable_generation": attrs.bool(default = False, doc = "Enables generation of vtable functions."),
        "generate_deleted_functions": attrs.bool(default = False, doc = "Whether to generate C++ functions marked with =delete even though they can't be called."),
        "generate_pure_virtual_functions": attrs.bool(default = False, doc = "Whether to generate C++ pure virtual functions even though they can't be called."),
        "generate_private_functions": attrs.bool(default = False, doc = "Whether to generate C++ private functions even though they can't be called."),

        # -- Dynamic loading --
        "dynamic_loading": attrs.option(attrs.string(), default = None, doc = "Use dynamic loading mode with the given library name."),
        "dynamic_link_require_all": attrs.bool(default = False, doc = "Require successful linkage to all functions in the library."),

        # -- Static function wrapping --
        "wrap_static_fns": attrs.bool(default = False, doc = "Generate wrappers for static and static inline functions."),
        "wrap_static_fns_path": attrs.option(attrs.string(), default = None, doc = "Sets the path for the source file that must be created due to the presence of static and static inline functions."),
        "wrap_static_fns_suffix": attrs.option(attrs.string(), default = None, doc = "Sets the suffix added to the extern wrapper functions generated for static and static inline functions."),

        # -- ABI overrides --
        "override_abi": attrs.list(attrs.string(), default = [], doc = "Overrides the ABI of functions matching a regex. The value must be of the shape REGEX=ABI where ABI can be one of C, stdcall, efiapi, fastcall, thiscall, aapcs, win64 or C-unwind."),

        # -- Misc --
        "builtins": attrs.bool(default = False, doc = "Output bindings for builtin definitions, e.g. __builtin_va_list."),
        "distrust_clang_mangling": attrs.bool(default = False, doc = "Do not trust the libclang-provided mangling."),
        "no_include_path_detection": attrs.bool(default = False, doc = "Do not try to detect default include paths."),
        "no_record_matches": attrs.bool(default = False, doc = "Do not record matching items in the regex sets. This disables reporting of unused items."),
        "c_naming": attrs.bool(default = False, doc = "Generate types with C style naming."),
        "clang_macro_fallback": attrs.bool(default = False, doc = "Enable fallback for clang macro parsing."),
        "clang_macro_fallback_build_dir": attrs.option(attrs.string(), default = None, doc = "Set path for temporary files generated by fallback for clang macro parsing."),
        "prefix_link_name": attrs.option(attrs.string(), default = None, doc = "Prefix the name of exported symbols."),
        "wasm_import_module_name": attrs.option(attrs.string(), default = None, doc = "The name to be used in a #[link(wasm_import_module = ...)] statement."),
        "enable_function_attribute_detection": attrs.bool(default = False, doc = "Enables detecting unexposed attributes in functions (slow). Used to generate #[must_use] annotations."),
        "objc_extern_crate": attrs.bool(default = False, doc = "Use extern crate instead of use for objc."),
        "block_extern_crate": attrs.bool(default = False, doc = "Use extern crate instead of use for block."),
        "emit_diagnostics": attrs.bool(default = False, doc = "Whether to emit diagnostics or not."),
        "experimental": attrs.bool(default = False, doc = "Enables experimental features."),

        "_bindgen_toolchain": attrs.toolchain_dep(default = "toolchains//:bindgen", providers = [BindgenToolchainInfo])
    }
)
