# Session Tracker

A cross-platform, background time-tracking monitor that captures screen lock, unlock, and sleep events. This system operates cleanly alongside your OS to generate accurate, timestamped logs of your activity and provides scripts to automatically synchronize these gaps with [Timewarrior](https://timewarrior.net/).

## Features

- **macOS Integration:** A native Swift script that listens to `NSWorkspace` notifications for precise sleep and unlock detection, managed by `launchd`.
- **Linux Integration:** An event-driven Bash script that monitors `systemd-logind` D-Bus signals (`org.freedesktop.login1`) for lock, unlock, and sleep events, managed by a `systemd` user service.
- **Cross-Platform Vision:** Unified session logging across macOS and Linux (with Windows support in `win/`), ready to feed into tools like the [Timewarrior Integrations](../timewarrior/).

## Repository Structure

```text
.
├── install.sh             # Installs and starts the background service
├── uninstall.sh           # Stops and removes the background service
├── README.md              # This file
├── linux/
│   ├── time_tracker.sh               # Core Linux monitoring script
│   └── session-tracker.service       # systemd user service configuration
└── mac/
    ├── SessionTracker.swift          # Core macOS monitoring script
    └── com.user.sessiontracker.plist # launchd configuration template
```

## Setup & Installation (macOS & Linux)

1. **Run the Installer:**
   Make the installation script executable and run it.
   - **On macOS:** Compiles `SessionTracker.swift` into `~/.config/mooseware/bin/SessionTracker`, installs the `launchd` service into `~/Library/LaunchAgents/`, and starts it.
   - **On Linux:** Copies `time_tracker.sh` into `~/.config/mooseware/bin/time_tracker.sh`, installs `session-tracker.service` into `~/.config/systemd/user/`, and enables/starts it via `systemd`.

   ```bash
   chmod +x install.sh
   ./install.sh
   ```

2. **Verify Logs:**
   The tracker logs its events to `~/.config/mooseware/logs/`. You can view the latest events to confirm it is working:

   ```bash
   tail -n 10 $(ls -t ~/.config/mooseware/logs/Log_*.txt | head -n 1)
   ```

3. **Check Service Status (`launchd` on macOS):**
   For users familiar with `systemctl`, macOS uses `launchctl` to manage user services:
   - **Quick Status (PID & Exit Code):**

     ```bash
     launchctl list | grep sessiontracker
     ```

     _(The first column is the process ID; the second column is `0` for normal operation)._

   - **Detailed Status (`systemctl status` equivalent):**

     ```bash
     launchctl print gui/$(id -u)/com.user.sessiontracker
     ```

   - **Inspect Service Configuration:**

     ```bash
     cat ~/Library/LaunchAgents/com.user.sessiontracker.plist
     ```

   - **View Service stdout / stderr:**

     ```bash
     cat /tmp/com.user.sessiontracker.out
     cat /tmp/com.user.sessiontracker.err
     ```

   - **Restart the Service:**
     ```bash
     launchctl kickstart -k gui/$(id -u)/com.user.sessiontracker
     ```

4. **Check Service Status (`systemd` on Linux):**
   On Linux, the tracker runs as a `systemd` user service, which naturally inherits your desktop session environment, handles automatic restarts on failure, and stops cleanly on logout:
   - **Check Service Status:**

     ```bash
     systemctl --user status session-tracker.service
     ```

   - **View Service Logs (`journalctl`):**

     ```bash
     journalctl --user -u session-tracker.service -n 20
     ```

   - **Restart the Service:**

     ```bash
     systemctl --user restart session-tracker.service
     ```

## Timewarrior Integration

For automated Timewarrior gap synchronization (`tw_sync.py`, `tw-begin`, and `tw-end`) that consumes these session logs, see the [`timewarrior/`](../timewarrior/) package.

## How to Uninstall / Stop the Service

To cleanly stop the background service and remove it from macOS, simply run the included uninstall script:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

_Note: This will not delete your logged data in `~/.config/mooseware/logs/`._
