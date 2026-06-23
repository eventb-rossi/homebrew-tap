class Prob < Formula
  desc "Animator, constraint solver and model checker for B, Event-B, CSP-M, TLA+, Z"
  homepage "https://prob.hhu.de/"
  # ProB ships a prebuilt Tcl/Tk distribution (a SICStus Prolog image plus launchers);
  # the macOS archive is a universal binary, so a single download serves both arches.
  url "https://stups.hhu-hosting.de/downloads/prob/tcltk/releases/1.15.1/ProB.macos.zip"
  sha256 "6e85c88eee56ec7f18f4b1737693b1dc4bfbf4f9081c42def8c09afff48f24c2"
  license "EPL-1.0"

  livecheck do
    # The release index also lists beta/rc/"final" directories and an empty
    # current_version.txt, so match only bare X.Y.Z directory names.
    url "https://stups.hhu-hosting.de/downloads/prob/tcltk/releases/"
    regex(%r{href=["']?(\d+(?:\.\d+)+)/}i)
  end

  depends_on macos: :big_sur
  depends_on "openjdk" # Java-backed features (-check_java_version, KodKod, ProB2 bridge)
  depends_on "tcl-tk@8" # libtcl8.6 the SICStus image loads for the Tcl/Tk GUI

  def install
    libexec.install Dir["*"]

    # probcli.sh execs the self-contained SICStus binary next to it; just put
    # Homebrew's java on PATH so the Java-backed features resolve a JDK.
    (bin/"probcli").write <<~EOS
      #!/bin/bash
      export PATH="#{formula_opt_bin("openjdk")}:$PATH"
      exec "#{libexec}/probcli.sh" "$@"
    EOS
    (bin/"probcli").chmod 0555

    # StartProB.sh loads Tcl/Tk through SICStus's SP_TCL_DSO; pin Homebrew's
    # tcl-tk@8 dylib via its version-independent opt_lib path instead of relying on
    # the script's Cellar glob.
    (bin/"prob-tk").write <<~EOS
      #!/bin/bash
      export PATH="#{formula_opt_bin("openjdk")}:$PATH"
      export SP_TCL_DSO="#{formula_opt_lib("tcl-tk@8")}/libtcl8.6.dylib"
      exec "#{libexec}/StartProB.sh" "$@"
    EOS
    (bin/"prob-tk").chmod 0555
  end

  def caveats
    <<~EOS
      `probcli` is the command-line interface; `prob-tk` starts the Tcl/Tk GUI.

      The bundled CSP-M parser (cspmf) is Intel-only, so on Apple Silicon CSP-M
      (.csp) inputs need Rosetta 2:
        softwareupdate --install-rosetta

      Graph visualisation (e.g. probcli's -dot output) needs Graphviz:
        brew install graphviz
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/probcli -version")
  end
end
