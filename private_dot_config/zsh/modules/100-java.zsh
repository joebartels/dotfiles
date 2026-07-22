# ==========================================================
#  MANAGED BY CHEZMOI
#  Edit:  chezmoi edit ~/.config/zsh/modules/100-java.zsh
#  Apply: chezmoi apply ~/.config/zsh
# ==========================================================

function jh() {
  if [[ "$1" == "-v" && $# == 1 ]]; then
    [[ -n "${JAVA_HOME:-}" ]] || jh >/dev/null || return
    "$JAVA_HOME/bin/java" -version
    return
  fi

  local -a args=("$@")

  if (( $# == 0 )); then
    args=(-v "${JAVA_HOME_DEFAULT_VERSION:-21}")
  fi

  local home
  home=$(/usr/libexec/java_home "${args[@]}") || return

  export JAVA_HOME="$home"
  echo "$JAVA_HOME"
}
