class Rossi < Formula
  desc "Rust toolchain for Event-B: parser, static checker, CLI, and language server"
  homepage "https://github.com/eventb-rossi/rossi"
  url "https://github.com/eventb-rossi/rossi/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "8ce0f1b23dc30c638c284234a0d48aaa5184d286adcb03afdccae341c8e07df1"
  license any_of: ["Apache-2.0", "MIT"]

  livecheck do
    # Rossi releases every workspace crate in lockstep to crates.io; track the
    # rossi-cli crate (the `rossi` binary) there rather than GitHub releases. The
    # Crate strategy only needs the package name from this URL; the version
    # placeholder keeps it valid across bumps.
    url "https://static.crates.io/crates/rossi-cli/rossi-cli-#{version}.crate"
    strategy :crate
  end

  depends_on "rust" => :build

  def install
    # Two binaries from one Cargo workspace, each its crate's sole bin:
    #   crates/rossi-cli  -> `rossi` (validate/import/export/fmt/build/lsp)
    #   crates/eventb-lsp -> `eventb-language-server` (the editor-facing LSP; the
    #                        same server as `rossi lsp`, under the name editors expect)
    system "cargo", "install", *std_cargo_args(path: "crates/rossi-cli")
    system "cargo", "install", *std_cargo_args(path: "crates/eventb-lsp")
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/rossi --version")
    assert_match version.to_s, shell_output("#{bin}/eventb-language-server --version")

    # A self-contained Event-B context (no external SEES), mirroring upstream's
    # crates/rossi/examples/counter.eventb.
    (testpath/"counter_ctx.eventb").write <<~EVENTB
      CONTEXT counter_ctx
      SETS
          STATUS
      CONSTANTS
          max_value
      AXIOMS
          @axm1 max_value = 100
          @axm2 max_value > 0
      END
    EVENTB

    # `validate` exits non-zero on any failure; a well-formed component passes.
    system bin/"rossi", "validate", testpath/"counter_ctx.eventb"

    # `fmt` with no write-mode flag prints the normalised model to stdout.
    assert_match "max_value", shell_output("#{bin}/rossi fmt #{testpath}/counter_ctx.eventb")
  end
end
