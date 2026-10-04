#!/usr/bin/env bash

# This is an example alias file for moosetilities.
# It demonstrates standard aliases, documented functions, hidden functions, and OS checks.

# Standard alias for listing files
alias ll='ls -la'

# OS-specific aliases
if [ "$(uname)" = "Darwin" ]; then
    alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'
else
    alias flushdns='sudo systemd-resolve --flush-caches'
fi

# HELP: Displays a scholarly moose greeting
moose_greet() {
    echo "Greetings! I am the scholarly moose. 🦌📚"
}

# A hidden, internal helper function (ignored by the 'a' command because it starts with an underscore)
_hidden_helper() {
    echo "This is a secret, internal function. It won't be listed by 'a example'."
}

# HELP: Calculates the size of a directory
dir_size() {
    local target="${1:-.}"
    du -sh "$target"
}
