cask "rodin@rc" do
  arch arm: "aarch64", intel: "x86_64"

  version "3.10-RC2"
  sha256 arm:   "7d1b50aab54f0fe839462a5924954a08529e57a4c10207f625186c37f40c8a2b",
         intel: "57f7d8585e95b60f13140ae1ab50cf6d591a750696fbee8ef3f470135aaedc31"

  # The filename embeds an opaque build id (timestamp + git hash); update it on version bumps.
  url "https://downloads.sourceforge.net/rodin-b-sharp/Core_Rodin_Platform/#{version}/rodin-3.10.0.202605210654-RC2-881664d81-macosx.cocoa.#{arch}.tar.gz",
      verified: "downloads.sourceforge.net/rodin-b-sharp/"
  name "Rodin Platform"
  desc "IDE for formal modelling and verification with Event-B"
  homepage "https://wiki.event-b.org/"

  livecheck do
    url "https://sourceforge.net/projects/rodin-b-sharp/files/Core_Rodin_Platform/"
    strategy :page_match do |page|
      page.scan(%r{Core_Rodin_Platform/(\d+(?:\.\d+)+-RC\d+)/}i).flatten
    end
  end

  conflicts_with cask: "rodin"
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
