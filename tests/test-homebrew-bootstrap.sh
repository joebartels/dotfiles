#!/usr/bin/env bash

set -euo pipefail

readonly test_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly source_dir="$(cd -- "$test_dir/.." && pwd)"
readonly template="$source_dir/run_once_before_00-install-homebrew.sh.tmpl"
readonly bundle_template="$source_dir/run_onchange_before_10-install-brew-bundles.sh.tmpl"
readonly legacy_bundle_template="$source_dir/run_onchange_before_install-packages.sh.tmpl"
readonly chezmoiignore="$source_dir/.chezmoiignore"
readonly zshrc="$source_dir/dot_zshrc"
readonly readme="$source_dir/README.md"

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

assert_line() {
  local file=$1
  local expected=$2

  grep -Fx -- "$expected" "$file" >/dev/null || fail "expected $file to contain line: $expected"
}

assert_first_line() {
  local file=$1
  local expected=$2
  local actual

  IFS= read -r actual <"$file" || true
  [[ "$actual" == "$expected" ]] || fail "expected first line of $file to be: $expected"
}

assert_manifest_declarations() {
  local file=$1
  shift
  local actual="$tmp_dir/$(basename "$file").actual"
  local expected="$tmp_dir/$(basename "$file").expected"

  grep -Ev '^[[:space:]]*(#|$)' "$file" >"$actual" || true
  : >"$expected"
  if (( $# > 0 )); then
    printf '%s\n' "$@" >"$expected"
  fi
  cmp -s "$expected" "$actual" || fail "unexpected manifest declarations in $file"
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

assert_readme_documents_bootstrap() {
  [[ -f "$readme" ]] || fail "missing README.md"

  assert_contains "$readme" '## Setup'
  assert_contains "$readme" '## Homebrew Packages'
  assert_contains "$readme" 'sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin"'
  assert_contains "$readme" '`chezmoi init https://github.com/'
  assert_contains "$readme" '`chezmoi apply`'
  assert_contains "$readme" '`PATH`'
  assert_contains "$readme" '/opt/homebrew/bin/brew'
  assert_contains "$readme" '/usr/local/bin/brew'
  assert_contains "$readme" '/home/linuxbrew/.linuxbrew/bin/brew'
  assert_contains "$readme" '$HOME/.linuxbrew/bin/brew'
  assert_contains "$readme" 'official interactive installer'
  assert_contains "$readme" 'machine-local'
  assert_contains "$readme" 'Before the first apply'
  assert_contains "$readme" '~/.config/chezmoi/chezmoi.toml'
  assert_contains "$readme" '[data]'
  assert_contains "$readme" 'env = "personal"'
  assert_contains "$readme" 'env = "work"'
  assert_before "$readme" '~/.config/chezmoi/chezmoi.toml' 'Apply: `chezmoi apply`'
  assert_before "$readme" '[data]' 'Apply: `chezmoi apply`'
  assert_before "$readme" 'env = "personal"' 'Apply: `chezmoi apply`'
  assert_before "$readme" 'env = "work"' 'Apply: `chezmoi apply`'
  for brewfile in Brewfile.base Brewfile.darwin Brewfile.linux Brewfile.personal Brewfile.work; do
    assert_contains "$readme" "\`$brewfile\`"
  done
  assert_contains "$readme" 'source-only declarations'
  assert_contains "$readme" 'initial applicable `chezmoi apply`'
  assert_contains "$readme" '`brew bundle install --no-upgrade`'
  assert_contains "$readme" 'rendered input'
  assert_contains "$readme" 'selected Brewfiles'
  assert_contains "$readme" 'The profile must be `personal` or `work`.'
}

assert_readme_documents_bootstrap

render_template() {
  local os=$1
  local output=$2

  "$chezmoi_bin" execute-template \
    --override-data "{\"chezmoi\":{\"os\":\"$os\"}}" \
    --file "$template" >"$output"
}

render_bundle_template() {
  local source=$1
  local os=$2
  local profile=$3
  local output=$4

  "$chezmoi_bin" execute-template \
    --source "$source" \
    --override-data "{\"chezmoi\":{\"os\":\"$os\"},\"env\":\"$profile\"}" \
    --file "$source/run_onchange_before_10-install-brew-bundles.sh.tmpl" >"$output"
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
assert_first_line "$darwin_script" '#!/bin/bash'
assert_first_line "$linux_script" '#!/bin/bash'

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
  assert_contains "$script" 'installer="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  assert_contains "$script" 'Failed to download Homebrew installer.'
  assert_contains "$script" '/bin/bash -c "$installer"'
  assert_not_contains "$script" '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
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

cat >"$bootstrap_no_brew_bin/curl" <<'EOF'
#!/bin/sh
exit 22
EOF
chmod +x "$bootstrap_no_brew_bin/curl"

curl_failure_output="$tmp_dir/curl-download-failure-output"
expected_curl_failure_output="$tmp_dir/expected-curl-download-failure-output"
printf '%s\n' 'Failed to download Homebrew installer.' >"$expected_curl_failure_output"
if HOME="$bootstrap_no_brew_home" \
  PATH="$bootstrap_no_brew_bin" \
  "${BASH:-/bin/bash}" "$isolated_installer_script" >"$curl_failure_output" 2>&1; then
  fail "bootstrap script succeeded after the Homebrew installer download failed"
fi
cmp -s "$expected_curl_failure_output" "$curl_failure_output" || \
  fail "expected an exact Homebrew installer download failure diagnostic"

cat >"$bootstrap_no_brew_bin/curl" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$bootstrap_no_brew_bin/curl"

empty_curl_failure_output="$tmp_dir/empty-curl-download-failure-output"
if HOME="$bootstrap_no_brew_home" \
  PATH="$bootstrap_no_brew_bin" \
  "${BASH:-/bin/bash}" "$isolated_installer_script" >"$empty_curl_failure_output" 2>&1; then
  fail "bootstrap script succeeded after the Homebrew installer download returned an empty response"
fi
cmp -s "$expected_curl_failure_output" "$empty_curl_failure_output" || \
  fail "expected an exact Homebrew installer empty-download failure diagnostic"

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

[[ -f "$bundle_template" ]] || fail "missing Homebrew bundle runner template"
[[ -x "$bundle_template" ]] || fail "Homebrew bundle runner template is not executable"
[[ ! -e "$legacy_bundle_template" ]] || fail "legacy Homebrew bundle runner template still exists"

for brewfile in Brewfile.base Brewfile.darwin Brewfile.linux Brewfile.personal Brewfile.work; do
  [[ -f "$source_dir/$brewfile" ]] || fail "missing source-only Brewfile: $brewfile"
done
[[ ! -e "$source_dir/Brewfile" ]] || fail "legacy Brewfile still exists"

assert_manifest_declarations "$source_dir/Brewfile.base" \
  'tap "bufbuild/buf"' \
  'brew "chezmoi"' \
  'brew "gemini-cli"' \
  'brew "gh"' \
  'brew "ghostscript"' \
  'brew "gnupg"' \
  'brew "imagemagick"' \
  'brew "fnm"' \
  'brew "rtk"' \
  'brew "sqlc"' \
  'brew "tmux"' \
  'brew "go"' \
  'go "golang.org/x/tools/cmd/goimports"' \
  'go "connectrpc.com/connect/cmd/protoc-gen-connect-go"' \
  'go "google.golang.org/protobuf/cmd/protoc-gen-go"'
assert_manifest_declarations "$source_dir/Brewfile.darwin" \
  'cask "claude-code@latest"' \
  'cask "codex"' \
  'cask "maccy"'
assert_manifest_declarations "$source_dir/Brewfile.personal" 'brew "arduino-cli"'
assert_manifest_declarations "$source_dir/Brewfile.linux"
assert_manifest_declarations "$source_dir/Brewfile.work" \
  'tap "snowflakedb/snowflake-cli", trusted: { casks: ["snowflake-cli"] }' \
  'cask "snowflake-cli"'
assert_line "$source_dir/Brewfile.linux" '# Linux-specific Homebrew packages are declared here.'
assert_line "$source_dir/Brewfile.work" '# Work-only Homebrew packages are declared here.'

bundle_source="$tmp_dir/bundle-source"
mkdir -p "$bundle_source"
cp "$bundle_template" "$bundle_source/"
cp "$chezmoiignore" "$bundle_source/"
for brewfile in Brewfile.base Brewfile.darwin Brewfile.linux Brewfile.personal Brewfile.work; do
  cp "$source_dir/$brewfile" "$bundle_source/$brewfile"
done

ignored_brewfiles="$tmp_dir/ignored-brewfiles"
"$chezmoi_bin" --source "$bundle_source" --destination "$tmp_dir/ignored-home" ignored >"$ignored_brewfiles"
for brewfile in Brewfile.base Brewfile.darwin Brewfile.linux Brewfile.personal Brewfile.work; do
  assert_line "$ignored_brewfiles" "$brewfile"
done

bundle_darwin_script="$tmp_dir/bundle-darwin-personal.sh"
bundle_linux_script="$tmp_dir/bundle-linux-work.sh"
bundle_unsupported_os_script="$tmp_dir/bundle-windows-personal.sh"
bundle_unsupported_profile_script="$tmp_dir/bundle-darwin-unsupported-profile.sh"
readonly invalid_profile='invalid-profile-value'

render_bundle_template "$bundle_source" darwin personal "$bundle_darwin_script"
render_bundle_template "$bundle_source" linux work "$bundle_linux_script"
render_bundle_template "$bundle_source" windows personal "$bundle_unsupported_os_script"
render_bundle_template "$bundle_source" darwin "$invalid_profile" "$bundle_unsupported_profile_script"

[[ -s "$bundle_darwin_script" ]] || fail "darwin/personal bundle runner rendered no script"
[[ -s "$bundle_linux_script" ]] || fail "linux/work bundle runner rendered no script"
[[ -z "$(tr -d '[:space:]' <"$bundle_unsupported_os_script")" ]] || fail "unsupported OS rendered a bundle runner"

"${BASH:-/bin/bash}" -n "$bundle_darwin_script"
"${BASH:-/bin/bash}" -n "$bundle_linux_script"
"${BASH:-/bin/bash}" -n "$bundle_unsupported_profile_script"

for script in "$bundle_darwin_script" "$bundle_linux_script"; do
  assert_first_line "$script" '#!/bin/bash'
  assert_contains "$script" '#!/bin/bash'
  assert_contains "$script" 'set -euo pipefail'
  assert_contains "$script" 'command -v brew'
  assert_contains "$script" '/opt/homebrew/bin/brew'
  assert_contains "$script" '/usr/local/bin/brew'
  assert_contains "$script" '/home/linuxbrew/.linuxbrew/bin/brew'
  assert_contains "$script" '$HOME/.linuxbrew/bin/brew'
  assert_contains "$script" 'eval "$(brew shellenv)"'
  assert_contains "$script" 'Brewfile checksum: Brewfile.base'
done

assert_contains "$bundle_darwin_script" 'Brewfile checksum: Brewfile.darwin'
assert_contains "$bundle_darwin_script" 'Brewfile checksum: Brewfile.personal'
assert_not_contains "$bundle_darwin_script" 'Brewfile checksum: Brewfile.linux'
assert_not_contains "$bundle_darwin_script" 'Brewfile checksum: Brewfile.work'
assert_contains "$bundle_linux_script" 'Brewfile checksum: Brewfile.linux'
assert_contains "$bundle_linux_script" 'Brewfile checksum: Brewfile.work'
assert_not_contains "$bundle_linux_script" 'Brewfile checksum: Brewfile.darwin'
assert_not_contains "$bundle_linux_script" 'Brewfile checksum: Brewfile.personal'

bundle_darwin_after_change_script="$tmp_dir/bundle-darwin-personal-after-change.sh"
printf '%s\n' '# checksum test change' >>"$bundle_source/Brewfile.personal"
render_bundle_template "$bundle_source" darwin personal "$bundle_darwin_after_change_script"
if cmp -s "$bundle_darwin_script" "$bundle_darwin_after_change_script"; then
  fail "changing a selected Brewfile did not change the rendered bundle runner"
fi

bundle_bin="$tmp_dir/bundle-bin"
bundle_home="$tmp_dir/bundle-home"
mkdir -p "$bundle_bin" "$bundle_home"
cat >"$bundle_bin/brew" <<'EOF'
#!/bin/bash
set -euo pipefail
case "${1:-}" in
  shellenv)
    if [[ -n "${HOMEBREW_SHELLENV_LOG:-}" ]]; then
      printf '%s\n' "$0" >>"${HOMEBREW_SHELLENV_LOG:?}"
    fi
    if [[ -n "${HOMEBREW_CHEZMOI_SOURCE_LOG:-}" ]]; then
      printf '%s\0' "${CHEZMOI_SOURCE_DIR:?CHEZMOI_SOURCE_DIR was not supplied by chezmoi}" >>"${HOMEBREW_CHEZMOI_SOURCE_LOG:?}"
    fi
    printf '%s\n' 'export HOMEBREW_BUNDLE_SHELLENV=1'
    ;;
  bundle)
    [[ "${HOMEBREW_BUNDLE_SHELLENV:-}" == 1 ]] || exit 98
    printf '%s\0' "$@" >>"${HOMEBREW_BUNDLE_LOG:?}"
    printf '\0' >>"${HOMEBREW_BUNDLE_LOG:?}"
    ;;
  *)
    exit 99
    ;;
esac
EOF
chmod +x "$bundle_bin/brew"
cat >"$bundle_bin/touch" <<'EOF'
#!/bin/sh
: > "${1:?}"
EOF
chmod +x "$bundle_bin/touch"
assert_bundle_calls() {
  local calls=$1
  local first_file=$2
  local second_file=$3
  local third_file=$4
  local argument
  local index
  local -a actual=()
  local -a expected=(
    bundle install --no-upgrade "--file=$first_file" ''
    bundle install --no-upgrade "--file=$second_file" ''
    bundle install --no-upgrade "--file=$third_file" ''
  )

  while IFS= read -r -d '' argument; do
    actual+=("$argument")
  done <"$calls"

  (( ${#actual[@]} == ${#expected[@]} )) || fail "unexpected brew argument count in $calls"
  for index in "${!expected[@]}"; do
    [[ "${actual[$index]}" == "${expected[$index]}" ]] || fail "unexpected brew argument $index in $calls"
  done
}

bundle_call_count() {
  local calls=$1
  local argument
  local argument_count=0

  while IFS= read -r -d '' argument; do
    ((argument_count += 1))
  done <"$calls"

  (( argument_count % 5 == 0 )) || fail "NUL bundle logger in $calls contains an incomplete call"
  printf '%s\n' "$((argument_count / 5))"
}

assert_bundle_call_count() {
  local calls=$1
  local expected_count=$2
  local actual_count

  actual_count="$(bundle_call_count "$calls")"
  [[ "$actual_count" == "$expected_count" ]] || fail "expected $expected_count bundle calls in $calls, got $actual_count"
}

assert_bundle_call_group() {
  local calls=$1
  local start_call=$2
  local first_file=$3
  local second_file=$4
  local third_file=$5
  local argument
  local index
  local start_argument=$((start_call * 5))
  local -a actual=()
  local -a expected=(
    bundle install --no-upgrade "--file=$first_file" ''
    bundle install --no-upgrade "--file=$second_file" ''
    bundle install --no-upgrade "--file=$third_file" ''
  )

  while IFS= read -r -d '' argument; do
    actual+=("$argument")
  done <"$calls"

  (( ${#actual[@]} >= start_argument + ${#expected[@]} )) || fail "missing bundle call group starting at call $start_call in $calls"
  for index in "${!expected[@]}"; do
    [[ "${actual[$((start_argument + index))]}" == "${expected[$index]}" ]] || fail "unexpected brew argument $((start_argument + index)) in $calls"
  done
}

assert_nul_values() {
  local file=$1
  shift
  local value
  local index
  local -a actual=()
  local -a expected=("$@")

  while IFS= read -r -d '' value; do
    actual+=("$value")
  done <"$file"

  (( ${#actual[@]} == ${#expected[@]} )) || fail "unexpected NUL value count in $file"
  for index in "${!expected[@]}"; do
    [[ "${actual[$index]}" == "${expected[$index]}" ]] || fail "unexpected NUL value $index in $file"
  done
}

darwin_calls="$tmp_dir/darwin-bundle-calls"
linux_calls="$tmp_dir/linux-bundle-calls"
: >"$darwin_calls"
: >"$linux_calls"
HOME="$bundle_home" \
  PATH="$bundle_bin" \
  HOMEBREW_BUNDLE_LOG="$darwin_calls" \
  CHEZMOI_SOURCE_DIR="$bundle_source" \
  "${BASH:-/bin/bash}" "$bundle_darwin_script"
assert_bundle_calls \
  "$darwin_calls" \
  "$bundle_source/Brewfile.base" \
  "$bundle_source/Brewfile.darwin" \
  "$bundle_source/Brewfile.personal"
HOME="$bundle_home" \
  PATH="$bundle_bin" \
  HOMEBREW_BUNDLE_LOG="$linux_calls" \
  CHEZMOI_SOURCE_DIR="$bundle_source" \
  "${BASH:-/bin/bash}" "$bundle_linux_script"
assert_bundle_calls \
  "$linux_calls" \
  "$bundle_source/Brewfile.base" \
  "$bundle_source/Brewfile.linux" \
  "$bundle_source/Brewfile.work"
path_payload_marker="$tmp_dir/source-path-payload-ran"
path_payload_source="$tmp_dir/bundle source \$(touch $path_payload_marker)"
path_payload_script="$tmp_dir/bundle-darwin-path-payload.sh"
path_payload_calls="$tmp_dir/path-payload-bundle-calls"
mkdir -p "$path_payload_source"
cp "$bundle_template" "$path_payload_source/"
for brewfile in Brewfile.base Brewfile.darwin Brewfile.linux Brewfile.personal Brewfile.work; do
  cp "$source_dir/$brewfile" "$path_payload_source/$brewfile"
done
render_bundle_template "$path_payload_source" darwin personal "$path_payload_script"
"${BASH:-/bin/bash}" -n "$path_payload_script"
: >"$path_payload_calls"
HOME="$bundle_home" \
  PATH="$bundle_bin" \
  HOMEBREW_BUNDLE_LOG="$path_payload_calls" \
  CHEZMOI_SOURCE_DIR="$path_payload_source" \
  "${BASH:-/bin/bash}" "$path_payload_script"
[[ ! -e "$path_payload_marker" ]] || fail "source path command substitution was evaluated"
assert_bundle_calls \
  "$path_payload_calls" \
  "$path_payload_source/Brewfile.base" \
  "$path_payload_source/Brewfile.darwin" \
  "$path_payload_source/Brewfile.personal"

missing_source_output="$tmp_dir/missing-source-output"
if (
  unset CHEZMOI_SOURCE_DIR
  HOME="$bundle_home" \
    PATH="$bundle_bin" \
    HOMEBREW_BUNDLE_LOG="$tmp_dir/missing-source-calls" \
    "${BASH:-/bin/bash}" "$bundle_darwin_script" >"$tmp_dir/missing-source-stdout" 2>"$missing_source_output"
); then
  fail "bundle runner succeeded without CHEZMOI_SOURCE_DIR"
fi
assert_contains "$missing_source_output" 'CHEZMOI_SOURCE_DIR is required'

unsupported_profile_output="$tmp_dir/unsupported-profile-output"
if HOME="$bundle_home" \
  PATH="$bundle_bin" \
  HOMEBREW_BUNDLE_LOG="$tmp_dir/unsupported-profile-calls" \
  CHEZMOI_SOURCE_DIR="$bundle_source" \
  "${BASH:-/bin/bash}" "$bundle_unsupported_profile_script" >"$tmp_dir/unsupported-profile-stdout" 2>"$unsupported_profile_output"; then
  fail "unsupported profile bundle runner succeeded"
fi
assert_line "$unsupported_profile_output" 'unsupported chezmoi profile (expected personal or work)'
assert_not_contains "$bundle_unsupported_profile_script" "$invalid_profile"
assert_not_contains "$unsupported_profile_output" "$invalid_profile"

fresh_fallback_source="$tmp_dir/fresh-fallback-source"
fresh_fallback_home="$tmp_dir/fresh-fallback-home"
fresh_fallback_path="$tmp_dir/fresh-fallback-path"
fresh_fallback_script="$tmp_dir/fresh-fallback-darwin.sh"
fresh_fallback_isolated_script="$tmp_dir/fresh-fallback-darwin-isolated.sh"
fresh_fallback_mutant_script="$tmp_dir/fresh-fallback-darwin-mutant.sh"
fresh_fallback_calls="$tmp_dir/fresh-fallback-calls"
fresh_fallback_shellenv="$tmp_dir/fresh-fallback-shellenv"
fresh_fallback_mutant_calls="$tmp_dir/fresh-fallback-mutant-calls"
fresh_fallback_mutant_output="$tmp_dir/fresh-fallback-mutant-output"
mkdir -p "$fresh_fallback_source" "$fresh_fallback_home/.linuxbrew/bin" "$fresh_fallback_path"
cp "$bundle_template" "$fresh_fallback_source/"
for brewfile in Brewfile.base Brewfile.darwin Brewfile.linux Brewfile.personal Brewfile.work; do
  cp "$source_dir/$brewfile" "$fresh_fallback_source/$brewfile"
done
render_bundle_template "$fresh_fallback_source" darwin personal "$fresh_fallback_script"
# Keep the test hermetic even when a developer machine has Homebrew in a fixed prefix.
sed \
  -e "s|/opt/homebrew/bin/brew|$tmp_dir/no-homebrew/opt/homebrew/bin/brew|g" \
  -e "s|/usr/local/bin/brew|$tmp_dir/no-homebrew/usr/local/bin/brew|g" \
  -e "s|/home/linuxbrew/.linuxbrew/bin/brew|$tmp_dir/no-homebrew/home/linuxbrew/.linuxbrew/bin/brew|g" \
  "$fresh_fallback_script" >"$fresh_fallback_isolated_script"
"${BASH:-/bin/bash}" -n "$fresh_fallback_isolated_script"
cp "$bundle_bin/brew" "$fresh_fallback_home/.linuxbrew/bin/brew"
chmod +x "$fresh_fallback_home/.linuxbrew/bin/brew"

if PATH="$fresh_fallback_path" command -v brew >/dev/null 2>&1; then
  fail "fresh-process fallback fixture unexpectedly has brew on PATH"
fi

: >"$fresh_fallback_calls"
: >"$fresh_fallback_shellenv"
HOME="$fresh_fallback_home" \
  PATH="$fresh_fallback_path" \
  HOMEBREW_BUNDLE_LOG="$fresh_fallback_calls" \
  HOMEBREW_SHELLENV_LOG="$fresh_fallback_shellenv" \
  CHEZMOI_SOURCE_DIR="$fresh_fallback_source" \
  "${BASH:-/bin/bash}" "$fresh_fallback_isolated_script"
assert_line "$fresh_fallback_shellenv" "$fresh_fallback_home/.linuxbrew/bin/brew"
assert_bundle_calls \
  "$fresh_fallback_calls" \
  "$fresh_fallback_source/Brewfile.base" \
  "$fresh_fallback_source/Brewfile.darwin" \
  "$fresh_fallback_source/Brewfile.personal"

# Delete the user-prefix entry while retaining valid shell syntax; the fixture must then fail to find brew.
sed -e 's|"\$HOME/\.linuxbrew/bin/brew"; do|; do|' \
  "$fresh_fallback_isolated_script" >"$fresh_fallback_mutant_script"
"${BASH:-/bin/bash}" -n "$fresh_fallback_mutant_script"
: >"$fresh_fallback_mutant_calls"
if HOME="$fresh_fallback_home" \
  PATH="$fresh_fallback_path" \
  HOMEBREW_BUNDLE_LOG="$fresh_fallback_mutant_calls" \
  HOMEBREW_SHELLENV_LOG="$tmp_dir/fresh-fallback-mutant-shellenv" \
  CHEZMOI_SOURCE_DIR="$fresh_fallback_source" \
  "${BASH:-/bin/bash}" "$fresh_fallback_mutant_script" >"$fresh_fallback_mutant_output" 2>&1; then
  fail "fresh-process fallback mutant unexpectedly found brew without the user-prefix fallback"
fi
assert_contains "$fresh_fallback_mutant_output" 'Homebrew was not found on PATH or in a supported default prefix.'
[[ ! -s "$fresh_fallback_mutant_calls" ]] || fail "fresh-process fallback mutant issued bundle calls"

apply_run_onchange_bundle_runner() {
  local source=$1
  local destination=$2
  local persistent_state=$3
  local brew_bin=$4
  local brew_home=$5
  local calls=$6
  local shellenv_log=$7
  local chezmoi_source_log=$8

  (
    unset CHEZMOI_SOURCE_DIR
    HOME="$brew_home" \
      PATH="$brew_bin" \
      HOMEBREW_BUNDLE_LOG="$calls" \
      HOMEBREW_SHELLENV_LOG="$shellenv_log" \
      HOMEBREW_CHEZMOI_SOURCE_LOG="$chezmoi_source_log" \
      "$chezmoi_bin" \
        --source "$source" \
        --destination "$destination" \
        --persistent-state "$persistent_state" \
        --override-data '{"chezmoi":{"os":"darwin"},"env":"personal"}' \
        --refresh-externals=never \
        --force \
        --no-tty \
        apply --source-path "$source/run_onchange_before_10-install-brew-bundles.sh.tmpl"
  )
}

state_source="$tmp_dir/run-onchange-state-source"
state_destination="$tmp_dir/run-onchange-state-destination"
state_persistent_state="$tmp_dir/run-onchange-state.json"
state_brew_bin="$tmp_dir/run-onchange-state-bin"
state_brew_home="$tmp_dir/run-onchange-state-home"
state_calls="$tmp_dir/run-onchange-state-calls"
state_shellenv="$tmp_dir/run-onchange-state-shellenv"
state_chezmoi_source="$tmp_dir/run-onchange-state-chezmoi-source"
state_runner="$state_source/run_onchange_before_10-install-brew-bundles.sh.tmpl"
mkdir -p "$state_source" "$state_destination" "$state_brew_bin" "$state_brew_home"
for brewfile in Brewfile.base Brewfile.darwin Brewfile.linux Brewfile.personal Brewfile.work; do
  cp "$source_dir/$brewfile" "$state_source/$brewfile"
done
# Fixed candidates are intentionally unreachable: the only brew visible to the runner is this fake.
sed \
  -e "s|/opt/homebrew/bin/brew|$state_source/no-homebrew/opt/homebrew/bin/brew|g" \
  -e "s|/usr/local/bin/brew|$state_source/no-homebrew/usr/local/bin/brew|g" \
  -e "s|/home/linuxbrew/.linuxbrew/bin/brew|$state_source/no-homebrew/home/linuxbrew/.linuxbrew/bin/brew|g" \
  "$bundle_template" >"$state_runner"
chmod +x "$state_runner"
cp "$bundle_bin/brew" "$state_brew_bin/brew"
chmod +x "$state_brew_bin/brew"
: >"$state_calls"
: >"$state_shellenv"
: >"$state_chezmoi_source"
[[ "$(PATH="$state_brew_bin" command -v brew)" == "$state_brew_bin/brew" ]] || fail "run_onchange state fixture did not isolate brew on PATH"

apply_run_onchange_bundle_runner \
  "$state_source" \
  "$state_destination" \
  "$state_persistent_state" \
  "$state_brew_bin" \
  "$state_brew_home" \
  "$state_calls" \
  "$state_shellenv" \
  "$state_chezmoi_source"
[[ -s "$state_persistent_state" ]] || fail "run_onchange apply did not create the requested persistent-state file"
[[ ! -e "$state_destination/Brewfile.base" ]] || fail "run_onchange source-path apply selected Brewfile.base"
assert_bundle_call_count "$state_calls" 3
assert_bundle_call_group \
  "$state_calls" 0 \
  "$state_source/Brewfile.base" \
  "$state_source/Brewfile.darwin" \
  "$state_source/Brewfile.personal"
assert_line "$state_shellenv" "$state_brew_bin/brew"
assert_nul_values "$state_chezmoi_source" "$state_source"

apply_run_onchange_bundle_runner \
  "$state_source" \
  "$state_destination" \
  "$state_persistent_state" \
  "$state_brew_bin" \
  "$state_brew_home" \
  "$state_calls" \
  "$state_shellenv" \
  "$state_chezmoi_source"
assert_bundle_call_count "$state_calls" 3
assert_nul_values "$state_chezmoi_source" "$state_source"

printf '%s\n' '# run_onchange state test change' >>"$state_source/Brewfile.personal"
apply_run_onchange_bundle_runner \
  "$state_source" \
  "$state_destination" \
  "$state_persistent_state" \
  "$state_brew_bin" \
  "$state_brew_home" \
  "$state_calls" \
  "$state_shellenv" \
  "$state_chezmoi_source"
assert_bundle_call_count "$state_calls" 6
assert_bundle_call_group \
  "$state_calls" 3 \
  "$state_source/Brewfile.base" \
  "$state_source/Brewfile.darwin" \
  "$state_source/Brewfile.personal"
assert_nul_values "$state_chezmoi_source" "$state_source" "$state_source"

state_mutant_source="$tmp_dir/run-onchange-state-mutant-source"
state_mutant_destination="$tmp_dir/run-onchange-state-mutant-destination"
state_mutant_persistent_state="$tmp_dir/run-onchange-state-mutant.json"
state_mutant_brew_bin="$tmp_dir/run-onchange-state-mutant-bin"
state_mutant_brew_home="$tmp_dir/run-onchange-state-mutant-home"
state_mutant_calls="$tmp_dir/run-onchange-state-mutant-calls"
state_mutant_shellenv="$tmp_dir/run-onchange-state-mutant-shellenv"
state_mutant_chezmoi_source="$tmp_dir/run-onchange-state-mutant-chezmoi-source"
state_mutant_runner="$state_mutant_source/run_onchange_before_10-install-brew-bundles.sh.tmpl"
state_mutant_red_stdout="$tmp_dir/run-onchange-state-mutant-red-stdout"
state_mutant_red_stderr="$tmp_dir/run-onchange-state-mutant-red-stderr"
mkdir -p "$state_mutant_source" "$state_mutant_destination" "$state_mutant_brew_bin" "$state_mutant_brew_home"
for brewfile in Brewfile.base Brewfile.darwin Brewfile.linux Brewfile.personal Brewfile.work; do
  cp "$source_dir/$brewfile" "$state_mutant_source/$brewfile"
done
# This temporary mutant omits the selected profile checksum, so changing that Brewfile cannot trigger run_onchange.
sed \
  -e '/Brewfile checksum: Brewfile\.personal/d' \
  -e "s|/opt/homebrew/bin/brew|$state_mutant_source/no-homebrew/opt/homebrew/bin/brew|g" \
  -e "s|/usr/local/bin/brew|$state_mutant_source/no-homebrew/usr/local/bin/brew|g" \
  -e "s|/home/linuxbrew/.linuxbrew/bin/brew|$state_mutant_source/no-homebrew/home/linuxbrew/.linuxbrew/bin/brew|g" \
  "$bundle_template" >"$state_mutant_runner"
chmod +x "$state_mutant_runner"
cp "$bundle_bin/brew" "$state_mutant_brew_bin/brew"
chmod +x "$state_mutant_brew_bin/brew"
: >"$state_mutant_calls"
: >"$state_mutant_shellenv"
: >"$state_mutant_chezmoi_source"

apply_run_onchange_bundle_runner \
  "$state_mutant_source" \
  "$state_mutant_destination" \
  "$state_mutant_persistent_state" \
  "$state_mutant_brew_bin" \
  "$state_mutant_brew_home" \
  "$state_mutant_calls" \
  "$state_mutant_shellenv" \
  "$state_mutant_chezmoi_source"
assert_bundle_call_count "$state_mutant_calls" 3
apply_run_onchange_bundle_runner \
  "$state_mutant_source" \
  "$state_mutant_destination" \
  "$state_mutant_persistent_state" \
  "$state_mutant_brew_bin" \
  "$state_mutant_brew_home" \
  "$state_mutant_calls" \
  "$state_mutant_shellenv" \
  "$state_mutant_chezmoi_source"
assert_bundle_call_count "$state_mutant_calls" 3
printf '%s\n' '# run_onchange state mutant change' >>"$state_mutant_source/Brewfile.personal"
apply_run_onchange_bundle_runner \
  "$state_mutant_source" \
  "$state_mutant_destination" \
  "$state_mutant_persistent_state" \
  "$state_mutant_brew_bin" \
  "$state_mutant_brew_home" \
  "$state_mutant_calls" \
  "$state_mutant_shellenv" \
  "$state_mutant_chezmoi_source"
if (assert_bundle_call_count "$state_mutant_calls" 6) >"$state_mutant_red_stdout" 2>"$state_mutant_red_stderr"; then
  fail "run_onchange checksum mutant unexpectedly reran after the selected Brewfile changed"
fi
assert_contains "$state_mutant_red_stderr" 'expected 6 bundle calls'
assert_bundle_call_count "$state_mutant_calls" 3

printf 'Homebrew bootstrap tests passed.\n'
