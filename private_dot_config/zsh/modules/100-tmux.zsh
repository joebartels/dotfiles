# ==========================================================
#  MANAGED BY CHEZMOI
#  Purpose: Tmux shortcuts that expose their underlying commands
#  Provides: tls, ta, tnew, td, trename, tkill
#  Edit:  chezmoi edit ~/.config/zsh/modules/100-tmux.zsh
#  Apply: chezmoi apply ~/.config/zsh
# ==========================================================

# Print the expanded command first so the underlying tmux commands stay
# familiar and can be used on machines without these helpers.
function _tmux_run() {
  local -a tmux_command=(tmux "$@")
  print -r -- "+ ${(q)tmux_command[@]}"
  command "${tmux_command[@]}"
}

function tmls() {
  _tmux_run list-sessions
}

function tmnew() {
  if (( $# > 1 )); then
    print -u2 -- "Usage: tnew [session-name]"
    return 2
  fi

  if (( $# == 1 )); then
    _tmux_run new-session -s "$1"
  else
    _tmux_run new-session
  fi
}

function tma() {
  if (( $# != 1 )); then
    print -u2 -- "Usage: ta [session-name]"
    return 2
  fi

  _tmux_run new-session -A -s "$1"
}

function tmd() {
  _tmux_run detach-client
}

function tmrename() {
  if (( $# != 1 )); then
    print -u2 -- "Usage: trename <new-session-name>"
    return 2
  fi

  _tmux_run rename-session "$1"
}

function tmkill() {
  if (( $# != 1 )); then
    print -u2 -- "Usage: tkill <session-name>"
    return 2
  fi

  _tmux_run kill-session -t "$1"
}
