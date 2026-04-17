#!/bin/bash
# orch_watchdog.sh — Watchdog for single book hermes
# Called by systemd timer every 5 minutes
# Checks if hermes is alive in tmux session "book", restarts if dead
# After restart, automatically injects the work prompt

SESSION="book-orch"
HERMES_CMD="hermes -p book chat --yolo"
WORKDIR="/home/ubuntu/agent-orchestration-book"
HEARTBEAT_FILE="/tmp/agent_orchestration_book_orch_heartbeat"
MAX_AGE=600  # 10 minutes
KICK_MSG="Read SPRINT.md and BOOK_QUALITY_RULES.md, then continue your current iteration: crawl -> extract insights -> 6-gate review -> inject into weakest chapters -> commit+push. If no baseline scores exist, score all 15 chapters first."

# Check heartbeat file first
if [ -f "$HEARTBEAT_FILE" ]; then
    now=$(date +%s)
    last_heartbeat=$(cat "$HEARTBEAT_FILE" 2>/dev/null || echo 0)
    age=$((now - last_heartbeat))
    if [ $age -le $MAX_AGE ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Heartbeat OK (${age}s ago)"
        exit 0
    fi
fi

# Heartbeat stale or missing — check tmux session
if ! tmux has-session -t "=$SESSION" 2>/dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Session '$SESSION' not found, recreating..."
    tmux new-session -d -s "$SESSION" -c "$WORKDIR"
    sleep 3
    tmux send-keys -t "$SESSION" "$HERMES_CMD" Enter
    # Wait for hermes to initialize (prefill_messages_file loads agent_prompt.txt automatically)
    sleep 15
    # Send kick message to start working
    tmux send-keys -t "$SESSION" "$KICK_MSG" Enter
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Hermes restarted + kicked in session '$SESSION'"
    exit 0
fi

# Session exists but heartbeat stale — check if hermes process is alive
pane_pid=$(tmux list-panes -t "$SESSION" -F '#{pane_pid}' 2>/dev/null | head -1)
if [ -n "$pane_pid" ]; then
    if pstree -p "$pane_pid" 2>/dev/null | grep -qE "hermes"; then
        # Hermes alive but heartbeat stale — just update heartbeat
        date +%s > "$HEARTBEAT_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Hermes alive but heartbeat stale, updated"
        exit 0
    fi
fi

# Hermes not running in session — restart it
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Hermes not running, restarting..."
tmux send-keys -t "$SESSION" C-c 2>/dev/null
sleep 2
tmux send-keys -t "$SESSION" "$HERMES_CMD" Enter
# Wait for hermes to initialize
sleep 15
# Send kick message
tmux send-keys -t "$SESSION" "$KICK_MSG" Enter
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Hermes restarted + kicked in session '$SESSION'"
