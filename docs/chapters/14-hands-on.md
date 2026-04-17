# Chapter 14: Hands-On — Building Your First Orchestrator

> Theory is one thing, practice is another. Let's build an orchestrator from scratch using simple tools that can keep Agents running continuously.

## 14.1 Goal

Build a dual-Agent orchestrator:
- **Architect Agent** (Hermes): Plans tasks, reviews results
- **Executor Agent** (Codex): Writes code, runs tests
- **Orchestrator Daemon** (Bash script): Monitors, recovers, drives

## 14.2 Minimal Viable Orchestrator (30 Lines of Code)

```bash
#!/bin/bash
# minimal-orchestrator.sh — 30-line minimal orchestrator

PROJECT_DIR="$1"
cd "$PROJECT_DIR" || exit 1

# Start two Agents
tmux new-session -d -s architect "hermes chat --yolo"
tmux new-session -d -s executor "codex"

while true; do
    # Check if Agents are still alive
    if ! tmux has-session -t architect 2>/dev/null; then
        echo "[$(date)] Architect crashed, restarting..."
        tmux new-session -d -s architect "hermes chat --yolo"
    fi
    
    if ! tmux has-session -t executor 2>/dev/null; then
        echo "[$(date)] Executor crashed, restarting..."
        tmux new-session -d -s executor "codex"
    fi
    
    sleep 60  # Check every minute
done
```

**What does this 30-line solution accomplish?**
- Auto-restarts Agents when they crash ✓
- No human supervision required ✓

**What's missing?**
- No communication between Agents
- No active detection (Agents might be stuck but processes are running)
- No rule enforcement

## 14.3 Adding Communication (+20 Lines)

```bash
# Function to send message to architect
send_to_architect() {
    local msg="$1"
    tmpf=$(mktemp)
    printf '\e[200~%s\e[201~' "$msg" > "$tmpf"
    tmux load-buffer -t architect "$tmpf"
    rm -f "$tmpf"
    tmux paste-buffer -t architect
    sleep 1
    tmux send-keys -t architect Enter
}

# Function to send message to executor
send_to_executor() {
    local msg="$1"
    tmpf=$(mktemp)
    printf '\e[200~%s\e[201~' "$msg" > "$tmpf"
    tmux load-buffer -t executor "$tmpf"
    rm -f "$tmpf"
    tmux paste-buffer -t executor
    sleep 1
    tmux send-keys -t executor Enter
}
```

**What is bracket-paste?**
Regular `send-keys` treats each line of multi-line text as a separate Enter key, causing Agents to receive fragmented messages. Bracket-paste uses `\e[200~` and `\e[201~` to wrap text, telling the terminal "this is a single paste operation" and preventing line breaks from being misinterpreted.

## 14.4 Adding Active Detection (+15 Lines)

```bash
# Check if Agent is stuck
STALE_THRESHOLD=1800  # Consider stuck after 30 minutes of no change

check_stale() {
    local session="$1"
    local hash_file="/tmp/${session}_screen_hash"
    local current_hash
    
    current_hash=$(tmux capture-pane -t "$session" -p | md5sum)
    
    if [ -f "$hash_file" ]; then
        local old_hash last_change
        old_hash=$(cat "$hash_file")
        if [ "$current_hash" = "$old_hash" ]; then
            last_change=$(cat "/tmp/${session}_last_change" 2>/dev/null || echo "0")
            local now=$(date +%s)
            if [ $((now - last_change)) -gt "$STALE_THRESHOLD" ]; then
                echo "[$(date)] $session stuck for ${STALE_THRESHOLD} seconds, force restarting"
                tmux kill-session -t "$session"
                return 1
            fi
        else
            echo $(date +%s) > "/tmp/${session}_last_change"
        fi
    fi
    
    echo "$current_hash" > "$hash_file"
    return 0
}
```

## 14.5 Adding systemd Daemon (+10 Lines of Configuration)

```ini
# ~/.config/systemd/user/minimal-orchestrator.service
[Unit]
Description=Minimal Agent Orchestrator
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/minimal-orchestrator.sh /path/to/project
Restart=always
RestartSec=15

[Install]
WantedBy=default.target
```

```bash
# Enable
systemctl --user daemon-reload
systemctl --user enable minimal-orchestrator
systemctl --user start minimal-orchestrator

# Ensure service runs even when user is logged out
loginctl enable-linger $(whoami)
```

## 14.6 Evolution Path for Complete Orchestrator

```
30-line minimal orchestrator
  → + Communication (bracket-paste)
  → + Active detection (screen hash)
  → + systemd daemon
  → + Rule guards (git checkout recovery)
  → + Rate limit handling (cooldown persistence)
  → + Fast crash protection (restart frequency limiting)
  → + Issue prompting (automatic decisions when waiting for human input)
  → This is a natural evolution process from simple to complex
```

**Key Principle**: Every feature is added because of real problems encountered, not pre-designed.

## 14.7 Summary

The evolution path from 30 to hundreds of lines is clear:

1. **Get it running first**: Minimal auto-restart functionality
2. **Add communication**: Agents can send messages to each other
3. **Add detection**: Know if Agents are stuck
4. **Add daemon protection**: The orchestrator itself doesn't fear crashes
5. **Add constraints**: Rule guards, cooldowns, crash protection
6. **Continuous iteration**: Every new problem is a seed for new features

## 14.8 Pattern: Playbook-Driven Orchestration

Beyond the script-based approach, agency-agents-zh demonstrates a **playbook pattern** — predefined workflows that guide agents through complex multi-step tasks:

```markdown
# playbook: feature-implementation.md
## Trigger
When a new feature is requested via sprint planning

## Steps
1. **Recon Agent**: Research existing code, identify integration points
   - Output: research-brief.md
   - Gate: Must identify at least 2 integration points
   
2. **Architect Agent**: Design implementation plan
   - Input: research-brief.md
   - Output: impl-plan.md  
   - Gate: Must cover error handling + testing strategy
   
3. **Builder Agent**: Implement the feature
   - Input: impl-plan.md
   - Output: code changes
   - Gate: All tests pass + lint clean
   
4. **QA Agent**: Review and test
   - Input: code changes
   - Output: qa-report.md
   - Gate: No P0/P1 issues
   
5. **Deploy Agent**: Ship it
   - Input: qa-report.md (passed)
   - Output: deployment confirmation
```

### Playbook vs Script: When to Use Each

| Dimension | Script Orchestration | Playbook Orchestration |
|-----------|---------------------|----------------------|
| Execution | Deterministic, automated | Guided, semi-automated |
| Flexibility | Low (hard-coded steps) | High (agents interpret steps) |
| Human involvement | Minimal | At quality gates |
| Best for | Repetitive, well-defined tasks | Complex, judgment-heavy tasks |
| Error recovery | Restart from checkpoint | Agent adapts and retries |

### Implementing Playbooks in Bash

```bash
#!/bin/bash
# playbook-runner.sh — Simple playbook executor

PLAYBOOK_DIR="./playbooks"
CURRENT_STEP_FILE="/tmp/playbook_current_step"

run_playbook() {
    local playbook="$1"
    local step=1
    
    if [ -f "$CURRENT_STEP_FILE" ]; then
        step=$(cat "$CURRENT_STEP_FILE")
        echo "[PLAYBOOK] Resuming from step $step"
    fi
    
    while true; do
        local step_file="${PLAYBOOK_DIR}/${playbook}/step${step}.md"
        [ ! -f "$step_file" ] && echo "[PLAYBOOK] All steps complete!" && break
        
        echo "[PLAYBOOK] Executing step $step..."
        send_to_architect "$(cat "$step_file")"
        
        # Wait for agent to signal completion (via SPRINT.md or file creation)
        wait_for_step_completion "$step"
        
        # Run quality gate
        if ! run_gate "$playbook" "$step"; then
            echo "[PLAYBOOK] Gate failed at step $step, requesting rework"
            send_to_architect "Step $step quality gate failed. Please rework."
            continue  # Retry same step
        fi
        
        echo "$((step + 1))" > "$CURRENT_STEP_FILE"
        step=$((step + 1))
    done
    
    rm -f "$CURRENT_STEP_FILE"
}
```

## 14.9 Next Steps

Now that you have the foundation, consider adding:

- **Rule checking**: Monitor for rule violations and take action
- **Rate limit handling**: Implement intelligent cooldown management
- **Progress tracking**: Monitor project progress and detect stalls
- **Cross-project coordination**: Share resources between multiple orchestrators
- **Self-healing**: Automatically recover from common failure patterns
- **Playbooks**: Define reusable multi-step workflows for common task types

Remember: A good orchestrator is honed, not designed. Every crash, every 429, every time an Agent slacks off — they're all telling you what to improve next.