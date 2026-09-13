<p align="center">
  <img src="assets/logo.png" alt="Arch Linux Config — tiled mountain logo" width="240">
</p>

<h1 align="center">Arch Linux Config</h1>

<p align="center">An interactive installer for a comfortable, Catppuccin-inspired i3 desktop.</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPL--3.0-b4befe" alt="License: GPL-3.0"></a>
  <img src="https://img.shields.io/badge/OS-Arch_Linux-1793D1?logo=archlinux&amp;logoColor=white" alt="Arch Linux">
  <img src="https://img.shields.io/badge/Desktop-i3-313244?logo=i3&amp;logoColor=white" alt="i3 desktop">
  <img src="https://img.shields.io/badge/Shell-Zsh-a6e3a1?logo=zsh&amp;logoColor=313244" alt="Zsh">
</p>

## What it sets up

- i3 gaps, dark borders, a top status bar, and Picom rounded corners.
- Compact Wi-Fi, CPU, RAM, disk, battery, and clock readouts with warning colors.
- Rofi with Catppuccin, Nord, and Dracula themes.
- Flameshot screenshots, Arabic-capable Noto fonts, and GTK dark preferences.
- Bluetooth and network tray applets, PipeWire audio, and two-finger scrolling.
- Optional browsers, file utilities, development tools, and AUR applications.
- Interactive package choices, preview mode, and configuration backups.

## Get started

```bash
git clone https://github.com/AhmedAnbar/arch-linux-config.git
cd arch-linux-config
```

Run on an already-installed Arch system as your normal user with sudo access:

```bash
bash install.sh --dry-run
bash install.sh
```

## Configuration and backups

Copy this entire directory to another machine, including `config/` and
`installed-explicit.txt`. No dependency on `/home/anbar` is required.
All yes/no questions default to No. Preview mode shows commands without writing
configuration, installing software, or changing services. Package availability
in preview uses the current local repository databases.

The package choices were assembled from `Install arch linux.md`, pacman's log,
explicitly installed packages, relevant shell installation history, and our
desktop setup conversation. The snapshot is in `installed-explicit.txt`.
Dependencies are resolved by pacman. Packages from older notes are optional and
may no longer exist in enabled repositories or AUR; unavailable repository names
are reported. AUR failures stop the script with the error visible.

Core configuration includes Alt-based i3 keybindings, 12px inner/8px outer gaps,
2px borders, a dark bar, Picom rounded corners, three Rofi palettes, Flameshot's
legacy X11 capture, Blueman and NetworkManager applets, GTK dark preferences,
and Noto fonts. PipeWire audio is offered separately. Pasystray is retained in
the package inventory but is neither installed by default nor autostarted,
because you requested its removal.

Select the core desktop package group before installing the complete configuration
on a fresh system. Skipping package groups is useful when configuring a system
where the applications are already installed. Existing files are compared; any
changed file requires confirmation and is saved under
`~/.local/state/arch-desktop-setup/TIMESTAMP-PID/` before replacement. Restore a
file by copying its saved counterpart back to the same relative path under
`~/.config/`. No running applications are terminated and no automatic logout occurs.

The bundled touchpad helper checks tapping and supported scroll methods, then
sets `1 0 0` (two-finger, edge, button). It runs at i3 login/restart. For immediate
application use `sh ~/.config/i3/touchpad.sh`. i3's config reload does not rerun
startup commands; log out/in to start the applets and compositor.

## Change the launcher theme

Rofi uses `~/.config/rofi/active-theme.rasi`. Change its single line to select:

```text
@theme "i3-theme.rasi"
```

Alternatives are `i3-theme-nord.rasi` and `i3-theme-dracula.rasi`. This bundle
explicitly sets transparent widget backgrounds to address the earlier broken
colors; visual rendering still needs checking in a real desktop session.

## After installation

After installation: Alt+D opens Rofi; Alt+Shift+S opens Flameshot; volume keys
control PipeWire-Pulse. Log out/in to load all startup settings. Pair headphones
in Blueman and choose a Firefox Catppuccin theme inside Firefox. Browser profiles,
extension databases, Bluetooth pairings, accounts, and credentials are not copied.
Qt applications may need their own appearance settings; GTK dark mode is not a
universal Qt theme.

Display resolution is hardware-specific; the old eDP-1/1920x1200 command is not
enabled in this portable configuration. Use xrandr for the target machine.
The old install guide's partitioning, formatting, mounts, bootloader writes,
user creation, timezone, microcode choice, and initramfs changes are outside this
post-install script. Kernel/boot packages in the captured inventory are offered
only if explicitly selected. Snapshot tools are installed as applications; their
snapshot schedules, GRUB integration, and zram service configuration remain manual.

## Validation

Validated: Bash/sh syntax, i3 config parser, and the three Rofi theme parsers.
No package installs or real session/service changes were run while creating this
bundle. Keep backups until you have checked the restored desktop visually.

## Zsh and Oh My Zsh

The installer offers Zsh setup, or run it independently:

```bash
bash setup-zsh.sh
```

It offers installing Zsh and the Arch autosuggestions/syntax-highlighting
packages, downloading Oh My Zsh, backing up and replacing `~/.zshrc`, and changing
the login shell. The configuration includes Git, sudo, extract, and colored-man-pages
plugins, history search, completion, and guarded development aliases.
The default theme is robbyrussell; if Starship is installed it supplies the prompt.
Atuin and NVM load only when installed. Personal credentials and server aliases
from the old configuration are excluded.

## License and credits

Copyright (C) 2026 AhmedAnbar. This project is distributed under the
[GNU General Public License v3.0](LICENSE) (`GPL-3.0-only`), without warranty.
Installed third-party applications retain their respective licenses.
The i3 configuration builds on the standard i3-config-wizard defaults;
the colors are inspired by Catppuccin, Nord, and Dracula.
This is an independent personal project, unaffiliated with Arch Linux.

The logo was generated with OpenAI's built-in image generation tool.
Its generation prompt is recorded in [assets/LOGO.md](assets/LOGO.md).
