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

## 4.7 Deep Dive: Swarm Handoff vs SQLite Mail - A Detailed Comparison

### The Architectural Divide

**Swarm Handoff (agency-agents-zh)** represents a human-in-the-loop approach where context transfer happens through structured handoff templates, while **SQLite Mail (Overstory)** implements a machine-to-machine coordination system with typed protocol messages.

### Implementation Architecture

#### Swarm Handoff: Memory-Based Context Transfer

```typescript
// Core handoff workflow
interface HandoffContext {
  decisions: string[];
  deliverables: string[];
  tags: string[];
  checkpoint: string;
}

// MCP memory operations
1. Agent A completes work → remember(decisions + deliverables + tags)
2. Agent B starts → recall(search context by tags)
3. On failure → rollback(return to checkpoint)
```

**Key Components:**
- **7 standardized handoff templates**: Standard handoff, QA pass, QA fail, escalation report, stage gate, sprint handoff, incident handoff
- **MCP memory server**: Provides semantic search and automatic context passing
- **Rollback mechanism**: Unique ability to return to previous checkpoints
- **Human-driven default mode**: Copy-paste between Agent outputs and inputs

#### SQLite Mail: Protocol-Based Coordination

```typescript
// Mail system with strong typing
interface MailMessage {
  id: string;
  from: string;
  to: string;
  subject: string;
  body: string;
  type: MailProtocolType;
  priority: "low" | "normal" | "high" | "urgent";
  threadId: string | null;
  payload: string | null; // JSON-encoded structured data
  read: boolean;
  createdAt: string;
}

// 9 protocol types with structured payloads
type MailProtocolType = 
  | "dispatch"      // Coordinator → Lead: Task dispatch
  | "assign"        // Supervisor → Worker: Work assignment
  | "worker_done"    // Worker → Supervisor: Task completion
  | "merge_ready"    // Supervisor → Merger: Request merge
  | "merged"         // Merger → Supervisor: Merge success
  | "merge_failed"   // Merger → Worker: Merge failed
  | "escalation"     // Any → Upper: Issue escalation
  | "health_check"   // Watchdog → Agent: Health probe
  | "decision_gate"  // Agent → Human: Human-machine decision
```

**Key Components:**
- **SQLite WAL mode**: Ensures concurrent access safety
- **Hook injection**: Messages automatically injected via UserPromptSubmit hook
- **Group addresses**: `@all`, `@builders`, `@scouts` resolve to agent lists
- **Threaded conversations**: Maintains conversation context across messages

### Detailed Comparison Matrix

| Dimension | Swarm Handoff | SQLite Mail |
|-----------|---------------|-------------|
| **Primary Use Case** | Human-AI collaboration workflows | Machine-to-machine coordination |
| **Context Transfer** | Semantic search via tags | Structured protocols with payloads |
| **Error Recovery** | Rollback to checkpoints | Retry with escalation paths |
| **Scalability** | Limited by human handoff capacity | High (automatic protocol routing) |
| **Real-time Performance** | Medium (depends on human speed) | High (1-5ms mail operations) |
| **Complexity Management** | Templates reduce cognitive load | Type system prevents ambiguity |
| **Multi-Agent Orchestration** | Manual coordination | Automatic hierarchical dispatch |
| **Failure Handling** | Human intervention required | Automated escalation workflows |

### When to Choose Each Approach

#### Choose Swarm Handoff When:
- You need human oversight in the workflow
- Context transfer requires semantic understanding
- Projects involve creative decision-making
- Team size is small (< 10 agents)
- Quality control requires human judgment
- You need rollback capabilities for iterative work

#### Choose SQLite Mail When:
- You need fully automated multi-agent coordination
- Structured protocols are required for reliability
- Large-scale deployment (> 10 agents)
- Machine-to-machine communication dominates
- Real-time coordination is critical
- Hierarchical organization is needed

### Implementation Patterns

#### Swarm Handoff Implementation
```markdown
# Standard Handoff Template
## 元数据
- 发送方: [智能体名称]（[部门]）
- 接收方: [智能体名称]（[部门]）
- 阶段: 第 [N] 阶段 — [阶段名称]
- 任务引用: [任务 ID]
- 优先级: [紧急 / 高 / 中 / 低]

## 上下文
- 项目: [项目名称]
- 当前状态: [具体进展]
- 相关文件: [文件列表]
- 依赖: [依赖关系]
- 约束: [技术约束]

## 交付要求
- 需要什么: [具体交付物]
- 验收标准: [可衡量的标准]
- 参考材料: [相关链接]

## 质量预期
- 必须通过: [质量标准]
- 需要的证据: [完成证明]
- 下一步: [接收方要求]
```

#### SQLite Mail Implementation
```typescript
// Sending a task dispatch
mail.sendProtocol({
  from: "coordinator",
  to: "lead-1",
  subject: "Implement user authentication",
  type: "dispatch",
  priority: "high",
  payload: {
    taskId: "auth-001",
    specPath: "specs/auth-spec.md",
    capability: "backend",
    fileScope: ["src/auth/", "tests/auth/"],
    skipScouts: true
  }
});

// Receiving and processing
const messages = mail.check("lead-1");
for (const msg of messages) {
  if (msg.type === "dispatch") {
    const payload = parsePayload(msg, "dispatch");
    // Process task dispatch
  }
}
```

### Performance Characteristics

#### Swarm Handoff
- **Latency**: Variable (human-dependent)
- **Reliability**: High (human oversight)
- **Throughput**: Low (limited by human speed)
- **Scalability**: Poor beyond small teams

#### SQLite Mail
- **Latency**: 1-5ms per operation
- **Reliability**: High (WAL mode, type safety)
- **Throughput**: High (concurrent access)
- **Scalability**: Excellent (hierarchical routing)

### Integration Patterns

#### Hybrid Approach
Many successful orchestrators combine both approaches:

1. **SQLite Mail** for machine-to-machine coordination
2. **Swarm Handoff** for human-in-the-loop decision points
3. **MCP Memory** for cross-session context persistence

### Real-World Examples

#### agency-agents-zh NEXUS System
- Uses handoff templates for quality gates
- MCP memory for cross-session context
- Human oversight at critical decision points
- Rollback capability for iterative refinement

#### Overstory System
- SQLite mail for all inter-agent communication
- Protocol types for different coordination needs
- Hook injection for seamless integration
- Group addresses for broadcast messaging

## 4.8 In-Depth Comparison of Five Communication Approaches

|| Dimension | Bracket-Paste | send-keys | SQLite Mail | Shared Files | MCP Memory |
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
