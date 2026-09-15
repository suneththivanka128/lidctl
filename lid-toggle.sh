#!/bin/bash
#
# lid-toggle.sh
# Installed to: ~/toggle-lid.sh
#
# User-facing toggle. Reads current state from logind.conf and flips
# it by calling the privileged wrapper at /usr/local/sbin/lid-toggle.sh,
# which is allowed to run passwordless via a locked-down sudoers rule.

CONF="/etc/systemd/logind.conf"

if grep -qE "^HandleLidSwitch=ignore" "$CONF"; then
    sudo /usr/local/sbin/lid-toggle.sh enable
    notify-send "Lid Action Changed" "Lid Suspend ENABLED (Normal Sleep)" -i dialog-information
else
    sudo /usr/local/sbin/lid-toggle.sh disable
    notify-send "Lid Action Changed" "Lid Suspend DISABLED (Docker Ready)" -i dialog-warning
fi
