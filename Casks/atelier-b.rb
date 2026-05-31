cask "atelier-b" do
  arch arm: "arm64", intel: "x86_64"

  version "24.04.2"
  sha256 arm:   "96437876d04746d5b2bf175834dd2468d0529c4f90389cda33e837035c5564e1",
         intel: "8bc757fb98f467633915a964af6501e47b63566e1f2d8e4fdf970cb2f74db24d"

  # The arm64 and x86_64 installers were published in different months, so the
  # WordPress upload path differs per architecture.
  url "https://www.atelierb.eu/wp-content/uploads/#{on_arch_conditional arm: "2024/11", intel: "2024/10"}/atelierb-free-#{version}-macos-#{arch}.dmg"
  name "Atelier B"
  name "Atelier B Community Edition"
  desc "Formal modelling and verification tool for the B method"
  homepage "https://www.atelierb.eu/"

  livecheck do
    url "https://www.atelierb.eu/en/atelier-b-support-maintenance/download-atelier-b/"
    strategy :page_match do |page|
      page.scan(/atelierb-free-(\d+(?:\.\d+)+)-macos-arm64\.dmg/i).flatten
    end
  end

  depends_on macos: :big_sur

  app "atelierb-free-#{arch}-#{version}.app", target: "Atelier B.app"

  zap trash: [
    "~/.atelierb",
    "~/Library/Preferences/com.clearsy.AtelierB*.plist",
    "~/Library/Saved Application State/com.clearsy.AtelierB*.savedState",
  ]

  caveats <<~EOS
    Atelier B is not notarized by Apple. If macOS Gatekeeper blocks it from opening, run:
      xattr -dr com.apple.quarantine "#{appdir}/Atelier B.app"
  EOS
end
