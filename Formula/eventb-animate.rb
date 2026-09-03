class EventbAnimate < Formula
  desc "Animate Event-B models with the ProB model checker, no Rodin required"
  homepage "https://github.com/eventb-rossi/eventb-animate"
  # Upstream's release asset is the fat jar from `./gradlew shadowJar`; installing
  # it directly avoids a Gradle build and the JDK 21 it would need.
  url "https://github.com/eventb-rossi/eventb-animate/releases/download/v7.0/eventb-animate-7.0.jar"
  sha256 "50f245abc4cc156f88670caa09104007d361f26c0b76e3f1f1b949f85e7e2440"
  license "Apache-2.0"

  livecheck do
    url :stable
    strategy :github_releases
  end

  depends_on "openjdk"

  def install
    libexec.install "eventb-animate-#{version}.jar" => "eventb-animate.jar"
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
