class EventbChecker < Formula
  desc "Standalone validator for Event-B models, no Rodin installation required"
  homepage "https://github.com/eventb-rossi/eventb-checker"
  # Upstream's release asset is the fat jar from `./gradlew shadowJar`; installing
  # it directly avoids a Gradle build and the JDK 21 it would need.
  url "https://github.com/eventb-rossi/eventb-checker/releases/download/v1.14/eventb-checker-1.14-all.jar"
  sha256 "4555a56814268017d4de2235738189669ad3b5439dec00e78184182b33b9ac33"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_releases
  end

  depends_on "openjdk"

  def install
    libexec.install "eventb-checker-#{version}-all.jar" => "eventb-checker.jar"
    # Pin Homebrew's openjdk so the tool runs regardless of the user's JAVA_HOME.
    # --enable-native-access silences the JNA native-access warnings emitted by the
    # bundled Rodin AST libraries (and pre-empts their hard removal in a future JDK).
    (bin/"eventb-checker").write <<~EOS
      #!/bin/bash
      exec "#{formula_opt_bin("openjdk")}/java" --enable-native-access=ALL-UNNAMED -jar "#{libexec}/eventb-checker.jar" "$@"
    EOS
    (bin/"eventb-checker").chmod 0555
  end

  test do
    assert_match "eventb-checker #{version}", shell_output("#{bin}/eventb-checker --version")

    # A minimal, fully valid Event-B machine in Camille notation: one variable, one
    # invariant, and an INITIALISATION that establishes it. `check` must report VALID.
    (testpath/"Counter.eventb").write <<~EOS
      machine Counter
      variables n
      invariants
        @inv1 n ∈ ℕ
      events
        event INITIALISATION
        then
          @act1 n ≔ 0
        end
      end
    EOS
    assert_match "RESULT: VALID", shell_output("#{bin}/eventb-checker check #{testpath}/Counter.eventb")
  end
end
