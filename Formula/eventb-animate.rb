class EventbAnimate < Formula
  desc "Animate Event-B models with the ProB model checker, no Rodin required"
  homepage "https://github.com/eventb-rossi/eventb-animate"
  url "https://github.com/eventb-rossi/eventb-animate/archive/refs/tags/v5.1.tar.gz"
  sha256 "4ba3a903bed25ccde1140ca0c68a01e323b0df1b92d4e011d6fd3cae17eaf9ac"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_releases
  end

  # The Gradle toolchain targets Java 21 with auto-download disabled, so a JDK 21
  # must be present to build; the resulting fat jar runs on any modern JDK.
  depends_on "openjdk@21" => :build
  depends_on "openjdk"

  def install
    ENV["JAVA_HOME"] = formula_opt_prefix("openjdk@21")
    ENV["GRADLE_USER_HOME"] = buildpath/".gradle"
    system "./gradlew", "--no-daemon", "shadowJar", "-x", "test"

    libexec.install "build/libs/eventb-animate-#{version}.jar" => "eventb-animate.jar"
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
    # Animating a model would make the ProB kernel download probcli at runtime, so
    # the test stays offline and only exercises the CLI surface.
    assert_match "--steps", shell_output("#{bin}/eventb-animate --help")
  end
end
