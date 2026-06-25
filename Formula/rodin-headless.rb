class RodinHeadless < Formula
  desc "Headless toolchain to build, model-check, and prove Rodin Event-B models"
  homepage "https://github.com/eventb-rossi/rodin-headless"
  url "https://github.com/eventb-rossi/rodin-headless/archive/refs/tags/v4.0.tar.gz"
  sha256 "cbc19398518ceefc0153ebe66a4caf6ba33e2d767f93a7aa5739282d84abddab"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_releases
  end

  def install
    # Pure shell toolchain — nothing to compile. The upstream FHS Makefile copies
    # the two CLI entry points, the libexec engine/library, the Docker build
    # context, and the man pages, and rewrites the library-location sentinels to
    # these (absolute) install paths.
    system "make", "install", "prefix=#{prefix}"
  end

  def caveats
    <<~EOS
      rodin-headless bundles no Rodin, ProB, or Java; the wrapper picks a runtime
      automatically. Set up at least one path:

      Java (needed for native runs and the on-the-fly builder plugin; 21+ recommended):
        brew install --cask temurin            # or temurin@21
        rodin-headless-install --check-deps    # report anything still missing

      Native runtime (fast; macOS needs a logged-in graphical session):
        rodin-headless-install                 # downloads Rodin + ProB + plugins
                                               # into ~/.local/share/rodin-headless

      Container runtime (works headless, over SSH, and in CI):
        brew install --cask docker             # or: brew install podman
      The wrapper then pulls ghcr.io/eventb-rossi/rodin-headless on first use.

      To drive a GUI Rodin you already have (the rodin / rodin@rc cask), point
      RODIN_DIR at its rodin.app. A stock cask install can only `build`; the
      ProB-backed commands (check/prove/validate/autoprove) need the ProB plugin
      that only rodin-headless-install adds.
    EOS
  end

  test do
    # build/check/prove need a Rodin runtime (a native install or Docker), neither
    # of which the sandbox has; --version and help are the only fully-local commands.
    assert_match "rodin-headless #{version}", shell_output("#{bin}/rodin-headless --version")
    assert_match "Usage: rodin-headless", shell_output("#{bin}/rodin-headless help")
  end
end
