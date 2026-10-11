# Session Tracker

A cross-platform, background time-tracking monitor that captures screen lock, unlock, and sleep events. This system operates cleanly alongside your OS to generate accurate, timestamped logs of your activity and provides scripts to automatically synchronize these gaps with [Timewarrior](https://timewarrior.net/).

## Features

- **macOS Integration:** A native Swift script that listens to `NSWorkspace` notifications for precise sleep and unlock detection, managed by `launchd`.
- **Timewarrior Gap Sync:** Included Python scripts (`tw_sync.py`) that intelligently stop and start your Timewarrior tracking based on when you _actually_ walked away (even calculating and subtracting Mac sleep timers).
- **Cross-Platform Vision:** (Coming Soon) Support for Windows and Linux to ensure a unified time-tracking experience regardless of your OS.

## Repository Structure

```text
.
├── install.sh             # Installs and starts the background service
├── README.md              # This file
├── mac/
│   ├── SessionTracker.swift          # Core macOS monitoring script
│   └── com.user.sessiontracker.plist # launchd configuration template
└── scripts/
    └── tw_sync.py         # Timewarrior gap sync tool (tw-end / tw-begin)
```

## Setup & Installation (macOS)

1. **Run the Installer:**
   Make the installation script executable and run it. This compiles `SessionTracker.swift` into a native binary at `~/.config/mooseware/bin/SessionTracker`, installs the `launchd` service into `~/Library/LaunchAgents/`, and starts it.

   ```bash
   chmod +x install.sh
   ./install.sh
   ```

2. **Verify Logs:**
   The tracker logs its events to `~/.config/mooseware/logs/`. You can view the latest events to confirm it is working:

   ```bash
   tail -n 10 $(ls -t ~/.config/mooseware/logs/Log_*.txt | head -n 1)
   ```

3. **Check Service Status (`launchd`):**
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

## Timewarrior Integration

> **Tip:** If you are using the Moosetilities **Alias Manager**, these aliases (`tw-end` and `tw-begin`) are already pre-configured for you in `aliases.d/timewarrior.sh`.

To use the automated gap synchronization with Timewarrior without the Alias Manager, add these aliases to your shell configuration (e.g., `~/.bashrc` or `~/.zshrc`):

```bash
# Add these to your shell config (or use the Alias Manager)
alias tw-end='$HOME/.config/mooseware/bin/tw_sync.py --end'
alias tw-begin='$HOME/.config/mooseware/bin/tw_sync.py --begin'
```

### How to use the Aliases:

1. **Walking Away:** When you leave your desk, simply lock your screen.
2. **Returning (`tw-begin`):** When you return and unlock your computer, run `tw-begin`.
   - **Smart Start:** `tw-begin` will look for your unlock time, check if you left a Timewarrior segment running, and if so, safely stop that previous segment at the exact moment you locked the screen (or the calculated sleep time). It will then start a brand new segment at the unlock time.
3. **End of Day (`tw-end`):** If you just want to stop tracking for the day without starting a new task, run `tw-end`. It will stop your active segment at your last lock/sleep time.

## How to Uninstall / Stop the Service

To cleanly stop the background service and remove it from macOS, simply run the included uninstall script:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

_Note: This will not delete your logged data in `~/.config/mooseware/logs/`._
