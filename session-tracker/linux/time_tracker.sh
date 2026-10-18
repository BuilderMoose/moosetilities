#!/usr/bin/env bash

# ==============================================================
# time_tracker.sh
#
# Monitors screen lock/unlock events and logs them to both
# the console and a timestamped log file.
#
# USAGE:
#   ./time_tracker.sh [LOG_DIR]
#
#   LOG_DIR defaults to ~/.config/mooseware/logs if not provided.
#
# MANUAL TIMESTAMP:
#   Send SIGUSR1 to the running process:
#     kill -USR1 <PID>
#   The PID is printed on startup.
#
# STOP:
#   Ctrl+C  or  kill <PID>
#
# LOCK DETECTION:
#   Uses `loginctl` (systemd-logind), which works on most modern
#   Linux desktops — GNOME, KDE, XFCE, etc.
#   Falls back to a GNOME screensaver D-Bus query if loginctl
#   cannot determine the state (e.g. no XDG_SESSION_ID set).
# ==============================================================


# ==========================================
# CONFIGURATION
# ==========================================

LOG_DIR="${1:-$HOME/.config/mooseware/logs}"


# ==========================================
# GLOBAL STATE
# ==========================================

IS_LOCKED=false
LOG_FILE=""
MONITOR_PID=""


# ==========================================
# LOGGING
# ==========================================

initialize_logging() {
    mkdir -p "$LOG_DIR" || exit 1
    local startup_ts
    startup_ts=$(date '+%Y%m%d_%H%M%S')
    LOG_FILE="$LOG_DIR/Log_${startup_ts}.txt"
    touch "$LOG_FILE" || exit 1
}

# Writes a timestamped message to both stdout and the log file.
# Writes a timestamped message to both the local text file and systemd
write_log() {
    local message="$1"
    local type="${2:-INFO}" # Default to INFO if not specified
    local ts
    ts=$(date '+%Y-%m-%dT%H:%M:%S')
    
    # 1. Write to your custom text log file
    echo "$ts [$type] - $message" >> "$LOG_FILE"
    
    # 2. Print to stdout/stderr so systemd journald can capture it cleanly
    if [ "$type" = "ERROR" ]; then
        echo "[$type] $message" >&2
    else
        echo "[$type] $message"
    fi
}


# ==========================================
# LOCK DETECTION
# ==========================================

# Returns the current user's systemd session ID.
# get_session_id() {
#     # Prefer the env var stamped by PAM/systemd on login
#     if [ -n "${XDG_SESSION_ID:-}" ]; then
#         echo "$XDG_SESSION_ID"
#         return 0
#     fi
#
#     # Fall back: find the first session belonging to this user
#     loginctl list-sessions --no-legend 2>/dev/null \
#         | awk -v user="$(whoami)" '$3 == user { print $1; exit }'
# }

get_session_id() {
    # Prefer the env var stamped by PAM/systemd on login (most reliable)
    if [ -n "${XDG_SESSION_ID:-}" ]; then
        echo "$XDG_SESSION_ID"
        return 0
    fi

    # Fall back: find a graphical (non-TTY) session for this user
    loginctl list-sessions --no-legend 2>/dev/null \
        | awk -v user="$USER" '
            $3 == user {
                cmd = "loginctl show-session " $1 " -p Type --value 2>/dev/null"
                cmd | getline stype
                close(cmd)
                if (stype == "x11" || stype == "wayland") {
                    print $1
                    exit
                }
            }'
}

# Returns 0 (true) when the screen is locked, 1 (false) otherwise.
test_system_locked() {
    # --- Primary: loginctl LockedHint (systemd-logind) ---
    local session_id
    session_id=$(get_session_id)

    if [ -n "$session_id" ]; then
        local locked_hint
        locked_hint=$(loginctl show-session "$session_id" \
            -p LockedHint --value 2>/dev/null || echo "no")

        # loginctl responded — trust its answer and return
        [ "$locked_hint" = "yes" ]
        return
    fi

    # --- Fallback: GNOME screensaver via D-Bus ---
    if command -v gdbus &>/dev/null; then
        local active
        active=$(gdbus call --session \
            --dest org.gnome.ScreenSaver \
            --object-path /org/gnome/ScreenSaver \
            --method org.gnome.ScreenSaver.GetActive 2>/dev/null \
            | grep -o 'true' || echo "false")
        [ "$active" = "true" ]
        return
    fi

    # Cannot determine state — assume unlocked
    return 1
}


# ==========================================
# SIGNAL HANDLERS
# ==========================================

handle_manual_log() {
    write_log "USER ACTION: Manual timestamp."
}

handle_exit() {
    echo ""
    if [ -n "$MONITOR_PID" ]; then
        kill "$MONITOR_PID" 2>/dev/null
    fi
    write_log "SESSION END"
    exit 0
}


# ==========================================
# MAIN
# ==========================================

initialize_logging

echo "-------------------------------------"
echo " Screen Lock Monitor Started"
echo "-------------------------------------"
echo " Log File : $LOG_FILE"
echo " PID      : $$"
echo ""
echo " Lock/unlock events are logged automatically."
echo " Manual timestamp : kill -USR1 $$"
echo " Stop             : Ctrl+C"
echo "-------------------------------------"
echo ""

write_log "SESSION START"

# Register signal handlers
trap 'handle_manual_log' USR1
trap 'handle_exit'       INT TERM

# Initialize current lock state
if test_system_locked; then
    IS_LOCKED=true
fi

# Event-driven monitoring via systemd-logind D-Bus signals
# Using process substitution on FD 3 with `read` allows USR1/INT/TERM traps to be handled cleanly.
exec 3< <(gdbus monitor --system --dest org.freedesktop.login1 2>/dev/null)
MONITOR_PID=$!

while true; do
    if read -r line <&3; then
        # Detect system sleep / suspend (matches macOS "STATUS: ABOUT TO SLEEP")
        if [[ "$line" == *"PrepareForSleep (true)"* ]]; then
            write_log "STATUS: ABOUT TO SLEEP"

        # Detect LOCK transition (manual lock or idle timeout lock)
        elif [[ "$line" == *"'LockedHint': <true>"* || "$line" == *".Lock ()"* ]]; then
            if [[ "$IS_LOCKED" == "false" ]]; then
                IS_LOCKED=true
                write_log "STATUS: LOCKED"
            fi

        # Detect UNLOCK transition
        elif [[ "$line" == *"'LockedHint': <false>"* || "$line" == *".Unlock ()"* ]]; then
            if [[ "$IS_LOCKED" == "true" ]]; then
                IS_LOCKED=false
                write_log "STATUS: UNLOCKED"
            fi
        fi
    else
        # If read was interrupted by a signal (like SIGUSR1), continue reading if monitor is still alive
        if ! kill -0 "$MONITOR_PID" 2>/dev/null; then
            break
        fi
    fi
done
