# ==========================================================
#  MANAGED BY CHEZMOI
#  Edit:  chezmoi edit ~/.config/zsh/modules/100-docker.zsh
#  Apply: chezmoi apply ~/.config/zsh
# ==========================================================

alias docker-kill='docker ps -q | xargs -n 1 docker kill'

# Clear any alias from plugins so the function definition works.
unalias docker-reset 2>/dev/null || true
docker-reset() {
  local ids
  ids="$(docker ps -q)"
  [[ -n "$ids" ]] && echo "$ids" | xargs docker kill
  docker container prune -f
  docker volume prune -f
}

alias dpsa='docker ps -a'
alias dsp='docker stop'
alias dst='docker start'
alias dex='docker exec -it'
alias di='docker info'
alias ds='docker stats'
alias drm='docker rm $(docker ps -a -q)'
alias dfrm='docker rm -f $(docker ps -a -q)'
