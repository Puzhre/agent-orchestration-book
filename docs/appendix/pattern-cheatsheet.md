# Pattern Cheatsheet

> One-page quick reference for all orchestration patterns

## Architecture Patterns

| Pattern | Topology | Applicable Scenarios | Representative Project |
|---------|----------|---------------------|----------------------|
| Dual-Agent Loop | A↔B | Small-to-medium projects | Three-Layer Hierarchy | O→PM→E | Multi-task parallelism | Tmux-Orchestrator |
| Multi-Stage Pipeline | Linear 7 stages | Quality-first | agency-agents-zh |
| Orchestrator-Worker | 1:N | Framework-based | Composio |
| Layered Watchdog | 4-layer daemon | Production-grade | Overstory |

## Fault Tolerance Patterns

| Pattern | Mechanism | Recovery Speed | Applicable Scenarios |
|---------|-----------|---------------|---------------------|
| Self-Scheduling | nohup+sleep | Slow (minutes) | Simple projects |
| Built-in Watchdog | Heartbeat check | Fast (seconds) | Medium projects |
| Dual-Layer Watchdog | Inner + Outer | Very fast (15s) | Critical projects |
| Progressive Remediation | 4-level escalation | As needed | General |

## Communication Patterns

| Pattern | Reliability | Latency | Complexity | Representative Project |
|---------|------------|---------|------------|----------------------|
| send-keys | Low | Low | Low | Tmux-Orchestrator |
| bracket-paste | Medium | Low | Medium | Shared Files | Medium | Medium | Low | Composio |
| SQLite Mail | High | Medium | High | Overstory |
| MCP Memory | Low | High | Medium | agency-agents-zh |

## Isolation Patterns

| Pattern | Isolation Strength | Complexity | Representative Project |
|---------|-------------------|------------|----------------------|
| Prompt Specification | Weak | Low | agency-agents-zh |
| Role Division | Medium | Low | Git Worktree | Strong | Medium | Overstory/Composio |

## Knowledge Accumulation Patterns

| Pattern | Structured | Queryable | Representative Project |
|---------|-----------|----------|----------------------|
| Natural Language Docs | Low | No | Tmux-Orchestrator |
| Feature Tracking | Medium | No | Structured Knowledge Base | High | Yes | Overstory |
| MCP Memory Service | High | Yes | agency-agents-zh |

## Anti-Pattern Quick Reference

| Anti-Pattern | One-Liner | Fix |
|-------------|-----------|-----|
| No Watchdog | Automation ≠ Reliability | Add Watchdog |
| Self-Modifying Rules | Agents are not trustworthy | External daemon |
| Single-Point Orchestrator | One failure kills all | Layering/Self-Scheduling |
| Natural Language Communication | Messages will be lost | Structured protocol |
| Infinite Retry | 429 loop | Progressive Remediation |
| Shared Space | File conflicts | Physical isolation |
| Context Waste | Tokens burning money | Layered context |
| Stateless Restart | Repeated work | State persistence |
| Over-Engineering | Harder to maintain than the Agents themselves | Progressive enhancement |
