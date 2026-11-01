# Dotfiles (chezmoi)

## Setup
1. Install chezmoi first on a new macOS or Linux machine.
   - Use the supported official binary installer: `sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin"`
   - The installer directory, `$HOME/.local/bin`, must be on your `PATH`. A native package manager is also valid.
2. Clone/init: `chezmoi init https://github.com/…/dotfiles.git` (or `chezmoi init .` from this repo).
3. Before the first apply, set the machine-local profile in `~/.config/chezmoi/chezmoi.toml` (create it if absent):
   ```toml
   [data]
   env = "personal" # or "work"
   ```
   Use `env = "work"` on work machines. The profile selects the relevant Brewfile and must be `personal` or `work`.
4. Apply: `chezmoi apply` (run with `-v` to see steps). On macOS or Linux, each applicable `chezmoi apply` checks `PATH` and `/opt/homebrew/bin/brew`, `/usr/local/bin/brew`, `/home/linuxbrew/.linuxbrew/bin/brew`, and `$HOME/.linuxbrew/bin/brew`. If none is detected, it invokes Homebrew's official interactive installer.

## Homebrew Packages

`Brewfile.base`, `Brewfile.darwin`, `Brewfile.linux`, `Brewfile.personal`, and `Brewfile.work` are tracked source-only declarations. The selected declarations match the operating system and profile, alongside the base declarations. The initial applicable `chezmoi apply` reconciles the selected base, operating-system, and profile Brewfiles with `brew bundle install --no-upgrade`. Subsequent runs do so when the runner's rendered input changes, including declarations in the selected Brewfiles. The profile must be `personal` or `work`.

## Neovim

`~/.config/nvim/init.lua`, `lua/config/lazy.lua`, `lua/plugins/init.lua`, `README.md`, and `lazy-lock.json` are managed under `private_dot_config/nvim/`. This preserves the existing **lazy.nvim** plugin-manager bootstrap with an empty plugin spec; it is not the **LazyVim** distribution. See [`private_dot_config/nvim/README.md`](private_dot_config/nvim/README.md) (also deployed to `~/.config/nvim/README.md`) for editing, plugin declarations, and cross-machine workflows. The managed `100-neovim.zsh` module aliases `vi` and `vim` to `nvim` only when it is available.

`Brewfile.base` installs Neovim, Git (for the bootstrap), ripgrep, and fd on both macOS and Linux; fzf is also included. The normal apply/bootstrap and checksum-triggered bundle reconciliation above handle these packages on each machine, without reinstalling on every apply. Do not assume Debian's `apt` Neovim version is recent enough for lazy.nvim: this setup uses Homebrew's Neovim on Linux too. Install Homebrew's Linux prerequisites first (on Debian/Ubuntu: `sudo apt-get update && sudo apt-get install build-essential procps curl file git`); the interactive Homebrew installer may require sudo and network access.

The first `nvim` launch needs network access to clone lazy.nvim; its update checker also uses the network. Downloaded plugins and Neovim data/cache/state directories are not managed. The lazy.nvim-generated `lazy-lock.json` is shared: after first-machine init/apply or a receiving machine's `chezmoi update`, run `:Lazy restore`, not `:Lazy sync`, to restore locked plugin revisions without unintended upgrades. Preserve local target edits before applying/updating. Applying these files does not launch Neovim or install plugins.

The work profile's Snowflake cask is macOS-only and is skipped on Linux; this does not provision Snowflake on Linux. Root repository documentation and tests are source-only; the Neovim README is deployed with its configuration.

## Notes
- Oh My Zsh installs via `run_once_install-oh-my-zsh.sh`; custom plugins/themes are pulled from `.chezmoiexternal.toml`.
- Manage personal additions (e.g., `~/.oh-my-zsh/custom/functions`) with `chezmoi add <path>` then `chezmoi diff` and commit.
- To skip external downloads during apply: `chezmoi apply --refresh-externals=false`.
