# Cross-Platform Homebrew Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bootstrap Homebrew idempotently on macOS and Linux, then reconcile layered Brewfiles through chezmoi.

**Architecture:** A `run_before_` script supplies the package-manager prerequisite. A separate `run_onchange_before_` script hashes selected package declarations and invokes `brew bundle install --no-upgrade`. Brewfiles are Git-tracked but ignored by chezmoi target state.

**Tech Stack:** chezmoi templates and scripts, Bash, Homebrew Bundle, shell-based template validation.

---

### Task 1: Add Homebrew bootstrap and shell initialization

**Files:**
- Create: `run_before_00-install-homebrew.sh.tmpl`
- Modify: `dot_zshrc`
- Test: `tests/test-homebrew-bootstrap.sh`

- [ ] **Step 1: Write the failing test**

Create a shell test that asserts the bootstrap script exists, renders for `darwin` and `linux`, exits without invoking the installer when a fake `brew` is present, and that `dot_zshrc` contains the standard supported-prefix fallback before Oh My Zsh loads.

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/test-homebrew-bootstrap.sh`

Expected: a non-zero exit because the bootstrap script and its assertions do not yet exist.

- [ ] **Step 3: Implement the minimal bootstrap behavior**

Create a Bash template guarded to `darwin` and `linux`. Use `set -euo pipefail`; consider `brew` present when it is in `PATH` or executable at `/opt/homebrew/bin/brew`, `/usr/local/bin/brew`, `/home/linuxbrew/.linuxbrew/bin/brew`, or `$HOME/.linuxbrew/bin/brew`; otherwise run Homebrew's official installer. Add an idempotent prefix fallback and `eval "$(brew shellenv)"` to `dot_zshrc` before Oh My Zsh.

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash tests/test-homebrew-bootstrap.sh`

Expected: exit 0 and assertions for both rendered operating systems pass.

### Task 2: Layer Brewfiles and reconcile packages on change

**Files:**
- Rename: `Brewfile` to `Brewfile.base`
- Create: `Brewfile.darwin`
- Create: `Brewfile.linux`
- Modify: `Brewfile.personal`
- Modify: `run_onchange_before_install-packages.sh.tmpl` to `run_onchange_before_10-install-brew-bundles.sh.tmpl`
- Modify: `.chezmoiignore`
- Modify: `tests/test-homebrew-bootstrap.sh`

- [ ] **Step 1: Write failing test cases**

Extend the test to require: `Brewfile.base` exists and declares `brew "go"`; macOS casks and VS Code entries are in `Brewfile.darwin`; both OS and profile files are listed in `.chezmoiignore`; the rendered bundle script has `--file=` syntax, `--no-upgrade`, and checksums that change after editing a copied selected Brewfile.

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/test-homebrew-bootstrap.sh`

Expected: a non-zero exit because the layered files and runner behavior do not yet exist.

- [ ] **Step 3: Implement minimal layered bundle behavior**

Move shared formulae and `go` package declarations into `Brewfile.base`, move `cask` and `vscode` declarations into `Brewfile.darwin`, preserve the personal and work profile files, and add an initially empty Linux overlay. The bundle script must resolve Homebrew independently, emit a SHA256 comment for every selected Brewfile, install base plus the current OS plus the current profile, and fail for an unsupported profile value.

- [ ] **Step 4: Run the test to verify it passes**

Run: `bash tests/test-homebrew-bootstrap.sh`

Expected: exit 0; macOS and Linux rendering assertions pass and the checksum regression check detects a copied Brewfile modification.

### Task 3: Document bootstrap use and validate full source state

**Files:**
- Modify: `README.md`
- Test: `tests/test-homebrew-bootstrap.sh`

- [ ] **Step 1: Write the failing documentation assertion**

Extend the test to require the README to say that chezmoi is the first prerequisite and Homebrew is bootstrapped during the first apply on supported platforms.

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/test-homebrew-bootstrap.sh`

Expected: a non-zero exit because the README still directs macOS users to install chezmoi through Homebrew.

- [ ] **Step 3: Update documentation**

Describe obtaining chezmoi before initialization, state that Homebrew is bootstrapped on macOS and Linux during `chezmoi apply`, and identify the layered Brewfiles as tracked source-only inputs.

- [ ] **Step 4: Run full validation**

Run: `bash tests/test-homebrew-bootstrap.sh && chezmoi apply --dry-run --verbose --source-path run_before_00-install-homebrew.sh.tmpl run_onchange_before_10-install-brew-bundles.sh.tmpl`

Expected: exit 0; tests pass, both scripts render, and dry-run does not execute an installer or bundle.
