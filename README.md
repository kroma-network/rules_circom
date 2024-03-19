# Rules Circom

Bazel Rule for Circom!

Please take a look at [kroma-network/circomlib](https://github.com/kroma-network/circomlib) for real examples!

## How to use

Add this to your `WORKSPACE`:

```bazel
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "kroma_network_rules_circom",
    sha256 = "<sha256>",
    strip_prefix = "rules_circom-<commit>",
    urls = ["https://github.com/kroma-network/rules_circom/archive/<commit>.tar.gz"],
)

load("@kroma_network_rules_circom//:rules_circom_deps.bzl", "rules_circom_deps")

rules_circom_deps()

load("@rules_rust//rust:repositories.bzl", "rules_rust_dependencies", "rust_register_toolchains")

rules_rust_dependencies()

rust_register_toolchains(
    edition = "2021",
    versions = [
        "1.66.1",
    ],
)

load("@rules_rust//crate_universe:repositories.bzl", "crate_universe_dependencies")

crate_universe_dependencies()

load("@rules_rust//crate_universe:defs.bzl", "crates_repository")

crates_repository(
    name = "crate_index",
    cargo_lockfile = "@kroma_network_rules_circom//:Cargo.lock",
    lockfile = "@kroma_network_rules_circom//:Cargo.Bazel.lock",
    manifests = ["@kroma_network_rules_circom//:Cargo.toml"],
)

load("@crate_index//:defs.bzl", "crate_repositories")

crate_repositories()
```

### How to compute sha256

```shell
curl -LO https://github.com/kroma-network/rules_circom/archive/<commit>.tar.gz
shasum -a 256 <commit>.tar.gz
```

And then, add this to your `BUILD.bazel`:

```bazel
load("@kroma_network_rules_circom//:build_defs.bzl", "circom_library", "compile_circuit")

circom_library(
    name = "<circom_lib_name>",
    srcs = [
      "foo.circom",
      "bar.circom",
    ],
)

compile_circuit(
    name = "<compile_circuit_name>",
    main = "baz.circom",
    deps = [":<circom_lib_name>"]
)
```

## Rules

### circom_library

- `srcs`: a list of sources. The files should end with **.circom**.
- `includes`: a list of directory to be linked. The list is going to be passed to [compile_circuit](#compile_circuit) as **-l** options.
- `deps`: a list of dependencies. Only the target defined by [circom_library](#circom_library) can be added.

### compile_circuit

- `srcs`: a list of sources. The files should end with **.circom**.
- `main`: a single file that contains main component.
- `includes`: a list of directory to be linked. The list is going to be passed to [compile_circuit](#compile_circuit) as **-l** options.
- `deps`: a list of dependencies. Only the target defined by [circom_library](#circom_library) can be added.

The followings flags are defined by [circom v2.1.8](https://github.com/iden3/circom/releases/tag/v2.1.8).

- `O0`: no simplification is applied.
- `O1`: only applies signal to signal and signal to constant simplification.
- `O2`: full constraint simplification.
- `verbose`: shows logs during compilation.
- `inspect`: does an additional check over the constraints produced.
- `use_old_simplification_heuristics`: applies the old version of the heuristics when performing linear .simplification
- `simplification_substitution`: outputs the substitution applied in the simplification phase in json.
- `prime`: to choose the prime number to use to generate the circuit. It should be either one of ("bn128", "bls12381", "goldilocks", "grumpkin", "pallas", "vesta", "secq256r1"). By default, "bn128".
- `O2round`: maximum number of rounds of the simplification process.
