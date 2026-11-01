#!/usr/bin/env bash
set -euo pipefail

source_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
module="$source_dir/private_dot_config/zsh/modules/600-initialize-java-home.zsh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

# Replace only the resolver path in a test copy, so both branches can be
# exercised on macOS and Linux without depending on the host's Java install.
printf '#!/bin/sh\nexit 0\n' >"$tmp_dir/java_home"
chmod +x "$tmp_dir/java_home"
sed "s|/usr/libexec/java_home|$tmp_dir/java_home|g" "$module" >"$tmp_dir/module.zsh"

MODULE_UNDER_TEST="$tmp_dir/module.zsh" zsh -df -c '
  jh() { called=yes; }
  for platform in linux-gnu darwin23; do
    OSTYPE=$platform
    called=no
    export JAVA_HOME=/existing/jdk
    source "$MODULE_UNDER_TEST"
    [[ "$JAVA_HOME" == /existing/jdk ]] || exit 1
    if [[ "$platform" == darwin* ]]; then
      [[ "$called" == yes ]] || exit 1
    else
      [[ "$called" == no ]] || exit 1
    fi
  done
'

rm "$tmp_dir/java_home"
MODULE_UNDER_TEST="$tmp_dir/module.zsh" zsh -df -c '
  OSTYPE=darwin23
  jh() { return 99; }
  source "$MODULE_UNDER_TEST"
'

printf 'Zsh Java initialization tests passed.\n'
