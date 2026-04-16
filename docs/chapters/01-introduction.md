# Introduction: Core Problems of AI Agent Orchestration

## 1.1 Why Do We Need Orchestration?

Individual AI Agents are already powerful—Claude Code can write code, Codex can implement features, Aider can refactor. But when you need:

- **24/7 unmanned project advancement**—humans can't monitor continuously
- **Multi-agent collaboration for complex tasks**—a single agent's context window can't hold everything
- **Quality over speed**—agents tend to settle for "good enough"
- **Recovery from errors rather than starting over**—agents can't lose all progress when they crash

This is where an **Orchestrator** becomes essential.

An orchestrator is not just another agent, but a **control system that enables effective collaboration among multiple agents**. It answers three core questions:

1. **Who does what**—roles and division of labor
2. **How do they communicate**—communication and coordination
3. **What happens when things fail**—fault tolerance and recovery

## 1.2 Five Core Pain Points Orchestrators Must Solve

From analyzing source code of five projects, we've identified five critical pain points that orchestrators must address:

### Pain Point 1: Context Window Limitations

Individual agents have limited context windows (128K, 200K, etc.). When a project's codebase, historical decisions, and task lists exceed this capacity, agents start to "forget."

- **Tmux-Orchestrator's approach**: Three-tier architecture (Orchestrator→PM→Engineer), each layer focusing only on its own context
- **agency-agents-zh's approach**: 50+ specialized agents, each responsible for a narrow domain
- **Overstory's approach**: Scout only explores, Builder only codes, Reviewer only reviews—roles as context isolation
- **Our approach**: Architect + Executor dual-agent, architect doesn't touch code, executor doesn't touch planning

**Key Insight**: Context isolation is not an optional optimization but a fundamental constraint of orchestration.

### Pain Point 2: Insufficient Agent Reliability

AI Agents can:
- Get stuck in loops (repeatedly trying the same approach)
- Be rate-limited (429 Too Many Requests)
- Crash and exit (OOM, API timeouts)
- Take shortcuts and be lazy (skip testing, use hardcoding)
- Modify their own constraints (delete rules from prompts)

Each orchestrator spends significant effort on **fault tolerance**:

| Project | Fault Tolerance Layers | Core Mechanism |
|---------|----------------------|----------------|
| Overstory | 4 layers | Mechanical guardian→AI triage→monitoring→Supervisor |
| Tmux-Orchestrator | 1 layer | Self-scheduling chain (nohup+sleep) |
| agency-agents-zh | 4 layers | Task retry→escalation protocol→quality gates→reality check |
| Composio | 1 layer | LifecycleWorker process monitoring |

**Key Insight**: Fault tolerance is not a luxury but the core value of an orchestrator. An orchestrator without fault tolerance is more dangerous than no orchestrator at all—it creates the illusion of automation.

### Pain Point 3: Difficult Inter-Agent Communication

How do two independently running agent processes communicate? This is not simple function calling:

- They may be in different terminals/windows/tmux sessions
- They don't understand each other's internal states
- Their output is unstructured natural language

The five projects have taken five different approaches:

| Project | Communication Method | Reliability | Latency |
|---------|---------------------|-------------|---------|
| Tmux-Orchestrator | send-keys + capture-pane | Low | Low |
| Overstory | SQLite email system | High | Medium |
| Composio | Shared files (todo.md) | Medium | Medium |
| agency-agents-zh | MCP memory/copy-paste | Low | High |

**Key Insight**: The reliability of the communication mechanism determines the upper limit of the orchestration system. Communication based on screen text parsing (capture-pane + grep) is the most fragile, while structured protocol communication is the most reliable.

### Pain Point 4: Concurrency Conflicts

When multiple agents work simultaneously, they might:
- Modify the same file
- Operate on the same git branch
- Request the same API (triggering rate limiting)
- Work on the same task redundantly

| Project | Isolation Method | Effectiveness |
|---------|-----------------|---------------|
| Overstory | git worktree independent workspaces | Strongest—complete code-level isolation |
| Composio | git worktree independent workspaces | Strongest—same as above |
| Tmux-Orchestrator | PM assigns different files to different Engineers | Weak—depends on PM's allocation |
| agency-agents-zh | No runtime isolation | None—pure prompt specification only |

**Key Insight**: Git worktree is currently the most reliable concurrency isolation solution, but it requires additional merge strategies.

### Pain Point 5: Inability to Accumulate Experience

Agents start as "blank slate" each time, making the same mistakes as before. How can the system learn from experience?

| Project | Knowledge Accumulation Method |
|---------|-----------------------------|
| Tmux-Orchestrator | LEARNINGS.md—natural language experience documentation |
| Overstory | Mulch knowledge base—structured conflict patterns + failure records |
| agency-agents-zh | MCP memory server—remember/recall/rollback |
| Composio | None |
| Tmux-Orchestrator | FEATURES.md—feature tracking to prevent duplicate development |

**Key Insight**: Knowledge accumulation is the key step that elevates an orchestrator from a "tool" to a "system." Without knowledge accumulation, an orchestrator always does repetitive tasks.

## 1.3 Design Philosophies of the Five Projects

Each project背后 has different design philosophies that determine its architectural choices and trade-offs:

### Tmux-Orchestrator: Minimalism

> "tmux is the operating system, Claude CLI is the runtime, two scripts are the infrastructure"

Philosophy: Do the most with the fewest dependencies. The core innovation is **self-scheduling**—agents can set alarms to wake up and check. The drawback is that all "mechanisms" are natural language conventions without mandatory enforcement.

### agency-agents-zh: Structured Governance

> "Run an AI team like running a company"

Philosophy: Use processes and systems to ensure quality. Seven-stage pipelines, quality gates, standardized handover templates, escalation protocols—this is not a technical solution but an **organizational management solution**. The drawback is the lack of a runtime engine, relying entirely on humans (or host AI tools) for execution.

### Composio agent-orchestrator: Framework Approach

> "Let users start multi-agent parallel development with one command"

Philosophy: Build frameworks rather than applications. Agent-agnostic design, automatic configuration generation, Dashboard visualization—the goal is to make it easy for anyone to get started quickly. The drawback is insufficient orchestration depth, with the Orchestrator as a single point.

### Overstory: Engineering Completeness

> "From Tier 0 mechanical guardian to Tier 3 Supervisor, each layer has clear responsibilities and recovery strategies"

Philosophy: Production systems must have multiple layers of protection. 4-layer watchdog, ZFC health checks, structured email protocols, 4-level merge strategies—this is the only project that truly considers "how to precisely recover after an agent crash." The drawback is extremely high complexity.

## 1.4 Book Structure

Over the next nine chapters, we will delve deeper by theme:

- **Chapter 2**: Architecture—Why did these projects choose different topologies?
- **Chapter 3**: Roles—How are roles defined and constrained?
- **Chapter 4**: Communication—Five reliable communication schemes between agents
- **Chapter 5**: Fault Tolerance—Evolution from 1-layer to 4-layer protection
- **Chapter 6**: Isolation—Four weapons for concurrency safety
- **Chapter 7**: Knowledge—How to make orchestrators evolve from experience
- **Chapter 8**: Deployment—From development to production
- **Chapter 9**: Patterns—Reusable design patterns
- **Chapter 10**: Roadmap—Specific improvement plans