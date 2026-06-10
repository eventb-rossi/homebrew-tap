cask "prob2-ui" do
  arch arm: "aarch64", intel: "x86_64"

  version "1.3.1"
  sha256 arm:   "0f7f212d40ee86ed387ec0f5e315b0a15aae7b573bc413ce15e04c09acf41f10",
         intel: "29fe8acecfc008266f14ca8c81c70d5c215d7d7b3ca0725f51dd8013567470b2"

  # Apple Silicon ships a notarized .zip; Intel ships an unsigned .dmg, so both the
  # extension and the filename suffix differ per architecture.
  url "https://stups.hhu-hosting.de/downloads/prob2/#{version}/ProB2-UI-#{arch}-#{version}#{on_arch_conditional arm: "-notarized.zip", intel: ".dmg"}",
      verified: "stups.hhu-hosting.de/downloads/prob2/"
  name "ProB2-UI"
  desc "JavaFX interface for the ProB animator, constraint solver and model checker"
  homepage "https://prob.hhu.de/w/index.php/ProB2-UI"

  livecheck do
    # Read the release directory index directly (snapshot/, plugins/ and pre-release
    # dirs lack a bare numeric name, so they fall out).
    url "https://stups.hhu-hosting.de/downloads/prob2/"
    regex(%r{href=["']?(\d+(?:\.\d+)+)/}i)
  end

  depends_on macos: :big_sur

  app "ProB2-UI.app"

  # appdirs splits these on macOS: config dir -> Preferences, data dir -> Application Support.
  zap trash: [
    "~/Library/Application Support/prob2-ui",
    "~/Library/Preferences/prob2-ui",
  ]

  caveats <<~EOS
    On first launch you may need to open ProB2-UI twice before it starts
    properly. This should only happen once.

    The Intel (x86_64) build is not signed or notarized by Apple (the Apple
    Silicon build is). If macOS Gatekeeper blocks ProB2-UI from opening or
    reports it as damaged, run:
      xattr -dr com.apple.quarantine "#{appdir}/ProB2-UI.app"
  EOS
end
