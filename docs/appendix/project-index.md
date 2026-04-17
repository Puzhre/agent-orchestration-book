# Project Index

> Summary of all Orchestrator projects analyzed in this book

## Detailed Project Profiles

### Tmux-Orchestrator

| Dimension | Details |
|-----------|---------|
| **Language/Tech Stack** | Bash + tmux |
| **Core Architecture** | Three-Layer Hierarchy (Orchestrator → Architect → Executor) |
| **Communication Method** | bracket-paste injection + capture-pane monitoring |
| **Fault Tolerance** | 2 layers (built-in heartbeat + systemd watchdog) |
| **Knowledge Accumulation** | CLAUDE.md + LEARNINGS.md + FEATURES.md |
| **Isolation** | Role separation (Architect manages plans, Executor writes code) |
| **Deployment** | systemd user service + loginctl linger |
| **Key Features** | Self-triggering agents, git discipline, cross-project coordination |
| **Repository** | [GitHub](https://github.com/Jedward23/Tmux-Orchestrator) |
| **Evolution Stage** | Stage 2 (reliable operation, progressing toward Stage 3) |

**Standout innovation**: The bracket-paste protocol solves a real tmux problem — multi-line text corruption via send-keys. This is a "battle scar" pattern that can only come from production experience.

### agency-agents-zh

| Dimension | Details |
|-----------|---------|
| **Language/Tech Stack** | Markdown + MCP Memory Server |
| **Core Architecture** | Seven-Stage Pipeline (Recon → Plan → Review → Build → Test → Deploy → Monitor) |
| **Communication Method** | MCP Memory (semantic search + rollback) + copy-paste handoff |
| **Fault Tolerance** | 4 layers (quality gates at each pipeline stage) |
| **Knowledge Accumulation** | MCP Memory (remember/recall/rollback) |
| **Isolation** | Minimal (prompt-based role specification only) |
| **Deployment** | install.sh script deploys to 10+ AI tool formats |
| **Key Features** | 211 expert agents, DAG workflow, breakpoint resume, 32 handoff templates, cross-platform deployment |
| **Repository** | [GitHub](https://github.com/jnMetaCode/agency-agents-zh) |
| **Evolution Stage** | Stage 1 (running, but lacks autonomous fault tolerance) |

**Standout innovation**: Cross-platform agent deployment — a single agent definition can be installed as Claude Code, GitHub Copilot, Cursor, Aider, Windsurf, and more. This "write once, deploy everywhere" approach is unique in the ecosystem.

### Composio (agent-orchestrator)

| Dimension | Details |
|-----------|---------|
| **Language/Tech Stack** | TypeScript + pnpm |
| **Core Architecture** | Orchestrator-Worker (1:N with dashboard) |
| **Communication Method** | Shared files (todo.md, scratchpad) + JSON handoff |
| **Fault Tolerance** | 2 layers (LifecycleWorker + dashboard monitoring) |
| **Knowledge Accumulation** | None (agents are stateless per session) |
| **Isolation** | git worktree (Workers in independent worktrees) |
| **Deployment** | `ao start <url>` one-click CLI |
| **Key Features** | CI/CD integration, PR-based workflow, runtime agnostic, React dashboard, preflight checks |
| **Repository** | [GitHub](https://github.com/ComposioHQ/agent-orchestrator) |
| **Evolution Stage** | Stage 2 (reliable, but knowledge gap limits Stage 3) |

**Standout innovation**: Preflight mechanism — check all dependencies before starting, rather than discovering "git not installed" at runtime. This is a DevOps best practice applied to Agent orchestration.

### Overstory

| Dimension | Details |
|-----------|---------|
| **Language/Tech Stack** | TypeScript + Bun runtime |
| **Core Architecture** | Coordinator → Lead → Worker tree (hierarchical) |
| **Communication Method** | SQLite Mail (9 protocol types + group addresses) |
| **Fault Tolerance** | 4 layers (tiered watchdog: bash timer + AI triage) |
| **Knowledge Accumulation** | Mulch Knowledge Base (conflict patterns, failure patterns, project knowledge) |
| **Isolation** | git worktree (managed by WorktreeManager) + 4-level merge strategy |
| **Deployment** | `ov init` + `ov coordinator` CLI |
| **Key Features** | 11 runtime adapters, capability-based dispatch, overlay injection, event store, checkpoint handoff |
| **Repository** | [GitHub](https://github.com/jayminwest/overstory) |
| **Evolution Stage** | Stage 3 (intelligent enhancement, most mature) |

**Standout innovation**: Overlay injection — a three-layer rendering system (role definition + project profile + task assignment) that ensures every agent starts with the right context. This is the "consumer side" of knowledge accumulation.

### Reference Projects (Not Deeply Analyzed)

| Project | Language | Architecture | Key Contribution |
|---------|----------|-------------|-----------------|
| Claude Code | TypeScript | Single-Agent CLI | Native CLI integration, CLAUDE.md convention |
| CrewAI | Python | Role Collaboration | Human-agent collaboration, shared memory |
| LangGraph | Python | State Graph | Graph-based workflows, conditional edges, checkpoints |
| AutoGen | Python | Multi-Agent Conversation | Conversational orchestration, code execution |
| OpenAI Swarm | Python | Agent Handoff | Minimal handoff framework, lightweight |

## Cross-Project Comparison Matrix

| Dimension | Tmux-Orch | agency-zh | Composio | Overstory |
|-----------|-----------|-----------|----------|-----------|
| **Setup Complexity** | Medium | Low | Low | Medium |
| **Max Agent Count** | 3-5 | 211 (catalog) | 5-10 | 5-20 |
| **Autonomy Level** | High | Low (human-driven) | Medium | High |
| **Production Readiness** | Battle-tested | Template-only | Early stage | Most complete |
| **Cross-Runtime** | No | Yes (10+ formats) | Partial (4 runtimes) | Yes (11 adapters) |
| **Knowledge Persistence** | LEARNINGS.md | MCP Memory | None | Mulch + Event Store |
| **Merge Strategy** | None | None | Basic | 4-level AI-assisted |
