#!/bin/bash
# task_dispatch.sh — Reliable command sender for execution agent
# Usage: task_dispatch.sh "what you want the exec agent to do"
# How it works: bracket-paste injection (prevents multiline text being sent as individual Enter keypresses)
#               tmux commands wrapped with timeout to prevent hangs
set +u

EXEC_SESSION="agent_orchestration_book"
TMUX_TIMEOUT=10

if [ -z "$1" ]; then
    echo "Usage: task_dispatch.sh <message>"
    exit 1
fi

# Step 1: Write bracket-paste wrapped content to temp file, load into buffer
tmpf=$(mktemp)
printf '\e[200~%s\e[201~' "$1" > "$tmpf"
if ! timeout "$TMUX_TIMEOUT" tmux load-buffer -t "$EXEC_SESSION" "$tmpf"; then
    rm -f "$tmpf"
    echo "ERROR: agent_send load-buffer timed out"
    exit 1
fi
rm -f "$tmpf"

# Step 2: Paste buffer into exec agent
if ! timeout "$TMUX_TIMEOUT" tmux paste-buffer -t "$EXEC_SESSION"; then
    echo "ERROR: agent_send paste-buffer timed out"
    exit 1
fi

# Step 3: Small delay then press Enter separately
sleep 1
if ! timeout "$TMUX_TIMEOUT" tmux send-keys -t "$EXEC_SESSION" Enter; then
    echo "ERROR: agent_send send-keys timed out"
    exit 1
fi

echo "Sent to exec agent: $1"
