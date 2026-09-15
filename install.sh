#!/bin/bash
#
# install.sh — sets up the lid-toggle utility for the current user.
#
# What this does:
#   1. Installs the privileged wrapper to /usr/local/sbin/lid-toggle.sh
#      (root:root, mode 750).
#   2. Adds a sudoers rule granting the current user passwordless rights
#      to run ONLY that exact script with "enable" or "disable" — nothing
#      else. No wildcards.
#   3. Installs the user-side toggle script to ~/toggle-lid.sh.
#   4. Installs a desktop launcher to ~/Desktop/LidToggle.desktop.
#
# Safe to re-run — it overwrites its own files idempotently.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

echo "==> Installing root-level wrapper to /usr/local/sbin/lid-toggle.sh"
sudo install -o root -g root -m 750 "$SCRIPT_DIR/lid-toggle-root.sh" /usr/local/sbin/lid-toggle.sh

echo "==> Writing sudoers rule for user: $TARGET_USER"
SUDOERS_LINE="$TARGET_USER ALL=(ALL) NOPASSWD: /usr/local/sbin/lid-toggle.sh enable, /usr/local/sbin/lid-toggle.sh disable"
echo "$SUDOERS_LINE" | sudo tee /etc/sudoers.d/lid-toggle > /dev/null
sudo chmod 440 /etc/sudoers.d/lid-toggle

# Validate the sudoers file before it's trusted — a syntax error here
# could otherwise break sudo entirely for the system.
sudo visudo -c -f /etc/sudoers.d/lid-toggle

echo "==> Installing user-side toggle script to $USER_HOME/toggle-lid.sh"
install -m 755 "$SCRIPT_DIR/lid-toggle.sh" "$USER_HOME/toggle-lid.sh"

echo "==> Installing desktop launcher to $USER_HOME/Desktop/LidToggle.desktop"
mkdir -p "$USER_HOME/Desktop"
cp "$SCRIPT_DIR/LidToggle.desktop" "$USER_HOME/Desktop/LidToggle.desktop"
chmod +x "$USER_HOME/Desktop/LidToggle.desktop"

echo ""
echo "Done."
echo "On GNOME you may need to right-click the Desktop icon and choose"
echo "'Allow Launching' before it will run on double-click."
