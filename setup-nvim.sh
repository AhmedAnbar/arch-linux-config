#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
set -Eeuo pipefail
bundle_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
dry_run=false
case "${1:-}" in
    --dry-run) dry_run=true ;;
    --help|-h) printf 'Usage: bash setup-nvim.sh [--dry-run]\n'; exit 0 ;;
    '') ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; exit 2 ;;
esac
(( EUID != 0 )) || { printf 'Run as your normal user, not root.\n' >&2; exit 1; }
ask() { local answer; read -r -p "$1 [y/N] " answer || return 1; [[ "$answer" == y || "$answer" == Y || "$answer" == yes ]]; }
run() { printf '  '; printf '%q ' "$@"; printf '\n'; if ! "$dry_run"; then "$@"; fi; }
if ask 'Install/upgrade Neovim and its system dependencies on Arch?'; then
    [[ -f /etc/arch-release ]] || { printf 'Package installation requires Arch Linux.\n' >&2; exit 1; }
    run sudo pacman -Syu --needed neovim git base-devel nodejs npm php composer go ripgrep fd unzip curl xclip lazygit ttf-jetbrains-mono-nerd
fi
config_root=${XDG_CONFIG_HOME:-$HOME/.config}
if ask 'Back up the entire current Neovim configuration and restore this bundle?'; then
    backup_root="${XDG_STATE_HOME:-$HOME/.local/state}/arch-desktop-setup/nvim-$(date +%Y%m%d-%H%M%S)-$$"
    if [[ -e "$config_root/nvim" || -L "$config_root/nvim" ]]; then
        run mkdir -p -- "$backup_root"
        run mv -- "$config_root/nvim" "$backup_root/nvim"
        printf 'Previous configuration retained at %s/nvim\n' "$backup_root"
    fi
    run mkdir -p -- "$config_root"
    run cp -a -- "$bundle_dir/config/nvim" "$config_root/nvim"
fi
if ask 'Download/build the locked Neovim plugins?'; then
    run nvim --headless '+Lazy! restore' '+qa!'
fi
if ask 'Install the configured Mason language servers and formatters?'; then
    for tool in node npm php composer go; do
        if ! "$dry_run" && ! command -v "$tool" >/dev/null; then
            printf 'Missing %s; install system dependencies first.\n' "$tool" >&2; exit 1
        fi
    done
    run nvim --headless '+MasonToolsInstallSync' '+qa!'
    run nvim --headless '+lua for _, name in ipairs(require("anbar.plugins.mason")[2].opts.ensure_installed) do if not require("mason-registry").get_package(name):is_installed() then io.stderr:write("Mason package failed: " .. name .. "\n"); vim.cmd("cquit 1") end end' '+qa!'
fi
if ask 'Install the official Laravel language server into your Composer global environment?'; then
    run composer global require laravel/lsp --no-interaction
fi
if ask 'Install syntax parsers and run configuration smoke tests?'; then
    run nvim --headless '+TSInstallSync lua vim vimdoc php json blade javascript typescript tsx html css go rust markdown markdown_inline' '+qa!'
    run nvim --headless -l "$bundle_dir/tests/nvim-smoke.lua"
fi
printf '\nRestart Neovim after tool installation. Leader is Space; Space + ? searches keymaps.\n'
printf 'Use :checkhealth and :Mason to inspect optional tools. No AI completion plugins are included.\n'
