# ==========================================================
#  MANAGED BY CHEZMOI
#  Purpose: Set up Neovim shell aliases when available
#  Provides: vi and vim aliases for Neovim
#  Edit:  chezmoi edit ~/.config/zsh/modules/100-neovim.zsh
#  Apply: chezmoi apply ~/.config/zsh
# ==========================================================

if command -v nvim >/dev/null 2>&1; then
  alias vim='nvim'
  alias vi='nvim'
fi
