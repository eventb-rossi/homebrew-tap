# Homebrew Tap for Event-B Rossi

Homebrew formulae and casks for the [Event-B](https://www.event-b.org/) ecosystem — the
Rodin Platform IDE and the EventBTool code/documentation generator.

## Install

```sh
brew tap eventb-rossi/tap
```

### Casks (GUI applications)

| Cask       | Version                      | Architectures                  | Description                  |
| ---------- | ---------------------------- | ------------------------------ | ---------------------------- |
| `rodin`    | 3.9 (stable)                 | Intel (x86_64) only            | Rodin Platform — Event-B IDE |
| `rodin@rc` | 3.10-RC2 (release candidate) | Intel + Apple Silicon (native) | Rodin Platform pre-release   |

```sh
brew install --cask rodin        # stable 3.9 — Intel Macs only
brew install --cask rodin@rc     # 3.10 release candidate — Intel + Apple Silicon
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

- Rodin is **not notarized** by Apple. If Gatekeeper blocks it from opening, clear the
  quarantine flag:

  ```sh
  xattr -dr com.apple.quarantine /Applications/rodin.app
  ```
