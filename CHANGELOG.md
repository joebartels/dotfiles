# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to date based versioning (`YYYY-mm-DD.<version>`) where `.<version>` is optional (e.g. if signficant changes made on same day)

## [2026-01-11.2]

### Changed
- **BREAKING**: Completely refactored zsh configuration files to be minimal and universal
  - `zsh/.zshrc`: Now contains only cross-platform aliases, docker utilities, and `pathn()` function
  - `zsh/.zprofile`: Now contains only the `pathn()` function
  - `zsh/.zshenv`: Now intentionally minimal with just comments
- Changed installation approach for shell configs from symlinks to source-based
  - `install.sh` now appends source lines to existing shell config files instead of replacing them
  - Preserves existing configurations and system defaults
  - Safe to use in remote/cloud environments without breaking system configs
- Updated README.md with new "Philosophy" section explaining minimal, universal design
- Updated README.md installation instructions to reflect source-based approach

### Removed
- All environment-specific configurations from committed files:
  - oh-my-zsh and Powerlevel10k setup
  - Nix, Conda, Deno, Bun initialization
  - Personal tool paths and development directories
  - NVM, Google Cloud SDK setup
  - Cargo/Rust environment
  - Python version paths

## [2026-01-11.1]

### Removed
- iTerm2 configuration files and directory (`config/iterm2/`)
- iTerm2 installation section from `install.sh`
- iTerm2 references from `README.md`, `AGENTS.md`

### Changed
- Updated AGENTS.md to clarify that past changelog entries should never be edited

## [2026-01-11]

### Added
- Local configuration system with `.example` template files
  - `zsh/.zshrc.local.example` for machine-specific shell configuration
  - `git/.gitconfig.local.example` for personal git user information
  - `config/gh/hosts.yml.example` for GitHub CLI authentication
- Git config now uses `[include]` directive to source personal information from `.gitconfig.local`
- Install script automatically creates `.local` files from templates during setup
- `.zshrc` now sources `.zshrc.local` from dotfiles repo directory (location-agnostic)
- Comprehensive `.gitignore` rules for local configuration files
- `CHANGELOG.md` stores the latest change & version (date)
- `AGENTS.md` documentation for AI agents and developers
  - PII protection guidelines
  - Local configuration system documentation
  - Contribution workflow
  - Testing procedures
  - Common gotchas and platform differences

### Changed
- Replaced all hardcoded `/Users/<user>` paths with `$HOME` environment variable
  - `zsh/.zshrc`: oh-my-zsh, nix, conda, deno, bun, claude paths
  - `zsh/.zprofile`: development paths, Google Cloud SDK paths
  - `config/iterm2/com.googlecode.iterm2.plist`: working directory
  - `config/uv/uv-receipt.json`: install prefix
- Updated README.md with detailed local configuration instructions
- Enhanced install script with automatic local config file creation

### Removed
- Personal information from `git/.gitconfig` (now in gitignored `.gitconfig.local`)
- GitHub username from `config/gh/hosts.yml` (now gitignored, use `gh auth login`)
- Sensitive IP address from `ssh/config`

### Security
- All PII (names, emails, usernames) now stored in gitignored `.local` files
- No hardcoded user-specific paths in committed files
- Safe to commit to public repositories
