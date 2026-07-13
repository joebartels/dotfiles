# Dotfiles (chezmoi)

## Setup
1. Install chezmoi first on a new macOS or Linux machine.
   - Use the supported official binary installer: `sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin"`
   - The installer directory, `$HOME/.local/bin`, must be on your `PATH`. A native package manager is also valid.
2. Clone/init: `chezmoi init https://github.com/…/dotfiles.git` (or `chezmoi init .` from this repo).
3. Apply: `chezmoi apply` (run with `-v` to see steps). On macOS or Linux, each applicable `chezmoi apply` checks `PATH` and `/opt/homebrew/bin/brew`, `/usr/local/bin/brew`, `/home/linuxbrew/.linuxbrew/bin/brew`, and `$HOME/.linuxbrew/bin/brew`. If none is detected, it invokes Homebrew's official interactive installer.

## Homebrew Packages

`Brewfile.base`, `Brewfile.darwin`, `Brewfile.linux`, `Brewfile.personal`, and `Brewfile.work` are tracked source-only declarations. The selected declarations match the operating system and profile, alongside the base declarations. The initial applicable `chezmoi apply` reconciles the selected base, operating-system, and profile Brewfiles with `brew bundle install --no-upgrade`. Subsequent runs do so when the runner's rendered input changes, including declarations in the selected Brewfiles. The profile must be `personal` or `work`.

## Notes
- Oh My Zsh installs via `run_once_install-oh-my-zsh.sh`; custom plugins/themes are pulled from `.chezmoiexternal.toml`.
- Manage personal additions (e.g., `~/.oh-my-zsh/custom/functions`) with `chezmoi add <path>` then `chezmoi diff` and commit.
- To skip external downloads during apply: `chezmoi apply --refresh-externals=false`.
