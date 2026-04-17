#!/bin/bash
# orch_watchdog.sh — Watchdog for single book hermes
# Called by systemd timer every 5 minutes
# Checks if hermes is alive AND active in tmux session, restarts if dead/stuck
# After restart, automatically injects the work prompt
#
# Priority order:
#   1. Check if hermes is at an idle prompt → kick immediately
#   2. Check if output hasn't changed for MAX_IDLE_MINUTES → kick
#   3. Check if heartbeat is stale (> MAX_HEARTBEAT_AGE) → deep check
#   4. All good → update tracking and exit

SESSION="book-orch"
HERMES_CMD="hermes -p book chat --yolo"
WORKDIR="/home/ubuntu/agent-orchestration-book"
HEARTBEAT_FILE="/tmp/agent_orchestration_book_orch_heartbeat"
ACTIVITY_FILE="/tmp/agent_orchestration_book_orch_last_activity"
MAX_HEARTBEAT_AGE=600   # 10 minutes — heartbeat staleness threshold
MAX_IDLE_MINUTES=15     # 15 minutes no output change = stuck
KICK_MSG="Read SPRINT.md and BOOK_QUALITY_RULES.md, then continue your current iteration: crawl -> extract insights -> 6-gate review -> inject into weakest chapters -> commit+push. If no baseline scores exist, score all 15 chapters first."

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

# --- Helper: reset tracking files after kick/restart ---
reset_tracking() {
    local now=$(date +%s)
    local hash=$(tmux capture-pane -t "$SESSION" -p 2>/dev/null | md5sum | awk '{print $1}')
    echo -e "${hash}\n${now}" > "$ACTIVITY_FILE"
    date +%s > "$HEARTBEAT_FILE"
}

# --- Helper: send kick and reset ---
do_kick() {
    local reason="$1"
    log "KICK: $reason"
    tmux send-keys -t "$SESSION" "$KICK_MSG" Enter
    reset_tracking
    log "Kick sent, tracking reset"
    exit 0
}

# --- Helper: restart hermes in session ---
do_restart() {
    local reason="$1"
    log "RESTART: $reason"
    if ! tmux has-session -t "=$SESSION" 2>/dev/null; then
        tmux new-session -d -s "$SESSION" -c "$WORKDIR"
    else
        tmux send-keys -t "$SESSION" C-c 2>/dev/null
        sleep 2
    fi
    sleep 3
    tmux send-keys -t "$SESSION" "$HERMES_CMD" Enter
    sleep 15
    tmux send-keys -t "$SESSION" "$KICK_MSG" Enter
    reset_tracking
    log "Hermes restarted + kicked in session '$SESSION'"
    exit 0
}

# --- Check 1: Is tmux session alive? ---
if ! tmux has-session -t "=$SESSION" 2>/dev/null; then
    do_restart "Session '$SESSION' not found"
fi

# --- Check 2: Is hermes process running? ---
pane_pid=$(tmux list-panes -t "$SESSION" -F '#{pane_pid}' 2>/dev/null | head -1)
if [ -z "$pane_pid" ]; then
    do_restart "Cannot get pane PID for session '$SESSION'"
fi

hermes_running=false
if pstree -p "$pane_pid" 2>/dev/null | grep -qE "hermes"; then
    hermes_running=true
fi

# --- Check 3: Is hermes at an idle prompt? (highest priority detection) ---
# When hermes is active (generating/thinking), tmux shows "type a message + Enter to interrupt"
# When hermes is idle at prompt, that line is GONE — only "profilename ❯" remains
# This is the most reliable signal
pane_output=$(tmux capture-pane -t "$SESSION" -p 2>/dev/null)
type_a_msg_count=$(echo "$pane_output" | grep -c 'type a message')
if [ "$type_a_msg_count" -eq 0 ]; then
    # No "type a message" = hermes is NOT in an active generation cycle = IDLE
    do_kick "Hermes at idle prompt (no 'type a message' indicator)"
fi

# --- Check 4: Activity tracking (hash-based idle detection) ---
current_hash=$(echo "$pane_output" | md5sum | awk '{print $1}')
now=$(date +%s)

if [ -f "$ACTIVITY_FILE" ]; then
    prev_hash=$(head -1 "$ACTIVITY_FILE")
    prev_ts=$(tail -1 "$ACTIVITY_FILE")
    if [ "$current_hash" = "$prev_hash" ]; then
        # Output unchanged since last check
        idle_seconds=$((now - prev_ts))
        idle_minutes=$((idle_seconds / 60))
        if [ $idle_minutes -ge $MAX_IDLE_MINUTES ]; then
            if $hermes_running; then
                do_kick "Hermes STUCK — no output change for ${idle_minutes} minutes"
            else
                do_restart "Hermes not running and no output for ${idle_minutes} minutes"
            fi
        else
            log "Hermes idle ${idle_minutes}min (hash unchanged, threshold=${MAX_IDLE_MINUTES}min) — waiting"
            # Don't exit here — continue to heartbeat check
        fi
    else
        # Output changed — hermes is active
        echo -e "$current_hash\n$now" > "$ACTIVITY_FILE"
        date +%s > "$HEARTBEAT_FILE"
        log "Hermes active (output changed), tracking updated"
        exit 0
    fi
else
    # First run — just record state
    echo -e "$current_hash\n$now" > "$ACTIVITY_FILE"
    log "Activity tracker initialized"
fi

# --- Check 5: Heartbeat staleness (catches cases missed by hash changes) ---
if [ -f "$HEARTBEAT_FILE" ]; then
    last_heartbeat=$(cat "$HEARTBEAT_FILE" 2>/dev/null || echo 0)
    hb_age=$((now - last_heartbeat))
    if [ $hb_age -le $MAX_HEARTBEAT_AGE ]; then
        log "Heartbeat fresh (${hb_age}s old), all checks passed"
        exit 0
    fi
    log "Heartbeat stale (${hb_age}s old, threshold=${MAX_HEARTBEAT_AGE}s)"
fi

# --- Heartbeat stale AND hash idle not yet at threshold ---
# This means hermes has been minimally active (tiny hash changes) but not meaningfully working
if $hermes_running; then
    # Check if hermes is actually doing something or just sitting there
    if [ "$(echo "$pane_output" | grep -c 'type a message')" -eq 0 ]; then
        do_kick "Hermes at prompt with stale heartbeat"
    fi
    # Hermes alive but stale — just update heartbeat and log
    date +%s > "$HEARTBEAT_FILE"
    log "Hermes alive but heartbeat stale, updated heartbeat"
    exit 0
else
    do_restart "Hermes not running and heartbeat stale"
fi
