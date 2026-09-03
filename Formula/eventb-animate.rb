class EventbAnimate < Formula
  desc "Animate Event-B models with the ProB model checker, no Rodin required"
  homepage "https://github.com/eventb-rossi/eventb-animate"
  # Upstream's release asset is the fat jar from `./gradlew shadowJar`; installing
  # it directly avoids a Gradle build and the JDK 21 it would need.
  url "https://github.com/eventb-rossi/eventb-animate/releases/download/v6.6/eventb-animate-6.6.jar"
  sha256 "52428e45e0a8dc4e5f558a0b9d22feb56ade2ca7abbf8a7788510ed5b4be7cf5"
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
