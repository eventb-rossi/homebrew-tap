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
  # `tag:` pins the version for Homebrew's autodetection. The asset names carry no
  # version, and the `x86_64` in the Intel names defeats detection (it scans `64`
  # out of `x86_64`); `tag:` makes every arch resolve to 0.1.0 and is kept in sync
  # by `brew bump-formula-pr`. Do not remove it.
  on_macos do
    on_arm do
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.1.0/rossi-aarch64-apple-darwin.tar.gz", tag: "0.1.0"
      sha256 "80f5410ca364367d23c9505d0c10ec6b139246b3d6108f8e3489660ab6c9c4b3"
    end
    on_intel do
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.1.0/rossi-x86_64-apple-darwin.tar.gz", tag: "0.1.0"
      sha256 "5bd3903a2d5ca81318eafed95881d70af05d08f3634ccd320af1b2ae5cd16b2e"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.1.0/rossi-aarch64-unknown-linux-gnu.tar.gz", tag: "0.1.0"
      sha256 "f86d6bd2e062a414ee64fc36d8c9af5a68fda5167c4bb59040f3073ecf33a57e"
    end
    on_intel do
      url "https://github.com/eventb-rossi/rossi/releases/download/v0.1.0/rossi-x86_64-unknown-linux-gnu.tar.gz", tag: "0.1.0"
      sha256 "654d1e1e219b49553d3052574ddcfc9f7ab3408d30f06acc0474500dca72d511"
    end
  end

  def install
    # Both binaries and the dual licenses sit at the tarball root.
    bin.install "rossi", "eventb-language-server"
    prefix.install "LICENSE-APACHE", "LICENSE-MIT"
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
