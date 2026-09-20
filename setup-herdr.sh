#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Install Herdr and optionally configure its prefix without changing agents/editors.
set -Eeuo pipefail
bundle_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
dry_run=false
case "${1:-}" in
    --dry-run) dry_run=true ;;
    --help|-h)
        printf 'Usage: bash setup-herdr.sh [--dry-run]\n'
        printf 'Optional Herdr install into ~/.local/bin and Ctrl+A prefix; existing binaries are left unchanged.\n'
        exit 0 ;;
    '') ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
esac
(( EUID != 0 )) || { printf 'Run as your normal user, without sudo.\n' >&2; exit 1; }
ask() {
    local answer
    read -r -p "$1 [y/N] " answer || return 1
    [[ "$answer" == y || "$answer" == Y || "$answer" == yes ]]
}
install_dir="$HOME/.local/bin"
configure_prefix() {
    local config_path=${HERDR_CONFIG_PATH:-${XDG_CONFIG_HOME:-$HOME/.config}/herdr/config.toml}
    if ask 'Set the Herdr prefix to Ctrl+A, preserving other settings and backing up changes?'; then
        if "$dry_run"; then
            printf 'Would validate and update only keys.prefix in %s to ctrl+a.\n' "$config_path"
        else
            bash "$bundle_dir/scripts/configure-herdr-prefix.sh" "$config_path" "$existing"
        fi
    fi
}
status_source="$bundle_dir/config/herdr/workspaces-status.sh"
configure_ui() {
    local config_dir=${XDG_CONFIG_HOME:-$HOME/.config}/herdr
    local config_path=${HERDR_CONFIG_PATH:-$config_dir/config.toml}
    local status_path=$config_dir/workspaces-status.sh
    command -v jq >/dev/null || {
        printf 'The workspace tab row needs jq. Install it first: sudo pacman -Syu --needed jq\n'
        return 0
    }
    if ask 'Hide the Herdr sidebar and list workspaces in the tab row instead?'; then
        if "$dry_run"; then
            printf 'Would install -Dm755 -- %s %s\n' "$status_source" "$status_path"
            printf 'Would set only the [ui] sidebar and tab_bar_right keys in %s.\n' "$config_path"
        else
            install -Dm755 -- "$status_source" "$status_path"
            bash "$bundle_dir/scripts/configure-herdr-ui.sh" "$config_path" "$existing" "$status_path"
        fi
    fi
}
existing=$(command -v herdr || :)
if [[ -x "$install_dir/herdr" ]]; then existing="$install_dir/herdr"; fi
if [[ -n "$existing" ]]; then
    printf 'Herdr already installed at %s; leaving the binary unchanged.\n' "$existing"
    if ! "$dry_run"; then "$existing" --version; fi
    configure_prefix
    configure_ui
    exit 0
fi
if [[ -e "$install_dir/herdr" || -L "$install_dir/herdr" ]]; then
    printf 'An existing non-executable file or broken symlink occupies %s/herdr. Leaving it unchanged.\n' "$install_dir" >&2
    exit 1
fi
printf 'Source: https://herdr.dev/install.sh (upstream code run as your user, not root).\n'
if ! ask 'Download the official Herdr installer for review?'; then exit 0; fi
if "$dry_run"; then
    printf 'Would download https://herdr.dev/install.sh to a private temporary directory.\n'
    printf 'Would syntax-check it, ask before execution, and run it with HERDR_INSTALL_DIR=%s.\n' "$install_dir"
    printf 'No download, installation or background process is performed in preview mode.\n'
    configure_prefix
    configure_ui
    exit 0
fi
for tool in curl awk sha256sum; do
    command -v "$tool" >/dev/null || {
        printf 'Missing prerequisite: %s. On Arch, curl plus the base system tools are required.\n' "$tool" >&2
        printf 'Install curl if needed: sudo pacman -Syu --needed curl\n' >&2
        exit 1
    }
done
download_dir=$(mktemp -d -t arch-herdr-installer.XXXXXXXX)
installer_file="$download_dir/install.sh"
cleanup() {
    # Only clean the exact downloaded file and empty private directory we created.
    if [[ -f "$installer_file" ]]; then unlink -- "$installer_file"; fi
    rmdir -- "$download_dir" || :
}
trap cleanup EXIT
curl --proto '=https' --tlsv1.2 -fsSL --connect-timeout 10 --max-time 120 \
    https://herdr.dev/install.sh -o "$installer_file"
sh -n "$installer_file"
printf 'Review the installer in another terminal: less %q\n' "$installer_file"
if ! ask 'Run the downloaded official installer now?'; then exit 0; fi
HERDR_INSTALL_DIR="$install_dir" sh "$installer_file"
[[ -x "$install_dir/herdr" ]] || { printf 'Herdr installation did not produce the expected executable.\n' >&2; exit 1; }
"$install_dir/herdr" --version
existing="$install_dir/herdr"
configure_prefix
configure_ui
printf 'Installed. The bundled Zsh configuration already includes ~/.local/bin in PATH.\n'
printf 'Open a new terminal and run herdr when ready; no Herdr server or agents were started here.\n'
