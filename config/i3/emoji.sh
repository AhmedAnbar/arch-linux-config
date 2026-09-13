#!/bin/sh
# Copy the selected emoji; do not send synthetic typing to another application.
set -eu
config_root=${XDG_CONFIG_HOME:-$HOME/.config}
exec rofi -no-config -modi emoji -show emoji -emoji-mode copy \
    -emoji-format '{emoji}  {name}' -theme "$config_root/rofi/emoji.rasi"
