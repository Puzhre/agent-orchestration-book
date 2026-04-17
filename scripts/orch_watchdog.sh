#!/bin/bash
# orch_watchdog.sh — External heartbeat watchdog
# Called by systemd timer every 5 minutes
# If heartbeat file is stale (>10min), restarts the orchestrator service
#
# This is the last line of defense:
# Even if the orchestrator's built-in watchdog hangs (all safe_tmux calls timeout),
# the heartbeat file won't update, and this script will detect and restart

HEARTBEAT_FILE="/tmp/agent_orchestration_book_orch_heartbeat"
MAX_AGE=600  # 10 minutes
SERVICE_NAME="agent_orchestration_book-orchestrator"

if [ ! -f "$HEARTBEAT_FILE" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] No heartbeat file, restarting $SERVICE_NAME..." >&2
    systemctl --user restart "$SERVICE_NAME" 2>/dev/null || true
    exit 0
fi

now=$(date +%s)
last_heartbeat=$(cat "$HEARTBEAT_FILE" 2>/dev/null || echo 0)
age=$((now - last_heartbeat))

if [ $age -gt $MAX_AGE ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Heartbeat is ${age}s old (max ${MAX_AGE}s), restarting $SERVICE_NAME..." >&2
    systemctl --user restart "$SERVICE_NAME" 2>/dev/null || true
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Heartbeat OK (${age}s ago)" >&2
fi
