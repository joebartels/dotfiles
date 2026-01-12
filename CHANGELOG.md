# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to date based versioning (`YYYY-mm-DD.<version>`) where `.<version>` is optional (e.g. if signficant changes made on same day)

## [2026-01-11.9]

### Changed
- `backup_and_link` now logs where existing symlinks point before removing them
  - Helps preserve knowledge of hand-managed symlinks (e.g., to iCloud/Dropbox configs)
  - Output: "Removing existing symlink /path/to/file -> /original/target"

## [2026-01-11.8]

### Fixed
- Fixed git include path to support dotfiles directories with spaces
  - Git config path now quoted: `path = "$DOTFILES_DIR/git/.gitconfig"`
  - Previously would break if dotfiles were in `/Users/name/my dotfiles/`
- Added comment documenting SSH Include limitation with spaces in paths

## [2026-01-11.7]

### Fixed
- Fixed brittle git include detection logic in `install.sh`
  - Now uses `git config --get-regexp` to parse gitconfig instead of grep
  - Handles whitespace variations (`path=`, `path =`, quoted paths, etc.)
  - Only detects active includes (ignores commented-out lines)
  - Prevents duplicate `[include]` blocks over time

## [2026-01-11.6]

### Changed
- Renamed `ssh/config.d` to `ssh/defaults` for clarity
  - The `.d` suffix conventionally means "directory of config snippets"
  - New name clearly indicates it's a single file with default SSH settings

### Removed
- Removed `config/gh/hosts.yml.example` from repository
  - GitHub CLI's `gh auth login` automatically creates and manages `hosts.yml`
  - No need to track a template file when the tool handles it
  - `install.sh` no longer attempts to create or symlink this file
- Removed `config/uv/` directory and uv configuration
  - Tool not regularly used, no need to manage its config in dotfiles
  - Users can configure uv locally if needed
- Removed `zsh/.zprofile` from repository
  - Simplified to just `.zshrc` (interactive shells) and `.zshenv` (environment variables)
  - `.zprofile` was redundant - contained duplicate `pathn()` function already in `.zshrc`
  - Most users only need `.zshrc` for their shell customization

### Fixed
- SSH permissions now enforced during installation
  - `install.sh` now sets `~/.ssh` to 700 (drwx------)
  - `install.sh` now sets `~/.ssh/config` to 600 (-rw-------)
  - Prevents SSH from silently ignoring config files due to incorrect permissions
  - Critical for containers, shared home directories, and fresh environments

## [2026-01-11.5]

### Changed
- **BREAKING**: Git configuration now uses append-include pattern instead of symlink replacement
  - `install.sh` now appends `[include]` directive to existing `~/.gitconfig` instead of replacing it
  - Prevents data loss of existing git configurations on remote systems
  - Preserves user's existing git settings while adding dotfiles configurations
- Improved backup directory structure to preserve full paths
  - Backups now maintain original directory structure (e.g., `$BACKUP_DIR/Users/user/.config/gh/config.yml`)
  - Makes restoration easier by preserving context of where files came from

### Fixed
- SSH config now handles macOS-specific `UseKeychain` directive gracefully on Linux
  - Added `IgnoreUnknown UseKeychain` directive to prevent warnings/errors on non-macOS systems
  - SSH will silently ignore the option on unsupported platforms
- GitHub CLI hosts.yml now created from example template if missing
  - `install.sh` copies `hosts.yml.example` to `hosts.yml` if it doesn't exist
  - Prevents symlink creation failures when hosts.yml is missing

## [2026-01-11.4]

### Changed
- **BREAKING**: Changed SSH Include approach from prepend to append
  - Renamed `prepend_include_if_needed()` to `append_include_if_needed()` in `install.sh`
  - SSH Include directive now appended to end of `~/.ssh/config` instead of prepended
  - Host-specific SSH configs now take precedence over dotfiles (first match wins in SSH)
  - Dotfiles SSH config becomes a fallback/default configuration
- Updated README.md Philosophy section to explain SSH precedence behavior

## [2026-01-11.3]

### Changed
- Fixed SSH configuration to be truly universal
  - Removed environment-specific `Match all` directive from `ssh/config.d`
  - Removed codespaces-specific Include directive
- Improved `prepend_include_if_needed()` function in `install.sh`
  - Now creates `~/.ssh` directory if it doesn't exist
  - Handles fresh systems with no existing SSH configuration

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
- Changed SSH configuration to use Include pattern
  - Renamed `ssh/config` to `ssh/config.d`
  - `install.sh` now prepends Include directive to existing `~/.ssh/config` instead of replacing it
  - Preserves existing SSH configurations on remote systems
- Updated README.md with new "Philosophy" section explaining minimal, universal design
- Updated README.md installation instructions to reflect source-based and Include-based approaches

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
