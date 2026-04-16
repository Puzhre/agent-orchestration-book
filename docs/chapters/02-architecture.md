# Architecture Patterns: From Dual-Agent to Layered Trees

## 2.1 Five Architecture Topologies

Architecture is the skeleton of an orchestrator. Five projects present five topologies from simplest to most complex:

```
┌─────────────┐     task_dispatch.sh     ┌─────────────┐
│  Architect   │ ──────────────────────→│   Worker     │
│  (Hermes)   │ ←── capture-pane poll ──│  (Codex)    │
└──────┬──────┘                        └─────────────┘
       │
   Orchestrator Daemon (patrol, fault tolerance, driving)
```

**Characteristics**:
- Simplest topology, two roles each with distinct responsibilities
- Architect is the sole decision-maker, worker passively accepts tasks
- Orchestrator is not an Agent, but a pure script daemon
- Only 2 communication paths: orchestrator↔architect, orchestrator↔worker, architect→worker

**Use case**: Small-to-medium projects, single tech stack, linear task progression

### Topology 2: Three-Layer Hierarchy (Tmux-Orchestrator)

```
┌──────────────────┐
│   Orchestrator    │  ← Global monitoring and coordination
└───────┬──────────┘
        │
   ┌────┴────┐
   │         │
┌──┴──┐  ┌──┴──┐
│ PM1 │  │ PM2 │       ← Project Managers, task assignment and quality control
└──┬──┘  └──┬──┘
   │        │
┌──┴──┐  ┌──┴──┐
│Eng1 │  │Eng2 │       ← Engineers, code implementation
└─────┘  └─────┘
```

**Real-World Implementation** (from Tmux-Orchestrator research):
- **Self-Triggering**: Agents schedule their own check-ins and continue work autonomously
- **Cross-Project Coordination**: Project managers assign tasks to engineers across multiple codebases
- **Git Discipline**: Mandatory 30-minute commits, feature branches, meaningful commit messages
- **Bracket-Paste Communication**: Multi-line messages sent via tmux bracket-paste for clean transfer
- **Status Monitoring**: Real-time status updates from multiple agents working in parallel

**Characteristics**:
- Adds a PM middle layer on top of dual-agent
- PM handles quality control, Orchestrator focuses on cross-project coordination
- Hub-and-Spoke communication: developers report only to PM, PM reports to Orchestrator
- Can scale by adding more PMs and Engineers as needed

**Use case**: Multi-project parallel work, mid-to-large projects requiring quality control

### Topology 3: Prompt Pipeline (agency-agents-zh)

```
┌─────────────────────────────────────────────┐
│              Seven-Stage Pipeline            │
│                                              │
│ Stage0→Stage1→Stage2→Stage3↔Stage4→Stage5→Stage6 │
│ (Intel) (Strat) (Base) (Build) (QA) (Ship) (Ops)│
│                                              │
│ Each stage activates a different agent subset │
│ Mandatory quality gates between stages       │
└─────────────────────────────────────────────┘
```

**Real-World Implementation** (from agency-agents-zh research):
- **Massive Scale**: 211 expert agents across 18 departments (165 translated + 46 China-specific)
- **Zero-Code Orchestration**: Pure natural language or YAML specification
- **DAG Workflow**: Automatic dependency detection, parallel execution for independent steps
- **Breakpoint Resume**: Failed steps can be re-run independently, no need to restart from beginning
- **Multi-Tool Support**: 16 AI programming tools including Claude Code, Gemini CLI, Copilot, Codex
- **Template System**: 32 ready-to-use templates for development, marketing, design, operations

**Characteristics**:
- Not a runtime architecture, but a process specification defined in prompts
- 50+ agents activated per stage, not all online simultaneously
- Pipeline is linear, but each stage can run internally in parallel
- Three deployment modes: Full (50+ agents), Sprint (15-25), Micro (5-10)

**Use case**: Product development requiring strict quality processes, not pure coding scenarios

### Topology 4: Orchestrator-Worker (Composio)

```
┌─────────────────────────────────┐
│       Orchestrator Agent        │  ← Task decomposition + progress monitoring + result integration
│   (via --append-system-prompt   │
│    injecting orchestration      │
│    instructions)                │
└───────┬────────┬────────┬───────┘
        │        │        │
   ┌────┴──┐ ┌──┴───┐ ┌──┴───┐
   │Worker1│ │Worker2│ │Worker3│    ← Independent git worktrees
   │(code) │ │(code) │ │(code) │       Parallel subtask execution
   └───────┘ └──────┘ └──────┘
```

**Real-World Implementation** (from Composio research):
- **CI/CD Integration**: Agents autonomously fix CI failures, address review comments, open PRs
- **PR-Based Workflow**: Each agent gets its own branch and PR, human oversight through dashboard
- **Runtime Agnostic**: Supports Claude Code, Codex, Aider with tmux/Docker backends
- **Tracker Integration**: GitHub/Linear integration, human judgment escalation only when needed
- **Parallel Processing**: Multiple agents work simultaneously on different parts of codebase

**Characteristics**:
- Classic master-worker pattern, Orchestrator doesn't write code, only coordinates
- Each Worker has an independent git worktree, fully isolated
- Communication based on shared files (todo.md/scratchpad)
- Orchestrator itself is an AI Agent (orchestration capability injected via prompt)

**Use case**: Parallel development on large codebases, low-dependency subtasks

### Topology 5: Coordinator-Lead-Worker Tree (Overstory)

```
┌─────────────────┐
│   Coordinator   │  ← Persistent coordinator, runs across batches
└───────┬─────────┘
        │ mail dispatch
   ┌────┴────┐
   │         │
┌──┴──┐  ┌──┴──┐
│Lead1│  │Lead2│         ← Team leads, Phase flow management
└─┬─┬─┘  └─┬─┬─┘
  │ │      │ │
 S B R    S B R          ← Scout/Builder/Reviewer
```

**Real-World Implementation** (from Overstory research):
- **SQLite Mail System**: Custom SQLite-based messaging for inter-agent communication
- **11 Runtime Support**: Claude Code, Pi, Gemini CLI, Aider, Goose, Amp, and more
- **Tiered Conflict Resolution**: Three-tier merge conflict handling
- **Warning System**: Comprehensive risk analysis for agent swarms
- **Phase Flow**: Leads advance through Scout→Build→Review→Merge phases
- **Persistent Roles**: Coordinator and Supervisor exist across batches

**Characteristics**:
- Most complex topology, three-layer delegation + specialized roles
- Leads advance through Phase flow: Scout→Build→Review→Merge
- Coordinator and Supervisor are persistent roles, exist across batches
- Each Lead independently manages its own sub-team

**Use case**: Ultra-large projects requiring deep division of labor and continuous operation

## 2.2 Key Trade-offs in Architecture Selection

### Trade-off 1: Simplicity vs Scalability

| Topology | Role Count | Code Size | Scaling to 10 Agents |
|----------|-----------|-----------|---------------------|
| Dual-Agent Loop | 2 | ~700 lines Bash | Not supported |
| Three-Layer Hierarchy | 3-6 | ~1000 lines Bash+Markdown | Manual configuration needed |
| Prompt Pipeline | 50+ | Pure Markdown | Naturally supported |
| Orchestrator-Worker | 1+N | TS monorepo | Specified via config file |
| Tree | 1+M+N×3 | TS/Bun large project | Auto-spawn |

**Conclusion**: For teams of 2-4 agents, dual-agent or three-layer hierarchy is most practical. Beyond 5 agents, Orchestrator-Worker or tree topology is needed.

### Trade-off 2: Orchestrator's Role — Agent or Script?

| Project | What is the Orchestrator | Advantage | Disadvantage |
|---------|------------------------|-----------|-------------|
| Tmux-Orchestrator | Claude Agent | Can understand complex situations and make judgments | Consumes tokens, may misjudge |
| Composio | Claude Agent (prompt-injected) | Agent-agnostic design | Orchestration quality depends on LLM |
| Overstory | Hybrid: scripts for monitoring + Agent for triage | Balances reliability and intelligence | Complex implementation |
| agency-agents-zh | None (pure specification) | Zero implementation cost | No execution guarantee |

**Key Insight**: The "intelligence level" of the orchestrator should be inversely proportional to fault tolerance requirements. Critical operations like monitoring and recovery should use deterministic scripts, while task decomposition and anomaly diagnosis can use AI Agents. Overstory's "Tier 0 mechanical guard + Tier 1 AI triage" is the best embodiment of this principle.

### Trade-off 3: State Storage — Files vs Database vs Stateless

| Project | State Storage | Advantage | Disadvantage |
|---------|-------------|-----------|-------------|
| Tmux-Orchestrator | Text files + next_check_note.txt | Ultra-simple | Lost after restart |
| Composio | YAML config + running-state file | Structured | Single-machine limitation |
| Overstory | SQLite (WAL mode) | Concurrent-safe, queryable | SQLite dependency |
| agency-agents-zh | MCP memory server | Semantic search, rollback | External dependency |

**Key Insight**: For multi-agent concurrent scenarios, SQLite (WAL) is currently the best practice — it provides concurrency safety and query capabilities that the filesystem lacks, without introducing heavy dependencies like Redis/PostgreSQL.

## 2.3 New Pattern: Handoff-Based Orchestration (OpenAI Swarm/Agents SDK)

OpenAI's Swarm (now evolved into the [Agents SDK](https://github.com/openai/openai-agents-python)) introduces a different paradigm: **handoff-based orchestration**. Instead of a central orchestrator dispatching tasks, agents hand off conversations to each other.

```python
from swarm import Swarm, Agent

def transfer_to_agent_b():
    return agent_b

agent_a = Agent(
    name="Agent A",
    instructions="You are a helpful agent.",
    functions=[transfer_to_agent_b],
)

agent_b = Agent(
    name="Agent B",
    instructions="Only speak in Haikus.",
)
```

**Key characteristics**:
- Two primitives: `Agent` (instructions + tools) and **handoffs** (transfer to another agent)
- No central orchestrator — agents decide when to hand off
- Stateless between calls (Factor 12 from 12-Factor Agents)
- Lightweight, highly controllable, easily testable

**Comparison with orchestrator patterns**:

| Dimension | Handoff (Swarm) | Orchestrator-Worker (Composio) |
|-----------|-----------------|-------------------------------|
| Control | Distributed (agents decide) | Centralized (orchestrator decides) |
| Complexity | Very low | Medium |
| Reliability | Depends on agent judgment | Deterministic monitoring |
| Scalability | Limited (2-5 agents) | High (N workers) |
| Best for | Customer service, routing | Parallel coding, CI/CD |

**Key Insight**: Handoff-based orchestration is soft orchestration in its purest form — the "orchestration" is entirely in the prompt (instructions tell agents when to hand off). There is no hard orchestration layer. This works for simple routing but breaks down for long-running autonomous work where you need deterministic monitoring and recovery.

*Reference: [openai/swarm](https://github.com/openai/swarm) → [openai/openai-agents-python](https://github.com/openai/openai-agents-python)*

## 2.4 Architecture Evolution Path

From the experience of five projects, we summarize the orchestrator architecture evolution path:

```
Level 0: Manual Coordination (no orchestrator)
  Humans manually copy-paste between multiple AI tools
  ↓
Level 1: Script-Driven (Tmux-Orchestrator)
  Bash scripts manage agent lifecycle, simple patrol + restart
  ↓
Level 2: Framework-Driven (Composio)
  Structured configuration + automatic agent detection + session management
  ↓
Level 3: Protocol-Driven (Overstory)
  Structured messaging protocol + multi-layer fault tolerance + knowledge accumulation
  ↓
Level 4: Autonomous System (ultimate form)
  Auto-spawn/destroy agents + dynamic topology adjustment + cross-project learning
```

Each level increases system reliability, but complexity grows exponentially. **Which level to choose depends on your scenario and team capability** — Level 1 already solves 80% of problems.
