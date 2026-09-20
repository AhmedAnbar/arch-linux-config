# SPDX-License-Identifier: GPL-3.0-only
# Set only the workspace-tab UI keys in conventional table-based Herdr TOML.
# The caller rejects multiline strings and validates the resulting TOML.
function emit_keys() {
    print "sidebar_start_collapsed = true"
    print "sidebar_collapsed_mode = \"hidden\""
    print "tab_bar_right = [{ type = \"command\", command = \"" CMD "\", interval_seconds = 1, timeout_seconds = 2 }]"
    print "tab_bar_right_separator = \"  \""
}
/^[[:space:]]*\[/ {
    if (in_ui) emit_keys()
    in_ui = ($0 ~ /^[[:space:]]*\[[[:space:]]*ui[[:space:]]*\][[:space:]]*(#.*)?$/)
    if (in_ui) found_ui = 1
    print
    next
}
in_ui && /^[[:space:]]*(sidebar_start_collapsed|sidebar_collapsed_mode|tab_bar_right|tab_bar_right_separator)[[:space:]]*=/ {
    # A managed key whose array spills onto later lines needs manual editing.
    if ($0 ~ /\[/ && $0 !~ /\]/) {
        printf "A multi-line %s array needs manual editing; file unchanged.\n", $1 > "/dev/stderr"
        bail = 1
        exit 1
    }
    next
}
{ print }
END {
    if (bail) exit 1
    if (in_ui) emit_keys()
    if (!found_ui) {
        print ""
        print "[ui]"
        emit_keys()
    }
}
