class EventbAnimate < Formula
  desc "Animate Event-B models with the ProB model checker, no Rodin required"
  homepage "https://github.com/eventb-rossi/eventb-animate"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_releases
  end

  depends_on "openjdk"

  # Upstream ships per-platform fat jars from `./gradlew shadowJar -PprobPlatform=…`,
  # each bundling only that platform's probcli; installing one directly avoids a
  # Gradle build and the JDK 21 it would need. The jars are not arch-specific:
  # the on_arm/on_intel split exists only because `brew style` rejects a url
  # directly inside on_macos/on_linux. Upstream ships no ARM Linux jar, so ARM
  # Linux gets linux64. `brew bump-formula-pr` can't rewrite these nested urls,
  # so the release tracker's bump-per-os job updates them together.
  on_macos do
    on_arm do
      url "https://github.com/eventb-rossi/eventb-animate/releases/download/v7.1/eventb-animate-7.1-macos.jar"
      sha256 "287b2c18f658eee06627e181c68d4eddae3f4d278600a2de725e268f747c364b"
    end
    on_intel do
      url "https://github.com/eventb-rossi/eventb-animate/releases/download/v7.1/eventb-animate-7.1-macos.jar"
      sha256 "287b2c18f658eee06627e181c68d4eddae3f4d278600a2de725e268f747c364b"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/eventb-rossi/eventb-animate/releases/download/v7.1/eventb-animate-7.1-linux64.jar"
      sha256 "5d9859cf6fb4d03a13e65136158d3534385b0a33583fccf88232c239eb5ca992"
    end
    on_intel do
      url "https://github.com/eventb-rossi/eventb-animate/releases/download/v7.1/eventb-animate-7.1-linux64.jar"
      sha256 "5d9859cf6fb4d03a13e65136158d3534385b0a33583fccf88232c239eb5ca992"
    end
  end

  def install
    libexec.install Dir["eventb-animate-*.jar"].first => "eventb-animate.jar"
    # Pin Homebrew's openjdk so the tool runs regardless of the user's JAVA_HOME.
    # --sun-misc-unsafe-memory-access=allow silences the sun.misc.Unsafe deprecation
    # warnings emitted by the bundled Guice on JDK 24+.
    (bin/"eventb-animate").write <<~EOS
      #!/bin/bash
      exec "#{formula_opt_bin("openjdk")}/java" --sun-misc-unsafe-memory-access=allow -jar "#{libexec}/eventb-animate.jar" "$@"
    EOS
    (bin/"eventb-animate").chmod 0555
  end

  test do
    assert_match "eventb-animate #{version}", shell_output("#{bin}/eventb-animate --version")
    # Model-checking would make the ProB kernel download probcli at runtime, so the
    # test stays offline and only exercises the CLI surface.
    assert_match "Usage: eventb-animate", shell_output("#{bin}/eventb-animate --help")
  end
end
