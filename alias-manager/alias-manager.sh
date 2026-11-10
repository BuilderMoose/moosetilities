#!/usr/bin/env bash

a() {
    local alias_dir="$HOME/.config/mooseware/aliases.d"
    local style="${MOOSE_ALIAS_STYLE:-2}"
    local groups=()

    # Parse flags and groups
    while [ $# -gt 0 ]; do
        case "$1" in
            -1|-t|--table)
                style=1
                shift
                ;;
            -2|-s|--sections)
                style=2
                shift
                ;;
            -3|-c|--cards|--card)
                style=3
                shift
                ;;
            -h|--help)
                echo "Usage: a [-1|-2|-3] [group ...]"
                echo "  -1, -t, --table     Compact table style"
                echo "  -2, -s, --sections  Categorized sections (default)"
                echo "  -3, -c, --card      Card style"
                return 0
                ;;
            -*)
                echo -e "\033[31mError:\033[0m Unknown option: $1" >&2
                return 1
                ;;
            *)
                groups+=("$1")
                shift
                ;;
        esac
    done

    # If no argument, list available categories with formatting
    if [ ${#groups[@]} -eq 0 ]; then
        echo -e "\033[1;34mAvailable alias groups:\033[0m"
        local found=0
        local g
        for g in $(ls -1 "$alias_dir" 2>/dev/null | grep '\.sh$' | sed 's/\.sh$//'); do
            printf "  \033[36m•\033[0m \033[1m%s\033[0m\n" "$g"
            found=1
        done
        if [ "$found" -eq 0 ]; then
            echo -e "  \033[90m(no alias files found in $alias_dir)\033[0m"
        else
            echo ""
            echo -e "\033[90mUsage: a [-1|-2|-3] <group...>\033[0m"
        fi
        return 0
    fi

    local group
    for group in "${groups[@]}"; do
        local target="${alias_dir}/${group}.sh"
        if [ ! -f "$target" ]; then
            echo -e "\033[31mError:\033[0m No alias group found for '$group'." >&2
            return 1
        fi

        # Parse target file for aliases and functions, then render by selected style
        awk -v style="$style" -v group="$group" '
        BEGIN {
            alias_count = 0
            func_count = 0
            help = ""
            C_RESET = "\033[0m"
            C_BOLD  = "\033[1m"
            C_DIM   = "\033[90m"
            C_BLUE  = "\033[1;34m"
            C_CYAN  = "\033[36m"
            C_GREEN = "\033[32m"
        }

        # Capture help comments
        /^[[:space:]]*# HELP:/ {
            help = $0
            sub(/^[[:space:]]*# HELP: */, "", help)
            next
        }

        # Parse aliases: name and command
        /^[[:space:]]*alias / {
            line = $0
            sub(/^[[:space:]]*alias /, "", line)
            eq_idx = index(line, "=")
            if (eq_idx > 0) {
                name = substr(line, 1, eq_idx - 1)
                val = substr(line, eq_idx + 1)
                sub(/^[\x27\x22]/, "", val)
                sub(/[\x27\x22]$/, "", val)
            } else {
                name = line
                val = ""
            }
            alias_names[alias_count] = name
            alias_vals[alias_count] = val
            alias_helps[alias_count] = help
            alias_count++
            help = ""
            next
        }

        # Print functions and append the help string if it exists.
        # Excludes functions that start with an underscore (privacy rule).
        /^[[:space:]]*[a-zA-Z0-9][a-zA-Z0-9_-]*[[:space:]]*\(\)/ {
            name = $1
            sub(/\(\).*/, "", name)
            sub(/^[[:space:]]*/, "", name)
            func_names[func_count] = name "()"
            func_helps[func_count] = help
            func_count++
            help = ""
            next
        }

        # Reset help if non-comment code is encountered
        !/^[[:space:]]*#/ { help = "" }

        END {
            # Group banner
            printf "%s── %s[ %s ]%s ", C_DIM, C_BLUE, group, C_DIM
            for (i = length(group) + 7; i < 48; i++) printf "─"
            printf "%s\n", C_RESET

            if (style == 1) {
                # --- Style 1: Table ---
                max_len = 14
                for (i = 0; i < alias_count; i++) if (length(alias_names[i]) > max_len) max_len = length(alias_names[i])
                for (i = 0; i < func_count; i++)  if (length(func_names[i]) > max_len) max_len = length(func_names[i])
                fmt_a = sprintf("  %s%%-%ds%s  %%s\n", C_CYAN, max_len, C_RESET)
                fmt_f = sprintf("  %s%%-%ds%s  %%s\n", C_GREEN, max_len, C_RESET)

                for (i = 0; i < alias_count; i++) {
                    desc = alias_helps[i] ? alias_helps[i] : alias_vals[i]
                    printf fmt_a, alias_names[i], desc
                }
                for (i = 0; i < func_count; i++) {
                    desc = func_helps[i] ? func_helps[i] : (C_DIM "(function)" C_RESET)
                    printf fmt_f, func_names[i], desc
                }
            } else if (style == 2) {
                # --- Style 2: Categorized Sections (Default) ---
                if (alias_count > 0) {
                    printf "  %s%sALIASES%s\n", C_BOLD, C_DIM, C_RESET
                    max_len = 12
                    for (i = 0; i < alias_count; i++) if (length(alias_names[i]) > max_len) max_len = length(alias_names[i])
                    fmt = sprintf("    %s%%-%ds%s  %%s\n", C_CYAN, max_len, C_RESET)
                    for (i = 0; i < alias_count; i++) {
                        printf fmt, alias_names[i], alias_vals[i]
                        if (alias_helps[i]) printf "      %s# %s%s\n", C_DIM, alias_helps[i], C_RESET
                    }
                }
                if (func_count > 0) {
                    if (alias_count > 0) printf "\n"
                    printf "  %s%sFUNCTIONS%s\n", C_BOLD, C_DIM, C_RESET
                    max_len = 12
                    for (i = 0; i < func_count; i++) if (length(func_names[i]) > max_len) max_len = length(func_names[i])
                    fmt = sprintf("    %s%%-%ds%s  %%s\n", C_GREEN, max_len, C_RESET)
                    for (i = 0; i < func_count; i++) {
                        desc = func_helps[i] ? func_helps[i] : (C_DIM "(no description)" C_RESET)
                        printf fmt, func_names[i], desc
                    }
                }
            } else if (style == 3) {
                # --- Style 3: Cards ---
                for (i = 0; i < alias_count; i++) {
                    printf "  %s%s%s %s→%s %s\n", C_CYAN, alias_names[i], C_RESET, C_DIM, C_RESET, alias_vals[i]
                    if (alias_helps[i]) printf "    %s%s%s\n", C_DIM, alias_helps[i], C_RESET
                }
                for (i = 0; i < func_count; i++) {
                    printf "  %s%s%s\n", C_GREEN, func_names[i], C_RESET
                    if (func_helps[i]) printf "    %s%s%s\n", C_DIM, func_helps[i], C_RESET
                }
            }
            printf "\n"
        }
        ' "$target"
    done
}

# --- Tab Completion ---

if [ -n "$ZSH_VERSION" ]; then
    # Zsh completion logic
    _a_completions_zsh() {
        local alias_dir="$HOME/.config/mooseware/aliases.d"
        local -a available_groups used_groups flags
        flags=(-1 -2 -3 -t -s -c --table --sections --cards --card -h --help)
        local i
        available_groups=($(ls -1 "$alias_dir" 2>/dev/null | grep '\.sh$' | sed 's/\.sh$//'))
        for (( i=2; i <= ${#words[@]}; i++ )); do
            if (( i != CURRENT )); then
                used_groups+=("${words[i]}")
            fi
        done
        available_groups=(${available_groups:|used_groups})
        if [[ "$words[CURRENT]" == -* ]]; then
            compadd -a flags
        else
            compadd -a available_groups
        fi
    }
    compdef _a_completions_zsh a

elif [ -n "$BASH_VERSION" ]; then
    # Bash completion logic
    _a_completions() {
        local alias_dir="$HOME/.config/mooseware/aliases.d"
        local all_groups=$(ls -1 "$alias_dir" 2>/dev/null | grep '\.sh$' | sed 's/\.sh$//')
        local flags="-1 -2 -3 -t --table -s --sections -c --cards --card -h --help"
        local cur="${COMP_WORDS[COMP_CWORD]}"
        local remaining_groups=()
        local group used i

        if [[ "$cur" == -* ]]; then
            COMPREPLY=($(compgen -W "$flags" -- "$cur"))
            return 0
        fi

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

        COMPREPLY=($(compgen -W "${remaining_groups[*]}" -- "$cur"))
    }
    complete -F _a_completions a
fi
