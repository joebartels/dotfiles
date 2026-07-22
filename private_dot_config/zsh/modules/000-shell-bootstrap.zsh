# ==========================================================
#  MANAGED BY CHEZMOI
#  Edit:  chezmoi edit ~/.config/zsh/modules/000-shell-bootstrap.zsh
#  Apply: chezmoi apply ~/.config/zsh
# ==========================================================

# Enable Powerlevel10k instant prompt. This module must load before commands
# that may produce console output or require user input.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Make Homebrew available before Oh My Zsh loads plugins.
if ! command -v brew >/dev/null 2>&1; then
  for homebrew_bin in \
    /opt/homebrew/bin \
    /usr/local/bin \
    /home/linuxbrew/.linuxbrew/bin \
    "$HOME/.linuxbrew/bin"; do
    if [[ -x "$homebrew_bin/brew" ]]; then
      case ":$PATH:" in
        *":$homebrew_bin:"*) ;;
        *) export PATH="$homebrew_bin:$PATH" ;;
      esac
      break
    fi
  done
fi
unset homebrew_bin

if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
fi

# Only enable Oh My Zsh if installed.
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  export ZSH="$HOME/.oh-my-zsh"
  export UPDATE_ZSH_DAYS=21

  plugins=(git)
  ZSH_THEME="powerlevel10k/powerlevel10k"

  source "$ZSH/oh-my-zsh.sh"

  # Autoload all functions inside fpath by their name.
  autoload -Uz $fpath[1]/*(.:t)
fi

# Autoload custom functions from oh-my-zsh/custom/functions.
custom_functions_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/functions"
if [[ -d "$custom_functions_dir" ]]; then
  autoload -Uz "$custom_functions_dir"/*(.N:t)
fi
unset custom_functions_dir
