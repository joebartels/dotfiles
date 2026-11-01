#!/usr/bin/env bash
set -euo pipefail

readonly source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly chezmoi_bin="$(command -v chezmoi)"
readonly zsh_bin="$(command -v zsh)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# Copy only the assigned configuration: no external downloads or package scripts.
mkdir -p "$tmp_dir/source/private_dot_config/zsh/modules" "$tmp_dir/home" "$tmp_dir/bin" "$tmp_dir/empty-bin"
cp -R "$source_dir/private_dot_config/nvim" "$tmp_dir/source/private_dot_config/"
cp "$source_dir/private_dot_config/zsh/modules/100-neovim.zsh" "$tmp_dir/source/private_dot_config/zsh/modules/"
cp "$source_dir/dot_zshrc" "$tmp_dir/source/"
: >"$tmp_dir/chezmoi.toml"
HOME="$tmp_dir/home" "$chezmoi_bin" --config "$tmp_dir/chezmoi.toml" \
  --source "$tmp_dir/source" --destination "$tmp_dir/home" \
  --persistent-state "$tmp_dir/state.json" --refresh-externals=never --force --no-tty apply

for file in init.lua lua/config/lazy.lua lua/plugins/init.lua; do
  cmp -s "$source_dir/private_dot_config/nvim/$file" "$tmp_dir/home/.config/nvim/$file" || fail "unmanaged or changed nvim/$file"
done
[[ "$(find "$tmp_dir/home/.config/nvim" -type f | wc -l | tr -d ' ')" == 3 ]] || fail 'unexpected Neovim runtime files'
cmp -s "$source_dir/private_dot_config/zsh/modules/100-neovim.zsh" \
  "$tmp_dir/home/.config/zsh/modules/100-neovim.zsh" || fail 'Neovim module not managed'

cat >"$tmp_dir/bin/nvim" <<'EOF'
#!/bin/sh
printf 'stub-nvim:%s\n' "$*"
EOF
chmod +x "$tmp_dir/bin/nvim"

# Use the real loader with only the applied module and a controlled PATH.
HOME="$tmp_dir/home" XDG_CONFIG_HOME="$tmp_dir/home/.config" PATH="$tmp_dir/bin" \
  "$zsh_bin" -dfi -c '
    source "$HOME/.zshrc"
    [[ ${aliases[vi]} == nvim && ${aliases[vim]} == nvim ]] || exit 1
    [[ $(eval "vi sample") == stub-nvim:sample ]] || exit 1
    [[ $(eval "vim sample") == stub-nvim:sample ]]
  ' || fail 'available Neovim aliases did not resolve and execute'

HOME="$tmp_dir/home" XDG_CONFIG_HOME="$tmp_dir/home/.config" PATH="$tmp_dir/empty-bin" \
  "$zsh_bin" -dfi -c '
    (( ! $+commands[nvim] )) || exit 1
    source "$HOME/.zshrc"
    (( ! $+aliases[vi] && ! $+aliases[vim] )) || exit 1
    alias vi=original_vi vim=original_vim
    source "$HOME/.zshrc"
    [[ ${aliases[vi]} == original_vi && ${aliases[vim]} == original_vim ]]
  ' || fail 'missing Neovim changed existing editor resolution'

printf 'Neovim management and alias tests passed (offline; no Neovim launched).\n'
