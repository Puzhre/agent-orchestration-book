# Orchestrating Agents: From Hard Guards to Soft Constraints

[中文](./README.zh.md) | **English**

[![GitHub Pages](https://img.shields.io/badge/Website-Live-brightgreen)](https://puzhre.github.io/agent-orchestration-book)
[![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC%20BY--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)
[![GitHub stars](https://img.shields.io/github/stars/Puzhre/agent-orchestration-book?style=social)](https://github.com/Puzhre/agent-orchestration-book)

A systematic guide to AI Agent orchestration — from infrastructure-level hard orchestration to prompt-level soft orchestration.

## What Makes This Book Different?

This is not a project analysis report. It's a **systematically integrated book** that extracts key insights from multiple open-source orchestrator projects and production systems, organizes them by theme, and provides deep cross-project comparisons.

## Part I: Hard Orchestration

Using infrastructure to keep agents running continuously:

- **Process Daemons**: systemd, tmux, supervisor — keeping agents alive 24/7
- **Scheduling**: cron, self-scheduling loops, bracket-paste injection — driving agent work cycles
- **Fault Recovery**: double-layer Watchdog, progressive recovery, rapid crash protection — surviving failures
- **Communication**: send-keys, bracket-paste, structured mail, file coordination — inter-agent messaging
- **Concurrency Isolation**: git worktree, process isolation, file locks — preventing conflicts

## Part II: Soft Orchestration

Using prompts, skills, and process specifications to shape agent behavior:

- **Prompt Engineering**: rule blocks, mission injection, sprint-driven workflows
- **Skill Systems**: reusable capability templates, MCP tool integration
- **Pipeline Orchestration**: multi-stage flows with quality gates and escalation
- **Antipatterns**: loop detection, laziness prevention, rule self-deletion guards

## Part III: Practice & Evolution

- **Hands-on**: Build your own orchestrator from scratch
- **Evolution Roadmap**: From "barely running" to "intelligent self-healing"

## Source Projects

| Project | Tech Stack | Key Feature | Link |
|---------|-----------|-------------|------|
| Tmux-Orchestrator | Bash + tmux + Claude CLI | Minimal self-scheduling, hierarchical roles | [GitHub](https://github.com/Jedward23/Tmux-Orchestrator) |
| agency-agents-zh | Markdown Prompt + MCP | 50+ agent multi-stage pipeline | [GitHub](https://github.com/jnMetaCode/agency-agents-zh) |
| Composio agent-orchestrator | TypeScript + pnpm monorepo | Orchestrator-Worker, git worktree | [GitHub](https://github.com/ComposioHQ/agent-orchestrator) |
| Overstory | TypeScript/Bun + 11 runtimes | Layered Watchdog, structured mail | [GitHub](https://github.com/jayminwest/overstory) |

## Read Online

🌐 **[https://puzhre.github.io/agent-orchestration-book](https://puzhre.github.io/agent-orchestration-book)**

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-topic`)
3. Commit your changes with clear, atomic messages
4. Open a Pull Request

Please ensure all cited content includes proper source links.

## License

This book is licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). You are free to share and adapt the material with attribution.

---

⭐ If this book helps you, please give it a star!
