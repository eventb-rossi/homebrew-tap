class EventbChecker < Formula
  desc "Standalone validator for Event-B models, no Rodin installation required"
  homepage "https://github.com/eventb-rossi/eventb-checker"
  url "https://github.com/eventb-rossi/eventb-checker/archive/refs/tags/v1.4.tar.gz"
  sha256 "eb73070553698cc75376833ea57ae6635ebbbd593fa9b24defc48abe79218eed"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_releases
  end

  # The Gradle toolchain targets Java 21 with auto-download disabled upstream, so a
  # JDK 21 must be present to build; the resulting fat jar runs on any modern JDK.
  depends_on "openjdk@21" => :build
  depends_on "openjdk"

  def install
    ENV["JAVA_HOME"] = Formula["openjdk@21"].opt_prefix
    ENV["GRADLE_USER_HOME"] = buildpath/".gradle"
    system "./gradlew", "--no-daemon", "shadowJar", "-x", "test"

    libexec.install "build/libs/eventb-checker-#{version}-all.jar" => "eventb-checker.jar"
    # Pin Homebrew's openjdk so the tool runs regardless of the user's JAVA_HOME.
    # --enable-native-access silences the JNA native-access warnings emitted by the
    # bundled Rodin AST libraries (and pre-empts their hard removal in a future JDK).
    (bin/"eventb-checker").write <<~EOS
      #!/bin/bash
      exec "#{Formula["openjdk"].opt_bin}/java" --enable-native-access=ALL-UNNAMED -jar "#{libexec}/eventb-checker.jar" "$@"
    EOS
    (bin/"eventb-checker").chmod 0555
  end

  test do
    assert_match "eventb-checker #{version}", shell_output("#{bin}/eventb-checker --version")

    # A minimal, fully valid Event-B machine in Camille notation: one variable, one
    # invariant, and an INITIALISATION that establishes it. Must report VALID.
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
    assert_match "RESULT: VALID", shell_output("#{bin}/eventb-checker #{testpath}/Counter.eventb")
  end
end
