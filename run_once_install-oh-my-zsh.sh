#!/usr/bin/env bash
set -euo pipefail

if ! command -v git >/dev/null 2>&1; then
  echo "git is required to install oh-my-zsh" >&2
  exit 1
fi

OH_MY_ZSH_DIR="${HOME}/.oh-my-zsh"
BACKUP_DIR="${OH_MY_ZSH_DIR}.pre-chezmoibak"

if [ -d "${OH_MY_ZSH_DIR}/.git" ]; then
  echo "oh-my-zsh already installed, skipping"
  exit 0
fi

if [ -d "${OH_MY_ZSH_DIR}" ]; then
  if [ -e "${BACKUP_DIR}" ]; then
    echo "Backup ${BACKUP_DIR} already exists; refusing to overwrite" >&2
    exit 1
  fi

  echo "Backing up existing ${OH_MY_ZSH_DIR} to ${BACKUP_DIR}"
  mv "${OH_MY_ZSH_DIR}" "${BACKUP_DIR}"
fi

echo "Cloning oh-my-zsh..."
git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "${OH_MY_ZSH_DIR}"

if [ -d "${BACKUP_DIR}/custom" ]; then
  echo "Restoring custom content from backup"
  rsync -a "${BACKUP_DIR}/custom/" "${OH_MY_ZSH_DIR}/custom/"
fi

echo "oh-my-zsh installed at ${OH_MY_ZSH_DIR}"
