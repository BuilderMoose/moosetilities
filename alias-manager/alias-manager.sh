#!/usr/bin/env bash

a() {
    local alias_dir="$HOME/.config/mooseware/aliases.d"
    
    # If no argument, list available categories (file names without .sh)
    if [ -z "$1" ]; then
        echo -e "\033[1mAvailable alias groups:\033[0m"
        ls -1 "$alias_dir" 2>/dev/null | grep '\.sh$' | sed 's/\.sh$//' | paste -sd ' ' -
        return 0
    fi

    local group
    for group in "$@"; do
        local target="${alias_dir}/${group}.sh"
        if [ ! -f "$target" ]; then
            echo "No alias group found for '$group'."
            return 1
        fi

        echo -e "\033[1m--- $group ---\033[0m"
        
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
            if (help) {
                printf "  %s\n      \033[36m%s\033[0m\n", help, line;
                help = ""
            } else {
                print "  " line 
            }
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
    done
}

# --- Tab Completion ---

if [ -n "$ZSH_VERSION" ]; then
    # Zsh completion logic
    _a_completions_zsh() {
        local alias_dir="$HOME/.config/mooseware/aliases.d"
        local -a available_groups used_groups
        local i
        available_groups=($(ls -1 "$alias_dir" 2>/dev/null | grep '\.sh$' | sed 's/\.sh$//'))
        for (( i=2; i <= ${#words[@]}; i++ )); do
            if (( i != CURRENT )); then
                used_groups+=("${words[i]}")
            fi
        done
        available_groups=(${available_groups:|used_groups})
        compadd -a available_groups
    }
    compdef _a_completions_zsh a

elif [ -n "$BASH_VERSION" ]; then
    # Bash completion logic
    _a_completions() {
        local alias_dir="$HOME/.config/mooseware/aliases.d"
        local all_groups=$(ls -1 "$alias_dir" 2>/dev/null | grep '\.sh$' | sed 's/\.sh$//')
        local remaining_groups=()
        local group used i

        for group in $all_groups; do
            used=0
            for (( i=1; i < ${#COMP_WORDS[@]}; i++ )); do
                if [ "$i" -ne "$COMP_CWORD" ] && [ "${COMP_WORDS[i]}" = "$group" ]; then
                    used=1
                    break
                fi
            done
            if [ "$used" -eq 0 ]; then
                remaining_groups+=("$group")
            fi
        done

        COMPREPLY=($(compgen -W "${remaining_groups[*]}" -- "${COMP_WORDS[COMP_CWORD]}"))
    }
    complete -F _a_completions a
fi
