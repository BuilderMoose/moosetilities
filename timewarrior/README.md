# Timewarrior Integrations

A collection of shell aliases, helper functions, and automated gap-synchronization scripts designed to supercharge [Timewarrior](https://timewarrior.net/) alongside the Moosetilities [Alias Manager](../alias-manager/) and [Session Tracker](../session-tracker/).

## Repository Structure

```text
.
├── install.sh             # Installs scripts and aliases into ~/.config/mooseware/
├── uninstall.sh           # Removes installed Timewarrior helper scripts
├── README.md              # This file
├── aliases/
│   └── timewarrior.sh     # Timewarrior shell aliases and documented helper functions
└── scripts/
    └── tw_sync.py         # Timewarrior gap sync tool (tw-end / tw-begin)
```

## Setup & Installation

Run the installer directly (or run the top-level `setup.sh` in the repository root):

```bash
chmod +x install.sh
./install.sh
```

For developers/forkers who want symlinks back to this repository instead of physical copies:

```bash
./install.sh --use-links
```

## Timewarrior Gap Synchronization (`tw_sync.py`)

When paired with the [Session Tracker](../session-tracker/), `tw_sync.py` reads your lock, unlock, and sleep events in `~/.config/mooseware/logs/` to automatically manage away-from-desk time gaps.

> **Tip:** If you are using the Moosetilities **Alias Manager**, the `tw-end`, `tw-begin`, and `tw-addbreak` aliases are already pre-configured for you in `aliases/timewarrior.sh`.

To use automated gap synchronization without the Alias Manager, add these aliases to your shell configuration (`~/.bashrc` or `~/.zshrc`):

```bash
alias tw-end='$HOME/.config/mooseware/bin/tw_sync.py --end'
alias tw-begin='$HOME/.config/mooseware/bin/tw_sync.py --begin'
alias tw-addbreak='$HOME/.config/mooseware/bin/tw_sync.py --break'
```

### How to use `tw-begin`, `tw-addbreak`, and `tw-end`:

1. **Walking Away:** When you leave your desk, simply lock your screen.
2. **Returning — Untracked Gap (`tw-begin`):** When you return and unlock your computer, run `tw-begin`.
   - **Smart Start:** `tw-begin` finds your unlock time, checks if you left a Timewarrior segment running, and safely stops that previous segment at the exact moment you locked the screen (or the calculated sleep time) before starting a new segment at the unlock time.
3. **Returning — Tagged Break (`tw-addbreak`):** If you want the away time recorded as a `break` interval rather than an empty gap, run `tw-addbreak`.
   - Verifies your active segment started before the lock time, stops it at the lock time, inserts a `break`-tagged interval from lock to unlock, and starts a new untagged segment at the unlock time.
4. **End of Day (`tw-end`):** To stop tracking for the day without starting a new task, run `tw-end`. It stops your active segment at your last lock/sleep time.
