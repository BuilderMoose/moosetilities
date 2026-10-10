#!/usr/bin/env python3

import os
import glob
import subprocess
import json
import argparse
from datetime import datetime, timedelta
import sys

LOG_DIR = os.path.expanduser("~/scripts/logs")

def run_tw(args):
    cmd = ["timew"] + args
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error running {' '.join(cmd)}:\n{result.stderr}")
        sys.exit(1)
    return result.stdout

def get_tw_data():
    try:
        tw_export = subprocess.run(["timew", "export"], capture_output=True, text=True)
        return json.loads(tw_export.stdout)
    except FileNotFoundError:
        print("Error: 'timew' command not found. Is Timewarrior installed and in your PATH?")
        sys.exit(1)
    except json.JSONDecodeError:
        return []

def get_latest_log():
    log_files = glob.glob(os.path.join(LOG_DIR, "Log_*.txt"))
    if not log_files:
        print(f"Error: No log files found in {LOG_DIR}")
        sys.exit(1)
    return max(log_files, key=os.path.getmtime)

def get_mac_sleep_timer_minutes():
    try:
        result = subprocess.run(["pmset", "-g"], capture_output=True, text=True)
        for line in result.stdout.split('\n'):
            line = line.strip()
            if line.startswith("sleep ") or line.startswith("sleep\t"):
                parts = line.split()
                if len(parts) >= 2:
                    return int(parts[1])
    except Exception as e:
        print(f"Warning: Could not read pmset sleep timer: {e}")
    return 0

def get_event_time(event_type, latest_log):
    last_event_time_str = None
    with open(latest_log, 'r') as f:
        for line in f:
            if event_type in line:
                last_event_time_str = line.split()[0]
    
    if last_event_time_str:
        try:
            return datetime.fromisoformat(last_event_time_str)
        except ValueError:
            print(f"Error: Log timestamp {last_event_time_str} is not in ISO format.")
            sys.exit(1)
    return None

def get_lock_time(latest_log):
    last_locked = get_event_time("STATUS: LOCKED", latest_log)
    last_sleep = get_event_time("STATUS: ABOUT TO SLEEP", latest_log)
    
    event_time = None
    if last_locked and last_sleep:
        event_time = max(last_locked, last_sleep)
    else:
        event_time = last_locked or last_sleep
        
    if not event_time:
        return None

    if event_time == last_sleep and (not last_locked or last_sleep > last_locked):
        sleep_mins = get_mac_sleep_timer_minutes()
        if sleep_mins > 0:
            print(f"Detected sleep event. Subtracting Mac sleep timer ({sleep_mins} mins) from lock time...")
            event_time = event_time - timedelta(minutes=sleep_mins)

    return event_time

def handle_end():
    latest_log = get_latest_log()
    
    event_time = get_lock_time(latest_log)
    if not event_time:
        print("Error: Could not find LOCKED or ABOUT TO SLEEP in the latest log.")
        sys.exit(1)

    tw_data = get_tw_data()
    if not tw_data or "end" in tw_data[-1]:
        print("No active Timewarrior segment to stop.")
        return

    now = datetime.now()
    if event_time.date() != now.date():
        print(f"Error: The end event did not occur today ({now.date()}).")
        sys.exit(1)

    end_time_str = event_time.strftime("%Y-%m-%dT%H:%M:%S")
    print(f"Stopping active segment at {end_time_str}...")
    run_tw(["stop", end_time_str])
    print("Done.")

def handle_begin():
    latest_log = get_latest_log()
    last_unlocked = get_event_time("STATUS: UNLOCKED", latest_log)

    if not last_unlocked:
        print("Error: Could not find UNLOCKED in the latest log.")
        sys.exit(1)

    now = datetime.now()
    if last_unlocked.date() != now.date():
        print(f"Error: The unlock event did not occur today ({now.date()}).")
        sys.exit(1)

    tw_data = get_tw_data()
    
    begin_time_str = last_unlocked.strftime("%Y-%m-%dT%H:%M:%S")

    if tw_data and "end" not in tw_data[-1]:
        # There's an active segment. Let's try to close it at the lock time.
        lock_time = get_lock_time(latest_log)
        
        if lock_time and lock_time <= last_unlocked:
            stop_time_str = lock_time.strftime("%Y-%m-%dT%H:%M:%S")
            print(f"Active segment detected. Stopping it at lock time {stop_time_str}...")
            run_tw(["stop", stop_time_str])
        else:
            # Fallback if no lock time is found, or it's invalid/later than unlock
            print(f"Active segment detected but no valid lock time found. Stopping it at unlock time {begin_time_str}...")
            run_tw(["stop", begin_time_str])

    print(f"Starting new segment at {begin_time_str}...")
    run_tw(["start", begin_time_str])
    print("Done.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Timewarrior gap sync tool")
    parser.add_argument("--end", action="store_true", help="Stop current segment at lock/sleep time")
    parser.add_argument("--begin", action="store_true", help="Start new segment at unlock time")
    args = parser.parse_args()

    if args.end:
        handle_end()
    elif args.begin:
        handle_begin()
    else:
        print("Please specify --end or --begin")
