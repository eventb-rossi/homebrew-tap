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
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.2.1/rossi-aarch64-apple-darwin.tar.gz", tag: "0.2.1"
      sha256 "d759fd84f320de75e8372a0cc7b4644a73ec2350cbd97b94855b60209aacab34"
    end
    on_intel do
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.2.1/rossi-x86_64-apple-darwin.tar.gz", tag: "0.2.1"
      sha256 "3294a9f231145f5b32db2a73bef1ef2555dab7f78bd5257eb257af4121e7e57f"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.2.1/rossi-aarch64-unknown-linux-gnu.tar.gz", tag: "0.2.1"
      sha256 "e2a205d73135fadf0ad7db83033c0490ab5bc4fac87f159ac65a19e550f67c52"
    end
    on_intel do
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.2.1/rossi-x86_64-unknown-linux-gnu.tar.gz", tag: "0.2.1"
      sha256 "b60168d50d44eb9418c7ccb27df019311fe670ffe935610a36c7e3d91f10e19d"
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
