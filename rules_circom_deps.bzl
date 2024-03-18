load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def rules_circom_deps():
    if not native.existing_rule("com_google_absl"):
        http_archive(
            name = "com_google_absl",
            sha256 = "51d676b6846440210da48899e4df618a357e6e44ecde7106f1e44ea16ae8adc7",
            strip_prefix = "abseil-cpp-20230125.3",
            urls = ["https://github.com/abseil/abseil-cpp/archive/20230125.3.zip"],
        )

    if not native.existing_rule("rules_rust"):
        # Start of rules_rust
        http_archive(
            name = "rules_rust",
            sha256 = "9d04e658878d23f4b00163a72da3db03ddb451273eb347df7d7c50838d698f49",
            urls = ["https://github.com/bazelbuild/rules_rust/releases/download/0.26.0/rules_rust-v0.26.0.tar.gz"],
        )
