# Chapter 5 Fault Tolerance & Recovery: What Happens When the System Goes Down

## 5.1 Fault Tolerance Is the Core Value of an Orchestrator

An Orchestrator without fault tolerance is more dangerous than no Orchestrator at all — it gives the illusion of "automation," making you think the system is running normally when an Agent may have been stuck for half an hour.

The five major projects differ dramatically in their investment in fault tolerance, ranging from 1 to 4 layers. This chapter systematically dissects each layer of fault tolerance mechanisms.

## 5.2 Layer 1: Process Liveness Monitoring

The most basic fault tolerance — is the Agent process still alive?

### tmux Session Detection

All tmux-based projects use this approach:

```bash
# Exact match (= prefix prevents prefix matching bug)
tmux has-session -t "=$SESSION" 2>/dev/null

# Overstory: ZFC principle (Zero Failure Crash)
# Signal priority: tmux liveness > PID liveness > recorded state
# tmux dead + recorded "working" → immediately mark zombie
# tmux alive + recorded "zombie" → investigate (don't auto-kill)
```

**Process liveness detection details:**
```bash
is_generic_process_alive() {
  local pane_pid=$(tmux list-panes -t "$SESSION" -F "#{pane_pid}" 2>/dev/null)
  pstree -p "$pane_pid" | grep -qE "hermes|codex"
}
```

Key point: Don't just check whether the tmux session exists — check whether there's an Agent process inside it. The tmux session may exist but the Agent has already exited.

### PID Process Detection

Overstory's ZFC health check state machine further distinguishes:

```
Observable state (tmux/pid alive) takes precedence over recorded state
This is the source of truth for health judgment

State transitions are forward-only:
  booting → working → completed/stalled/zombie
  
tmux dead + recorded "working" → immediately zombie
pid dead + tmux alive → treated as zombie
```

### LifecycleWorker (Composio)

```typescript
// Background Worker continuously monitors Agent processes
ensureLifecycleWorker(config): void;
// Attempts recovery or sends notification on abnormal exit
// Prevents duplicate launches: isAlreadyRunning(id)
// Prevents system sleep: preventIdleSleep()
```

## 5.3 Layer 2: Behavioral Anomaly Detection

An Agent's process may be alive but behaving abnormally — stuck, trapped in a loop, or rate-limited.

```bash
# Each round, capture-pane takes the last 30 lines and computes MD5
# Compare with previous round to determine if "stuck"
SCREEN_MD5=$(tmux capture-pane ... | tail -30 | md5sum)

# Early-stop detection: 3 checks with no change + Agent at prompt + Agent idle
# → nudge push

# Hard timeout: STALE_THRESHOLD(3600s) with no change → force restart
```

This is the most sophisticated rate-limit handling scheme:

```
Detection: scan last 3 lines of capture-pane for 429/rate.limit keywords

First trigger → enter RATE_LIMIT_COOLDOWN(300s)
          ↓
State persisted to disk (survives restart)
          ↓
Decay renewal: each renewal shortens cooldown time cooldown/renew_count
          ↓
4 renewals force restart: breaks infinite rate-limit loop
          ↓
Cooldown expired → notify architect to resume dispatch
```

Why is "4 renewals force restart" needed? Because an Agent may repeatedly request → get rate-limited → wait → request again → get rate-limited again, forming a dead loop. Decay renewal breaks this cycle.

### AI Triage (Overstory Tier 1)

When mechanical monitoring cannot determine the situation, call a short-lived AI Agent to analyze:

```typescript
// Tier 1: AI triage agent
// Reads the Agent's recent output
// Determines whether it's stuck / waiting / or truly crashed
// Returns TriageResult: continue / restart / kill
```

This is a clever hybrid strategy — the mechanical daemon handles deterministic scenarios (process is dead), while AI triage handles ambiguous scenarios (process is alive but it's unclear what it's doing).

## 5.4 Layer 3: Self-Healing & Recovery

After detecting a problem, how do you recover?

### Progressive Recovery (Overstory 4-Tier Watchdog)

```
Tier 0 — Mechanical daemon
  Level 0 (warn):      Log warning
  Level 1 (nudge):     Send tmux nudge (key press to wake)
  Level 2 (escalate):  Call Tier 1 AI triage
  Level 3 (terminate): Kill tmux session

Progressive handling: light touch first, heavy touch later — don't kill the process right away
```

### Self-Scheduling Chain (Tmux-Orchestrator)

```bash
schedule_with_note.sh <minutes> "<note>" [target_window]

# How it works:
# 1. Write scheduling info to next_check_note.txt
# 2. nohup background sleep process
# 3. After sleep ends, tmux send-keys sends wake command
```

This is Tmux-Orchestrator's most core innovation — Agents can set their own alarms. The Orchestrator schedules its own checks, the PM schedules its own re-checks, the Engineer schedules its own syncs.

**Fragility**: Relies on nohup+sleep; the scheduling chain breaks after a system restart.

```
Layer 1: Built-in Watchdog (forked child process)
  - Checks heartbeat file (updated every 60s)
  - Heartbeat not updated for 600s → TERM signal → wait 30s → KILL → restart

Layer 2: External Watchdog (systemd timer)
  - Checks heartbeat file every 5 minutes
  - Acts as last resort: triggers when built-in Watchdog is also down

Why two layers?
  safe_session() may fully time out (10s each, multiple sessions), causing the built-in Watchdog to hang
  At that point the heartbeat file stops updating, and the systemd timer triggers an external restart
```

### Session Handoff & Recovery (Overstory)

```typescript
// Checkpoint: save complete session state
{
  agentName, taskId, progressSummary,
  filesModified, pendingWork, currentBranch,
  lastCommit, openQuestions
}

// Handoff: record handoff history
{ fromSessionId, toSessionId, reason, timestamp }

// Recovery: find the latest incomplete handoff, load checkpoint
resumeFromHandoff(agentName)
```

This is the only solution that supports "precise recovery" — not simply restarting the Agent, but restoring to the previous work progress and continuing.

```bash
crash_restart() {
  CRASH_TIMESTAMPS+=(now_ts)
  # Keep the last 10 crash timestamps
  # 3 crashes within 120 seconds → force 120s cooldown
  # Prevents infinite restart loops caused by Agent repeatedly crashing
}
```

## 5.5 Layer 4: Quality Assurance

Even if an Agent hasn't crashed, it may still produce low-quality results. Quality assurance is the highest form of fault tolerance.

### Dev-Test Loop (agency-agents-zh)

```
Developer implements → Evidence Collector tests → Decision logic
  ├── PASS → next task
  ├── FAIL + retries < 3 → back to developer with feedback
  └── FAIL + retries = 3 → escalate to Orchestrator
```

Core rules:
- Every task must pass QA before proceeding
- Each task has a maximum of 3 retries
- Retries must carry specific QA feedback

### Reality Checker (agency-agents-zh)

```
Default judgment: NEEDS WORK
Only give READY under overwhelming evidence

Three judgments:
  READY → ready for production
  NEEDS WORK → back to phase 3 for revision
  NOT READY → back to phase 1/2 for redesign
```

This is the last line of defense against "premature production readiness." A first implementation is expected to need 2-3 rounds of revision — this is normal.

```bash
# Check for IRON_LAW marker in prompt every 300 seconds
# If marker is deleted (Agent modified the rules itself):
#   1. git checkout HEAD -- scripts/auto_push.sh  # restore from git
#   2. Send warning message to architect
```

### PM Quality Assurance Protocol (Tmux-Orchestrator)

- Code review before merge
- Test coverage monitoring
- Performance benchmarking
- Security scanning
- Enforced git discipline: commit every 30 minutes, feature branches, meaningful commit messages

## 5.6 Fault Tolerance Comparison Across Five Projects

|| Fault Tolerance Capability |---------|-----------------|-------------------|----------|-----------|-----------------||
|| Process Monitoring | tmux+pid | tmux | LifecycleWorker | ZFC state machine | No runtime ||
|| Rate-Limit Handling | Persist + decay + 4-renewal restart | None | None | None | None ||
|| Stuck Detection | MD5 snapshot + early-stop + hard timeout | Self-scheduling chain | None | 4-tier Watchdog | Quality gate ||
|| AI-Assisted Diagnosis | None | None | None | Tier 1 triage | None ||
|| Session Recovery | None (restart) | None (restart) | git rollback | checkpoint + handoff | MCP rollback ||
|| Crash Protection | fast-crash protection rate limiting | None | None | Progressive nudge | Escalation protocol ||
|| Rule Guard | rule guard | CLAUDE.md convention | None | constraints field | Prompt rules ||
|| Quality Assurance | None (trust architect) | PM review | Orchestrator review | Reviewer role | Evidence collection + reality check ||
|| Dual-Layer Protection | Built-in + systemd | None | LifecycleWorker | 4-tier Watchdog | 4-level fault tolerance ||

### Real-World Fault Tolerance Patterns

**Tmux-Orchestrator's Git Discipline as Fault Tolerance:**
- Mandatory 30-minute commits prevent work loss
- Feature branches and stable tags create recovery points
- Project Managers enforce quality standards as first line of defense
- Self-scheduling chain ensures agents don't get permanently stuck

**agency-agents-zh's Multi-Stage QA as Fault Tolerance:**
- Seven-stage pipeline with mandatory quality gates
- Evidence collector tests every implementation
- Reality checker with three-tier judgment (READY/NEEDS WORK/NOT READY)
- Maximum 3 retries per task with specific feedback

**Composio's CI/CD Integration as Fault Tolerance:**
- Agents autonomously fix CI failures
- PR-based workflow provides human oversight
- Each agent in isolated git worktree prevents conflicts
- Dashboard monitoring for real-time status

**Overstory's 4-Tier Watchdog System:**
- Tier 0: Mechanical daemon (logging, nudging)
- Tier 1: AI triage (analyze ambiguous situations)
- Tier 2: Progressive escalation (warn → nudge → escalate → terminate)
- Tier 3: Session handoff with checkpoint recovery

## 5.7 Core Principles of Fault Tolerance Design

### Principle 1: Mechanical Monitoring Over AI Judgment

The core of the ZFC principle — use deterministic signals (is the process alive, is the heartbeat updated) rather than uncertain signals (AI thinks it's stuck) as recovery triggers. AI triage only intervenes when mechanical monitoring cannot make a determination.

### Principle 2: Progressive Recovery

Don't kill the process right away. warn → nudge → escalate → terminate, progressively escalating. Many "stuck" situations are just the Agent thinking — a nudge is all it takes.

### Principle 3: State Must Be Persisted

Rate-limit state, crash records, checkpoints — these must be written to disk. Losing state after a restart means repeating the same mistakes.

### Principle 4: Anti-Loop Mechanisms

fast-crash protection, 4-renewal force restart — these seemingly edge-case scenarios are guaranteed to happen in 24/7 operation. Without anti-loop mechanisms, the Orchestrator falls into a "crash → restart → crash" dead loop.

### Principle 5: Quality Is the Highest Form of Fault Tolerance

Preventing low-quality output is more important than preventing crashes. Crashes can be restarted, but once low-quality code is merged into the main branch, the cost of rollback far exceeds the cost of re-running.
