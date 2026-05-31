# Homebrew Tap for Event-B Rossi

Homebrew formulae and casks for the [Event-B](https://www.event-b.org/) / B-method
ecosystem — the Rodin Platform IDE, the EventBTool code/documentation generator, and
ClearSy's Atelier B.

## Install

```sh
brew tap eventb-rossi/tap
```

### Casks (GUI applications)

| Cask        | Version                      | Architectures                  | Description                       |
| ----------- | ---------------------------- | ------------------------------ | --------------------------------- |
| `rodin`     | 3.9 (stable)                 | Intel (x86_64) only            | Rodin Platform — Event-B IDE      |
| `rodin@rc`  | 3.10-RC2 (release candidate) | Intel + Apple Silicon (native) | Rodin Platform pre-release        |
| `atelier-b` | 24.04.2 (Community Edition)  | Intel + Apple Silicon (native) | Atelier B — IDE for the B method  |

```sh
brew install --cask rodin        # stable 3.9 — Intel Macs only
brew install --cask rodin@rc     # 3.10 release candidate — Intel + Apple Silicon
brew install --cask atelier-b    # Atelier B Community Edition
```

On Apple Silicon use `rodin@rc`; the `rodin` cask is Intel-only and will refuse to
install. Both Rodin casks install the same `rodin.app` and therefore conflict — install
only one at a time.

### Formulae (command-line tools)

| Formula | Version | Description                                                                 |
| ------- | ------- | --------------------------------------------------------------------------- |
| `evbt`  | 1.5.0   | [EventBTool](https://codeberg.org/viklauverk/EventBTool) — code generation and documentation from Event-B models |

```sh
brew install evbt
```

## Requirements

- macOS 11 (Big Sur) or newer.
- **Rodin** needs a system **Java 17 or newer** — it bundles no JRE:

  ```sh
  brew install --cask temurin
  ```

  `evbt` does not need a separate JDK; Homebrew installs `openjdk` for it automatically.

- Rodin and Atelier B are **not notarized** by Apple. If Gatekeeper blocks an app from
  opening, clear the quarantine flag, e.g.:

  ```sh
  xattr -dr com.apple.quarantine /Applications/rodin.app
  xattr -dr com.apple.quarantine "/Applications/Atelier B.app"
  ```
