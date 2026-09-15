#!/bin/bash
#
# lid-toggle-root.sh
# Installed to: /usr/local/sbin/lid-toggle.sh
# Must be owned by root:root with mode 750.
#
# This is the ONLY script granted passwordless sudo rights (see the
# sudoers rule created by install.sh). It accepts exactly one argument,
# "enable" or "disable", and nothing else — so the sudoers entry can be
# locked to these two exact invocations instead of a wildcard.
#
# It edits /etc/systemd/logind.conf directly and reloads systemd-logind
# with SIGHUP (NOT a restart). A restart of systemd-logind while a GUI
# session is active can drop the session's seat and crash the display —
# a reload just re-reads the config file and is safe to run live.

set -e
CONF="/etc/systemd/logind.conf"
MODE="$1"

set_key () {
    local key="$1"
    local value="$2"
    if grep -qE "^#?${key}=" "$CONF"; then
        sed -i -E "s/^#?${key}=.*/${key}=${value}/" "$CONF"
    else
        echo "${key}=${value}" >> "$CONF"
    fi
}

case "$MODE" in
    disable)
        # "Docker mode" — closing the lid does nothing at all,
        # regardless of AC power or an external monitor/dock.
        set_key "HandleLidSwitch" "ignore"
        set_key "HandleLidSwitchExternalPower" "ignore"
        set_key "HandleLidSwitchDocked" "ignore"
        ;;
    enable)
        # Normal laptop behaviour — closing the lid suspends.
        set_key "HandleLidSwitch" "suspend"
        set_key "HandleLidSwitchExternalPower" "suspend"
        set_key "HandleLidSwitchDocked" "suspend"
        ;;
    *)
        echo "Usage: $0 [enable|disable]" >&2
        exit 1
        ;;
esac

# Reload config without dropping the active session.
systemctl kill -s HUP systemd-logind
