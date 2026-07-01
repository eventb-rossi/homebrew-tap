cask "rodin" do
  arch arm: "aarch64", intel: "x86_64"

  version "3.10"
  sha256 arm:   "8902f55f4171b506eaf74757e73dcb33d4a7b214a14fbdd6971b65a2a3392bca",
         intel: "82a339f664ab01161d2f389c9983e6a0fc0bdb151312900bec1079e6cf03556e"

  # The filename embeds an opaque build id (timestamp + git hash); update it on version bumps.
  url "https://downloads.sourceforge.net/rodin-b-sharp/Core_Rodin_Platform/#{version}/rodin-#{version}.0.202607010932-881664d81-macosx.cocoa.#{arch}.tar.gz",
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

  depends_on macos: :big_sur

  app "rodin.app"

  postflight do
    ini = "#{appdir}/rodin.app/Contents/Eclipse/rodin.ini"
    contents = File.read(ini)
    unless contents.include?("org.eclipse.e4.ui.css.swt.theme")
      File.open(ini, "a") { |f| f.puts "-Dorg.eclipse.e4.ui.css.swt.theme=org.eclipse.e4.ui.css.theme.e4_default" }
    end

    # The e4 CSS theme above only pins the Eclipse-drawn widgets. On a dark-mode
    # Mac, SWT also picks its dark theme and flips the native Cocoa controls dark
    # (a broken mixed UI). SWT's Display.isSystemDarkTheme() reads the
    # "AppleInterfaceStyle" user default via NSUserDefaults.standardUserDefaults,
    # whose per-app domain shadows the global one. Pinning it to "Light" in
    # Rodin's own domain makes SWT choose the light theme and turn the native
    # appearance light too. This is the macOS analog of forcing
    # GTK_THEME=Adwaita:light on Linux, scoped to Rodin's bundle id only.
    # (NSRequiresAquaSystemAppearance is ignored on modern macOS, so it cannot be
    # used for this.)
    system_command "/usr/bin/defaults",
                   args: ["write", "org.rodinp.platform.product",
                          "AppleInterfaceStyle", "-string", "Light"]
  end

  zap trash: [
    "~/Library/Application Support/rodin",
    "~/Library/Preferences/org.rodinp.platform.plist",
    "~/Library/Preferences/org.rodinp.platform.product.plist",
  ]

  caveats <<~EOS
    Rodin requires a system Java 17+ (it bundles none); install one with e.g.:
      brew install --cask temurin

    Rodin is not notarized by Apple. If macOS Gatekeeper blocks it from opening, run:
      xattr -dr com.apple.quarantine "#{appdir}/rodin.app"
  EOS
end
