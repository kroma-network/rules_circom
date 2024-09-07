CircomInfo = provider(
    "Info needed to extract circom files and link directory.",
    fields = ["includes", "srcs"],
)

def _cpp_dir(name):
    return name + "_cpp/"

def _c_srcs(name):
    return [_cpp_dir(name) + file for file in [
        name + ".cpp",
    ]]

def _c_data(name):
    return [_cpp_dir(name) + file for file in [
        name + ".dat",
    ]]

def _c_name(name):
    if name == "main" or name == "fr" or name == "calcwit":
        return name + "_c"
    return name

def _GetPath(ctx, path):
    if ctx.label.workspace_root:
        return ctx.label.workspace_root + "/" + path
    else:
        return path

def _includes(ctx):
    includes = []
    for include in ctx.attr.includes:
        if include == ".":
            includes.append(_GetPath(ctx, ctx.label.package))
        else:
            includes.append(_GetPath(ctx, include))
    for dep in ctx.attr.deps:
        includes += dep[CircomInfo].includes
    return includes

def _circom_library_impl(ctx):
    return [CircomInfo(
        includes = _includes(ctx),
        srcs = depset(ctx.attr.srcs, transitive = [
            dep[CircomInfo].srcs
            for dep in ctx.attr.deps
        ]),
    )]

def _compile_circuit_impl(ctx):
    arguments = ["--r1cs"]

    if ctx.attr.generate_c:
        arguments.append("--c")
    if ctx.attr.generate_wasm:
        arguments.append("--wasm")
    if ctx.attr.generate_wasm:
        arguments.append("--sym")

    if ctx.attr.O0:
        arguments.append("--O0")
    if ctx.attr.O1:
        arguments.append("--O1")
    if ctx.attr.O2:
        arguments.append("--O2")
    if ctx.attr.verbose:
        arguments.append("--verbose")
    if ctx.attr.inspect:
        arguments.append("--inspect")
    if ctx.attr.use_old_simplification_heuristics:
        arguments.append("--use_old_simplification_heuristics")
    if ctx.attr.simplification_substitution:
        arguments.append("--simplification_substitution")
    if ctx.attr.prime:
        arguments.append("--prime={}".format(ctx.attr.prime))
    if ctx.attr.O2round != 0:
        arguments.append("--O2round={}".format(ctx.attr.O2round))

    src = ctx.attr.main.files.to_list()[0]
    arguments.append(src.path)

    name = _c_name(src.basename[:-len(".circom")])
    outputs = [
        name + ".r1cs",
    ]
    if ctx.attr.generate_c:
        outputs.append(_c_srcs(name))
        outputs.append(_c_data(name))
    if ctx.attr.generate_wasm:
        outputs.append(name + "_js/" + name + ".wasm")
    if ctx.attr.generate_sym:
        outputs.append(name + ".sym")
    outputs = [ctx.actions.declare_file(out) for out in outputs]
    arguments.append("--output=" + outputs[0].dirname)

    deps = depset(
        [],
        transitive = [
            dep[CircomInfo].srcs
            for dep in ctx.attr.deps
        ],
    ).to_list()
    deps = depset([], transitive = [
        dep[DefaultInfo].files
        for dep in deps
    ]).to_list()

    arguments.append("-l=.")

    includes = _includes(ctx)
    for include in includes:
        arguments.append("-l={}".format(include))

    ctx.actions.run(
        inputs = ctx.files.srcs + ctx.files.main + deps,
        tools = [ctx.executable._tool],
        executable = ctx.executable._tool,
        progress_message = "Compiling for " + name,
        outputs = outputs,
        arguments = arguments,
    )

    return [DefaultInfo(files = depset(outputs))]

circom_library = rule(
    implementation = _circom_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".circom"]),
        "includes": attr.string_list(),
        "deps": attr.label_list(providers = [CircomInfo]),
    },
)

compile_circuit = rule(
    implementation = _compile_circuit_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".circom"]),
        "main": attr.label(mandatory = True, allow_single_file = [".circom"]),
        "includes": attr.string_list(),
        "deps": attr.label_list(providers = [CircomInfo]),
        "generate_c": attr.bool(doc = "Compiles the circuit to C", default=True),
        "generate_wasm": attr.bool(doc = "Compiles the circuit to WASM"),
        "generate_sym": attr.bool(doc = "Outputs witness in sym format"),
        "O0": attr.bool(doc = "No simplification is applied"),
        "O1": attr.bool(doc = "Only applies signal to signal and signal to constant simplification"),
        "O2": attr.bool(doc = "Full constraint simplification"),
        "verbose": attr.bool(doc = "Shows logs during compilation"),
        "inspect": attr.bool(doc = "Does an additional check over the constraints produced"),
        "use_old_simplification_heuristics": attr.bool(
            doc = "Applies the old version of the heuristics when performing linear simplification",
        ),
        "simplification_substitution": attr.bool(
            doc = "Outputs the substitution applied in the simplification phase in json",
        ),
        "prime": attr.string(
            doc = "To choose the prime number to use to generate the circuit",
            values = ["bn128", "bls12381", "goldilocks", "grumpkin", "pallas", "vesta", "secq256r1"],
            default = "bn128",
        ),
        "O2round": attr.int(doc = "Maximum number of rounds of the simplification process"),
        "_tool": attr.label(
            # TODO(chokobole): Change to "exec", so we can build on macos.
            cfg = "target",
            executable = True,
            allow_single_file = True,
            default = Label("@kroma_network_rules_circom//:circom"),
        ),
    },
)
