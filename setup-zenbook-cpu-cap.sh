#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 AhmedAnbar
# Stop the ASUS Zenbook S 16 (UM5606) firmware from capping the CPU at its lowest
# performance level. Only writes one modprobe.d file; no packages, no session changes.
set -Eeuo pipefail
trap 'printf "Zenbook CPU fix stopped at line %s. Review the error above.\n" "$LINENO" >&2' ERR
dry_run=false
remove=false
force=false
for argument in "$@"; do
    case "$argument" in
        --dry-run) dry_run=true ;;
        --remove) remove=true ;;
        --force) force=true ;;
        --help|-h)
            printf 'Usage: bash setup-zenbook-cpu-cap.sh [--dry-run] [--remove] [--force]\n'
            printf 'Blocks amd_pmf, amdxdna and asus_armoury at boot on the ASUS Zenbook S 16 (UM5606),\n'
            printf 'where loading them locks the CPU to ~605 MHz and about 5 W.\n'
            printf '--remove: delete the file again and restore the stock drivers.\n'
            printf '--force:  apply on hardware whose model does not match UM5606.\n'
            exit 0 ;;
        *) printf 'Unknown argument: %s\n' "$argument" >&2; exit 2 ;;
    esac
done
(( EUID != 0 )) || { printf 'Run as your normal user, without sudo. Commands needing root will use sudo.\n' >&2; exit 1; }
[[ -f /etc/arch-release ]] || { printf 'This script requires Arch Linux.\n' >&2; exit 1; }
# Test hooks: the defaults are the real system paths.
dmi_file=${ZENBOOK_CPU_CAP_DMI_FILE:-/sys/class/dmi/id/product_name}
conf_file=${ZENBOOK_CPU_CAP_CONF:-/etc/modprobe.d/zenbook-um5606-cpu-cap.conf}
modules=(amd_pmf amdxdna asus_armoury)
ask() {
    local answer
    read -r -p "$1 [y/N] " answer || return 1
    [[ "$answer" == y || "$answer" == Y || "$answer" == yes ]]
}
run() {
    printf '  '; printf '%q ' "$@"; printf '\n'
    if ! "$dry_run"; then "$@"; fi
}
model=$(cat -- "$dmi_file" 2>/dev/null || true)
printf 'Detected model: %s\n' "${model:-unknown}"
if [[ "$model" != *UM5606* ]] && ! "$force"; then
    printf 'This fix is specific to the ASUS Zenbook S 16 (UM5606); nothing changed.\n' >&2
    printf 'Other hardware needs its own diagnosis: compare cpufreq/scaling_cur_freq under load.\n' >&2
    printf 'Use --force only after confirming the same CPU cap on this machine.\n' >&2
    exit 1
fi

if "$remove"; then
    if [[ ! -f "$conf_file" ]]; then
        printf 'Not present: %s\n' "$conf_file"
        exit 0
    fi
    printf '\nRemoving %s restores amd_pmf, amdxdna and asus_armoury at the next boot,\n' "$conf_file"
    printf 'which is expected to bring back the ~605 MHz CPU cap on this laptop.\n'
    if ask 'Delete the file and rebuild the initramfs?'; then
        run sudo rm -f -- "$conf_file"
        run sudo mkinitcpio -P
        printf 'Removed. Restart to load the stock drivers again.\n'
    fi
    exit 0
fi

printf '\nMeasured on this model (BIOS 318, Linux 7.2.4): loading amd_pmf, amdxdna and\n'
printf 'asus_armoury during boot leaves every core at 605 MHz with a 5 W package limit,\n'
printf 'about eight times slower than normal, while Linux requests full performance\n'
printf '(CPPC_REQ max equals the highest supported level). Blocking the three modules\n'
printf 'restores full speed: 34 W and 2.4-3.2 GHz under a 24-thread load.\n'
printf '\nCost of the fix:\n'
printf '  - amd_pmf: AMD automatic power tuning. Power profiles keep working through asus-wmi.\n'
printf '  - amdxdna: the NPU driver, which needs amd_pmf. Linux software for the NPU is minimal.\n'
printf '  - asus_armoury: some ASUS firmware attributes. Fan, backlight and charge limits stay in asus_wmi.\n'
printf '\nWould write %s:\n' "$conf_file"
config_temp=$(mktemp)
trap 'rm -f -- "$config_temp"' EXIT
{
    printf '# SPDX-License-Identifier: GPL-3.0-only\n'
    printf '# ASUS Zenbook S 16 (UM5606): loading these during boot makes the firmware pin\n'
    printf '# every core to its lowest performance level (~605 MHz, ~5 W package power),\n'
    printf '# even though cpufreq requests maximum performance. Written by arch-desktop-setup.\n'
    printf '# Remove with: bash setup-zenbook-cpu-cap.sh --remove\n'
    printf 'blacklist %s\n' "${modules[@]}"
} > "$config_temp"
sed 's/^/    /' -- "$config_temp"

if [[ -f "$conf_file" ]] && cmp -s -- "$config_temp" "$conf_file"; then
    printf 'Unchanged: %s\n' "$conf_file"
else
    if [[ -e "$conf_file" ]]; then
        ask "Replace the existing $conf_file?" || exit 0
    else
        ask 'Write this file?' || exit 0
    fi
    run sudo install -Dm644 -- "$config_temp" "$conf_file"
    # The modconf hook copies modprobe.d into the initramfs, so stale copies must go.
    if ask 'Rebuild the initramfs now (needed by the modconf hook)?'; then
        run sudo mkinitcpio -P
    fi
fi

printf '\nRestart, then confirm the cap is gone:\n'
printf '  time (head -c 256M /dev/zero | sha256sum)   # well under 1s; about 4.5s when capped\n'
printf '  lsmod | grep -E %s   # expect no output\n' "'amd_pmf|amdxdna|asus_armoury'"
if "$dry_run"; then printf 'Preview only: no files were written and no initramfs was rebuilt.\n'; fi
