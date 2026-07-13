#!/usr/bin/env bash

set -euo pipefail

readonly test_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly source_dir="$(cd -- "$test_dir/.." && pwd)"
readonly template="$source_dir/run_before_00-install-homebrew.sh.tmpl"
readonly zshrc="$source_dir/dot_zshrc"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

require_command() {
  local command_name=$1

  command -v "$command_name" >/dev/null 2>&1 || fail "required command not found: $command_name"
}

require_command chezmoi
require_command zsh
readonly chezmoi_bin="$(command -v chezmoi)"
readonly zsh_bin="$(command -v zsh)"

assert_contains() {
  local file=$1
  local expected=$2

  grep -F -- "$expected" "$file" >/dev/null || fail "expected $file to contain: $expected"
}

assert_not_contains() {
  local file=$1
  local unexpected=$2

  if grep -F -- "$unexpected" "$file" >/dev/null; then
    fail "expected $file not to contain: $unexpected"
  fi
}

assert_before() {
  local file=$1
  local first=$2
  local second=$3
  local first_line
  local second_line

  first_line="$(grep -nF -- "$first" "$file" | head -n 1 | cut -d: -f1)"
  second_line="$(grep -nF -- "$second" "$file" | head -n 1 | cut -d: -f1)"
  [[ -n "$first_line" ]] || fail "missing expected line: $first"
  [[ -n "$second_line" ]] || fail "missing expected line: $second"
  (( first_line < second_line )) || fail "expected $first to precede $second"
}

render_template() {
  local os=$1
  local output=$2

  "$chezmoi_bin" execute-template \
    --override-data "{\"chezmoi\":{\"os\":\"$os\"}}" \
    --file "$template" >"$output"
}

[[ -f "$template" ]] || fail "missing Homebrew bootstrap template"

darwin_script="$tmp_dir/homebrew-darwin.sh"
linux_script="$tmp_dir/homebrew-linux.sh"
unsupported_script="$tmp_dir/homebrew-windows.sh"

render_template darwin "$darwin_script"
render_template linux "$linux_script"
render_template windows "$unsupported_script"

[[ -s "$darwin_script" ]] || fail "darwin template rendered no script"
[[ -s "$linux_script" ]] || fail "linux template rendered no script"
[[ -z "$(tr -d '[:space:]' <"$unsupported_script")" ]] || fail "unsupported OS rendered a script"

"${BASH:-/bin/bash}" -n "$darwin_script"
"${BASH:-/bin/bash}" -n "$linux_script"

for script in "$darwin_script" "$linux_script"; do
  assert_contains "$script" '#!/bin/bash'
  assert_contains "$script" 'set -euo pipefail'
  assert_contains "$script" 'command -v brew'
  assert_contains "$script" '/opt/homebrew/bin/brew'
  assert_contains "$script" '/usr/local/bin/brew'
  assert_contains "$script" '/home/linuxbrew/.linuxbrew/bin/brew'
  assert_contains "$script" '$HOME/.linuxbrew/bin/brew'
  assert_contains "$script" '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  assert_not_contains "$script" 'NONINTERACTIVE=1'
done

bootstrap_bin="$tmp_dir/bootstrap-bin"
bootstrap_home="$tmp_dir/bootstrap-home"
bootstrap_no_brew_bin="$tmp_dir/bootstrap-no-brew-bin"
bootstrap_no_brew_home="$tmp_dir/bootstrap-no-brew-home"
mkdir -p "$bootstrap_bin" "$bootstrap_home" "$bootstrap_no_brew_bin" "$bootstrap_no_brew_home"

cat >"$bootstrap_bin/brew" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$bootstrap_bin/brew"

cat >"$bootstrap_bin/curl" <<'EOF'
#!/bin/sh
: > "$HOMEBREW_BOOTSTRAP_INSTALLER_CALLED"
printf '%s\n' 'exit 97'
EOF
chmod +x "$bootstrap_bin/curl"

HOMEBREW_BOOTSTRAP_INSTALLER_CALLED="$tmp_dir/installer-called" \
  HOME="$bootstrap_home" \
  PATH="$bootstrap_bin" \
  "${BASH:-/bin/bash}" "$darwin_script"
[[ ! -e "$tmp_dir/installer-called" ]] || fail "installer ran even though brew was on PATH"

cat >"$bootstrap_no_brew_bin/curl" <<'EOF'
#!/bin/sh
: > "$HOMEBREW_BOOTSTRAP_INSTALLER_CALLED"
printf '%s\n' 'exit 0'
EOF
chmod +x "$bootstrap_no_brew_bin/curl"

installer_marker="$tmp_dir/installer-branch-called"
isolated_installer_script="$tmp_dir/homebrew-installer-isolated.sh"
# Redirect host-only candidates in the test copy so local Homebrew cannot short-circuit this branch.
sed \
  -e "s|/opt/homebrew/bin/brew|$tmp_dir/no-homebrew/opt/homebrew/bin/brew|g" \
  -e "s|/usr/local/bin/brew|$tmp_dir/no-homebrew/usr/local/bin/brew|g" \
  -e "s|/home/linuxbrew/.linuxbrew/bin/brew|$tmp_dir/no-homebrew/home/linuxbrew/.linuxbrew/bin/brew|g" \
  "$darwin_script" >"$isolated_installer_script"
HOMEBREW_BOOTSTRAP_INSTALLER_CALLED="$installer_marker" \
  HOME="$bootstrap_no_brew_home" \
  PATH="$bootstrap_no_brew_bin" \
  "${BASH:-/bin/bash}" "$isolated_installer_script"
[[ -e "$installer_marker" ]] || fail "installer did not run when no brew was available"

assert_contains "$zshrc" '[[ -o interactive ]] || return'
assert_contains "$zshrc" '/opt/homebrew/bin'
assert_contains "$zshrc" '/usr/local/bin'
assert_contains "$zshrc" '/home/linuxbrew/.linuxbrew/bin'
assert_contains "$zshrc" '"$HOME/.linuxbrew/bin"'
assert_contains "$zshrc" 'eval "$(brew shellenv)"'
assert_before "$zshrc" '[[ -o interactive ]] || return' '/opt/homebrew/bin'
assert_before "$zshrc" 'eval "$(brew shellenv)"' 'source "$ZSH/oh-my-zsh.sh"'

zsh_home="$tmp_dir/zsh-home"
zsh_bin_dir="$tmp_dir/zsh-bin"
mkdir -p "$zsh_home/.oh-my-zsh" "$zsh_bin_dir"

cat >"$zsh_bin_dir/brew" <<'EOF'
#!/bin/sh
if [ "${1:-}" = shellenv ]; then
  printf '%s\n' 'export HOMEBREW_SHELLENV_EVALUATED=1'
fi
EOF
chmod +x "$zsh_bin_dir/brew"

cat >"$zsh_home/.oh-my-zsh/oh-my-zsh.sh" <<'EOF'
print -r -- "${HOMEBREW_SHELLENV_EVALUATED:-}" > "$HOME/omz-shellenv-state"
EOF

HOME="$zsh_home" \
  PATH="$zsh_bin_dir" \
  ZSHRC_UNDER_TEST="$zshrc" \
  "$zsh_bin" -dfi -c 'source "$ZSHRC_UNDER_TEST" 2>/dev/null; [[ "${HOMEBREW_SHELLENV_EVALUATED:-}" == 1 ]]'
[[ "$(<"$zsh_home/omz-shellenv-state")" == 1 ]] || fail "Homebrew shellenv did not run before Oh My Zsh"

fallback_zsh_home="$tmp_dir/fallback-zsh-home"
fallback_zsh_bin_dir="$tmp_dir/fallback-zsh-bin"
fallback_zshrc="$tmp_dir/fallback-dot-zshrc"
mkdir -p "$fallback_zsh_home/.linuxbrew/bin" "$fallback_zsh_home/.oh-my-zsh" "$fallback_zsh_bin_dir"

cat >"$fallback_zsh_home/.linuxbrew/bin/brew" <<'EOF'
#!/bin/sh
if [ "${1:-}" = shellenv ]; then
  printf '%s\n' 'export HOMEBREW_SHELLENV_EVALUATED=home-prefix'
fi
EOF
chmod +x "$fallback_zsh_home/.linuxbrew/bin/brew"

cat >"$fallback_zsh_home/.oh-my-zsh/oh-my-zsh.sh" <<'EOF'
print -r -- "${HOMEBREW_SHELLENV_EVALUATED:-}" > "$HOME/fallback-omz-shellenv-state"
EOF

sed \
  -e "s|/opt/homebrew/bin|$tmp_dir/no-homebrew/opt/homebrew/bin|g" \
  -e "s|/usr/local/bin|$tmp_dir/no-homebrew/usr/local/bin|g" \
  -e "s|/home/linuxbrew/.linuxbrew/bin|$tmp_dir/no-homebrew/home/linuxbrew/.linuxbrew/bin|g" \
  "$zshrc" >"$fallback_zshrc"
if ! HOME="$fallback_zsh_home" \
  PATH="$fallback_zsh_bin_dir" \
  ZSHRC_UNDER_TEST="$fallback_zshrc" \
  "$zsh_bin" -dfi -c '[[ -z "$(command -v brew)" ]] || exit 1; source "$ZSHRC_UNDER_TEST" 2>/dev/null; [[ "$(command -v brew)" == "$HOME/.linuxbrew/bin/brew" ]] && [[ "${HOMEBREW_SHELLENV_EVALUATED:-}" == home-prefix ]]'; then
  fail "Homebrew fallback did not make the user-prefix brew resolvable"
fi
[[ "$(<"$fallback_zsh_home/fallback-omz-shellenv-state")" == home-prefix ]] || fail "Homebrew fallback did not initialize before Oh My Zsh"

rm -f "$zsh_home/omz-shellenv-state"
HOME="$zsh_home" \
  PATH="$zsh_bin_dir" \
  ZSHRC_UNDER_TEST="$zshrc" \
  HOMEBREW_SHELLENV_EVALUATED= \
  "$zsh_bin" -df -c 'source "$ZSHRC_UNDER_TEST"; [[ -z "${HOMEBREW_SHELLENV_EVALUATED:-}" ]]'
[[ ! -e "$zsh_home/omz-shellenv-state" ]] || fail "noninteractive shell initialized Oh My Zsh"

printf 'Homebrew bootstrap tests passed.\n'
