cask "prob2-ui" do
  arch arm: "aarch64", intel: "x86_64"

  version "1.4.0"
  sha256 arm:   "95c0de2fdaaeb27db6def70cda48a228b99c380b261e5a9bc9c2125c6277d878",
         intel: "22a57411e22f7abf7c83fe86186fcfd655593e586b53633f9f6378ae342a96ad"

  url "https://stups.hhu-hosting.de/downloads/prob2/#{version}/ProB2-UI-#{arch}-#{version}.dmg"
  name "ProB2-UI"
  desc "JavaFX interface for the ProB animator, constraint solver and model checker"
  homepage "https://prob.hhu.de/w/index.php/ProB2-UI"

  livecheck do
    # Read the release directory index directly (snapshot/, plugins/ and pre-release
    # dirs lack a bare numeric name, so they fall out).
    url "https://stups.hhu-hosting.de/downloads/prob2/"
    regex(%r{href=["']?(\d+(?:\.\d+)+)/}i)
  end

  depends_on :macos

  app "ProB2-UI.app"

  # appdirs splits these on macOS: config dir -> Preferences, data dir -> Application Support.
  zap trash: [
    "~/Library/Application Support/prob2-ui",
    "~/Library/Preferences/prob2-ui",
  ]

  caveats <<~EOS
    On first launch you may need to open ProB2-UI twice before it starts
    properly. This should only happen once.

    ProB2-UI is not notarized by Apple. If macOS Gatekeeper blocks it from
    opening or reports it as damaged, run:
      xattr -dr com.apple.quarantine "#{appdir}/ProB2-UI.app"
  EOS
end
