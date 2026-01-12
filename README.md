# Dotfiles

Minimal, safe dotfiles meant to layer on top of existing configs.

## What This Manages

- **Zsh**: `.zshrc` and `.zshenv` sourced from this repo
- **Git**: `.gitconfig` include + global ignore
- **SSH**: `ssh/defaults` included as fallback defaults
- **GitHub CLI**: `config/gh/config.yml`

## Install

```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

This will:
- Create local templates (`.zshrc.local`, `.gitconfig.local`) if missing
- Append source/include lines to your existing shell and SSH configs
- Symlink other configs (git ignore, GitHub CLI)
- Back up any files it replaces

## Required After Install

1. Edit `~/.dotfiles/git/.gitconfig.local` with your name and email.
2. Run `gh auth login` to set up GitHub CLI auth.
3. Optional: add machine-specific settings in `~/.dotfiles/zsh/.zshrc.local`.

## Manual Setup (Optional)

```bash
# Zsh
echo '[ -f "$HOME/.dotfiles/zsh/.zshrc" ] && source "$HOME/.dotfiles/zsh/.zshrc"' >> ~/.zshrc
echo '[ -f "$HOME/.dotfiles/zsh/.zshenv" ] && source "$HOME/.dotfiles/zsh/.zshenv"' >> ~/.zshenv

# SSH
echo "Include $HOME/.dotfiles/ssh/defaults" >> ~/.ssh/config

# Git
ln -s ~/.dotfiles/git/.gitconfig ~/.gitconfig
ln -s ~/.dotfiles/config/git/ignore ~/.config/git/ignore

# GitHub CLI
ln -s ~/.dotfiles/config/gh/config.yml ~/.config/gh/config.yml
```

## Update

```bash
cd ~/.dotfiles
git pull origin main
```

Restart your terminal or run `source ~/.zshrc` after updates.

## Uninstall

```bash
ls -d ~/.dotfiles_backup_*
rm ~/.zshrc ~/.zshenv ~/.gitconfig
cp ~/.dotfiles_backup_TIMESTAMP/* ~/
```
