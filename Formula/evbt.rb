class Evbt < Formula
  desc "Event-B tool for code generation and documentation (EventBTool)"
  homepage "https://codeberg.org/viklauverk/EventBTool"
  # Upstream ships a single self-executable jar as the release asset; the source
  # repository now lives on Codeberg, while release binaries remain on GitHub.
  url "https://github.com/viklauverk/EventBTool/releases/download/v1.5.0/evbt"
  sha256 "8366a220c47f128d195993e426db7c0d50a14f1f03ebbe37501eb1bc25fb10ff"
  license "AGPL-3.0-or-later"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
    # Upstream flags every release as a prerelease, so the default
    # :github_releases filter never matches anything — only skip drafts.
    strategy :github_releases do |json, regex|
      json.filter_map do |release|
        next if release["draft"]

        release["tag_name"]&.[](regex, 1)
      end
    end
  end

  # EventBTool requires Java 22 or later.
  depends_on "openjdk"

  def install
    libexec.install "evbt" => "evbt.jar"
    # Pin Homebrew's openjdk (>= 22) rather than relying on the user's JAVA_HOME,
    # which may point at an older JDK that EventBTool refuses to run on.
    (bin/"evbt").write <<~EOS
      #!/bin/bash
      exec "#{Formula["openjdk"].opt_bin}/java" -jar "#{libexec}/evbt.jar" "$@"
    EOS
    (bin/"evbt").chmod 0555
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/evbt version")
  end
end
