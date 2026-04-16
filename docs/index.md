# Orchestrating Agents: From Hard Guards to Soft Constraints

> A systematic guide to AI Agent orchestration — infrastructure meets instruction.

[:fontawesome-brands-github: Star on GitHub](https://github.com/Puzhre/agent-orchestration-book){: .md-button .md-button--primary }

## What You'll Learn

This book systematically integrates knowledge from multiple open-source AI agent orchestrator projects and production systems:

**Part I: Hard Orchestration** — Using infrastructure to keep agents running:
- Process daemons (systemd, tmux)
- Timed scheduling (cron, self-scheduling loops)
- State persistence & fault recovery
- Inter-agent communication (bracket-paste, structured mail, file coordination)
- Concurrency isolation (git worktree, process isolation, file locks)

**Part II: Soft Orchestration** — Using prompts and skills to shape agent behavior:
- Prompt engineering for agents (rule blocks, mission injection, sprint-driven)
- Skill systems (reusable templates, MCP tools)
- Pipeline orchestration (multi-stage flows, quality gates)
- Antipatterns & failure modes

**Part III: Practice & Evolution** — Build and evolve your own orchestrator:
- Hands-on: Build your first orchestrator from scratch
- Evolution roadmap: From "barely running" to "intelligent self-healing"

## Source Projects

| Project | Key Feature |
|---------|-------------|
| [Tmux-Orchestrator](https://github.com/Jedward23/Tmux-Orchestrator) | Minimal self-scheduling, hierarchical roles |
| [agency-agents-zh](https://github.com/jnMetaCode/agency-agents-zh) | 50+ agent multi-stage pipeline |
| [Composio agent-orchestrator](https://github.com/ComposioHQ/agent-orchestrator) | Orchestrator-Worker, git worktree |
| [Overstory](https://github.com/jayminwest/overstory) | Layered Watchdog, structured mail |

## Contributing

Contributions welcome! Fork [the repo](https://github.com/Puzhre/agent-orchestration-book), create a feature branch, and open a Pull Request.

## License

[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) — Free to share and adapt with attribution.
