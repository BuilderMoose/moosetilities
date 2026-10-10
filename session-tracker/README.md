# Session Tracker

A cross-platform, background time-tracking monitor that captures screen lock, unlock, and sleep events. This system operates cleanly alongside your OS to generate accurate, timestamped logs of your activity and provides scripts to automatically synchronize these gaps with [Timewarrior](https://timewarrior.net/).

## Features

* **macOS Integration:** A native Swift script that listens to `NSWorkspace` notifications for precise sleep and unlock detection, managed by `launchd`.
* **Timewarrior Gap Sync:** Included Python scripts (`tw_sync.py`) that intelligently stop and start your Timewarrior tracking based on when you *actually* walked away (even calculating and subtracting Mac sleep timers).
* **Cross-Platform Vision:** (Coming Soon) Support for Windows and Linux to ensure a unified time-tracking experience regardless of your OS.

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
   Make the installation script executable and run it. This will automatically configure the `launchd` plist with the absolute path to your cloned repository, place it in `~/Library/LaunchAgents/`, and start the background service.

   ```bash
   chmod +x install.sh
   ./install.sh
   ```

2. **Verify Logs:**
   The tracker logs its events to `~/scripts/logs/`. You can view the latest events to confirm it is working:
   
   ```bash
   tail -n 10 $(ls -t ~/scripts/logs/Log_*.txt | head -n 1)
   ```

## Timewarrior Integration

To use the automated gap synchronization with Timewarrior, you can add aliases to your shell configuration (e.g., `~/.bashrc` or `~/.zshrc`).

```bash
# Add these to your shell config, adjusting the path to where you cloned this repo
alias tw-end='~/projects/moose/moosetilities/session-tracker/scripts/tw_sync.py --end'
alias tw-begin='~/projects/moose/moosetilities/session-tracker/scripts/tw_sync.py --begin'
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

*Note: This will not delete your logged data in `~/scripts/logs/`.*
