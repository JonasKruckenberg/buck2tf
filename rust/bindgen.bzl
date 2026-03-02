load("@prelude//cxx/preprocessor.bzl", "CPreprocessorInfo")
load("@prelude//rules.bzl", "genrule", "rust_binary", "rust_library")

HeadersInfo = provider(fields = ["headers"])

def _bindgen_headers(
    ctx: AnalysisContext,
) -> list[Provider]:
    headers = {header.basename: header for header in ctx.attrs.headers}
    for dep in ctx.attrs.deps:
        for header in dep[HeadersInfo].headers:
            if header.basename in headers:
                fail("Duplicate header:", header.basename)
            headers[header.basename] = header
    out = ctx.actions.copied_dir(ctx.attrs.name, headers)
    return [DefaultInfo(default_output = out), HeadersInfo(headers = headers.values())]

bindgen_headers = rule(
    impl = _bindgen_headers,
    attrs = {
        "headers": attrs.list(attrs.source(), default = []),
        "deps": attrs.list(attrs.dep(), default = []),
    },
)

def rust_bindgen_library(
        name, # name of the target
        srcs, # rust files of the library
        build_script, # rust build script that generates the bindings
        headers = [], # list of .h/.hpp file to generate bindings for
        deps = [],
        build_script_deps = [],
        header_deps = [], # list of c/cpp deps to required by the headers we're generating bindings for
        build_env = None,
        visibility = [],
        **kwargs):
    build_name = name + "-build"
    headers_name = name + "-headers"

    rust_binary(
        name = build_name,
        srcs = [build_script],
        crate_root = build_script,
        deps = build_script_deps,
        visibility = [],
    )

    env = build_env or {}
    if headers:
        env["BUCK_BINDGEN_HEADERS"] = "$(location {})".format(headers)
    if header_deps:
        clang_args = cmd_args([])
        for dep in header_deps:
            pprint(type(dep))
            preprocessor_info = dep[CPreprocessorInfo]
            for preprocessors in preprocessor_info.set.traverse():
                for preprocessor in preprocessors:
                    clang_args.add(preprocessor.args.args)
        env["BUCK_BINDGEN_CLANG_ARGS"] = clang_args

    genrule(
        name = headers_name,
        srcs = headers,
        cmd = "$(exe :{})".format(build_name),
        env = env,
        out = ".",
        visibility = [],
    )

    rust_library(
        name = name,
        srcs = srcs,
        env = {
            "OUT_DIR": "$(location :{})".format(headers_name),
        },
        deps = (deps or []),
        visibility = visibility,
        **kwargs
    )
