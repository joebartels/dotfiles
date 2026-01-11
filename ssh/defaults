# Universal SSH Configuration from dotfiles
# This file is included by your main ~/.ssh/config

# Default settings for all hosts
Host *
  AddKeysToAgent yes
  # UseKeychain is macOS-specific, will be ignored with warning on other systems
  IgnoreUnknown UseKeychain
  UseKeychain yes

# GitHub specific configuration
Host github.com
  IdentityFile ~/.ssh/github_rsa
  IdentitiesOnly yes
