class Rossi < Formula
  desc "Rust toolchain for Event-B: parser, static checker, CLI, and language server"
  homepage "https://github.com/eventb-rossi/rossi"
  license any_of: ["Apache-2.0", "MIT"]

  livecheck do
    # We package the prebuilt binaries from upstream's GitHub releases, so track
    # those releases directly: a new release (with fresh binaries) is exactly what
    # a formula bump needs.
    url :stable
    strategy :github_latest
  end

  # Upstream ships official prebuilt binaries for every platform Homebrew supports;
  # each tarball bundles both `rossi` and `eventb-language-server` at its root.
  #
  # `tag:` pins the version for Homebrew: the asset names carry no version and the
  # `x86_64` in the Intel names defeats autodetection (it scans `64` out of
  # `x86_64`), while an explicit top-level `version` would be rejected by
  # `brew audit` as redundant with the version in the `/v<version>/` URL path.
  # `brew bump-formula-pr` can't rewrite these per-arch urls (they live in
  # on_os/on_arch blocks, not a top-level url stanza), so the release tracker's
  # bump-rossi job updates the four `tag:`, url, and sha256 values together.
  on_macos do
    on_arm do
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.1.7/rossi-aarch64-apple-darwin.tar.gz", tag: "0.1.7"
      sha256 "5d9b65db86daddee330baef787a40cb6cee6c36cc58080b130c1bc0395231ee2"
    end
    on_intel do
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.1.7/rossi-x86_64-apple-darwin.tar.gz", tag: "0.1.7"
      sha256 "4e29287d1843d85e3e1e71bae376a5ab27ca40917704e7c86ebf7ebff145cb88"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.1.7/rossi-aarch64-unknown-linux-gnu.tar.gz", tag: "0.1.7"
      sha256 "975a702c56859e14c532eb278ce95d3f17e00f66ddfb5e8e1693cf61353a5030"
    end
    on_intel do
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.1.7/rossi-x86_64-unknown-linux-gnu.tar.gz", tag: "0.1.7"
      sha256 "698214d8082e2c9e0e8b638cd561ff0b6d9f1066ee5b79444f7ac54acfb7d10d"
    end
  end

  def install
    # Both binaries and the dual licenses sit at the tarball root.
    bin.install "rossi", "eventb-language-server"
    prefix.install "LICENSE-APACHE", "LICENSE-MIT"

    # `rossi completions <shell>` prints a script generated from the CLI's own command tree,
    # so it always matches the installed version. The helper runs the freshly installed
    # binary once per shell (bash/zsh/fish) and drops each script in the right place.
    generate_completions_from_executable(bin/"rossi", "completions")
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
