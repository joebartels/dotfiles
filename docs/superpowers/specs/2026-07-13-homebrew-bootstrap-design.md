# Cross-Platform Homebrew Bootstrap Design

## Goal

Apply this chezmoi source state on macOS and Linux so Homebrew is installed when absent, existing installations are left alone, and declared packages are installed from version-controlled Brewfiles.

## Architecture

Homebrew bootstrap and package reconciliation have separate responsibilities:

1. `run_before_00-install-homebrew.sh.tmpl` runs on every apply on macOS and Linux. It detects `brew` in `PATH` and at supported default prefixes before invoking Homebrew's official installer.
2. `run_onchange_before_10-install-brew-bundles.sh.tmpl` runs only when the selected Brewfiles or its own logic changes. It resolves Homebrew independently, initializes its environment, then installs package layers without upgrading unrelated packages.

The Brewfiles remain in Git. `.chezmoiignore` prevents them from being materialized into the home directory.

## Package Layers

- `Brewfile.base`: cross-platform formulae and the Go toolchain needed by `go` package entries.
- `Brewfile.darwin`: macOS application casks and VS Code extensions.
- `Brewfile.linux`: Linux-only packages, initially empty but tracked for a stable interface.
- `Brewfile.personal` and `Brewfile.work`: profile overlays selected by `.env`.

## Operational Requirements

- Scripts must fail fast and be idempotent.
- Every selected Brewfile contributes a rendered checksum comment so chezmoi's `run_onchange_` state changes when package declarations change.
- The bundle script must not rely on the bootstrap script's process environment.
- Interactive shells load `brew shellenv` before Oh My Zsh initializes completions.
- Automated validation must render both macOS and Linux templates without running the Homebrew installer or changing installed packages.
