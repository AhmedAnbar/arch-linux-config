#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
set -u
export XDG_CURRENT_DESKTOP=sway XDG_SESSION_TYPE=wayland MOZ_ENABLE_WAYLAND=1
# Portals must get this session's Wayland socket, not an old X11 environment.
dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK \
    XDG_CURRENT_DESKTOP XDG_SESSION_TYPE MOZ_ENABLE_WAYLAND
gsettings set org.gnome.desktop.interface color-scheme prefer-dark

# No Picom, xss-lock, Flameshot or X11-wide autostart under Sway.
mako &
nm-applet --indicator &
blueman-applet &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

exec swayidle -w \
    timeout 300 'sh ~/.config/sway/lock.sh' \
    timeout 600 'swaymsg "output * power off"' \
        resume 'swaymsg "output * power on"' \
    before-sleep 'sh ~/.config/sway/lock.sh' \
    lock 'sh ~/.config/sway/lock.sh'
