#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Optional Wayland desktop. Never replaces/removes i3 or switches the live session.
set -Eeuo pipefail
trap 'printf "Sway setup stopped at line %s. Review the error above.\n" "$LINENO" >&2' ERR
bundle_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
dry_run=false
config_only=false
for argument in "$@"; do
    case "$argument" in
        --dry-run) dry_run=true ;;
        --config-only) config_only=true ;;
        --help|-h)
            printf 'Usage: bash setup-sway.sh [--dry-run] [--config-only]\n'
            printf 'Interactive Sway setup on installed Arch Linux; keeps i3 available.\n'
            exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$argument" >&2; exit 2 ;;
    esac
done
(( EUID != 0 )) || { printf 'Run as your normal desktop user, without sudo.\n' >&2; exit 1; }
[[ -f /etc/arch-release ]] || { printf 'This installer requires Arch Linux.\n' >&2; exit 1; }
target_config="$HOME/.config"
backup_dir="$HOME/.local/state/arch-desktop-setup/sway-$(date +%Y%m%d-%H%M%S)-$$"
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

printf 'Optional Sway/Wayland setup — i3 remains installed and unchanged.\n'
mapfile -t packages < "$bundle_dir/sway/packages.txt"
if ! "$config_only"; then
    printf 'Packages: %s\n' "${packages[*]}"
    printf 'PipeWire may conflict with an existing PulseAudio server; review pacman prompts.\n'
    if ask 'Install these packages with a full Arch upgrade?'; then
        run sudo pacman -Syu --needed "${packages[@]}"
    fi
    if ask 'Enable and start NetworkManager and Bluetooth services?'; then
        run sudo systemctl enable --now NetworkManager.service bluetooth.service
    fi
    if ask 'Enable PipeWire sockets and WirePlumber for this user?'; then
        run systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service
    fi
fi
if ask 'Apply Catppuccin Sway, Waybar, notifications, screen lock and portal configuration?'; then
    while IFS= read -r -d '' source <&3; do
        relative=${source#"$bundle_dir/sway/config/"}
        install_file "$source" "$relative"
    done 3< <(find "$bundle_dir/sway/config" -type f -print0 | sort -z)

    # Reuse the tested platform-independent helpers without needing i3 installed.
    install_file "$bundle_dir/config/i3/brightness.sh" sway/brightness.sh
    install_file "$bundle_dir/config/i3/emoji.sh" sway/emoji.sh
    for theme in i3-theme.rasi i3-theme-nord.rasi i3-theme-dracula.rasi emoji.rasi; do
        install_file "$bundle_dir/config/rofi/$theme" "rofi/$theme"
    done
    # Keep an existing Rofi palette selection; new setups start with Catppuccin.
    if [[ ! -e "$target_config/rofi/active-theme.rasi" && ! -L "$target_config/rofi/active-theme.rasi" ]]; then
        install_file "$bundle_dir/config/rofi/active-theme.rasi" rofi/active-theme.rasi
    fi
fi
printf 'The following profile is specific to the ASUS Zenbook UM5606, not other computers.\n'
if ask 'Use the Zenbook 1920x1200 screen profile and map its touchscreen to eDP-1?'; then
    install_file "$bundle_dir/sway/profiles/zenbook-um5606.conf" sway/config.d/20-zenbook.conf
fi

ready=true
if ! "$dry_run"; then
    missing=()
    for package in "${packages[@]}"; do
        pacman -Q "$package" >/dev/null 2>&1 || missing+=("$package")
    done
    if ((${#missing[@]})); then
        ready=false
        printf 'Packages still missing: %s\n' "${missing[*]}" >&2
        printf 'Install them before logging into Sway.\n' >&2
    fi
    if command -v sway >/dev/null && [[ -f "$target_config/sway/config" ]]; then
        # Parse configuration without taking over the display or running autostarts.
        run env -u DISPLAY -u WAYLAND_DISPLAY WLR_BACKENDS=headless WLR_RENDERER=pixman \
            sway --validate --config "$target_config/sway/config"
    else
        ready=false
        printf 'Sway configuration validation deferred until Sway and its config are installed.\n'
    fi
else
    printf 'Would check package availability and validate the installed Sway configuration.\n'
fi

printf '\nBackups, when needed: %s\n' "$backup_dir"
if ! "$ready"; then
    printf 'Setup is incomplete. Install missing packages/apply configuration and rerun setup-sway.sh.\n' >&2
    printf 'Keep using i3 until Sway configuration validation succeeds.\n' >&2
    exit 3
fi
printf 'Save your work, log out, choose Sway in the login screen session menu, then log in.\n'
printf 'Do not restart LightDM from inside your desktop. Choose i3 again to return to X11.\n'
printf 'If your greeter does not list Sway, log into a text console and run: dbus-run-session sway\n'
printf 'Alt+D: apps; Alt+B: native Firefox; Print: screenshot; Super+period: emoji.\n'
printf 'Shift+Caps Lock: English/Arabic; Alt+Ctrl+L: lock; Alt+Shift+E: logout confirmation.\n'
printf 'Auto-lock: 5 minutes idle and before sleep; screens power down at 10 minutes.\n'
printf 'Stock Sway uses square window corners. No existing i3/Flameshot/Picom settings were removed.\n'
