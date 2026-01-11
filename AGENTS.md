# Agent Guide for Dotfiles Repository

This document provides guidelines for AI agents and developers working on this dotfiles repository.

## Repository Overview

This is a personal dotfiles repository designed for consistent development environments across machines. It uses a **local configuration system** to separate committed configuration from personal/machine-specific data.

**Core Principle**: All personally identifiable information (PII) and machine-specific data must be stored in gitignored `.local` files, never in committed files.

## Working with This Repository

### PII Protection Rules

**CRITICAL**: Before committing any changes, verify there is no PII in your staged files.

**Never commit**:
- Personal names, emails, usernames
- IP addresses or hostnames
- File paths containing usernames (e.g., `/Users/specificname/`)
- API keys, tokens, or passwords

**Always use**:
- `$HOME` instead of `/Users/username` or `/home/username`
- Environment variables for machine-specific paths
- `.local` files for personal information (see below)

**Where PII belongs**:
- Git user info → `git/.gitconfig.local`
- Machine-specific shell config → `zsh/.zshrc.local`
- GitHub authentication → `config/gh/hosts.yml` (managed by `gh auth login`)

### PII Check Before Committing

```bash
# Scan staged changes for common PII patterns
git diff --cached | grep -iE "(your-name|@gmail|@yahoo|/Users/[a-z]+/)"

# View all staged files
git diff --cached --name-only
```

## Local Configuration System

This repository uses a template-based system for handling personal data:

1. **`.example` files** are committed to git (templates with placeholder values)
2. **`.local` files** are gitignored (actual personal data, created from templates)
3. **`install.sh`** automatically creates `.local` files from `.example` templates

### Current Local Configurations

| File | Purpose | How It Works |
|------|---------|--------------|
| `zsh/.zshrc.local` | Machine-specific shell config | Sourced by `.zshrc` using `${${(%):-%x}:A:h}/.zshrc.local` |
| `git/.gitconfig.local` | Git user name/email | Included by `.gitconfig` using `[include] path = .gitconfig.local` |
| `config/gh/hosts.yml` | GitHub CLI authentication | Managed by `gh auth login` command |

### Adding a New Local Configuration

If you need to add PII to a new file:

1. **Create an `.example` template**:
   ```bash
   # Example: config/tool/config.yml.example
   username: YOUR_USERNAME_HERE
   api_key: YOUR_API_KEY_HERE
   ```

2. **Add to `.gitignore`**:
   ```bash
   echo "config/tool/config.yml" >> .gitignore
   ```

3. **Update `install.sh`**:
   ```bash
   if [ ! -f "$DOTFILES_DIR/config/tool/config.yml" ]; then
       echo "Creating config/tool/config.yml from example"
       cp "$DOTFILES_DIR/config/tool/config.yml.example" "$DOTFILES_DIR/config/tool/config.yml"
       echo "  → Edit $DOTFILES_DIR/config/tool/config.yml with your details"
   fi
   ```

4. **Update README.md** with documentation about the new config

## Adding New Configuration Files

When adding a new dotfile to this repository:

1. **Place the file** in the appropriate directory (`zsh/`, `git/`, `config/`, etc.)

2. **Remove any PII**:
   - Replace hardcoded paths with `$HOME`
   - Move personal data to a `.local` file
   - Use environment variables where appropriate

3. **Update `install.sh`**:
   - Add a `backup_and_link` call to symlink the file

4. **Test installation**:
   ```bash
   ./install.sh
   ```

5. **Update documentation**:
   - Add entry to README.md under "Contents"
   - Update CHANGELOG.md

## Testing Changes

Before committing:

1. **Run install script**:
   ```bash
   ./install.sh
   ```

2. **Verify symlinks**:
   ```bash
   ls -la ~/. | grep "dotfiles"
   ```

3. **Check `.local` files created**:
   ```bash
   find . -name "*.local"
   ```

4. **Test with placeholder values**:
   - Ensure configs work even with template placeholders
   - Verify no errors when sourcing shell configs

5. **PII scan**:
   ```bash
   git diff --cached | grep -iE "(names|emails|specific-patterns)"
   ```

## Version Management

- **CHANGELOG.md** stores latest version, which is date of the change.
- New changes add to top of CHANGELOG.md file
- **NEVER edit past changelog entries** - they are historical records. Always add new entries for new changes.

### Releasing a New Version

1. **Update VERSION file**:
   ```bash
   echo "1.2.0" > VERSION
   ```

2. **Update CHANGELOG.md**:
   - Change `## [Unreleased]` to `## [1.2.0] - 2026-01-11`
   - Add new `## [Unreleased]` section at top

3. **Commit both files together**:
   ```bash
   git add VERSION CHANGELOG.md
   git commit -m "Release version 1.2.0"
   git tag v1.2.0
   ```

## Contribution Workflow

1. **Create feature branch**:
   ```bash
   git checkout -b feature/description
   ```

2. **Make changes**:
   - Follow PII protection rules
   - Test with `./install.sh`

3. **Update CHANGELOG.md**:
   - Add changes to `[Unreleased]` section
   - Use categories: Added, Changed, Deprecated, Removed, Fixed, Security

4. **Commit**:
   - Each major logical change = separate commit
   - Descriptive commit messages
   - Use conventional commits format when appropriate

5. **Verify before pushing**:
   ```bash
   # Final PII check
   git log -p | grep -iE "(personal-data-patterns)"

   # Check staged files
   git status
   ```

6. **Merge** (if releasing, update VERSION first)

## Common Gotchas

### Shell Configuration
- **`.zshrc.local` sourcing**: Uses `${${(%):-%x}:A:h}/.zshrc.local` which resolves the real file path even when `.zshrc` is symlinked
- **Single vs double quotes**: In `.zprofile`, Google Cloud SDK paths use single quotes (`'$HOME/...'`) to prevent expansion during shell startup

### Git Configuration
- **Include path**: `.gitconfig` uses relative path (`path = .gitconfig.local`) to find the local config
- **Install location**: Git config is symlinked from `~/.dotfiles/git/.gitconfig`, so relative paths work

### Install Script
- **Working directory**: Script must be run from the dotfiles directory
- **Backup directory**: Creates timestamped backup at `~/.dotfiles_backup_TIMESTAMP`
- **Idempotent**: Safe to run multiple times, skips existing `.local` files

### Platform Differences
- **macOS vs Linux**: Some aliases use macOS-specific flags (e.g., `ls -G` for color)

## File Structure Reference

```
dotfiles/
├── .gitignore              # Includes .local files and SSH keys
├── VERSION                 # Current version (e.g., 0.1.0)
├── CHANGELOG.md            # Version history following Keep a Changelog
├── README.md               # User-facing installation/usage guide
├── AGENTS.md               # This file - developer/agent guide
├── install.sh              # Installation script (creates symlinks)
├── config/
│   ├── gh/
│   │   ├── config.yml           # GitHub CLI preferences
│   │   ├── hosts.yml.example    # Template for authentication
│   │   └── hosts.yml            # gitignored - actual auth info
│   ├── git/
│   │   └── ignore               # Global gitignore patterns
│   └── uv/
│       └── uv-receipt.json      # Python uv package manager config
├── git/
│   ├── .gitconfig               # Git config (uses [include])
│   ├── .gitconfig.local.example # Template for user info
│   └── .gitconfig.local         # gitignored - name and email
├── ssh/
│   └── config                   # SSH client configuration
└── zsh/
    ├── .zshrc                   # Main zsh config (sources .zshrc.local)
    ├── .zshrc.local.example     # Template for machine-specific config
    ├── .zshrc.local             # gitignored - machine-specific overrides
    ├── .zprofile                # Login shell configuration
    └── .zshenv                  # Environment variables
```

## Quick Reference Commands

```bash
# Check for PII patterns in staged changes
git diff --cached | grep -iE "(your-patterns-here)"

# Test installation
./install.sh

# Find all template files
find . -name "*.example"

# Find all .local files (should be gitignored)
find . -name "*.local"

# Update version for release
echo "1.0.0" > VERSION
# Then update CHANGELOG.md manually

# Create release tag
git tag v$(cat VERSION)

# View current version
cat VERSION
```

## Support

For questions about this repository structure or contribution guidelines, please:
1. Review this document and the README.md
2. Check CHANGELOG.md for recent changes
3. Review existing commits for patterns
