# -------------------------------------------------------------------
# Core Timewarrior Aliases
# -------------------------------------------------------------------
alias tw='timew'
alias tws='tw summary :annotation :ids'
alias tws-week='tws :week'
alias tws-month='tws :month'
alias twy='tws :yesterday; tws'
alias twd='clear;tw day;tws'
alias tww='clear;tw week;tws'
alias twm='clear;tw month'
alias twj='tw join @1 @2'
alias twc='tw continue'
alias twt='tw tag'
alias twan='tw annotate'

# --- Allocation & Projection ---
alias twa='tw allocated :month'
alias twla='tw allocated :lastmonth'
alias twp='tw projected :month'
alias twlp='tw projected :lastmonth'

# --- Date/Time & Script Execution ---
alias tw-now='TZ=UTC date +%Y%m%dT%H%M%SZ'
alias tw-adj='tw-now --date'
alias tw-rsync='rsync -r "$HOME/.timewarrior/" "$HOME/Historical/Backup/TimeTracking/TimeWarrior/2026/"'

# Executes the custom Python script to parse locked/unlocked logs and insert breaks
alias tw-end='$HOME/.config/mooseware/bin/tw_sync.py --end'
alias tw-begin='$HOME/.config/mooseware/bin/tw_sync.py --begin'
alias tw-addbreak='$HOME/.config/mooseware/bin/tw_sync.py --break'

# -------------------------------------------------------------------
# Functions
# -------------------------------------------------------------------

# HELP: Displays the last N lines (default 10) across the most recent lock/unlock log files
locklogs() {
    local count="${1:-10}"
    if ! [[ "$count" =~ ^[0-9]+$ ]] || [ "$count" -le 0 ]; then
        echo "Usage: locklogs [count] (count must be a positive integer)"
        return 1
    fi

    local -a files
    files=($(ls -1 "$HOME"/.config/mooseware/logs/Log_*.txt 2>/dev/null | tail -n "$count"))

    if [ "${#files[@]}" -gt 0 ]; then
        echo -e "=== Last $count log entries ===\n"
        cat "${files[@]}" | tail -n "$count"
    else
        echo "No log files found."
    fi
}

# HELP: Starts a 'Conversation' timewarrior entry and annotates it with the provided name
Conversation () {
    if [ "$1" = "help" ]; then
        echo "Usage: Conversation <name>"
        return 0
    fi

    tw start Conversation
    twan "$1"
}

# HELP: Retags a target entry with the tags from a source entry (e.g., twr @1 @4)
twr() {
    if [[ -z "$1" || -z "$2" ]]; then
        echo "Retag an entry with the tags from another entry"
        echo "Usage: twr <target_id> <source_id> (e.g., twr @1 @4)"
        return 1
    fi

    local target_id="${1#@}"
    local source_id="${2#@}"
    local source_tags

    source_tags=$(timew get "dom.tracked.${source_id}.tags")

    if [[ -z "$source_tags" ]]; then
        echo "Error: No tags found on source interval @${source_id}."
        return 1
    fi

    # xargs natively parses the literal quotes in the string and groups the words
    # properly before passing them to timew.
    echo "$source_tags" | xargs timew retag "@${target_id}"

    echo "Successfully applied tags [ $source_tags ] to @${target_id}"
}

# HELP: Internal month calculator; maps names to numbers and handles year boundaries
_tw_month_logic() {
    local month_input=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    local action=$2
    shift 2

    case "$month_input" in
        january|jan)   m=01 ;;
        february|feb)  m=02 ;;
        march|mar)     m=03 ;;
        april|apr)     m=04 ;;
        may)           m=05 ;;
        june|jun)      m=06 ;;
        july|jul)      m=07 ;;
        august|aug)    m=08 ;;
        september|sep) m=09 ;;
        october|oct)   m=10 ;;
        november|nov)  m=11 ;;
        december|dec)  m=12 ;;
        *) echo "Error: Invalid month name"; return 1 ;;
    esac

    local cur_m=$(date +%m)
    local cur_y=$(date +%Y)
    local start_y=$cur_y
    
    # If the requested month is >= current month, assume it happened LAST year
    if [ "$m" -ge "$cur_m" ]; then
        start_y=$((cur_y - 1))
    fi

    local start_date="$start_y-$m-01"
    local end_m=$((10#$m + 1))
    local end_y=$start_y

    if [ "$end_m" -eq 13 ]; then
        end_m="01"
        end_y=$((start_y + 1))
    else
        end_m=$(printf "%02d" $end_m)
    fi

    local end_date="$end_y-$end_m-01"

    echo "Running: timew $action $start_date - $end_date $@"
    timew "$action" "$start_date" - "$end_date" "$@"
}

# HELP: Views Timewarrior data for a specific month (e.g., tw-view-month april)
tw-view-month() { _tw_month_logic "$1" "month"; }

# HELP: Exports Timewarrior data to JSON for a specific month
tw-export-month() { _tw_month_logic "$1" "Tee"; }

# HELP: Summarizes Timewarrior data for a specific month, accepts extra filters
tw-summary-month() { _tw_month_logic "$1" "summary" "${@:2}"; }

# HELP: Shows allocated time for a specific month
twa-month() { _tw_month_logic "$1" "allocated"; }

# HELP: Shows projected time for a specific month
twp-month() { _tw_month_logic "$1" "projected"; }