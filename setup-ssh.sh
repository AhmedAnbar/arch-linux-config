#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Generate private local SSH settings. No credentials or server addresses are bundled.
set -Eeuo pipefail
umask 077
dry_run=false
case "${1:-}" in
    --dry-run) dry_run=true ;;
    --help|-h) printf 'Usage: bash setup-ssh.sh [--dry-run]\nConfigure a private SSH alias without connecting or copying keys.\n'; exit 0 ;;
    '') ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
esac
(( EUID != 0 )) || { printf 'Run as your normal user, without sudo.\n' >&2; exit 1; }
command -v ssh >/dev/null || { printf 'Install OpenSSH first: sudo pacman -Syu --needed openssh\n' >&2; exit 1; }
read -r -p 'Short alias [vps]: ' ssh_alias || exit 0
ssh_alias=${ssh_alias:-vps}
read -r -p 'Server IP or hostname: ' ssh_host || exit 0
read -r -p 'SSH username: ' ssh_user || exit 0
read -r -p 'SSH port [22]: ' ssh_port || exit 0
ssh_port=${ssh_port:-22}
read -r -p 'Existing private key path (absolute or ~/...): ' key_file || exit 0
[[ "$ssh_alias" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]] || { printf 'Use letters, digits, underscores or hyphens for the alias.\n' >&2; exit 1; }
[[ "$ssh_host" =~ ^[a-zA-Z0-9][a-zA-Z0-9.:-]*$ ]] || { printf 'Invalid hostname/IP.\n' >&2; exit 1; }
[[ "$ssh_user" =~ ^[a-zA-Z_][a-zA-Z0-9_.-]*$ ]] || { printf 'Invalid SSH username.\n' >&2; exit 1; }
[[ "$ssh_port" =~ ^[0-9]{1,5}$ ]] && (( 10#$ssh_port >= 1 && 10#$ssh_port <= 65535 )) || { printf 'Port must be between 1 and 65535.\n' >&2; exit 1; }
ssh_port=$((10#$ssh_port))
case "$key_file" in '~/'*) key_file="$HOME/${key_file#\~/}" ;; esac
[[ "$key_file" == /* ]] || { printf 'Use an absolute key path or ~/...\n' >&2; exit 1; }
# Keep IdentityFile literal; do not accept SSH token/environment expansion in paths.
case "$key_file" in *\"*|*\\*|*%*|*'$'*|*$'\n'*|*$'\r'*) printf 'Unsupported special character in key path.\n' >&2; exit 1 ;; esac
if ! "$dry_run"; then
    [[ -f "$key_file" && -r "$key_file" && ! -L "$key_file" ]] || { printf 'Use an existing, readable regular key file (not a symlink).\n' >&2; exit 1; }
fi
printf '\nWill configure ssh %s for %s@%s on port %s.\n' "$ssh_alias" "$ssh_user" "$ssh_host" "$ssh_port"
printf 'Key file: %s (contents will not be copied or printed).\n' "$key_file"
printf 'The alias also becomes a shell command and may override a command of the same name.\n'
read -r -p 'Save locally, back up changed files, and restrict key permissions to 600? [y/N] ' answer || exit 0
[[ "$answer" == y || "$answer" == Y || "$answer" == yes ]] || exit 0
if "$dry_run"; then
    printf 'Would save ~/.ssh/config.d/%s.conf, add an SSH Include, and load ~/.ssh/aliases.sh in Bash/Zsh.\n' "$ssh_alias"
    printf 'Preview only: no files, permissions or connections changed.\n'
    exit 0
fi
ssh_dir="$HOME/.ssh"
backup_dir="$HOME/.local/state/arch-desktop-setup/ssh-$(date +%Y%m%d-%H%M%S)-$$"
# Refuse symlinks for managed paths rather than unexpectedly modifying their targets.
for directory in "$ssh_dir" "$ssh_dir/config.d"; do
    [[ ! -L "$directory" && ( ! -e "$directory" || -d "$directory" ) ]] || { printf 'Unsafe directory: %s\n' "$directory" >&2; exit 1; }
done
for file in "$ssh_dir/config" "$ssh_dir/config.d/$ssh_alias.conf" "$ssh_dir/aliases.sh" "$HOME/.bashrc" "$HOME/.zshrc"; do
    [[ ! -L "$file" && ( ! -e "$file" || -f "$file" ) ]] || { printf 'Refusing symlink/non-regular file: %s\n' "$file" >&2; exit 1; }
done
mkdir -p -- "$ssh_dir/config.d"
chmod 700 -- "$ssh_dir" "$ssh_dir/config.d"
stage_dir=$(mktemp -d -t arch-ssh-config.XXXXXXXX)
cleanup() {
    for name in host config aliases bashrc zshrc; do
        if [[ -f "$stage_dir/$name" ]]; then unlink -- "$stage_dir/$name"; fi
    done
    rmdir -- "$stage_dir" || :
}
trap cleanup EXIT
replace_file() {
    local staged=$1 target=$2
    if [[ -f "$target" ]] && cmp -s -- "$staged" "$target"; then return 0; fi
    if [[ -f "$target" ]]; then
        local relative=${target#"$HOME/"}
        mkdir -p -- "$backup_dir/$(dirname -- "$relative")"
        cp -a -- "$target" "$backup_dir/$relative"
    fi
    install -m600 -- "$staged" "$target"
}
printf 'Host %s\n    HostName %s\n    User %s\n    Port %s\n    IdentityFile "%s"\n    IdentitiesOnly yes\n    ForwardAgent no\n    StrictHostKeyChecking ask\n    ServerAliveInterval 30\n    ServerAliveCountMax 3\n' \
    "$ssh_alias" "$ssh_host" "$ssh_user" "$ssh_port" "$key_file" > "$stage_dir/host"
# -F prevents system config/Match commands from affecting this syntax-only check.
ssh -G -F "$stage_dir/host" "$ssh_alias" >/dev/null
replace_file "$stage_dir/host" "$ssh_dir/config.d/$ssh_alias.conf"
if ! grep -Fxq 'Include config.d/*.conf' "$ssh_dir/config" 2>/dev/null; then
    {
        printf 'Include config.d/*.conf\n\nHost *\n'
        if [[ -f "$ssh_dir/config" ]]; then cat -- "$ssh_dir/config"; fi
    } > "$stage_dir/config"
    replace_file "$stage_dir/config" "$ssh_dir/config"
fi
alias_line="alias $ssh_alias='ssh $ssh_alias'"
if ! grep -Fxq "$alias_line" "$ssh_dir/aliases.sh" 2>/dev/null; then
    {
        if [[ -f "$ssh_dir/aliases.sh" ]]; then cat -- "$ssh_dir/aliases.sh"; fi
        printf '\n%s\n' "$alias_line"
    } > "$stage_dir/aliases"
    bash -n "$stage_dir/aliases"
    replace_file "$stage_dir/aliases" "$ssh_dir/aliases.sh"
fi
hook='[[ ! -r "$HOME/.ssh/aliases.sh" ]] || source "$HOME/.ssh/aliases.sh"'
for shell_rc in bashrc zshrc; do
    target_rc="$HOME/.$shell_rc"
    if ! grep -Fxq "$hook" "$target_rc" 2>/dev/null; then
        {
            if [[ -f "$target_rc" ]]; then cat -- "$target_rc"; fi
            printf '\n# Private SSH aliases.\n%s\n' "$hook"
        } > "$stage_dir/$shell_rc"
        replace_file "$stage_dir/$shell_rc" "$target_rc"
    fi
done
chmod 600 -- "$key_file" "$ssh_dir/config" "$ssh_dir/config.d/$ssh_alias.conf" "$ssh_dir/aliases.sh"
printf 'Ready: ssh %s. For the one-word command, open a new terminal or run: source ~/.ssh/aliases.sh\n' "$ssh_alias"
printf 'Backups, if needed: %s\n' "$backup_dir"
printf 'No connection was made. Verify the server host-key fingerprint before trusting a new host.\n'
