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
  # bump-per-os job updates the four `tag:`, url, and sha256 values together.
  on_macos do
    on_arm do
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.3.0/rossi-aarch64-apple-darwin.tar.gz", tag: "0.3.0"
      sha256 "51bb2ac315eb087274d4e5fe0cd20bf650c9c3b12d6f33a690e8664a1578fdb4"
    end
    on_intel do
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.3.0/rossi-x86_64-apple-darwin.tar.gz", tag: "0.3.0"
      sha256 "41443c65d102af1963417a2e3fdaabd431cf29a4f0ab8c9616ca0f6223e8c829"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.3.0/rossi-aarch64-unknown-linux-gnu.tar.gz", tag: "0.3.0"
      sha256 "929ab7bd6218fbd11d6a9ffe71bea57a2223b667e2264bcdb94d069a147cc2af"
    end
    on_intel do
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.3.0/rossi-x86_64-unknown-linux-gnu.tar.gz", tag: "0.3.0"
      sha256 "a71a4738093e4bae2bab7cb529aec3706bdd7931e2cc7a0cc143a039279518ea"
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
