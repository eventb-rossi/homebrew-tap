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
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.2.2/rossi-aarch64-apple-darwin.tar.gz", tag: "0.2.2"
      sha256 "6a6e71e100311b79bfe76ecac6ae9d0951b49ec27dc12aab10c9f101c01d8f39"
    end
    on_intel do
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.2.2/rossi-x86_64-apple-darwin.tar.gz", tag: "0.2.2"
      sha256 "083e402c24a31f0b77bee73fe220b2604da395fd80a4666dfe3b1767a5a829cb"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.2.2/rossi-aarch64-unknown-linux-gnu.tar.gz", tag: "0.2.2"
      sha256 "9524d21d05118ba06d4490630b8aaa779be15b1228c32b168f1d79a15502b89e"
    end
    on_intel do
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.2.2/rossi-x86_64-unknown-linux-gnu.tar.gz", tag: "0.2.2"
      sha256 "d903d7f3fffdff122dc5192d151e216666526e8fe0939c6828e3a5fb9c85cc96"
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
