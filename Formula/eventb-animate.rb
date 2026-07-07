class EventbAnimate < Formula
  desc "Animate Event-B models with the ProB model checker, no Rodin required"
  homepage "https://github.com/eventb-rossi/eventb-animate"
  url "https://github.com/eventb-rossi/eventb-animate/archive/refs/tags/v6.0.tar.gz"
  sha256 "9e23b00936c693cfa95a902b919e49b73b9fa4050d05295c9431f08985ec0e78"
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
