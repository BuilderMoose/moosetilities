# Modular Bash Alias Manager

A scalable, modular system for managing Bash and Zsh aliases and functions. This setup prevents `.bashrc`/`.zshrc` bloat by utilizing a `.d` drop-in directory structure (`~/.config/bash/aliases.d/`). It allows aliases to be categorized by purpose, version-controlled easily, and explored dynamically using a built-in help tool.

## Features

* **Modular Design:** Aliases are separated into purpose-specific files (e.g., `timewarrior.sh`, `core.sh`, `toys.sh`).
* **Dynamic Autoloader:** Sourcing a single directory automatically loads all your alias groups.
* **The `a` Command:** A built-in utility to list your aliases by category.
* **Tab Completion:** Type `a <TAB>` to see available alias groups, or auto-complete a specific group name. Works natively in both Bash and Zsh.
* **Function Documentation:** Extracts `# HELP:` comments above your functions to display clean documentation in the terminal.
* **Privacy Rule:** Silently ignores any functions that begin with an underscore (e.g., `_helper_function()`), treating them as private/internal.

## Repository Structure

```text
.
├── install.sh             # Creates symlinks from this repo to ~/.config/bash/
├── alias-manager.sh       # Contains the 'a' function and cross-shell tab completion logic
└── aliases.d/             # Drop-in directory for alias files
    ├── timewarrior.sh     # Concrete example: Time tracking aliases and functions
    └── example.sh         # Basic template demonstrating OS checks
```

## Setup & Installation

1. **Run the Installer:**
   Make the installation script executable and run it. This will create absolute symlinks from your repository directly into `~/.config/bash/`.

   ```bash
   chmod +x install.sh
   ./install.sh
   ```

2. **Update your shell configuration:**
   Add the autoloader snippet to your shell's configuration file. This loads the manager and loops through your categorized aliases.

   **For Bash (`~/.bashrc` or `~/.bash_profile`):**
   ```bash
   # 1. Load the alias manager function and its tab completion
   if [ -f "$HOME/.config/bash/alias-manager.sh" ]; then
       source "$HOME/.config/bash/alias-manager.sh"
   fi
   
   # 2. Automatically load all purpose-specific alias files
   if [ -d "$HOME/.config/bash/aliases.d" ]; then
       for f in "$HOME"/.config/bash/aliases.d/*.sh; do
           [ -r "$f" ] && source "$f"
       done
   fi
   ```

   **For Zsh (`~/.zshrc`):**
   *Note: Ensure this snippet is placed somewhere AFTER your completion engine initializes (e.g., after `autoload -Uz compinit && compinit`).*
   ```zsh
   # 1. Load the cross-compatible alias manager function
   if [ -f "$HOME/.config/bash/alias-manager.sh" ]; then
       source "$HOME/.config/bash/alias-manager.sh"
   fi
   
   # 2. Automatically load all purpose-specific alias files
   if [ -d "$HOME/.config/bash/aliases.d" ]; then
       for f in "$HOME"/.config/bash/aliases.d/*.sh; do
           [ -r "$f" ] && source "$f"
       done
   fi
   ```

3. **Reload your shell:**
   ```bash
   source ~/.bashrc   # Or source ~/.zshrc if using Zsh
   ```

## How to Add or Modify Aliases

Take a look at the included `aliases.d/timewarrior.sh` for a robust, real-world example of how to structure your custom tools!

### Adding Standard Aliases
Simply open the relevant file in the `aliases.d/` directory (or create a new `.sh` file) and add your alias. For example, from `timewarrior.sh`:
```bash
alias tw='timew'
alias tws='tw summary :annotation :ids'
```

### Adding Documented Functions
To include a shell function and ensure it shows up when you run the `a <category>` command (e.g., `a timewarrior`), place a `# HELP:` comment directly above the function definition:
```bash
# HELP: Views Timewarrior data for a specific month (e.g., tw-view-month april)
tw-view-month() { _tw_month_logic "$1" "month"; }
```

### Adding Internal/Hidden Functions
If you have a complex script that requires helper functions, just prefix the function name with an underscore. The `a` command's privacy rule will automatically hide it from the help output so your terminal stays clean. 

For instance, in `timewarrior.sh`, the underlying logic function is hidden:
```bash
# This function won't be displayed when running 'a timewarrior'
_tw_month_logic() {
    local month_input=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    # ... logic ...
}
```

### Adding New Categories
If you create a completely new file (e.g., `docker.sh`), run `./install.sh` again to symlink the new file into your `~/.config/bash/aliases.d/` directory, then reload your shell. It will automatically be picked up by the `a` command's tab completion.

## Uninstallation

To remove the symlinks from your `~/.config/bash/` directory, simply run the uninstall script:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

Then, remove the autoload snippet you added to your `~/.bashrc` or `~/.zshrc`.
