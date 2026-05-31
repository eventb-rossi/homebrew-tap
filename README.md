# Homebrew Tap for Event-B Rossi

Casks for the [Rodin Platform](https://wiki.event-b.org/) — the Eclipse-based IDE for
formal modelling and verification with Event-B.

## Install

```sh
brew tap eventb-rossi/tap
```

| Cask       | Version                      | Architectures                  |
| ---------- | ---------------------------- | ------------------------------ |
| `rodin`    | 3.9 (stable)                 | Intel (x86_64) only            |
| `rodin@rc` | 3.10-RC2 (release candidate) | Intel + Apple Silicon (native) |

```sh
brew install --cask rodin       # stable 3.9 — Intel Macs only
brew install --cask rodin@rc    # 3.10 release candidate — Intel + Apple Silicon
```

On Apple Silicon use `rodin@rc`; the `rodin` cask is Intel-only and will refuse to
install. Both casks install the same `rodin.app` and therefore conflict — install only
one at a time.

## Requirements

- macOS 11 (Big Sur) or newer.
- A system **Java 17 or newer** — Rodin bundles no JRE:

  ```sh
  brew install --cask temurin
  ```

- Rodin is **not notarized** by Apple. If Gatekeeper blocks it from opening, clear the
  quarantine flag:

  ```sh
  xattr -dr com.apple.quarantine /Applications/rodin.app
  ```
