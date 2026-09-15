#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Generate private local SSH settings. No credentials or server addresses are bundled.
set -Eeuo pipefail
umask 077
dry_run=false
git_mode=false
for argument in "$@"; do
    case "$argument" in
        --dry-run) dry_run=true ;;
        --git) git_mode=true ;;
        --help|-h) printf 'Usage: bash setup-ssh.sh [--git] [--dry-run]\nConfigure a private SSH alias without connecting or copying keys.\n--git: configure an SSH Git host and rewrite its HTTPS Git URLs to SSH.\n'; exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$argument" >&2; exit 2 ;;
    esac
done
(( EUID != 0 )) || { printf 'Run as your normal user, without sudo.\n' >&2; exit 1; }
command -v ssh >/dev/null || { printf 'Install OpenSSH first: sudo pacman -Syu --needed openssh\n' >&2; exit 1; }
default_alias=vps
if "$git_mode"; then
    command -v git >/dev/null || { printf 'Install Git first.\n' >&2; exit 1; }
    default_alias=gitlab
    [[ -z "${GIT_CONFIG_GLOBAL:-}" || "$GIT_CONFIG_GLOBAL" == "$HOME/.gitconfig" ]] || { printf 'Custom GIT_CONFIG_GLOBAL is set; configure that file manually.\n' >&2; exit 1; }
fi
read -r -p "Short alias [$default_alias]: " ssh_alias || exit 0
ssh_alias=${ssh_alias:-$default_alias}
read -r -p 'Server IP or hostname: ' ssh_host || exit 0
if "$git_mode"; then
    read -r -p 'Git SSH username [git]: ' ssh_user || exit 0
    ssh_user=${ssh_user:-git}
else
    read -r -p 'SSH username: ' ssh_user || exit 0
fi
read -r -p 'SSH port [22]: ' ssh_port || exit 0
ssh_port=${ssh_port:-22}
read -r -p 'Existing private key path (absolute or ~/...): ' key_file || exit 0
[[ "$ssh_alias" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]] || { printf 'Use letters, digits, underscores or hyphens for the alias.\n' >&2; exit 1; }
[[ "$ssh_host" =~ ^[a-zA-Z0-9][a-zA-Z0-9.:-]*$ ]] || { printf 'Invalid hostname/IP.\n' >&2; exit 1; }
if "$git_mode" && [[ "$ssh_host" == *:* ]]; then
    printf 'Git mode requires a DNS hostname or IPv4 address without a port; enter the SSH port separately.\n' >&2
    exit 1
fi
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
if "$git_mode"; then
    git_source="https://$ssh_host/"
    git_destination="ssh://$ssh_user@$ssh_host/"
    # --get-url expands local configuration only; it never contacts a server.
    # In particular, a stale rewrite with another username overrides SSH User.
    existing_git_url=$(git -C "$HOME" ls-remote --get-url "$git_source")
    if [[ "$existing_git_url" != "$git_source" && "$existing_git_url" != "$git_destination" ]]; then
        printf 'An existing conflicting Git URL rewrite applies to this host. Resolve it in your Git configuration before retrying; no files changed.\n' >&2
        exit 1
    fi
fi
printf '\nWill configure ssh %s for %s@%s on port %s.\n' "$ssh_alias" "$ssh_user" "$ssh_host" "$ssh_port"
printf 'Key file: %s (contents will not be copied or printed).\n' "$key_file"
if "$git_mode"; then
    printf 'HTTPS Git URLs for this host will use SSH instead, for clone, fetch, pull and push. Other hosts are unchanged.\n'
else
    printf 'The alias also becomes a shell command and may override a command of the same name.\n'
fi
read -r -p 'Save locally, back up changed files, and restrict key permissions to 600? [y/N] ' answer || exit 0
[[ "$answer" == y || "$answer" == Y || "$answer" == yes ]] || exit 0
if "$dry_run"; then
    if "$git_mode"; then
        printf 'Would save ~/.ssh/config.d/%s.conf for alias and hostname, add an SSH Include, and update ~/.gitconfig.\n' "$ssh_alias"
        printf 'Git URL rewrite: https://%s/ -> ssh://%s@%s/\n' "$ssh_host" "$ssh_user" "$ssh_host"
    else
        printf 'Would save ~/.ssh/config.d/%s.conf, add an SSH Include, and load ~/.ssh/aliases.sh in Bash/Zsh.\n' "$ssh_alias"
    fi
    printf 'Preview only: no files, permissions or connections changed.\n'
    exit 0
fi
ssh_dir="$HOME/.ssh"
backup_dir="$HOME/.local/state/arch-desktop-setup/ssh-$(date +%Y%m%d-%H%M%S)-$$"
# Refuse symlinks for managed paths rather than unexpectedly modifying their targets.
for directory in "$ssh_dir" "$ssh_dir/config.d"; do
    [[ ! -L "$directory" && ( ! -e "$directory" || -d "$directory" ) ]] || { printf 'Unsafe directory: %s\n' "$directory" >&2; exit 1; }
done
managed_files=("$ssh_dir/config" "$ssh_dir/config.d/$ssh_alias.conf")
if "$git_mode"; then managed_files+=("$HOME/.gitconfig")
else managed_files+=("$ssh_dir/aliases.sh" "$HOME/.bashrc" "$HOME/.zshrc"); fi
for file in "${managed_files[@]}"; do
    [[ ! -L "$file" && ( ! -e "$file" || -f "$file" ) ]] || { printf 'Refusing symlink/non-regular file: %s\n' "$file" >&2; exit 1; }
done
mkdir -p -- "$ssh_dir/config.d"
chmod 700 -- "$ssh_dir" "$ssh_dir/config.d"
stage_dir=$(mktemp -d -t arch-ssh-config.XXXXXXXX)
cleanup() {
    for name in host config aliases bashrc zshrc gitconfig; do
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
host_patterns=$ssh_alias
if "$git_mode"; then
    host_patterns="$ssh_alias $ssh_host"
    if [[ -f "$HOME/.gitconfig" ]]; then cp -- "$HOME/.gitconfig" "$stage_dir/gitconfig"; fi
    # Match the complete host plus slash, never similar domains or every HTTPS URL.
    # Preserve other mappings under the same base and all unrelated Git settings.
    git config --file "$stage_dir/gitconfig" --fixed-value --replace-all \
        "url.ssh://$ssh_user@$ssh_host/.insteadOf" "https://$ssh_host/" "https://$ssh_host/"
fi
printf 'Host %s\n    HostName %s\n    User %s\n    Port %s\n    IdentityFile "%s"\n    IdentitiesOnly yes\n    ForwardAgent no\n    StrictHostKeyChecking ask\n    ServerAliveInterval 30\n    ServerAliveCountMax 3\n' \
    "$host_patterns" "$ssh_host" "$ssh_user" "$ssh_port" "$key_file" > "$stage_dir/host"
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
if "$git_mode"; then
    replace_file "$stage_dir/gitconfig" "$HOME/.gitconfig"
else
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
fi
chmod 600 -- "$key_file" "$ssh_dir/config" "$ssh_dir/config.d/$ssh_alias.conf"
if "$git_mode"; then
    printf 'Ready: git clone https://%s/GROUP/REPOSITORY.git (uses SSH automatically).\n' "$ssh_host"
    printf 'SSH Git URLs also use this key. No shell variables or per-command flags are required.\n'
else
    chmod 600 -- "$ssh_dir/aliases.sh"
    printf 'Ready: ssh %s. For the one-word command, open a new terminal or run: source ~/.ssh/aliases.sh\n' "$ssh_alias"
fi
printf 'Backups, if needed: %s\n' "$backup_dir"
printf 'No connection was made. Verify the server host-key fingerprint before trusting a new host.\n'
