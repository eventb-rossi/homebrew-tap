class Tlc4b < Formula
  desc "Model-check classical B specifications by translating them to TLA+/TLC"
  homepage "https://github.com/hhu-stups/tlc4b"
  url "https://github.com/hhu-stups/tlc4b/archive/refs/tags/1.2.3.tar.gz"
  sha256 "f2d893a222fe6b5be3c40073b8b839d9a5d0134c89122df45629097a900a31ec"
  # The repository ships no LICENSE file; the Maven Central POM declares the
  # Eclipse Public License (linking the v1.0 text), matching the other STUPS tools.
  license "EPL-1.0"

  livecheck do
    url :stable
    strategy :git
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  # The bundled Gradle 8.14 wrapper does not run on the current `openjdk` (26),
  # and TLC4B still targets Java 8 bytecode, which newer JDKs refuse to emit.
  depends_on "openjdk@21" => :build
  depends_on "openjdk"

  def install
    # TLC4B has no fat-jar/shadow task, so injecting one via an init script keeps
    # upstream's build untouched while folding the runtime classpath into the
    # standard `jar` task — the result is a single self-contained runnable jar.
    (buildpath/"homebrew-fatjar.gradle").write <<~EOS
      allprojects {
        afterEvaluate { p ->
          if (p.plugins.hasPlugin('java')) {
            p.tasks.named('jar', Jar) {
              duplicatesStrategy = DuplicatesStrategy.EXCLUDE
              exclude 'META-INF/*.SF', 'META-INF/*.DSA', 'META-INF/*.RSA'
              manifest { attributes('Main-Class': 'de.tlc4b.TLC4B') }
              from { p.configurations.runtimeClasspath.collect { it.isDirectory() ? it : zipTree(it) } }
            }
          }
        }
      }
    EOS

    ENV["JAVA_HOME"] = Formula["openjdk@21"].opt_prefix
    ENV["GRADLE_USER_HOME"] = buildpath/".gradle"
    system "./gradlew", "--no-daemon", "-I", "homebrew-fatjar.gradle", "jar", "-x", "test"

    libexec.install "build/libs/tlc4b-#{version}.jar" => "tlc4b.jar"
    # Pin Homebrew's openjdk so the tool runs regardless of the user's JAVA_HOME.
    (bin/"tlc4b").write <<~EOS
      #!/bin/bash
      exec "#{Formula["openjdk"].opt_bin}/java" -jar "#{libexec}/tlc4b.jar" "$@"
    EOS
    (bin/"tlc4b").chmod 0555
  end

  test do
    # A deadlock-free, invariant-preserving machine: TLC must report NoError.
    (testpath/"Counter.mch").write <<~EOS
      MACHINE Counter
      VARIABLES c
      INVARIANT c : 0..3
      INITIALISATION c := 0
      OPERATIONS
        inc = SELECT c < 3 THEN c := c + 1 END;
        reset = SELECT c = 3 THEN c := 0 END
      END
    EOS
    assert_match "Result: NoError", shell_output("#{bin}/tlc4b #{testpath}/Counter.mch")
  end
end
