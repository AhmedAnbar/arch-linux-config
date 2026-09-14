#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Install the standalone Herdr binary without changing agent/editor configuration.
set -Eeuo pipefail
dry_run=false
case "${1:-}" in
    --dry-run) dry_run=true ;;
    --help|-h)
        printf 'Usage: bash setup-herdr.sh [--dry-run]\n'
        printf 'Optional Herdr install into ~/.local/bin; existing installs are left unchanged.\n'
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
existing=$(command -v herdr || :)
if [[ -x "$install_dir/herdr" ]]; then existing="$install_dir/herdr"; fi
if [[ -n "$existing" ]]; then
    printf 'Herdr already installed at %s; leaving it unchanged.\n' "$existing"
    if ! "$dry_run"; then "$existing" --version; fi
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
printf 'Installed. The bundled Zsh configuration already includes ~/.local/bin in PATH.\n'
printf 'Open a new terminal and run herdr when ready; no Herdr server or agents were started here.\n'
