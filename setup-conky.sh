#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 AhmedAnbar
# Optional Conky system panel with Catppuccin, Nord and Dracula themes for Sway and i3.
set -Eeuo pipefail
trap 'printf "Conky setup stopped at line %s. Review the error above.\n" "$LINENO" >&2' ERR
bundle_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
dry_run=false
for argument in "$@"; do
    case "$argument" in
        --dry-run) dry_run=true ;;
        --help|-h)
            printf 'Usage: bash setup-conky.sh [--dry-run]\n'
            printf 'Install Conky, its themed system panel, and the Alt+Shift+T theme picker for Sway and i3.\n'
            exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$argument" >&2; exit 2 ;;
    esac
done
(( EUID != 0 )) || { printf 'Run as your normal desktop user, without sudo.\n' >&2; exit 1; }
[[ -f /etc/arch-release ]] || { printf 'This installer requires Arch Linux.\n' >&2; exit 1; }
target_config="$HOME/.config"
backup_dir="$HOME/.local/state/arch-desktop-setup/conky-$(date +%Y%m%d-%H%M%S)-$$"
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
        if [[ ! -e "$backup_dir/$relative" && ! -L "$backup_dir/$relative" ]]; then
            run cp -a -- "$destination" "$backup_dir/$relative"
        fi
        # Replace symlinks themselves; never overwrite their targets.
        run unlink -- "$destination"
    fi
    run install -Dm644 -- "$source" "$destination"
}

printf 'Conky system panel — clock, CPU, memory, disk, network and battery, top-right.\n'
printf 'Themes: Catppuccin (default), Nord, Dracula. Alt+Shift+T switches theme or turns it off.\n'
# The panel font is the Nerd Font already offered by the Neovim setup.
if ask 'Install conky and ttf-jetbrains-mono-nerd with a full Arch upgrade?'; then
    run sudo pacman -Syu --needed conky ttf-jetbrains-mono-nerd
fi
if ask 'Install the Conky panel, themes and theme switcher into ~/.config/conky?'; then
    while IFS= read -r -d '' source <&3; do
        install_file "$source" "conky/${source#"$bundle_dir/config/conky/"}"
    done 3< <(find "$bundle_dir/config/conky" -type f -print0 | sort -z)
fi
if ask 'Start the panel at Sway login and bind Alt+Shift+T (adds a config.d drop-in)?'; then
    install_file "$bundle_dir/sway/config/sway/config.d/30-conky.conf" sway/config.d/30-conky.conf
fi

i3_config="$target_config/i3/config"
if [[ -f "$i3_config" ]] && ! grep -qF 'conky/start.sh' "$i3_config"; then
    # i3 has no config.d include here, so append a clearly marked block once.
    if ask "Append the Conky autostart and Alt+Shift+T binding to $i3_config?"; then
        run mkdir -p -- "$backup_dir/i3"
        run cp -a -- "$i3_config" "$backup_dir/i3/config"
        if "$dry_run"; then
            printf '  Would append the Conky autostart and Alt+Shift+T binding to %s\n' "$i3_config"
        else
            {
                printf '\n# Conky system panel (no-op until conky is installed); Alt+Shift+T picks a theme or Off.\n'
                printf 'exec --no-startup-id sh ~/.config/conky/start.sh\n'
                printf 'bindsym $mod+Shift+t exec --no-startup-id sh ~/.config/conky/switch.sh\n'
            } >> "$i3_config"
        fi
    fi
fi

if "$dry_run"; then
    printf '\nPreview only: no packages, files or running sessions were changed.\n'
    exit 0
fi
if command -v conky >/dev/null && [[ -n "${WAYLAND_DISPLAY:-}${DISPLAY:-}" && -f "$target_config/conky/start.sh" ]]; then
    if ask 'Start the panel in this session now?'; then
        run sh "$target_config/conky/start.sh"
    fi
fi
printf '\nBackups, when needed: %s\n' "$backup_dir"
printf 'Alt+Shift+T: pick a Conky theme or Off. From a terminal: sh ~/.config/conky/switch.sh nord\n'
printf 'Reload Sway (Alt+Shift+C) or i3 to activate the new binding; the panel autostarts at next login.\n'
printf 'Panel errors, if any: %s/arch-desktop-conky.log\n' "${XDG_RUNTIME_DIR:-/tmp}"
