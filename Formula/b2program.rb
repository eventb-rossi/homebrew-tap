class B2program < Formula
  desc "Multi-target code generator from high-level B to Java, C++, Python, Rust, TS"
  homepage "https://github.com/favu100/b2program"
  # B2Program publishes no tagged releases (version is a perpetual 0.1.0-SNAPSHOT),
  # so the formula is pinned to a known-good master commit (dated 2026-05-12).
  url "https://github.com/favu100/b2program/archive/6deb3e17a4cdb97ccc2e2946f7aaafb8e5fa2ba6.tar.gz"
  version "0.1.0-20260512"
  sha256 "9572505f268c5743b180057e6534f6c646b764746e84e60692a7e58853df6ff4"
  # Upstream declares no license (it is a read-only mirror of the STUPS GitLab
  # repository, which ships none); intentionally left unset rather than guessed.

  livecheck do
    skip "No tagged releases; upstream ships only a moving master branch"
  end

  # The bundled Gradle 9.4 wrapper does not run on the current `openjdk` (26),
  # and B2Program targets Java 17 bytecode.
  depends_on "openjdk@21" => :build
  depends_on "openjdk"

  def install
    ENV["JAVA_HOME"] = formula_opt_prefix("openjdk@21")
    ENV["GRADLE_USER_HOME"] = buildpath/".gradle"
    system "./gradlew", "--no-daemon", "fatJar", "-x", "test"

    libexec.install Dir["build/libs/B2Program-all-*.jar"].first => "b2program.jar"
    # Pin Homebrew's openjdk so the tool runs regardless of the user's JAVA_HOME.
    (bin/"b2program").write <<~EOS
      #!/bin/bash
      exec "#{formula_opt_bin("openjdk")}/java" -jar "#{libexec}/b2program.jar" "$@"
    EOS
    (bin/"b2program").chmod 0555
  end

  test do
    # A B machine's name must match its file name for B2Program's parser.
    (testpath/"Counter.mch").write <<~EOS
      MACHINE Counter
      VARIABLES c
      INVARIANT c : INTEGER
      INITIALISATION c := 0
      OPERATIONS
        inc = BEGIN c := c + 1 END
      END
    EOS
    system bin/"b2program", "-l", "java", "-f", "Counter.mch"
    assert_path_exists testpath/"Counter.java"
    assert_match "class Counter", (testpath/"Counter.java").read
  end
end
