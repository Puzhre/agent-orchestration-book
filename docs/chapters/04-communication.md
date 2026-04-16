# Chapter 4 Communication Mechanisms: How Agents Talk to Each Other

## 4.1 Communication Is the Lifeline of the Orchestrator

The quality of communication between Agents directly determines the ceiling of an orchestration system. An unreliable communication system means: lost tasks, out-of-sync state, and failed fault tolerance.

The five projects took five radically different paths:

**Principle**: Leverage tmux's bracket-paste protocol to inject multi-line text as a "paste" into the target terminal, then send Enter separately to submit.

```bash
# Core implementation
send_message() {
  local msg="$1"
  local tmp=$(mktemp)
  printf '\e[200~%s\e[201~' "$msg" > "$tmp"  # bracket-paste wrapping
  tmux load-buffer "$tmp"
  tmux paste-buffer -t "$GENERIC_SESSION"
  sleep 0.5                                    # wait for UI to register input
  tmux send-keys -t "$GENERIC_SESSION" Enter   # submit separately
  rm "$tmp"
}
```

**Why not tmux send-keys**:
send-keys interprets every line in multi-line text as a separate Enter, causing commands to be fragmented. This is a known tmux behavior, not a bug.

**Communication paths**:
```
Orchestrator → Architect: send_message() (nudge/warning/recovery notification)
Orchestrator → Executor: send_to_exec() (/compact and other ops commands)
Architect → Executor: task_dispatch.sh (task dispatch)
Orchestrator → Both: tmux capture-pane (state awareness, read-only)
```

**Pros**:
- Reliable: multi-line text is not lost
- Low latency: written directly to the terminal
- No dependencies: no message queue or database needed

**Cons**:
- No ACK mechanism: no way to know if a message was processed
- Unstructured: natural language is sent, the receiver may misinterpret
- 0.5-second delay is empirical: different terminals/networks may require different delays
- One-way only: Agents cannot proactively send structured messages to the Orchestrator

## 4.3 Approach Two: send-keys + capture-pane (Tmux-Orchestrator)

**Principle**: Use tmux send-keys to send messages and tmux capture-pane to read Agent screen output.

```bash
# Send
./send-claude-message.sh "session:window" "message content"
# Internally: send text → sleep 0.5s → send Enter

# Receive
tmux capture-pane -t "session:window" -p -S -100  # read the last 100 lines
```

**Monitoring-style communication**: The Orchestrator passively "watches" Agent output through capture-pane, without requiring Agents to actively report:

```bash
# Check dev server window for errors
tmux capture-pane -t "project:Dev-Server" -p | grep -i error

# Get context across windows
tmux capture-pane -t "project:Claude-Agent" -p -S -50
```

**Pros**:
- Minimalist: a single script implements all communication
- Human-readable: terminal output can be read directly

**Cons**:
- Unreliable: the 0.5-second delay in send-keys is empirical, messages may be lost
- Fragile parsing: grepping screen text is prone to misjudgment
- Cannot distinguish between "processing" and "stuck"
- Terminal buffer is limited, historical messages may be scrolled away

## 4.4 Approach Three: SQLite Mail System (Overstory)

**Principle**: Use a SQLite database to implement an asynchronous message queue; Agents send and receive mail via CLI commands.

```typescript
// Send
mail.send({
  to: "lead-1",
  protocol: "dispatch",          // protocol type
  payload: { task: "...", files: [...] }
});

// Receive
const msgs = mail.check("builder-1");  // check and mark as read

// Reply (threaded)
mail.reply(originalMsg.id, { status: "done", summary: "..." });
```

**9 Protocol Message Types** (strongly-typed Payload):

| Type | Direction | Purpose |
|------|-----------|---------|
| `dispatch` | Coordinator → Lead | Task dispatch |
| `assign` | Supervisor → Worker | Work assignment |
| `worker_done` | Worker → Supervisor | Worker completed |
| `merge_ready` | Supervisor → Merger | Request merge |
| `merged` | Merger → Supervisor | Merge succeeded |
| `merge_failed` | Merger → Worker | Merge failed, rework needed |
| `escalation` | Any → Upper | Issue escalation |
| `health_check` | Watchdog → Agent | Health probe |
| `decision_gate` | Agent → Human | Human-machine decision gate |

**Group address broadcasting**: `@all`, `@builders`, `@scouts` and other group addresses are automatically resolved to lists of active Agents with corresponding capabilities.

**Hook injection**: Through a runtime UserPromptSubmit hook, mail content is injected into the Agent's context:

```bash
# When Agent submits a prompt, automatically check and inject unread mail
ov mail check --inject
```

**Pros**:
- Reliable: SQLite WAL mode guarantees message persistence
- Structured: strongly-typed protocols avoid natural language ambiguity
- Queryable: can search historical messages and trace threads
- Asynchronous: does not block the sender

**Cons**:
- Pull model: Agents need to actively check; latency depends on hook trigger frequency
- SQLite single-writer limitation: high-concurrency writes may become a bottleneck
- High complexity: requires understanding 9 protocol types

## 4.5 Approach Four: Shared File Coordination (Composio)

**Principle**: The Orchestrator and Workers coordinate work through shared todo.md and scratchpad files.

```
Orchestrator writes to todo.md:
  - [ ] Implement user authentication module (@worker-1)
  - [ ] Implement API endpoints (@worker-2)
  - [x] Set up project scaffolding (completed)

Worker reads and updates:
  - [→] Implement user authentication module (@worker-1)  ← marked in progress
  - [ ] Implement API endpoints (@worker-2)
```

**Pros**:
- Minimalist: no database or message queue needed
- Human-readable: view Markdown files directly to understand progress
- Agent-native: all AI Agents can read and write files

**Cons**:
- No concurrency protection: multiple Workers writing to todo.md simultaneously may conflict
- No real-time notification: requires polling for file changes
- Semantic ambiguity: Markdown format lacks strict parsing rules
- Loss risk: file corruption means all progress information is lost

## 4.6 Approach Five: MCP Memory + Copy-Paste Handoff (agency-agents-zh)

**Default mode**: Human-driven copy-paste handoff.

```
User copies and pastes between one Agent's output and another Agent's input:

Activate Backend Architect.
Here's our sprint plan: [paste Sprint Prioritizer output]
Here's our research brief: [paste UX Researcher output]
```

**Enhanced mode**: Automatic context passing via MCP memory server.

```
1. Agent A completes work → remember(decisions + deliverables + tags)
2. Agent B starts → recall(search context by tags)
3. On failure → rollback(return to checkpoint)
```

**7 standardized handoff templates**: Standard handoff, QA pass, QA fail, escalation report, stage gate, sprint handoff, incident handoff.

**Pros**:
- MCP mode supports semantic search and automatic context passing
- Handoff templates standardize information transfer format
- Rollback mechanism is a unique highlight

**Cons**:
- Default mode depends entirely on humans
- MCP requires an external server
- No runtime execution guarantee

## 4.7 In-Depth Comparison of Five Communication Approaches

| Dimension | Bracket-Paste | send-keys | SQLite Mail | Shared Files | MCP Memory |
|-----------|--------------|-----------|-------------|-------------|------------|
| **Reliability** | Medium | Low | High | Medium | Medium |
| **Latency** | Low | Low | Medium | Medium | High |
| **Structured** | None | None | Strongly-typed | Markdown | Semantic |
| **Queryable** | No | No | Yes | Yes | Yes |
| **Concurrency safety** | None | None | WAL mode | None | Implementation-dependent |
| **Implementation complexity** | Low | Very low | Medium | Low | High |
| **Human readability** | Yes | Yes | Requires tools | Yes | Yes |
| **Offline support** | No | No | Yes | Yes | Implementation-dependent |

## 4.8 Core Principles of Communication Design

Communication design principles distilled from the five projects:

### Principle 1: Use Structured Protocols for Critical Operations; Natural Language Is Fine for Routine Interaction

Overstory's approach is correct — task dispatch, completion notifications, and merge requests use strongly-typed protocols, while internal Agent work logs and thought processes use natural language.

### Principle 2: Push Over Pull

The problem with pull models (capture-pane polling, mail.check()) is uncontrollable latency. The ideal approach is:
- Push notifications for critical events (completion, failure, escalation)
- Pull for status queries

### Principle 3: Messages Must Be Persisted

In-memory/screen-based communication is entirely lost after an Agent crash. SQLite, filesystem, MCP memory — any persistence solution is better than "reading the screen."

### Principle 4: Communication Paths Must Be Explicitly Declared

Don't make Agents "guess" who to talk to. Explicit communication routing (like Overstory's mail address system) is far more reliable than implicit "read the screen and guess the state."

### Principle 5: Group Addresses Are Necessary

When the number of Agents exceeds 3, the complexity of point-to-point communication explodes. Group addresses like `@all` and `@builders` are necessary abstractions.
