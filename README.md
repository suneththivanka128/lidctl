# lid-toggle

A one-click desktop toggle for Ubuntu 24.04 (GNOME) that disables/enables
laptop lid-suspend behaviour — useful when you want to close the lid and
keep a server, Docker container, or download running without the machine
going to sleep.

On Ubuntu 24.04, `systemd-logind` handles the lid switch directly, which
means the lid-close action can be inconsistent through GNOME Settings or
extensions. This project edits `/etc/systemd/logind.conf` directly and
reloads `systemd-logind`, so it works regardless of desktop-environment
quirks.

## What it does

Toggles three related settings at once, so it works correctly whether
the laptop is on battery, on AC power, or docked to an external monitor:

- `HandleLidSwitch`
- `HandleLidSwitchExternalPower`
- `HandleLidSwitchDocked`

**Disabled (Docker-ready):** closing the lid does nothing — screen may
turn off, but the system keeps running.

**Enabled (normal):** closing the lid suspends the machine as usual.

## Design notes / why it's built this way

- **No wildcard sudo.** Early versions of this script granted
  passwordless `sudo` to `/bin/sed` with no fixed arguments, which is a
  serious privilege-escalation hole (it lets *any* file be edited as
  root). This version locks the sudoers rule to one exact script with
  exactly two allowed arguments (`enable` / `disable`) — nothing else is
  passwordless.
- **Reload, not restart.** `systemctl restart systemd-logind` while a
  GUI session is active can drop the session's seat and crash the
  display. This script uses `systemctl kill -s HUP systemd-logind`
  instead, which just makes logind re-read its config file safely,
  without disturbing the running session.
- **All three lid-switch keys are set together.** Only setting
  `HandleLidSwitch` looks like it works until the laptop is plugged into
  AC power — at that point `HandleLidSwitchExternalPower` is what
  actually governs lid behaviour, and if it's left on `suspend` the
  laptop will sleep anyway.

## Installation

```bash
git clone https://github.com/suneththivanka128/lid-toggle.git
cd lid-toggle
chmod +x install.sh
./install.sh
```

This installs:

| File | Installed to | Purpose |
|---|---|---|
| `lid-toggle-root.sh` | `/usr/local/sbin/lid-toggle.sh` (root:root, 750) | Does the actual privileged config edit + logind reload |
| (sudoers rule) | `/etc/sudoers.d/lid-toggle` | Lets your user run the above passwordless, and *only* the above |
| `lid-toggle.sh` | `~/toggle-lid.sh` | Detects current state, calls the root script, shows a notification |
| `LidToggle.desktop` | `~/Desktop/LidToggle.desktop` | Double-click launcher |

After installing, right-click the `LidToggle` icon on your Desktop and
choose **"Allow Launching"** (GNOME blocks execution of new `.desktop`
files by default for security).

## Usage

- **Before running Docker / a long task with the lid closed:** double-click
  the desktop icon. A notification confirms "Lid Suspend DISABLED
  (Docker Ready)". Close the lid — the machine keeps running.
- **Back to normal:** double-click again. Notification confirms "Lid
  Suspend ENABLED (Normal Sleep)". Closing the lid will now suspend as usual.

## Verifying it worked

```bash
grep -i handle /etc/systemd/logind.conf
```

All three `HandleLidSwitch*` keys should show `ignore` (disabled) or
`suspend` (enabled) consistently.

To confirm the machine truly isn't suspending (rather than just the
screen turning off), ping or SSH into it from another device after
closing the lid.

## Uninstalling

```bash
sudo rm /usr/local/sbin/lid-toggle.sh
sudo rm /etc/sudoers.d/lid-toggle
rm ~/toggle-lid.sh ~/Desktop/LidToggle.desktop
```

Then optionally reset the lid settings in `/etc/systemd/logind.conf` back
to commented-out defaults and reload:

```bash
sudo sed -i '/^HandleLidSwitch/d' /etc/systemd/logind.conf
sudo systemctl kill -s HUP systemd-logind
```

## Security notes

- The sudoers rule only ever allows running one specific, root-owned
  script with one of two fixed arguments — it cannot be used to run
  arbitrary commands as root.
- The wrapper script only ever touches `/etc/systemd/logind.conf` and
  only ever writes one of two known-safe values to three known keys.

## License

MIT — do whatever you want with it.
