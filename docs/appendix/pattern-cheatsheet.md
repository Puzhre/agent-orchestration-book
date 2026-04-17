# Pattern Cheatsheet

> One-page quick reference for all orchestration patterns

## Architecture Patterns

| Pattern | Topology | Applicable Scenarios | Representative Project |
|---------|----------|---------------------|----------------------|
| Dual-Agent Loop | A↔B | Small projects, tight coupling | Claude Code |
| Three-Layer Hierarchy | O→PM→E | Multi-task parallelism | Tmux-Orchestrator |
| Multi-Stage Pipeline | Linear 7 stages | Quality-first workflows | agency-agents-zh |
| Orchestrator-Worker | 1:N | Framework-based orchestration | Composio |
| Coordinator Tree | Root→Lead→Worker | Large-scale, hierarchical | Overstory |
| Layered Watchdog | 4-layer daemon | Production-grade fault tolerance | Overstory |

## Fault Tolerance Patterns

| Pattern | Mechanism | Recovery Speed | Applicable Scenarios |
|---------|-----------|---------------|---------------------|
| Self-Scheduling | nohup+sleep loop | Slow (minutes) | Simple, single-agent |
| Built-in Watchdog | Heartbeat check + nudge | Fast (seconds) | Medium projects |
| Dual-Layer Watchdog | Inner loop + systemd outer | Very fast (15s) | Critical projects |
| Tiered Watchdog | Bash timer + AI triage | Adaptive | Complex multi-agent |
| Progressive Remediation | 4-level escalation (nudge→restart→AI triage→human) | As needed | General purpose |
| Checkpoint Resume | Save/restore state on crash | Instant | Long-running pipelines |

## Communication Patterns

| Pattern | Reliability | Latency | Complexity | Representative Project |
|---------|------------|---------|------------|----------------------|
| send-keys | Low | Low | Low | Tmux-Orchestrator |
| bracket-paste | Medium | Low | Medium | Tmux-Orchestrator |
| Shared Files | Medium | Medium | Low | Composio |
| SQLite Mail | High | Medium | High | Overstory |
| MCP Memory | Medium | High | Medium | agency-agents-zh |
| Event Store | High | Low | High | Overstory |

## Isolation Patterns

| Pattern | Isolation Strength | Complexity | Representative Project |
|---------|-------------------|------------|----------------------|
| Prompt Specification | Weak | Low | agency-agents-zh |
| Role Division | Medium | Low | Tmux-Orchestrator |
| File Assignment | Medium | Medium | Tmux-Orchestrator |
| Session Isolation | Medium | Low | All tmux projects |
| Git Worktree | Strong | High | Overstory / Composio |

## Knowledge Accumulation Patterns

| Pattern | Structured | Queryable | Auto-Extract | Representative Project |
|---------|-----------|----------|-------------|----------------------|
| Natural Language Docs | Low | No | No | Tmux-Orchestrator (LEARNINGS.md) |
| Feature Tracking | Medium | No | No | Tmux-Orchestrator (FEATURES.md) |
| MCP Memory Service | High | Yes (semantic) | No | agency-agents-zh |
| Structured Knowledge Base | High | Yes (query) | Partial | Overstory (Mulch) |
| Event Store | High | Yes (time-series) | Yes | Overstory |

## Dispatch Patterns

| Pattern | Coupling | Scalability | Representative Project |
|---------|----------|------------|----------------------|
| Manual Assignment | Tight | Poor | agency-agents-zh |
| Script-Based Dispatch | Medium | Medium | Tmux-Orchestrator |
| Capability-Based Dispatch | Loose | Good | Overstory |
| Market-Based Bidding | Very Loose | Excellent | (theoretical) |

## Merge Patterns

| Pattern | Conflict Handling | Automation Level | Representative Project |
|---------|------------------|-----------------|----------------------|
| No Merge (single writer) | None needed | N/A | agency-agents-zh |
| Manual Merge | Human resolves | None | Composio (basic) |
| Auto + AI-Assisted Merge | 4-level strategy | High | Overstory |

## Anti-Pattern Quick Reference

| Anti-Pattern | One-Liner | Fix |
|-------------|-----------|-----|
| No Watchdog | Automation ≠ Reliability | Add Watchdog |
| Self-Modifying Rules | Agents are not trustworthy | External daemon |
| Single-Point Orchestrator | One failure kills all | Layering / Self-Scheduling |
| Natural Language Communication | Messages will be lost | Structured protocol |
| Infinite Retry | 429 loop of death | Progressive Remediation |
| Shared Space | File conflicts inevitable | Physical isolation (worktree) |
| Context Waste | Tokens burning money | Layered context / overlay injection |
| Stateless Restart | Repeated work after crash | State persistence |
| Over-Engineering | Harder to maintain than the Agents | Progressive enhancement |
| Capability Coupling | Hard-coded agent assignments | Capability-based dispatch |
| Knowledge Amnesia | Every session starts from zero | Structured knowledge base |
