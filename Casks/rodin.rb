cask "rodin" do
  arch arm: "aarch64", intel: "x86_64"

  version "3.10.0-2611,202611160826-a263a14"
  sha256 arm:   "bb81c992faab2737121d9f23d25734271cbf8e812c1458fba5b62dd755d4ecc4",
         intel: "e5764714b5b93d8beecc6eddbf8cf391176622087ee4ca535a715bb1ab5ec864"

  # The asset name carries the build qualifier (commit date + hash), which the
  # release tag does not, so the version is "<tag without v>,<qualifier>".
  url "https://github.com/eventb-rossi/Rodin-Bundle/releases/download/v#{version.csv.first}/rodin-#{version.csv.first.split("-").first}.#{version.csv.second}-rossi-macosx.cocoa.#{arch}.zip"
  name "Rodin Platform"
  name "Rodin Bundle"
  desc "IDE for formal modelling and verification with Event-B"
  homepage "https://github.com/eventb-rossi/Rodin-Bundle"

  # GitHub's latest release excludes the -rcN candidates (rodin@rc tracks those).
  # Read the qualifier from the release's macOS asset names.
  livecheck do
    url :url
    regex(/^rodin[._-]v?(\d+(?:\.\d+)+)\.(\d+-\h+)-rossi-macosx\.cocoa\.(?:aarch64|x86_64)\.zip$/i)
    strategy :github_latest do |json, regex|
      tag = json["tag_name"]&.delete_prefix("v")
      next if tag.blank?

      json["assets"]&.map do |asset|
        match = asset["name"]&.match(regex)
        next if match.nil?

        "#{tag},#{match[2]}"
      end
    end
  end

  depends_on :macos

  app "rodin.app"

  postflight_steps do
    # Rodin's editor and prover colours assume a light background. The bundle
    # already pins the Eclipse CSS theme in its product branding, and the app is
    # signed and notarized, so nothing inside rodin.app may be edited here (that
    # would break its code seal). On a dark-mode Mac, though, SWT still picks
    # its dark theme and flips the native Cocoa controls dark (a broken mixed
    # UI). SWT's Display.isSystemDarkTheme() reads the "AppleInterfaceStyle"
    # user default via NSUserDefaults.standardUserDefaults, whose per-app domain
    # shadows the global one. Pinning it to "Light" in Rodin's own domain makes
    # SWT choose the light theme and turn the native appearance light too. This
    # is the macOS analog of forcing GTK_THEME=Adwaita:light on Linux, scoped to
    # Rodin's bundle id only. (NSRequiresAquaSystemAppearance, which the bundle
    # sets, is ignored on modern macOS.)
    run "/usr/bin/defaults",
        args: ["write", "org.eventb.rossi.rodin",
               "AppleInterfaceStyle", "-string", "Light"]
  end

  zap trash: [
    "~/Library/Application Support/rodin",
    "~/Library/Preferences/org.eventb.rossi.rodin.plist",
    "~/Library/Preferences/org.rodinp.platform.plist",
    "~/Library/Preferences/org.rodinp.platform.product.plist",
  ]

  caveats <<~EOS
    Rodin requires a system Java 21+ (it bundles none); install one with e.g.:
      brew install --cask temurin

    On Apple Silicon the bundled CVC3 and CVC4 SMT solvers are Intel binaries
    and need Rosetta 2 (Z3, veriT and ProB run natively):
      softwareupdate --install-rosetta
  EOS
end
