# Changelog

## 0.1.1

### Changed

- **Alias Manager (`alias-manager/alias-manager.sh`)**:
  - Updated `a` default group listing to use single-space separation instead of padded columns.
  - Updated `a` to accept and display multiple alias groups in a single invocation.
  - Enhanced Bash and Zsh tab completion (`_a_completions` and `_a_completions_zsh`) to support completing multiple groups while filtering out already-selected arguments.
- **Timewarrior Integrations (`timewarrior/scripts/tw_sync.py`)**:
  - Added `SESSION START` fallback in `--begin` and `--break` so sessions can be started immediately after a reboot before any lock/unlock cycle occurs.
  - Added `SESSION END` detection and previous-log fallback for lock/sleep timestamps across mid-day reboots.
  - Added guards in `--begin` to prevent auto-closing unclosed segments from previous days or stopping an active segment before its start time.

## 0.1.0

Initial release of the Moosetilities toolkit: a modular Bash/Zsh alias manager, an event-driven screen lock and sleep session tracker for macOS and Linux, and automated Timewarrior gap-synchronization utilities.

### Added

- **XDG Architecture (`~/.config/mooseware/`)**: Centralized sandbox for user customizations (`aliases.d/`), compiled/helper executables (`bin/`), and session logs (`logs/`), orchestrated by the root `setup.sh` script.
- **Alias Manager (`alias-manager/`)**:
  - Modular drop-in alias and function loader (`alias-manager.sh`) for Bash and Zsh.
  - Interactive `a` discovery command with `# HELP:` comment extraction, `_`-prefixed private function filtering, and cross-shell tab completion.
  - Safe copy-by-default installer (`install.sh`) with `--use-links` symlink mode and auto-detection of previous symlink installs.
- **Session Tracker (`session-tracker/`)**:
  - **macOS (`SessionTracker.swift`)**: Native compiled Swift daemon listening to `NSWorkspace` and `DistributedNotificationCenter` events, managed via `launchd` (`com.user.sessiontracker.plist`).
  - **Linux (`time_tracker.sh`)**: Event-driven Bash monitor listening to `systemd-logind` (`org.freedesktop.login1`) D-Bus signals for lock, unlock, and sleep events, managed via a `systemd` user service (`session-tracker.service`).
- **Timewarrior Integrations (`timewarrior/`)**:
  - `tw_sync.py`: Automated Timewarrior interval synchronization from session logs supporting `--begin` (`tw-begin`), `--end` (`tw-end`), and `--break` (`tw-addbreak`).
  - `timewarrior.sh`: Timewarrior aliases and helper functions including `twr` (safe interval retagging via `xargs`), `Conversation`, `locklogs`, and monthly report helpers (`tw-view-month`, `tw-summary-month`, `twa-month`, `twp-month`).
