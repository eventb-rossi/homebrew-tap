class EventbToTxt < Formula
  include Language::Python::Virtualenv

  desc "Convert Rodin Event-B models to CamilleX plain-text format"
  homepage "https://github.com/eventb-rossi/eventb-to-txt"
  url "https://files.pythonhosted.org/packages/86/3e/c74b2cfefbabd4476e37fd05afd1fec2934efff4cea359bdbb821565c2b3/eventb_to_txt-1.7.tar.gz"
  sha256 "2f9c066d4b28bd4b4359be9b1287a4c83fd2e25035767c08b5eef379751bd4f9"
  license "MIT"

  livecheck do
    url :stable
    strategy :pypi
  end

  depends_on "python@3.14"

  def install
    virtualenv_install_with_resources
  end

  test do
    # argparse --version prints "eventb-to-txt <version>"; pins the installed release.
    assert_match "eventb-to-txt #{version}", shell_output("#{bin}/eventb-to-txt --version")

    # Functional round-trip: a minimal Rodin context must convert to CamilleX text.
    # The component name ("C0") is taken from the file name. `-o -` merges to stdout.
    (testpath/"model").mkpath
    (testpath/"model/C0.buc").write <<~EOS
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <org.eventb.core.contextFile org.eventb.core.configuration="org.eventb.core.fwd" version="3">
      <org.eventb.core.carrierSet name="'" org.eventb.core.identifier="set1"/>
      <org.eventb.core.axiom name=")" org.eventb.core.label="axm1" org.eventb.core.predicate="cst1 ∈ set1"/>
      <org.eventb.core.constant name="," org.eventb.core.identifier="cst1"/>
      </org.eventb.core.contextFile>
    EOS
    output = shell_output("#{bin}/eventb-to-txt -o - #{testpath}/model")
    assert_match "context C0", output
    assert_match "set1", output
  end
end
