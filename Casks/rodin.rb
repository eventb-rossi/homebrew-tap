cask "rodin" do
  version "3.9"
  sha256 "6a1663ab42c466c5fc7182fd794995f7442927f566309d6198df0923fbdd23bb"

  # The filename embeds an opaque build id (timestamp + git hash); update it on version bumps.
  url "https://downloads.sourceforge.net/rodin-b-sharp/Core_Rodin_Platform/#{version}/rodin-#{version}.0.202406100806-9b87fe13d-macosx.cocoa.x86_64.tar.gz",
      verified: "downloads.sourceforge.net/rodin-b-sharp/"
  name "Rodin Platform"
  desc "IDE for formal modelling and verification with Event-B"
  homepage "https://wiki.event-b.org/"

  livecheck do
    url "https://sourceforge.net/projects/rodin-b-sharp/files/Core_Rodin_Platform/"
    strategy :page_match do |page|
      page.scan(%r{Core_Rodin_Platform/(\d+(?:\.\d+)+)/}i).flatten
    end
  end

  depends_on arch: :x86_64
  depends_on macos: :big_sur

  app "rodin.app"

  postflight do
    ini = "#{appdir}/rodin.app/Contents/Eclipse/rodin.ini"
    contents = File.read(ini)
    unless contents.include?("org.eclipse.e4.ui.css.swt.theme")
      File.open(ini, "a") { |f| f.puts "-Dorg.eclipse.e4.ui.css.swt.theme=org.eclipse.e4.ui.css.theme.e4_default" }
    end
  end

  zap trash: [
    "~/Library/Application Support/rodin",
    "~/Library/Preferences/org.rodinp.platform.plist",
  ]

  caveats <<~EOS
    Rodin requires a system Java 17+ (it bundles none); install one with e.g.:
      brew install --cask temurin

    Rodin is not notarized by Apple. If macOS Gatekeeper blocks it from opening, run:
      xattr -dr com.apple.quarantine "#{appdir}/rodin.app"
  EOS
end
