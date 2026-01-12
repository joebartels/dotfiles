# Universal ZSH Configuration
# Safe to source from any environment

# If not interactive, bail early (prevents weird non-interactive failures)
[[ -o interactive ]] || return

# Only enable OMZ if installed
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  export ZSH="$HOME/.oh-my-zsh"
  plugins=(git)
  ZSH_THEME="powerlevel10k/powerlevel10k"
  source "$ZSH/oh-my-zsh.sh"
fi

#########
# ALIASES
#########

# Cross-platform ls alias (works on both macOS and Linux)
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias ls='ls -laphG'  # macOS with color
else
    alias ls='ls -laph --color=auto'  # Linux with color
fi

# Docker utilities (safe - only work if docker is installed)
alias docker-reset='docker ps -q | xargs -r docker kill && docker container prune -f && docker volume prune -f'
alias docker-kill='docker ps -q | xargs -n 1 docker kill'

#########
# FUNCTIONS
#########

# Display PATH with one entry per line
pathn() {
    echo $PATH | sed -e $'s/:/\\\n/g'
}

#########
# LOCAL CONFIGURATION
#########

# Source local configuration if it exists (from dotfiles repo)
# This works even if .zshrc is symlinked - it finds the real file location
source "${${(%):-%x}:A:h}/.zshrc.local" 2>/dev/null || true
