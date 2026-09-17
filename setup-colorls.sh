#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 AhmedAnbar
# Optional colorls: icons and colours for ls, as `ls` = `colorls -l` in Bash and Zsh.
set -Eeuo pipefail
trap 'printf "colorls setup stopped at line %s. Review the error above.\n" "$LINENO" >&2' ERR
bundle_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
dry_run=false
for argument in "$@"; do
    case "$argument" in
        --dry-run) dry_run=true ;;
        --help|-h)
            printf 'Usage: bash setup-colorls.sh [--dry-run]\n'
            printf 'Install colorls from the AUR and make ls, ll and la use it in Bash and Zsh.\n'
            exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$argument" >&2; exit 2 ;;
    esac
done
(( EUID != 0 )) || { printf 'Run as your normal user, without sudo. Commands needing root will use sudo.\n' >&2; exit 1; }
target_config="$HOME/.config"
backup_dir="$HOME/.local/state/arch-desktop-setup/colorls-$(date +%Y%m%d-%H%M%S)-$$"
source_line='[[ ! -r "$HOME/.config/shell/colorls.sh" ]] || source "$HOME/.config/shell/colorls.sh"'
ask() {
    local answer
    read -r -p "$1 [y/N] " answer || return 1
    [[ "$answer" == y || "$answer" == Y || "$answer" == yes ]]
}
run() {
    printf '  '; printf '%q ' "$@"; printf '\n'
    if ! "$dry_run"; then "$@"; fi
}
install_file() {
    local source=$1 relative=$2 destination="$target_config/$2"
    if [[ -f "$destination" ]] && cmp -s -- "$source" "$destination"; then
        printf 'Unchanged: %s\n' "$destination"
        return 0
    fi
    if [[ -e "$destination" || -L "$destination" ]]; then
        ask "Back up and replace $destination?" || return 0
        run mkdir -p -- "$backup_dir/$(dirname -- "$relative")"
        run cp -a -- "$destination" "$backup_dir/$relative"
        # Replace symlinks themselves; never overwrite their targets.
        run unlink -- "$destination"
    fi
    run install -Dm644 -- "$source" "$destination"
}
# Append the guarded source line once; the same line works in Bash and Zsh.
wire_rc() {
    local rc=$1
    [[ -f "$rc" ]] || return 0
    grep -qF '.config/shell/colorls.sh' -- "$rc" && return 0
    ask "Load the colorls aliases from $rc?" || return 0
    run mkdir -p -- "$backup_dir"
    run cp -a -- "$rc" "$backup_dir/${rc##*/}"
    if "$dry_run"; then
        printf '  Would append the colorls aliases to %s\n' "$rc"
    else
        printf '\n# colorls aliases (ls = colorls -l), shared by Bash and Zsh.\n%s\n' "$source_line" >> "$rc"
    fi
}

printf 'colorls — ls with colours and file icons. ls = colorls -l, ll = colorls -la, la = colorls -A.\n'
if ask 'Install ruby and the JetBrains Mono Nerd Font icons with a full Arch upgrade?'; then
    run sudo pacman -Syu --needed ruby ttf-jetbrains-mono-nerd
fi
if command -v yay >/dev/null; then
    if ask 'Install ruby-colorls from the AUR with yay (review its PKGBUILD when asked)?'; then
        run yay -S --needed ruby-colorls
    fi
else
    printf 'yay is not installed. Build it from the AUR section of install.sh, then rerun this script.\n'
fi
# colorls 1.5.0 requires unicode-display_width < 3.0, but pacman installs 3.x, so colorls
# exits with Gem::MissingSpecError. A 2.x copy in the user gem path satisfies it alone.
if command -v colorls >/dev/null && ! colorls --version >/dev/null 2>&1; then
    printf 'colorls is installed but fails to start (usually unicode-display_width 3.x from pacman).\n'
    if ask 'Install unicode-display_width 2.x for colorls into your user gems (~/.local/share/gem)?'; then
        run gem install --user-install --no-document unicode-display_width -v '~> 2.6'
    fi
fi
if ask 'Install the shared ls/ll/la aliases into ~/.config/shell/colorls.sh?'; then
    install_file "$bundle_dir/config/shell/colorls.sh" shell/colorls.sh
fi
wire_rc "$HOME/.bashrc"
wire_rc "$HOME/.zshrc"

if "$dry_run"; then
    printf '\nPreview only: no packages or files were changed.\n'
    exit 0
fi
printf '\nOpen a new terminal (or run: source ~/.bashrc) to use colorls.\n'
printf 'Plain GNU ls is still available as: command ls   or   \\ls\n'
