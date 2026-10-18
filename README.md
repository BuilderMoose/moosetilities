# moosetilities 🦌📚

The BuilderMoose toolkit: custom shell configurations, everyday command-line knick-knacks, and time-tracking scripts for the highly organized scholarly moose.

## Setup & Architecture

Moosetilities strictly separates the **Core Engine** (the scripts in this repository) from your **Personal Customizations**. 

By running the top-level setup script, Moosetilities will initialize a master configuration directory at `~/.config/mooseware/`:

```bash
chmod +x setup.sh
./setup.sh
```

**The `~/.config/mooseware/` Paradigm:**
This directory is your personal sandbox. The Alias Manager will look for your custom scripts in `~/.config/mooseware/aliases.d/`, and the Session Tracker will write its logs to `~/.config/mooseware/logs/`. 
You are highly encouraged to run `git init` inside `~/.config/mooseware/` and turn it into your own private dotfiles repository, allowing you to sync your customizations across all your computers while keeping the core Moosetilities engine perfectly generic!

## Repository Structure (The Toolbox)

Each tool in this repository is self-contained in its own directory:

- **[`alias-manager/`](alias-manager/)**: A modular Bash/Zsh alias management system. Prevents `.bashrc` bloat by allowing you to categorize aliases and functions into drop-in files, complete with an interactive autoloader and tab completion.
- **[`session-tracker/`](session-tracker/)**: A cross-platform, background session monitor that captures screen lock, unlock, and sleep events to `~/.config/mooseware/logs/`.
- **[`timewarrior/`](timewarrior/)**: Timewarrior aliases, helper functions, and automated gap-synchronization scripts (`tw_sync.py`) that integrate with `alias-manager` and `session-tracker`.
- _(More tools coming soon: C++ utilities like `moosecount`, Timewarrior hooks, and various terminal toys)_

## License

This project is licensed under the [MIT License](LICENSE).
