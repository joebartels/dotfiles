# Dotfiles (chezmoi)

## Setup
- Install chezmoi:
  - macOS: `brew install chezmoi`
  - Linux: `sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin`
- Clone/init: `chezmoi init https://github.com/…/dotfiles.git` (or `chezmoi init .` from this repo).
- Apply: `chezmoi apply` (run with `-v` to see steps).

## Notes
- Oh My Zsh installs via `run_once_install-oh-my-zsh.sh`; custom plugins/themes are pulled from `.chezmoiexternal.toml`.
- Manage personal additions (e.g., `~/.oh-my-zsh/custom/functions`) with `chezmoi add <path>` then `chezmoi diff` and commit.
- To skip external downloads during apply: `chezmoi apply --refresh-externals=false`.
