#!/bin/bash
# orch_watchdog.sh — Watchdog for single book hermes
# Called by systemd timer every 5 minutes
# v2: Fixed false positives:
#   1. idle prompt: "type a message" present = idle = kick (was backwards)
#   2. md5sum: filter noise before hash (was fooled by timestamps)
#   3. bare shell: detect hermes died + bash prompt visible
#   4. context over-compression: /new after 10+ compacts

SESSION="agent_orchestration_book"
HERMES_CMD="hermes -p book chat --yolo"
WORKDIR="/home/ubuntu/agent-orchestration-book"
HEARTBEAT_FILE="/tmp/agent_orchestration_book_orch_heartbeat"
ACTIVITY_FILE="/tmp/agent_orchestration_book_orch_last_activity"
MAX_HEARTBEAT_AGE=600
MAX_IDLE_MINUTES=10
MAX_COMPACT_COUNT=10
KICK_MSG="Read SPRINT.md and BOOK_QUALITY_RULES.md, then continue your current iteration: crawl -> extract insights -> 6-gate review -> inject into weakest chapters -> commit+push. If no baseline scores exist, score all 15 chapters first."

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

reset_tracking() {
    now=$(date +%s)
    hash=$(_clean_hash)
    echo -e "${hash}\n${now}" > "$ACTIVITY_FILE"
    date +%s > "$HEARTBEAT_FILE"
}

# Clean hash: filter noise before md5sum
_clean_hash() {
    tmux capture-pane -t "$SESSION" -p 2>/dev/null \
        | grep -vE '(type a message|preparing terminal|░|▓|▒|▰|▱|[0-9]+% to compaction|[0-9]+h [0-9]+m$|^\s*$|────)' \
        | md5sum | awk '{print $1}'
}

# Detect if hermes is truly idle (waiting for user input)
is_hermes_idle() {
    local pane
    pane=$(tmux capture-pane -t "$SESSION" -p -S -5 2>/dev/null)
    echo "$pane" | grep -q 'type a message'
}

# Detect bare bash shell
is_bare_shell() {
    local pane_pid
    pane_pid=$(tmux list-panes -t "$SESSION" -F '#{pane_pid}' 2>/dev/null | head -1)
    [ -z "$pane_pid" ] && return 0
    if ! pstree -p "$pane_pid" 2>/dev/null | grep -qE "hermes|python3.*hermes"; then
        local pane
        pane=$(tmux capture-pane -t "$SESSION" -p -S -3 2>/dev/null)
        echo "$pane" | grep -qE '\$\s*$|ubuntu@' && return 0
    fi
    return 1
}

# Count context compaction events
get_compact_count() {
    local pane
    pane=$(tmux capture-pane -t "$SESSION" -p -S -300 2>/dev/null)
    echo "$pane" | grep -c 'compacting context\|Session compressed'
}

do_kick() {
    local reason="$1"
    log "KICK: $reason"
    # /new if over-compressed
    local cc
    cc=$(get_compact_count)
    if [ "$cc" -ge "$MAX_COMPACT_COUNT" ]; then
        log "Compact count=$cc >= $MAX_COMPACT_COUNT, sending /new first"
        tmux send-keys -t "$SESSION" "/new" Enter
        sleep 10
    fi
    tmux send-keys -t "$SESSION" "$KICK_MSG" Enter
    reset_tracking
    exit 0
}

do_restart() {
    local reason="$1"
    log "RESTART: $reason"
    if ! tmux has-session -t "=$SESSION" 2>/dev/null; then
        tmux new-session -d -s "$SESSION" -c "$WORKDIR"
    else
        tmux send-keys -t "$SESSION" C-c 2>/dev/null
        sleep 2
        tmux send-keys -t "$SESSION" C-c 2>/dev/null
        sleep 1
        # Kill residual hermes
        local pane_pid
        pane_pid=$(tmux list-panes -t "$SESSION" -F '#{pane_pid}' 2>/dev/null | head -1)
        if [ -n "$pane_pid" ]; then
            pkill -P "$pane_pid" -f 'hermes' 2>/dev/null
        fi
        sleep 2
    fi
    sleep 3
    tmux send-keys -t "$SESSION" "$HERMES_CMD" Enter
    sleep 20
    tmux send-keys -t "$SESSION" "$KICK_MSG" Enter
    reset_tracking
    log "Hermes restarted + kicked in session '$SESSION'"
    exit 0
}

# ========== Checks ==========

# Check 0: bare shell
if is_bare_shell; then
    do_restart "Bare shell detected (no hermes process, bash prompt visible)"
fi

# Check 1: tmux session alive
if ! tmux has-session -t "=$SESSION" 2>/dev/null; then
    do_restart "Session '$SESSION' not found"
fi

# Check 2: hermes process running
pane_pid=$(tmux list-panes -t "$SESSION" -F '#{pane_pid}' 2>/dev/null | head -1)
if [ -z "$pane_pid" ]; then
    do_restart "Cannot get pane PID for session '$SESSION'"
fi

hermes_running=false
if pstree -p "$pane_pid" 2>/dev/null | grep -qE "hermes"; then
    hermes_running=true
fi

if ! $hermes_running; then
    do_restart "Hermes process not running"
fi

# Check 3: idle at prompt (KEY FIX: "type a message" = idle = needs kick)
if is_hermes_idle; then
    log "Hermes at idle prompt (waiting for input)"
    if [ -f "$ACTIVITY_FILE" ]; then
        prev_ts=$(tail -1 "$ACTIVITY_FILE" 2>/dev/null)
        now=$(date +%s)
        idle_seconds=$((now - prev_ts))
        idle_minutes=$((idle_seconds / 60))
        if [ $idle_minutes -ge $MAX_IDLE_MINUTES ]; then
            do_kick "Hermes idle at prompt for ${idle_minutes} minutes"
        else
            log "Hermes idle ${idle_minutes}min (threshold=${MAX_IDLE_MINUTES}min) - waiting"
        fi
    else
        now=$(date +%s)
        hash=$(_clean_hash)
        echo -e "${hash}\n${now}" > "$ACTIVITY_FILE"
        log "First idle detection, tracking initialized"
    fi
    exit 0
fi

# Check 4: activity tracking (clean hash, no noise)
current_hash=$(_clean_hash)
now=$(date +%s)

if [ -f "$ACTIVITY_FILE" ]; then
    prev_hash=$(head -1 "$ACTIVITY_FILE")
    prev_ts=$(tail -1 "$ACTIVITY_FILE")
    if [ "$current_hash" = "$prev_hash" ]; then
        idle_seconds=$((now - prev_ts))
        idle_minutes=$((idle_seconds / 60))
        if [ $idle_minutes -ge $MAX_IDLE_MINUTES ]; then
            do_kick "Hermes STUCK - no meaningful output change for ${idle_minutes} minutes"
        else
            log "Hermes idle ${idle_minutes}min (threshold=${MAX_IDLE_MINUTES}min) - waiting"
        fi
    else
        echo -e "$current_hash\n$now" > "$ACTIVITY_FILE"
        date +%s > "$HEARTBEAT_FILE"
        log "Hermes active (meaningful output changed), tracking updated"
        exit 0
    fi
else
    echo -e "$current_hash\n$now" > "$ACTIVITY_FILE"
    log "Activity tracker initialized"
fi

# Check 5: context over-compression
compact_count=$(get_compact_count)
if [ "$compact_count" -ge "$MAX_COMPACT_COUNT" ]; then
    log "Context compressed $compact_count times (max $MAX_COMPACT_COUNT), sending /new"
    tmux send-keys -t "$SESSION" "/new" Enter
    sleep 10
    tmux send-keys -t "$SESSION" "$KICK_MSG" Enter
    reset_tracking
    exit 0
fi

# Check 6: heartbeat staleness
if [ -f "$HEARTBEAT_FILE" ]; then
    last_heartbeat=$(cat "$HEARTBEAT_FILE" 2>/dev/null || echo 0)
    hb_age=$((now - last_heartbeat))
    if [ $hb_age -le "$MAX_HEARTBEAT_AGE" ]; then
        log "Heartbeat fresh (${hb_age}s old), all checks passed"
        exit 0
    fi
    log "Heartbeat stale (${hb_age}s old, threshold=${MAX_HEARTBEAT_AGE}s)"
fi

date +%s > "$HEARTBEAT_FILE"
log "All checks passed, heartbeat updated"
