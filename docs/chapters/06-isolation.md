# Chapter 6 Isolation and Concurrency: How to Avoid Stepping on Each Other's Toes

## 6.1 Three Forms of Concurrency Problems

When multiple Agents work simultaneously, concurrency problems are inevitable:

1. **Code conflicts**: Two Agents modify the same file
2. **Resource contention**: Two Agents call the same API simultaneously and get rate-limited
3. **State races**: Two Agents write to the task queue at the same time

## 6.2 Isolation Scheme 1: Git Worktree (Overstory / Composio)

This is currently the most reliable isolation scheme — each Agent works in a completely independent copy of the codebase.

### Overstory's Worktree Management

```typescript
// Create a worktree
git worktree add <path> -b overstory/{agentName}/{taskId}

// Branch naming convention
overstory/scout-1/explore-auth       // Scout explores auth module
overstory/builder-1/impl-auth        // Builder implements auth
overstory/reviewer-1/review-auth     // Reviewer reviews auth
```

**Worktree Manager responsibilities**:
- Create independent working directories
- Manage branch naming conventions
- Rollback on failure (`rollbackWorktree()`: remove + branch -D)
- Track which worktrees belong to which Agents

### Composio's Worktree Usage

Also based on git worktree, but simpler — Workers code in independent worktrees, and the Orchestrator integrates results via git merge.

### 4-Level Merge Strategy (Overstory)

When multiple Agents complete their respective tasks, code needs to be merged. Overstory designed a 4-level merge strategy:

```
Level 1: clean-merge    — No conflicts, merge directly
Level 2: auto-resolve   — Automatically resolve simple conflicts (e.g., import ordering)
Level 3: ai-resolve     — AI-assisted conflict resolution (leveraging historical patterns)
Level 4: reimagine      — AI re-imagines the entire file
```

**Key innovation**: The Level 3 AI conflict resolver queries the Mulch knowledge base for historical conflict patterns, predicts which files are prone to conflicts, and skips strategies with historically high failure rates.

```typescript
// Merger executes after receiving merge_ready mail
async function merge(mergeRequest: MergeReadyPayload) {
  const strategy = await selectStrategy(conflictAnalysis, historicalPatterns);
  // Level 1-2: Automatic handling
  // Level 3: Call AI to analyze conflicts
  // Level 4: Regenerate file
  if (success) mail.send({ protocol: "merged", ... });
  else mail.send({ protocol: "merge_failed", ... });
}
```

**Advantages**:
- Complete isolation — Agents cannot see each other's modifications
- Systematic handling for merge conflicts
- Clear branch naming conventions, traceable

**Disadvantages**:
- Merge cost — Every merge may have conflicts
- Storage cost — Each worktree is a complete copy of the codebase
- Latency — Must wait for all related Agents to complete before merging

## 6.3 Isolation Scheme 2: Role Separation

Rather than code-level isolation, conflicts are avoided through role separation — "you handle the backend, I'll handle the frontend."

### Role Isolation

```
Architect: Only manages SPRINT.md and FEATURES.md, never touches code
Executor: Only handles code implementation, does not manage project planning
```

The Architect's iron rule explicitly prohibits writing code, and the Executor can only receive tasks from the Architect. This "write/read separation" naturally avoids conflicts — because the sets of files operated on by the two Agents are completely non-overlapping.

### Tmux-Orchestrator's File Assignment

```
PM explicitly specifies when assigning tasks:
  "Engineer-1: You are responsible for the src/auth/ directory"
  "Engineer-2: You are responsible for the src/api/ directory"
```

**Advantages**:
- Zero isolation cost — No additional worktrees or branches needed
- Simple — No merge strategy needed

**Disadvantages**:
- Depends on the PM/Architect's assignment wisdom — If poorly assigned, conflicts are inevitable
- Not suitable for scenarios with inter-task dependencies (e.g., one Agent's output is another's input)
- Difficult to scale to 3+ coding Agents

## 6.4 Isolation Scheme 3: Session Isolation (All tmux Projects)

Each Agent runs in an independent tmux session/window, providing process-level isolation.

```
tmux session: project-name
  ├── window 0: Claude-Agent (Architect)
  ├── window 1: Shell
  ├── window 2: Dev-Server
  └── window 3: Codex (Executor)
```

This is the most basic isolation — Agents won't accidentally interfere with each other's terminals. But it doesn't provide file-level protection.

**safe_session()**:

```bash
# All tmux commands wrapped with timeout 10
safe_session() {
  timeout 10 tmux "$@" 2>/dev/null
}
# Prevents a single tmux operation from blocking the main loop
# If a session's tmux operation hangs, it times out after 10 seconds, not affecting other sessions
```

## 6.5 Isolation Scheme 4: File Locks and Concurrency Control

SPRINT.md is accessed simultaneously by the Architect (updating task status) and the Orchestrator (possibly reading status). In a single-Agent scenario this is fine, but scaling to multiple Agents would cause conflicts.

**Potential solution** (not yet implemented):
```bash
# Implement file locks with flock
(
  flock -x 200
  # Read/write SPRINT.md
) 200>/tmp/sprint.lock
```

### todo.md Race Condition (Composio)

Multiple Workers updating todo.md simultaneously may overwrite each other's updates. Composio does not explicitly handle this problem, relying on the convention that "Workers only update their own line."

### SQLite WAL Mode (Overstory)

Overstory uses SQLite (WAL) to solve concurrent read/write problems:

```
WAL (Write-Ahead Logging) mode:
- Read operations do not block write operations
- Write operations are serialized (single writer)
- Multiple read operations can run concurrently
- Suitable for "many reads, few writes" Agent communication scenarios
```

## 6.6 Concurrency Management for API Rate Limiting

When multiple Agents call the same API simultaneously (e.g., Claude API), it's easy to trigger 429 rate limiting.

### Solution

```
1. Detect 429 → Enter cooldown (300s)
2. Orchestrator skips nudges during cooldown to avoid avalanche
3. Cooldown expires → Notify Architect to resume
4. Force restart after 4 renewals
5. Persist state to disk
```

### Overstory's Solution

```
Watchdog detects Agent unresponsive → nudge → escalate → AI triage
Rate limiting is not handled as a special case, but as one type of "stuck"
```

**Key insight**: Rate limiting handling is more refined because a large number of 429 scenarios were encountered in practice. Overstory's general Watchdog approach is more elegant but may not respond as quickly as a dedicated solution.

## 6.7 Isolation Level Comparison

| Isolation Level | Scheme | Conflict Probability | Implementation Cost | Applicable Agent Count |
|---------|------|-----------|---------|------------|
| Level 0 | No isolation (agency-agents-zh) | High | Zero | 1 |
| Level 1 | Session isolation | Medium | Low | 2-3 |
| Level 2 | Role separation | Low | Low | 2-3 |
| Level 3 | File assignment | Low | Medium | 3-5 |
| Level 4 | Git worktree | Very low | High | 5+ |

## 6.8 Core Principles of Isolation Design

### Principle 1: Isolation Granularity Must Match Concurrency Needs

2 Agents only need role separation, 5 Agents need file assignment, 10 Agents must use git worktree. Don't over-engineer, and don't under-engineer.

### Principle 2: The Cost of Isolation Is Merging

Git worktree provides the strongest isolation, but also introduces merge costs. Merge strategies (4-level merge) and conflict resolution (AI-assisted) are necessary complements to worktree isolation.

### Principle 3: Write Operations Are the Root of Conflicts

Read-only Agents (Scout, Reviewer) don't need isolation — they don't modify files. Concentrating write operations in the fewest roles is an effective strategy for reducing isolation costs.

### Principle 4: API Rate Limiting Is an Implicit Concurrency Problem

Unlike file conflicts which are obvious, 429 rate limiting is equally serious in multi-Agent scenarios. Rate limiting state must be persisted, and all requests must be paused during cooldown.