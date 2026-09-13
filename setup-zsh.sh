#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
set -Eeuo pipefail
bundle_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
dry_run=false
case "${1:-}" in --dry-run) dry_run=true;; '') ;; *) exit 2;; esac
(( EUID != 0 )) || { printf 'Run as your normal user, without sudo.\n'; exit 1; }
ask() { local answer; read -r -p "$1 [y/N] " answer || return 1; [[ $answer == y || $answer == Y ]]; }
run() { printf '  '; printf '%q ' "$@"; printf '\n'; if ! "$dry_run"; then "$@"; fi; }
if ask 'Install Zsh, Git, autosuggestions, and syntax highlighting with a full Arch upgrade?'; then
  run sudo pacman -Syu --needed zsh git zsh-autosuggestions zsh-syntax-highlighting
fi
if [[ ! -e "$HOME/.oh-my-zsh" ]]; then
  if ask 'Download Oh My Zsh from its official repository?'; then
    run git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"
  fi
fi
if ask 'Apply the bundled zshrc (back up your existing file first)?'; then
  if ! "$dry_run"; then
    command -v zsh >/dev/null || { printf 'Install Zsh first.\n'; exit 1; }
    zsh -n "$bundle_dir/zsh/zshrc"
  fi
  if [[ -e "$HOME/.zshrc" || -L "$HOME/.zshrc" ]]; then
    run cp -a "$HOME/.zshrc" "$HOME/.zshrc.backup-$(date +%Y%m%d-%H%M%S)-$$"
    run unlink "$HOME/.zshrc"
  fi
  run install -m644 "$bundle_dir/zsh/zshrc" "$HOME/.zshrc"
fi
if ask 'Make /usr/bin/zsh your login shell?'; then
  run chsh -s /usr/bin/zsh
fi
printf 'Open Zsh now with: zsh\nLog out and back in after changing your login shell.\n'
