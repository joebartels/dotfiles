# ==========================================================
#  MANAGED BY CHEZMOI
#  Purpose: Load untracked machine-specific shell settings
#  Provides: ~/.zshrc.local overrides
#  Edit:  chezmoi edit ~/.config/zsh/modules/500-local-overrides.zsh
#  Apply: chezmoi apply ~/.config/zsh
# ==========================================================

# Machine-specific settings remain in the untracked ~/.zshrc.local file.
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
