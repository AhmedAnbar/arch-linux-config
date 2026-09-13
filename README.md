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

[Get started](#get-started) · [Package catalogue](#package-catalogue) · [Neovim / Laravel](#neovim--laravel) · [Backups](#configuration-and-backups)

## What it sets up

- i3 gaps, dark borders, a top status bar, and Picom rounded corners.
- Compact Wi-Fi, CPU, RAM, disk, battery, and clock readouts with warning colors.
- Rofi with Catppuccin, Nord, and Dracula themes.
- Flameshot screenshots, Arabic-capable Noto fonts, and GTK dark preferences.
- Bluetooth and network tray applets, PipeWire audio, and two-finger scrolling.
- Optional browsers, file utilities, development tools, and AUR applications.
- Interactive package choices, preview mode, and configuration backups.

## Package catalogue

Every package named by the installer scripts or the captured explicit-package
inventory is listed below, followed by separately installed tools and Neovim
plugins. This is a catalogue, **not a claim that every item is installed**:
all installer prompts default to No. Transitive dependencies are resolved by the
package managers and are not exhaustively listed. Emoji are category icons,
not official project logos.

Sources: [main installer](install.sh), [Zsh setup](setup-zsh.sh),
[Neovim setup](setup-nvim.sh), [captured inventory](installed-explicit.txt),
[Mason configuration](config/nvim/lua/anbar/plugins/mason.lua), and
[locked Neovim plugins](config/nvim/lazy-lock.json). System-package descriptions
are based on local Arch package metadata and each package's role in this setup.

### System applications and packages

“Installer” means offered by a selected package group; “Neovim” and “Zsh” refer
to those optional setup sections. “Inventory only” requires individual selection
and does not configure boot, disk or other system settings. Legacy/AUR entries
come from older notes and may be unavailable; they are not prerequisites.

| Icon | Package | Installation choice | Summary |
| --- | --- | --- | --- |
| ⌨️ | `alacritty` | Legacy option | A cross-platform, GPU-accelerated terminal emulator. |
| 🔊 | `alsa-utils` | Installer | Advanced Linux Sound Architecture - Utilities. |
| ⚙️ | `amd-ucode` | Inventory only | Microcode update image for AMD CPUs. |
| ⚙️ | `base` | Inventory only | Minimal package set to define a basic Arch Linux installation. |
| 🧰 | `base-devel` | Installer | Build-tool metapackage for compiling software and AUR packages. |
| 📡 | `blueman` | Installer | GTK+ Bluetooth Manager. |
| 📡 | `bluez` | Installer | Daemons for the bluetooth protocol stack. |
| 📡 | `bluez-utils` | Installer | Development and debugging utilities for the bluetooth protocol stack. |
| 🔎 | `bpytop` | Legacy option | Terminal CPU, memory, disk and network monitor. |
| ☀️ | `brightnessctl` | Laptop shortcuts | Adjust the hardware display backlight without keyboard-LED changes. |
| 💾 | `btrfs-progs` | Installer | Btrfs filesystem utilities. |
| 🧰 | `composer` | Installer | Dependency Manager for PHP. |
| 🖨️ | `cups` | Installer | OpenPrinting CUPS - daemon package. |
| 🌐 | `curl` | Neovim | command line tool and library for transferring data with URLs. |
| 🖥️ | `dex` | Installer | Program to generate and execute DesktopEntry files of type Application. |
| 💬 | `dialog` | Installer | A tool to display dialog boxes from shell scripts. |
| 💬 | `discord` | Optional applications | Voice, video and text chat. |
| 🐳 | `docker` | Docker setup | Container engine, command-line client and system daemon. |
| 🐳 | `docker-compose` | Docker setup | Define and run multi-container applications using `docker compose`. |
| 🖥️ | `dmenu` | Legacy option | Generic menu for X. |
| 💾 | `dosfstools` | Installer | DOS filesystem utilities. |
| 📦 | `dropbox` | Optional AUR | Synchronize files with Dropbox. |
| ⚙️ | `efibootmgr` | Inventory only | Linux user-space application to modify the EFI Boot Manager. |
| 📁 | `fd` | Neovim | Simple, fast and user-friendly alternative to find. |
| 📁 | `file-roller` | Installer | Create and modify archives. |
| 🌐 | `firefox` | Installer | Web browser. |
| 📷 | `flameshot` | Installer | Capture and annotate screenshots. |
| 🧰 | `git` | Installer | Track source-code changes and work with Git repositories. |
| 🧰 | `github-cli` | Installer | The GitHub CLI. |
| 🧰 | `go` | Neovim | Core compiler tools for the Go programming language. |
| 🌐 | `google-chrome` | Optional AUR | Google's web browser. |
| 📷 | `gpicview` | Installer | Lightweight image viewer. |
| ⚙️ | `grub` | Inventory only | GNU GRand Unified Bootloader (2). |
| 💾 | `grub-btrfs` | Installer | Integrate Btrfs snapshots into GRUB menus; configuration remains manual. |
| ⚙️ | `gsettings-desktop-schemas` | Installer | Desktop preference schemas used for dark-mode settings. |
| 📁 | `gvfs` | Installer | Virtual filesystem implementation for GIO. |
| 🖥️ | `i3-wm` | Installer | Tiling window manager with the bundled gaps and keybindings. |
| 🔒 | `i3lock` | Installer | Improved screenlocker based upon XCB and PAM. |
| 🖥️ | `i3status` | Installer | Generates status bar to use with i3bar, dzen2 or xmobar. |
| ⌨️ | `kitty` | Installer | GPU-accelerated terminal emulator. |
| 🐳 | `lazydocker` | Docker setup | Terminal UI for Docker containers, images, logs and Compose services. |
| 🧰 | `lazygit` | Neovim | Simple terminal UI for git commands. |
| 🔎 | `less` | AUR build review | A terminal based program for viewing text files. |
| 🔊 | `libpulse` | Installer | PulseAudio-compatible client library and command-line audio tools. |
| 🔒 | `lightdm` | Installer | A lightweight display manager. |
| 🔒 | `lightdm-gtk-greeter` | Installer | GTK+ greeter for LightDM. |
| 🔒 | `lightdm-gtk-greeter-settings` | Installer | Settings editor for the LightDM GTK+ Greeter. |
| ⚙️ | `linux` | Inventory only | The Linux kernel and modules. |
| ⚙️ | `linux-firmware` | Inventory only | Firmware files for Linux - Default set. |
| ⚙️ | `linux-headers` | Inventory only | Headers and scripts for building modules for the Linux kernel. |
| 💾 | `mtools` | Installer | A collection of utilities to access MS-DOS disks. |
| 📝 | `neovim` | Installer | Extensible editor used by the bundled development configuration. |
| 📡 | `network-manager-applet` | Installer | Applet for managing network connections. |
| 📡 | `networkmanager` | Installer | Network connection manager and user applications. |
| 🖥️ | `nitrogen` | Legacy option | Choose and restore an X11 wallpaper. |
| 🧰 | `nodejs` | Neovim | JavaScript runtime for development tools and language servers. |
| 🔤 | `noto-fonts` | Installer | Unicode fonts, including Arabic text support. |
| 😀 | `noto-fonts-emoji` | Laptop shortcuts | Color emoji font used by the picker and applications. |
| 🧰 | `npm` | Neovim | JavaScript package manager. |
| 💾 | `ntfs-3g` | Installer | NTFS FUSE driver. |
| 📝 | `obsidian` | Optional applications | Markdown-based notes and knowledge management. |
| 🔊 | `pasystray` | Inventory only | Volume tray applet retained in the old inventory; not autostarted. |
| 🧰 | `php` | Installer | PHP runtime for Laravel, Composer and language tools. |
| 🖥️ | `picom` | Installer | X11 compositor for shadows, transparency and rounded corners. |
| 🔊 | `pipewire` | Installer | Audio/video processing service. |
| 🔊 | `pipewire-alsa` | Installer | Low-latency audio/video router and processor - ALSA configuration. |
| 🔊 | `pipewire-jack` | Installer | Low-latency audio/video router and processor - JACK replacement. |
| 🔊 | `pipewire-pulse` | Installer | Low-latency audio/video router and processor - PulseAudio replacement. |
| 🧰 | `postman` | Optional AUR | Build and test API requests. |
| ⚙️ | `psmisc` | Installer | Process utilities including killall, fuser and pstree. |
| 🔎 | `ripgrep` | Neovim | A search tool that combines the usability of ag with the raw speed of grep. |
| 🖥️ | `rofi` | Installer | Themed application launcher and window switcher. |
| 😀 | `rofi-emoji` | Laptop shortcuts | Search emoji and copy a selection to the clipboard. |
| 📷 | `scrot` | Legacy option | Simple command-line screenshot utility for X. |
| 💬 | `teams` | Optional AUR | Legacy Microsoft Teams client entry from the old notes. |
| 📁 | `thunar` | Installer | Modern, fast and easy-to-use file manager for Xfce. |
| 📁 | `thunar-archive-plugin` | Installer | Adds archive operations to the Thunar file context menus. |
| 💾 | `timeshift` | Installer | A system restore utility for Linux. |
| 💾 | `timeshift-autosnap` | Optional AUR | Create Timeshift snapshots around package upgrades. |
| 🌐 | `tor-browser` | Optional AUR | Web browser configured for the Tor network. |
| 🖥️ | `trayer` | Legacy option | Standalone X11 system tray. |
| 🔤 | `ttf-jetbrains-mono-nerd` | Neovim | Patched font JetBrains Mono from nerd fonts library. |
| 📁 | `unzip` | Neovim | For extracting and viewing files in .zip archives. |
| 📝 | `vim` | Installer | Vi Improved, a highly configurable, improved version of the vi text editor. |
| 🔊 | `wireplumber` | Installer | Session / policy manager implementation for PipeWire. |
| 📁 | `xarchiver` | Legacy option | GTK frontend to various command line archivers. |
| 📋 | `xclip` | Neovim | Command line interface to the X11 clipboard. |
| 📁 | `xdg-user-dirs` | Installer | Manage user directories like ~/Desktop and ~/Music. |
| 📁 | `xdg-utils` | Installer | Command line tools that assist applications with a variety of desktop integration tasks. |
| ⌨️ | `xf86-input-libinput` | Installer | Generic input driver for the X.Org server based on libinput. |
| 🖥️ | `xmobar` | Legacy option | Minimalistic Text Based Status Bar. |
| 🖥️ | `xmonad` | Legacy option | Lightweight X11 tiled window manager written in Haskell. |
| 🖥️ | `xmonad-contrib` | Legacy option | Community-maintained extensions for xmonad. |
| 🖥️ | `xmonad-utils` | Legacy option | Small collection of X utilities. |
| 🖥️ | `xorg-server` | Installer | Xorg X server. |
| 🖥️ | `xorg-xinit` | Installer | X.Org initialisation program. |
| ⌨️ | `xorg-xinput` | Installer | Small commandline tool to configure devices. |
| 🖥️ | `xorg-xrandr` | Installer | Primitive command line interface to RandR extension. |
| 🔒 | `xss-lock` | Installer | Use external locker as X screen saver. |
| 📦 | `yay-bin` | Optional AUR helper | Prebuilt yay helper for Arch repositories and AUR packages. |
| 📦 | `yay-bin-debug` | Inventory only | Debug symbols for the prebuilt yay package. |
| ⚙️ | `zramd` | Optional AUR | Configure compressed RAM-backed swap. |
| ⌨️ | `zsh` | Zsh | A very advanced and programmable command interpreter (shell) for UNIX. |
| ⌨️ | `zsh-autosuggestions` | Zsh | Fish-like autosuggestions for zsh. |
| ⌨️ | `zsh-syntax-highlighting` | Zsh | Fish shell like syntax highlighting for Zsh. |

### Shell and language runtimes installed separately

These are downloaded only when their corresponding setup step is accepted.
Rust is installed through Rustup, not the Arch `rust` package.

| Icon | Tool | Installed through | Summary |
| --- | --- | --- | --- |
| 🐚 | Oh My Zsh | Git / Zsh setup | Shell framework and bundled Git, sudo, extract and colored-man-pages plugins. |
| 🦀 | Rustup | Official interactive installer | Install and manage Rust toolchains. |
| 🦀 | Rust / `rustc` | Rustup stable toolchain | Rust compiler needed for source-built tools. |
| 📦 | Cargo | Rustup stable toolchain | Rust package/build tool required by htmx-lsp. |
| 🧩 | `laravel/lsp` | Composer global | Official Laravel language server for PHP and Blade editing. |

### Mason language servers and formatters

Installed by the optional Mason step. These are Mason registry names, not
pacman packages. Installing a tool does not necessarily enable it for every
filetype; its use depends on the corresponding editor/project configuration.

| Icon | Package | Summary |
| --- | --- | --- |
| 🐘 | `phpactor` | PHP language server with navigation and refactoring support. |
| 🌙 | `lua-language-server` | Lua completion, diagnostics and navigation. |
| 🗂️ | `json-lsp` | JSON language support and schema validation. |
| 💚 | `vue-language-server` | Vue component language support. |
| 📜 | `typescript-language-server` | JavaScript and TypeScript language support. |
| 🦀 | `rust-analyzer` | Rust completion, diagnostics and navigation. |
| ⚡ | `emmet-language-server` | Emmet abbreviation completion for markup and styles. |
| 🧡 | `svelte-language-server` | Svelte component language support. |
| 🌐 | `html-lsp` | HTML completion and validation. |
| ✨ | `stylua` | Lua code formatter. |
| ✨ | `prettier` | Formatter for JavaScript, TypeScript, markup and other web files. |
| 🔎 | `eslint_d` | Background ESLint runner; requires project lint configuration. |
| 🎨 | `tailwindcss-language-server` | Tailwind CSS class completion and language support. |
| 🐘 | `pint` | Laravel's PHP code-style formatter. |
| 🗡️ | `blade-formatter` | Laravel Blade template formatter. |
| 🐳 | `hadolint` | Dockerfile linter. |
| 🗃️ | `sql-formatter` | SQL query formatter. |
| 🐹 | `gopls` | Go language server. |
| ✨ | `gofumpt` | Strict Go source formatter. |
| 📦 | `goimports-reviser` | Organize and group Go imports. |
| 📏 | `golines` | Shorten long Go lines through formatting. |
| 🌐 | `htmx-lsp` | HTMX language support; built with Rust/Cargo. |

### Neovim plugins

These are Git plugins managed by lazy.nvim, not system packages. The table
covers every entry in the bundled lockfile, including helper libraries.
Some load only on demand; having a completion source installed does not mean
it is enabled in every buffer. Codeium and Copilot are excluded.

<details>
<summary>Expand the complete Neovim plugin table (91 plugins)</summary>

| Icon | Plugin | Summary |
| --- | --- | --- |
| 🎨 | `Comment.nvim` | Toggle line and block comments. |
| 💡 | `LuaSnip` | Snippet expansion engine. |
| 🎨 | `automkdir.nvim` | Create missing parent directories when saving files. |
| 🎨 | `bufferline.nvim` | Buffer tabs and navigation. |
| 💡 | `cmp-buffer` | Completion from buffer text. |
| 💡 | `cmp-cmdline` | Command-line completion source. |
| 💡 | `cmp-dotenv` | Completion source for environment variables. |
| 💡 | `cmp-npm` | NPM package-name completion. |
| 💡 | `cmp-nvim-lsp` | Connect LSP completion to nvim-cmp. |
| 💡 | `cmp-path` | Filesystem path completion. |
| 💡 | `cmp-spell` | Spell-check completion source. |
| 💡 | `cmp-tw2css` | Translate Tailwind utilities in completion. |
| 💡 | `cmp-under-comparator` | Completion sorting helper for underscore-prefixed names. |
| 💡 | `cmp_luasnip` | Connect LuaSnip to nvim-cmp. |
| 🎨 | `color-picker.nvim` | Interactive color selection. |
| 🎨 | `comment-box.nvim` | Decorative comment boxes and separators. |
| 🎨 | `conform.nvim` | Formatting and format-on-save management. |
| 🧰 | `crates.nvim` | Cargo dependency versions and editing helpers. |
| 🎨 | `dressing.nvim` | Enhanced input and selection dialogs. |
| 🧩 | `ejs-syntax` | EJS template syntax support. |
| 🧩 | `emmet-vim` | Expand Emmet markup abbreviations. |
| 🎨 | `fidget.nvim` | Language-server progress display. |
| 💡 | `friendly-snippets` | Ready-made snippets for many languages. |
| 🌿 | `gitsigns.nvim` | Git changes, hunk actions and inline blame. |
| 🧰 | `go.nvim` | Go editing and development helpers. |
| 🧩 | `guihua.lua` | UI components used by Go tooling. |
| 🎨 | `indent-blankline.nvim` | Indentation guides. |
| 🧰 | `laravel.nvim` | Laravel Artisan, routes, Tinker and project helpers. |
| 🎨 | `lazy.nvim` | Neovim plugin installation and loading. |
| 🎨 | `lazydocker.nvim` | Open an external lazydocker terminal interface. |
| 🌿 | `lazygit.nvim` | Open the LazyGit terminal interface. |
| 🧰 | `lspkind.nvim` | Icons for completion item kinds. |
| 🎨 | `lualine.nvim` | Configurable editor status line. |
| 🎨 | `markdown-preview.nvim` | Preview Markdown in a browser. |
| 🧰 | `mason-tool-installer.nvim` | Install the configured Mason tool list. |
| 🧰 | `mason.nvim` | Manage language servers, linters and formatters. |
| 🔎 | `neo-tree.nvim` | Sidebar file explorer. |
| 🎨 | `noice.nvim` | Enhanced command line, messages and notifications. |
| 🎨 | `none-ls.nvim` | Bridge external tools into LSP; bundled sources are empty. |
| 🎨 | `nui.nvim` | Reusable Neovim UI components. |
| 🎨 | `nvim` | Catppuccin color theme; lockfile name for catppuccin/nvim. |
| 🧩 | `nvim-autopairs` | Automatically insert matching brackets and quotes. |
| 💡 | `nvim-cmp` | Completion menu engine. |
| 🎨 | `nvim-colorizer.lua` | Preview color values inline. |
| 🐞 | `nvim-dap` | Debug Adapter Protocol client. |
| 🐞 | `nvim-dap-go` | Go debugger integration; requires a suitable debugger. |
| 🧩 | `nvim-devdocs` | Browse programming documentation. |
| 🧰 | `nvim-lspconfig` | Language-server configuration definitions. |
| 🧩 | `nvim-neoclip.lua` | Clipboard history with Telescope integration. |
| 🧩 | `nvim-nio` | Asynchronous I/O library for plugins. |
| 🎨 | `nvim-notify` | Popup notifications. |
| 🧩 | `nvim-spectre` | Project-wide search and replace. |
| 🧩 | `nvim-surround` | Add, change and remove surrounding delimiters. |
| 🧩 | `nvim-tmux-navigation` | Navigate between Neovim windows and tmux panes. |
| 🔎 | `nvim-treesitter` | Install syntax parsers and enable structural highlighting. |
| 🔎 | `nvim-treesitter-textobjects` | Syntax-aware selection and movement. |
| 🧩 | `nvim-ts-autotag` | Automatically close and rename markup tags. |
| 🧩 | `nvim-ts-context-commentstring` | Choose comment syntax for embedded languages. |
| 🧩 | `nvim-ufo` | Code-folding enhancements. |
| 🧩 | `nvim-web-devicons` | File-type icons. |
| 🎨 | `obsidian.nvim` | Navigate and edit Obsidian Markdown vaults. |
| 🔎 | `oil.nvim` | Edit directories as buffers. |
| 🎨 | `plenary.nvim` | Shared Lua utilities used by plugins. |
| 🎨 | `prettierrc.nvim` | Use Prettier configuration for editor formatting preferences. |
| 🧩 | `promise-async` | Promise-based asynchronous helpers. |
| 🎨 | `splitjoin.nvim` | Split and join code structures. |
| 🎨 | `symbols-outline.nvim` | Tree view of document symbols. |
| 💡 | `tailwindcss-colorizer-cmp.nvim` | Color previews for Tailwind completion entries. |
| 🔎 | `telescope-file-browser.nvim` | File-browser picker. |
| 🔎 | `telescope-fzf-native.nvim` | Compiled fuzzy matching for Telescope. |
| 🔎 | `telescope-live-grep-args.nvim` | Pass additional arguments to live text searches. |
| 🔎 | `telescope-media-files.nvim` | Media-file search and previews; external preview tools may be needed. |
| 🔎 | `telescope-project.nvim` | Project selection picker. |
| 🔎 | `telescope-symbols.nvim` | Symbol and emoji picker data. |
| 🔎 | `telescope-ui-select.nvim` | Use Telescope for selection dialogs. |
| 🔎 | `telescope.nvim` | Searchable pickers for files, text, keymaps and more. |
| 🎨 | `todo-comments.nvim` | Highlight and find TODO-style comments. |
| 🎨 | `toggleterm.nvim` | Manage embedded terminal windows. |
| 🎨 | `trouble.nvim` | Diagnostics and quickfix-style lists. |
| 🧰 | `tsc.nvim` | Run TypeScript checking and show results. |
| 🧰 | `vim-blade` | Laravel Blade syntax and filetype support. |
| 🧩 | `vim-dadbod` | Database query interface. |
| 🧩 | `vim-dadbod-completion` | SQL completion for database workflows. |
| 🧩 | `vim-dadbod-ui` | Database connection and query sidebar. |
| 🧩 | `vim-dotenv` | Load project environment variables. |
| 🌿 | `vim-fugitive` | Git commands inside Neovim. |
| 🧰 | `vim-prisma` | Prisma schema syntax support. |
| 🧩 | `vim-visual-multi` | Multiple-cursor editing. |
| 🧰 | `vim-vue` | Vue file syntax support. |
| 🎨 | `which-key.nvim` | Discover available keybindings in popup menus. |
| 🎨 | `wrapping.nvim` | Manage hard and soft text wrapping. |

</details>

Tree-sitter parsers are grammar assets, not additional pacman packages. The
configuration requests: Lua, Vim, Vimdoc, JavaScript, HTML, CSS, SCSS, JSON,
JSONC, regex, Prisma, Svelte, PHP, Blade, TypeScript, TSX, Go, Rust, Markdown
and Markdown inline.

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

## Laptop brightness and emoji keys

Select the laptop-shortcuts package group and restore the configuration bundle.
On the ASUS Zenbook UM5606, try Fn+F5/F6 for screen brightness and Fn+F8 for
emoji (Fn-lock determines whether Fn is needed). The emoji shortcut can also
be invoked directly with Super+period; dedicated XF86EmojiPicker keys are supported.

Brightness changes in 5% steps with a 5% minimum. The helper selects the
backlight class automatically, rather than assuming a device name or changing
keyboard LEDs. It uses brightnessctl's normal access controls—no passwordless
sudo rules or broad device-permission changes are added. If permissions fail
after installing the package, log out and back in and test `brightnessctl -c backlight info`.

The Catppuccin emoji picker uses `rofi-emoji` and Noto Color Emoji. Search, press
Enter to copy, then paste into your application (Ctrl+V, or Ctrl+Shift+V in most
terminals). Copy mode avoids unreliable automatic typing under X11; see the
[picker documentation](https://github.com/Mange/rofi-emoji#mode).
After changing bindings, use Alt+Shift+C to reload i3. Physical key behavior and
the visible panel brightness should be checked on the target laptop.

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
Composer global binaries are exported on PATH, respecting COMPOSER_HOME or
XDG_CONFIG_HOME and also supporting the legacy ~/.composer/vendor/bin directory.
The development package group includes PHP and Composer.
The default theme is robbyrussell; if Starship is installed it supplies the prompt.
Atuin and NVM load only when installed. Personal credentials and server aliases
from the old configuration are excluded.

## Neovim / Laravel

Run `bash setup-nvim.sh` (also offered by the main installer). It offers system
dependencies, a full configuration backup/restore, locked plugin installation,
Mason tools, the official Laravel LSP, syntax parsers and smoke tests separately.
Parser installation skips existing parsers without prompting and verifies that
each configured parser loads, so the headless step is safe to rerun.
Use `--dry-run` to preview commands without making changes. Requires Neovim 0.11+.
The installer offers Rust/Cargo via the official interactive Rustup command:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

It loads Cargo's environment immediately for the Mason step, including when run
from Bash. An existing Rustup installation is reused; existing system Rust
packages are never removed automatically. Rust/Cargo is required to build
`htmx-lsp`. If Mason previously failed with `Could not find executable cargo`,
rerun and accept the Rustup step, then the Mason step. Already-installed tools
are kept. The script checks that Cargo and Rust actually run before starting Mason.

The bundle restores the old theme, editing preferences, snippets, Telescope,
Neo-tree/Oil, Git, completion, folds, debugging, database UI, Markdown/Obsidian,
Go/Rust helpers and Laravel tools. macOS metadata, IDE state and conflicted
duplicate files are excluded. Obsidian vault paths still point to your old
Dropbox folders; change them if needed. Database connections and AI credentials
are not included. Docker Engine, Compose and lazydocker are offered together by
the main installer's Docker group (`pacman --needed` keeps installed packages).
A separate service prompt runs `sudo systemctl enable --now docker.service`,
starting Docker immediately and at future boots. Existing container data and
daemon configuration are left intact; no test containers are downloaded or run.
Use `sudo docker compose version` to check Compose and `sudo lazydocker` to open
the terminal UI. Space + `ld` in Neovim runs lazydocker without sudo and therefore
requires separately configured Docker access.

The installer offers a separate, default-No prompt to add the current user to the
Docker group using `usermod -aG docker`, preserving existing group memberships.
It never loosens socket permissions. Log out of the desktop completely and back
in afterward so terminals and Neovim inherit the new group membership.
[Docker documents that group membership grants root-level privileges](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user).
Without sudo, the [upstream Go installation method](https://github.com/jesseduffield/lazydocker#go)
can install a user-local binary:

```bash
GOBIN="$HOME/.local/bin" go install github.com/jesseduffield/lazydocker@v0.25.2
```

The bundled Zsh config includes `~/.local/bin` on PATH. Optional external tools (Delve, database
clients) must be installed for those integrations. Codeium and Copilot are excluded;
completion comes from language servers, snippets and local sources.

Neovim uses **Catppuccin Mocha** with an opaque dark background. The theme loads
before UI plugins; lualine uses its `catppuccin-nvim` theme and notifications use
Mocha colors. Wrapping-mode notifications are disabled without disabling wrapping.

| Shortcut | Action |
| --- | --- |
| Space + `?` | Search keymaps (Telescope) |
| Space + Space | Show keymap groups (which-key) |
| Space + `ff` / `fg` | Find files / search text |
| Space + `n` | Toggle Neo-tree |
| Space + `la` / `lr` / `lt` | Artisan / routes / Tinker |
| `gd` / `K` | LSP definition / documentation |
| Space + `ca` / `rn` | Code actions / rename |
| Space + `mp` | Format file or selection |

PHPActor handles PHP; the [official Laravel LSP](https://github.com/laravel/lsp)
adds framework features for PHP and Blade, attaching only inside an `artisan`
project. The installer uses `composer global require laravel/lsp`. Neovim checks
PATH and the standard Composer global bin locations. Restart Neovim after
installing servers. Only open trusted projects: Laravel tooling can execute PHP
and generate helpers in the project's vendor directory.

Formatting uses Conform only (Pint for PHP, blade-formatter for Blade); the old
duplicate formatting hooks were removed. LSP setup uses the current Neovim API.
Tree-sitter/textobjects retain the legacy `master` API for the old integrations.
A scoped compatibility adapter converts Neovim 0.12 capture lists for the legacy
plugin's query handlers; it does not modify Neovim's global Tree-sitter API.
Autotag uses its standalone setup, without the deprecated Tree-sitter module.
`:Mason`, `:checkhealth` and `:checkhealth vim.lsp` show tool/runtime status.
Run `nvim --headless -l tests/nvim-smoke.lua` to exercise plugin loading, filetypes,
real Markdown/HTML/PHP/Blade/Lua content and README syntax highlighting;
this does not prove project-specific LSP, database, debugger or AI functionality.

Restoration checks passed on Neovim 0.12.5: Lua syntax, plugin loading, ten
filetypes, both keymap menus, Mason package names, and installer shell syntax.
At restoration time PHP, Composer, Node/npm and Go were not installed, so server
installation and end-to-end Laravel behavior still require running the setup script.

## License and credits

Copyright (C) 2026 AhmedAnbar. This project is distributed under the
[GNU General Public License v3.0](LICENSE) (`GPL-3.0-only`), without warranty.
Installed third-party applications retain their respective licenses.
The i3 configuration builds on the standard i3-config-wizard defaults;
the colors are inspired by Catppuccin, Nord, and Dracula.
This is an independent personal project, unaffiliated with Arch Linux.

The logo was generated with OpenAI's built-in image generation tool.
Its generation prompt is recorded in [assets/LOGO.md](assets/LOGO.md).
