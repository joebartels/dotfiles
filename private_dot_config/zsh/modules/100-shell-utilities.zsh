# ==========================================================
#  MANAGED BY CHEZMOI
#  Purpose: General cross-platform shell conveniences
#  Provides: ls, pathn, GPG_TTY
#  Edit:  chezmoi edit ~/.config/zsh/modules/100-shell-utilities.zsh
#  Apply: chezmoi apply ~/.config/zsh
# ==========================================================

# Cross-platform ls alias.
if [[ "$OSTYPE" == "darwin"* ]]; then
  alias ls='ls -laphG'
else
  alias ls='ls -laph --color=auto'
fi

# Print the entries in PATH with duplicates removed.
function pathn() {
  tr ':' '\n' <<< "$PATH" | sort -u
}

# GnuPG may need the current terminal for interactive prompts.
export GPG_TTY=$TTY
