# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Local configuration system with `.example` template files
  - `zsh/.zshrc.local.example` for machine-specific shell configuration
  - `git/.gitconfig.local.example` for personal git user information
  - `config/gh/hosts.yml.example` for GitHub CLI authentication
- Git config now uses `[include]` directive to source personal information from `.gitconfig.local`
- Install script automatically creates `.local` files from templates during setup
- `.zshrc` now sources `.zshrc.local` from dotfiles repo directory (location-agnostic)
- Comprehensive `.gitignore` rules for local configuration files

### Changed
- Replaced all hardcoded `/Users/jb` paths with `$HOME` environment variable
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
