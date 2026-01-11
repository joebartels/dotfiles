# Dotfiles

Personal dotfiles configuration for consistent development environment across machines.

## Contents

This repository contains configuration files for:

- **Zsh**: Shell configuration with aliases, functions, and environment variables
  - `.zshrc` - Main zsh configuration
  - `.zprofile` - Login shell configuration
  - `.zshenv` - Environment variables

- **Git**: Version control configuration
  - `.gitconfig` - Git global configuration
  - `config/git/ignore` - Global gitignore patterns

- **SSH**: Secure shell configuration
  - `ssh/config.d` - SSH host configurations (included by your main `~/.ssh/config`)

- **GitHub CLI**: GitHub command-line tool settings
  - `config/gh/config.yml` - GitHub CLI preferences
  - `config/gh/hosts.yml` - GitHub hosts configuration

- **uv**: Python package manager configuration
  - `config/uv/uv-receipt.json` - uv installation receipt

## Philosophy

This dotfiles repository is designed to be **minimal and universally safe**:

- **Shell configs** contain only universal aliases and functions that work in any environment
- **No dependencies** on specific tools (oh-my-zsh, themes, etc.)
- **Non-destructive** installation that preserves your existing configurations
- **Source-based approach** for shell configs means they work alongside system defaults
- **SSH configs are fallback defaults** - appended last so your existing host configurations always take precedence

If you have environment-specific configurations (like tool paths, framework initializations, or custom themes), keep those in your local shell config files. This repository provides universal utilities that enhance any environment.

## Installation

### Quick Install

Clone this repository and run the installation script:

```bash
git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

The script will:
1. Backup any existing configuration files that would be replaced
2. Create local configuration files from templates (`.zshrc.local`, `.gitconfig.local`)
3. **For shell configs** (`.zshrc`, `.zprofile`, `.zshenv`): Append source lines to your existing files (or create them if they don't exist)
4. **For SSH config**: Append an Include directive to your existing `~/.ssh/config` (host configs take precedence, dotfiles provide defaults)
5. **For other configs** (git, GitHub CLI, etc.): Create symlinks from your home directory to this repo

### Required: Configure Personal Information

After installation, you **must** edit these files with your personal information:

1. **Git configuration**: Edit `~/.dotfiles/git/.gitconfig.local`
   ```bash
   # Replace with your actual name and email
   [user]
       name = Your Name
       email = your.email@example.com
   ```

2. **GitHub CLI** (optional): Either run `gh auth login` or copy and edit `config/gh/hosts.yml.example`

3. **Machine-specific settings** (optional): Edit `~/.dotfiles/zsh/.zshrc.local` for custom aliases or environment variables

### Manual Installation

If you prefer to install specific configurations manually:

```bash
# Zsh - append source lines to your existing files
echo '[ -f "$HOME/.dotfiles/zsh/.zshrc" ] && source "$HOME/.dotfiles/zsh/.zshrc"' >> ~/.zshrc
echo '[ -f "$HOME/.dotfiles/zsh/.zprofile" ] && source "$HOME/.dotfiles/zsh/.zprofile"' >> ~/.zprofile
echo '[ -f "$HOME/.dotfiles/zsh/.zshenv" ] && source "$HOME/.dotfiles/zsh/.zshenv"' >> ~/.zshenv

# SSH - append Include directive to your existing config
echo "Include $HOME/.dotfiles/ssh/config.d" >> ~/.ssh/config

# Git
ln -s ~/.dotfiles/git/.gitconfig ~/.gitconfig
ln -s ~/.dotfiles/config/git/ignore ~/.config/git/ignore

# GitHub CLI
ln -s ~/.dotfiles/config/gh/config.yml ~/.config/gh/config.yml
ln -s ~/.dotfiles/config/gh/hosts.yml ~/.config/gh/hosts.yml

# uv
ln -s ~/.dotfiles/config/uv/uv-receipt.json ~/.config/uv/uv-receipt.json
```

## Updating

To update your dotfiles:

```bash
cd ~/.dotfiles
git pull origin main
```

Since shell configs are sourced (not symlinked), you'll need to restart your terminal or run `source ~/.zshrc` for changes to take effect. Other configs use symlinks and update immediately.

## Customization

### Adding New Dotfiles

1. Copy the config file to the appropriate directory in this repo
2. Update `install.sh` to symlink the new file
3. Update this README with information about the new config
4. Commit and push changes

### Local Configuration Files

This repository uses local configuration files for sensitive/machine-specific information:

- **`zsh/.zshrc.local`**: Machine-specific shell configuration (gitignored)
- **`git/.gitconfig.local`**: Personal git user info (gitignored)
- **`config/gh/hosts.yml`**: GitHub CLI authentication (gitignored)

These files are automatically created from `.example` templates during installation. They remain in the dotfiles directory but are excluded from git commits.

### Keeping Secrets Safe

The following patterns are gitignored to protect sensitive information:
- All `.local` configuration files
- SSH private keys (`*_rsa`, `*_ed25519`, etc.)
- Environment files (`.env`, `.env.local`)
- GitHub CLI authentication (`config/gh/hosts.yml`)

Never commit API keys, tokens, or passwords to this repository.

## Repository Structure

```
dotfiles/
├── config/
│   ├── gh/              # GitHub CLI configuration
│   ├── git/             # Git extended configuration
│   └── uv/              # uv Python package manager
├── git/
│   └── .gitconfig       # Git global configuration
├── ssh/
│   └── config.d         # SSH client configuration
├── zsh/
│   ├── .zshrc           # Zsh configuration
│   ├── .zprofile        # Zsh login shell config
│   └── .zshenv          # Zsh environment variables
├── install.sh           # Installation script
└── README.md            # This file
```

## Syncing Dotfiles Across Machines

### Initial Setup on New Machine

1. Install prerequisites (git, zsh, etc.)
2. Clone this repository
3. Run `./install.sh`
4. Restart your terminal

### Pushing Changes from One Machine

When you make changes to your dotfiles on one machine:

```bash
cd ~/.dotfiles
git add -A
git commit -m "Update configuration"
git push origin main
```

### Pulling Changes on Other Machines

On your other machines:

```bash
cd ~/.dotfiles
git pull origin main
source ~/.zshrc  # Reload shell config
```

## Uninstallation

To remove symlinks and restore backups:

```bash
# Find your backup directory
ls -d ~/.dotfiles_backup_*

# Remove symlinks and restore from backup
rm ~/.zshrc ~/.zprofile ~/.zshenv ~/.gitconfig
cp ~/.dotfiles_backup_TIMESTAMP/* ~/
```

## License

Free to use and modify for personal use.
