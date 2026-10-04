#!/usr/bin/env bash

a() {
    local alias_dir="$HOME/.config/bash/aliases.d"
    
    # If no argument, list available categories (file names without .sh)
    if [ -z "$1" ]; then
        echo -e "\033[1mAvailable alias groups:\033[0m"
        ls -1 "$alias_dir" 2>/dev/null | grep '\.sh$' | sed 's/\.sh$//' | column
        return 0
    fi

    local target="${alias_dir}/${1}.sh"
    if [ ! -f "$target" ]; then
        echo "No alias group found for '$1'."
        return 1
    fi

    echo -e "\033[1m--- $1 ---\033[0m"
    
    # Parse the target file for aliases and documented functions, ignoring leading spaces
    awk '
    # Capture the help string
    /^[[:space:]]*# HELP:/ { 
        help = $0; 
        sub(/^[[:space:]]*# HELP: */, "", help) 
    }
    
    # Print aliases with formatting
    /^[[:space:]]*alias / { 
        line = $0;
        sub(/^[[:space:]]*alias /, "", line);
        print "  " line 
    }
    
    # Print functions and append the help string if it exists.
    # Excludes functions that start with an underscore (privacy rule).
    /^[[:space:]]*[a-zA-Z0-9][a-zA-Z0-9_-]*[[:space:]]*\(\)/ { 
        name = $1; 
        sub(/\(\)/, "", name); 
        if (help) { 
            printf "  \033[36m%s()\033[0m - %s\n", name, help; 
            help = "" 
        } else { 
            printf "  \033[36m%s()\033[0m\n", name 
        }
    }
    ' "$target"
}

# --- Tab Completion ---

if [ -n "$ZSH_VERSION" ]; then
    # Zsh completion logic
    _a_completions_zsh() {
        local alias_dir="$HOME/.config/bash/aliases.d"
        local -a available_groups
        available_groups=($(ls -1 "$alias_dir" 2>/dev/null | grep '\.sh$' | sed 's/\.sh$//'))
        compadd -a available_groups
    }
    compdef _a_completions_zsh a

elif [ -n "$BASH_VERSION" ]; then
    # Bash completion logic
    _a_completions() {
        local alias_dir="$HOME/.config/bash/aliases.d"
        local available_groups=$(ls -1 "$alias_dir" 2>/dev/null | grep '\.sh$' | sed 's/\.sh$//')
        COMPREPLY=($(compgen -W "$available_groups" -- "${COMP_WORDS[1]}"))
    }
    complete -F _a_completions a
fi
