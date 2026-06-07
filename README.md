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
| `eventb-checker` | 1.3 | [eventb-checker](https://github.com/eventb-rossi/eventb-checker) — validate Event-B models (`.bum`/`.buc`/`.eventb` or `.zip`) without a Rodin installation |
| `eventb-animate` | 5.0 | [eventb-animate](https://github.com/eventb-rossi/eventb-animate) — animate Event-B models with the ProB model checker (random animation, invariant checking, trace save/replay) |
| `evbt`  | 1.5.0   | [EventBTool](https://codeberg.org/viklauverk/EventBTool) — code generation and documentation from Event-B models |
| `tlc4b` | 1.2.3   | [TLC4B](https://github.com/hhu-stups/tlc4b) — model-check classical B specifications by translating them to TLA+ and running TLC |
| `b2program` | 0.1.0 (master) | [B2Program](https://github.com/favu100/b2program) — generate Java/C++/Python/Rust/TypeScript code from high-level B |
| `eventb-to-txt` | 1.7 | [eventb-to-txt](https://github.com/eventb-rossi/eventb-to-txt) — convert Rodin Event-B models (`.bum`/`.buc`) to CamilleX plain text |

```sh
brew install eventb-checker
brew install eventb-animate
brew install evbt
brew install tlc4b
brew install b2program
brew install eventb-to-txt
```

## Requirements

- macOS 11 (Big Sur) or newer.
- **Rodin** needs a system **Java 17 or newer** — it bundles no JRE:

  ```sh
  brew install --cask temurin
  ```

  The `eventb-checker`, `eventb-animate`, `evbt`, `tlc4b` and `b2program` formulae do not
  need a separate JDK; Homebrew installs `openjdk` for them automatically. `eventb-to-txt` is a pure-Python
  tool (Python 3.10+); Homebrew installs `python` for it automatically.

- Rodin and Atelier B are **not notarized** by Apple. If Gatekeeper blocks an app from
  opening, clear the quarantine flag, e.g.:

  ```sh
  xattr -dr com.apple.quarantine /Applications/rodin.app
  xattr -dr com.apple.quarantine "/Applications/Atelier B.app"
  ```
