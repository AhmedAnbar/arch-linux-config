#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 AhmedAnbar
set -Eeuo pipefail
trap 'printf "Setup stopped at line %s. Review the error above before retrying.\n" "$LINENO" >&2' ERR
bundle_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
dry_run=false
case "${1:-}" in
    --dry-run) dry_run=true ;;
    --help|-h) printf 'Usage: bash install.sh [--dry-run]\nRun as your normal desktop user on installed Arch Linux.\n'; exit 0 ;;
    '') ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
esac
if (( EUID == 0 )); then printf 'Run as your normal user, without sudo. Commands needing root will use sudo.\n' >&2; exit 1; fi
[[ -f /etc/arch-release ]] || { printf 'This installer requires Arch Linux.\n' >&2; exit 1; }
[[ -d "$bundle_dir/config" ]] || { printf 'Keep install.sh with its config folder.\n' >&2; exit 1; }
target_config="$HOME/.config"
backup_dir="$HOME/.local/state/arch-desktop-setup/$(date +%Y%m%d-%H%M%S)-$$"
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
    if [[ -f "$destination" ]] && cmp -s "$source" "$destination"; then
        printf 'Unchanged: %s\n' "$destination"; return
    fi
    if [[ -e "$destination" || -L "$destination" ]]; then
        ask "Back up and replace $destination?" || return 0
        run mkdir -p -- "$backup_dir/$(dirname -- "$relative")"
        if [[ ! -e "$backup_dir/$relative" && ! -L "$backup_dir/$relative" ]]; then
            run cp -a -- "$destination" "$backup_dir/$relative"
        fi
        # Replace a symlink itself rather than writing through it.
        run unlink -- "$destination"
    fi
    run install -Dm644 -- "$source" "$destination"
}
packages=()
group() {
    local label=$1; shift
    printf '\n%s\n  %s\n' "$label" "$*"
    if ask 'Include these packages?'; then packages+=("$@"); fi
}
printf 'Arch desktop setup — packages, configuration and services\n'
printf 'Copyright (C) 2026 AhmedAnbar. GPL-3.0-only; no warranty. See LICENSE for redistribution terms.\n'
printf 'Existing configuration files are backed up before replacement.\n'
group 'Core i3 desktop and all configuration dependencies' i3-wm i3status i3lock xorg-server xorg-setxkbmap xorg-xinit xorg-xinput xorg-xrandr xf86-input-libinput kitty rofi picom flameshot noto-fonts dex xss-lock networkmanager network-manager-applet bluez bluez-utils blueman libpulse psmisc gsettings-desktop-schemas
group 'PipeWire audio (pacman may ask to replace conflicting PulseAudio packages)' pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber alsa-utils
group 'Laptop brightness keys and emoji picker' brightnessctl rofi-emoji noto-fonts-emoji xclip
group 'Browser and file utilities' firefox thunar thunar-archive-plugin file-roller gvfs gpicview xdg-user-dirs xdg-utils
group 'Development and command-line utilities (including PHP/Composer and uv)' base-devel git github-cli vim neovim dialog php composer curl openssh uv
group 'Docker Engine, Compose and lazydocker' docker docker-compose lazydocker
group 'LightDM login screen' lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
group 'Printing' cups
group 'Filesystem utilities and backup applications (no disk or bootloader configuration)' btrfs-progs dosfstools mtools ntfs-3g timeshift grub-btrfs
group 'Optional older desktop tools from your install notes' xmonad xmonad-contrib xmonad-utils xmobar dmenu nitrogen scrot trayer alacritty xarchiver bpytop
group 'Optional apps from the old notes, if available in enabled repositories' discord obsidian
if ask 'Choose individual additional packages from the captured installed-package list?'; then
    while IFS= read -r package <&3; do
        [[ -n "$package" ]] || continue
        if ask "Include $package?"; then packages+=("$package"); fi
    done 3< "$bundle_dir/installed-explicit.txt"
fi
if ((${#packages[@]})); then
    mapfile -t packages < <(printf '%s\n' "${packages[@]}" | sort -u)
    printf '\nSelected packages: %s\n' "${packages[*]}"
    if ask 'Perform a full Arch upgrade and install the selected repository packages?'; then
        # Never refresh databases without completing a full upgrade.
        run sudo pacman -Syu
        available=()
        for package in "${packages[@]}"; do
            if pacman -Si "$package" >/dev/null 2>&1; then available+=("$package");
            else printf 'Unavailable in repository databases: %s (may need AUR or be retired).\n' "$package"; fi
        done
        if ((${#available[@]})); then run sudo pacman -S --needed "${available[@]}"; fi
    fi
fi
if ask 'Select optional AUR packages, including Google Chrome (review third-party PKGBUILDs)?'; then
    if ! command -v yay >/dev/null && ask 'Build yay-bin from the AUR after reviewing its PKGBUILD?'; then
        run sudo pacman -Syu --needed base-devel git less
        if "$dry_run"; then
            printf 'Would clone https://aur.archlinux.org/yay-bin.git into a new temporary directory, display PKGBUILD, and ask before building.\n'
        else
            build_dir=$(mktemp -d -t arch-yay-build.XXXXXXXX)
            git clone https://aur.archlinux.org/yay-bin.git "$build_dir/yay-bin"
            less "$build_dir/yay-bin/PKGBUILD"
            if ask 'Build and install the reviewed yay-bin package?'; then
                (cd "$build_dir/yay-bin" && makepkg -si)
            fi
            printf 'Build files retained in %s\n' "$build_dir"
        fi
    fi
    if command -v yay >/dev/null; then
        aur=()
        # Keep Chrome explicit: it is installed using yay, not the pacman package group.
        if ask 'Install Google Chrome (google-chrome) using yay?'; then
            aur+=(google-chrome)
        fi
        for package in dropbox postman tor-browser timeshift-autosnap zramd teams; do
            if ask "Install $package using yay?"; then aur+=("$package"); fi
        done
        if ((${#aur[@]})); then run yay -S --needed "${aur[@]}"; fi
    else
        printf 'yay is not installed. Install/review an AUR helper first, then rerun this section.\n'
        printf 'Your previous helper was yay-bin. No AUR code is downloaded automatically.\n'
    fi
fi
if ask 'Install the desktop configuration bundle (each existing changed file asks before replacement)?'; then
    while IFS= read -r -d '' source <&3; do
        relative=${source#"$bundle_dir/config/"}
        install_file "$source" "$relative"
    done 3< <(find "$bundle_dir/config" -path "$bundle_dir/config/nvim" -prune -o -type f -print0 | sort -z)
    if ! "$dry_run" && command -v i3 >/dev/null; then i3 -C -c "$target_config/i3/config"; fi
fi
if ask 'Choose the Rofi theme for the installed launcher?'; then
    printf '1) Catppuccin  2) Nord  3) Dracula\n'
    read -r -p 'Theme [1]: ' choice
    case "$choice" in
        2) theme=i3-theme-nord.rasi ;;
        3) theme=i3-theme-dracula.rasi ;;
        *) theme=i3-theme.rasi ;;
    esac
    # The launcher uses a separate pointer so switching never edits i3 bindings.
    if ! "$dry_run"; then
        theme_temp=$(mktemp)
        printf '@theme "%s"\n' "$theme" > "$theme_temp"
        install_file "$theme_temp" rofi/active-theme.rasi
        unlink "$theme_temp"
    else printf 'Would select %s\n' "$theme"; fi
fi
if ask 'Set the dark appearance preference in your current desktop session?'; then
    if command -v gsettings >/dev/null; then
        run gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    else printf 'Install gsettings-desktop-schemas and rerun to set the desktop preference.\n'; fi
fi
for service in NetworkManager.service bluetooth.service cups.service fstrim.timer docker.service; do
    if ask "Enable and start $service?"; then run sudo systemctl enable --now "$service"; fi
done
printf '\nDocker group membership grants root-level access to this machine.\n'
if ask 'Allow this user to run Docker and lazydocker without sudo by joining the docker group?'; then
    docker_user=$(id -un)
    if [[ " $(id -nG "$docker_user") " == *" docker "* ]]; then
        printf '%s is already a member of the docker group.\n' "$docker_user"
    elif ! "$dry_run" && ! getent group docker >/dev/null; then
        printf 'The docker group does not exist. Install Docker first, then rerun this step.\n' >&2
    else
        run sudo usermod -aG docker "$docker_user"
        printf 'Log out of the desktop completely and log back in to activate Docker access.\n'
    fi
fi
if ask 'Enable LightDM for future boots (does not start it or replace an existing display manager)?'; then
    if [[ -L /etc/systemd/system/display-manager.service ]] && [[ $(readlink /etc/systemd/system/display-manager.service) != *lightdm.service ]]; then
        printf 'Another display manager is enabled; leaving it unchanged.\n'
    else run sudo systemctl enable lightdm.service; fi
fi
if ask 'Start/enable PipeWire sockets and WirePlumber for this user?'; then
    run systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service
fi
if ask 'Apply the touchpad script in the current X11 session?'; then
    run sh "$target_config/i3/touchpad.sh"
fi
if ask 'Set up Zsh, Oh My Zsh, autosuggestions and syntax highlighting?'; then
    if "$dry_run"; then
        bash "$bundle_dir/setup-zsh.sh" --dry-run
    else
        bash "$bundle_dir/setup-zsh.sh"
    fi
fi
if ask 'Configure a private SSH host alias (server details stay on this machine)?'; then
    if "$dry_run"; then bash "$bundle_dir/setup-ssh.sh" --dry-run
    else bash "$bundle_dir/setup-ssh.sh"; fi
fi
if ask 'Use an SSH key automatically for one Git host, including its HTTPS clone URLs?'; then
    if "$dry_run"; then bash "$bundle_dir/setup-ssh.sh" --git --dry-run
    else bash "$bundle_dir/setup-ssh.sh" --git; fi
fi
if ask 'Restore Neovim, its plugins and PHP/Laravel language tools?'; then
    if "$dry_run"; then bash "$bundle_dir/setup-nvim.sh" --dry-run
    else bash "$bundle_dir/setup-nvim.sh"; fi
fi
if ask 'Set up Herdr and optionally its Ctrl+A prefix (keeps an existing binary)?'; then
    if "$dry_run"; then bash "$bundle_dir/setup-herdr.sh" --dry-run
    else bash "$bundle_dir/setup-herdr.sh"; fi
fi
if ask 'Add the Conky system panel with switchable Catppuccin, Nord and Dracula themes?'; then
    if "$dry_run"; then bash "$bundle_dir/setup-conky.sh" --dry-run
    else bash "$bundle_dir/setup-conky.sh"; fi
fi
if [[ $(cat /sys/class/dmi/id/product_name 2>/dev/null || true) == *UM5606* ]]; then
    printf '\nOn this ASUS Zenbook S 16 (UM5606) the firmware pins the CPU to ~605 MHz when\n'
    printf 'amd_pmf, amdxdna and asus_armoury load at boot, which makes the desktop lag.\n'
    if ask 'Review the CPU power-cap fix for this laptop?'; then
        if "$dry_run"; then bash "$bundle_dir/setup-zenbook-cpu-cap.sh" --dry-run
        else bash "$bundle_dir/setup-zenbook-cpu-cap.sh"; fi
    fi
fi
if ask 'Add the optional Sway Wayland desktop alongside i3?'; then
    if "$dry_run"; then bash "$bundle_dir/setup-sway.sh" --dry-run
    else bash "$bundle_dir/setup-sway.sh"; fi
fi
printf '\nFinished. Backups, when needed: %s\n' "$backup_dir"
printf 'Log out and log in to apply startup programs. Alt+D: Rofi; Alt+Shift+S: screenshot.\n'
printf 'Keyboard: English (US) + Arabic. Shift+Caps Lock switches layouts after login/restart.\n'
printf 'Firefox Catppuccin theme installation and Bluetooth pairing remain interactive in those apps.\n'
