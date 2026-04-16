# Project Index

> Summary of all Orchestrator projects analyzed in this book

|| Project | Language/Tech Stack | Core Architecture | Communication Method | Fault Tolerance Layers | Knowledge Accumulation | Key Features | Repository ||
||---------|-------------------|-------------------|---------------------|----------------------|----------------------|-------------|------------||
|| Tmux-Orchestrator | Bash+tmux | Three-Layer Hierarchy | bracket-paste | 2 layers (built-in + systemd) | CLAUDE.md + LEARNINGS.md | Self-triggering agents, git discipline, cross-project coordination | [GitHub](https://github.com/Jedward23/Tmux-Orchestrator) ||
|| agency-agents-zh | Markdown+MCP | Seven-Stage Pipeline | MCP Memory | 4 layers (quality gates) | MCP Memory | 211 expert agents, DAG workflow, breakpoint resume, 32 templates | [GitHub](https://github.com/jnMetaCode/agency-agents-zh) ||
|| Composio | TypeScript+pnpm | Orchestrator-Worker | Shared Files | 2 layers (LifecycleWorker + dashboard) | None | CI/CD integration, PR-based workflow, runtime agnostic | [GitHub](https://github.com/ComposioHQ/agent-orchestrator) ||
|| Overstory | TypeScript/Bun | Coordinator-Lead-Worker Tree | SQLite Mail | 4 layers (4-tier watchdog) | Mulch Knowledge Base | 11 runtime support, phase flow, checkpoint handoff | [GitHub](https://github.com/jayminwest/overstory) ||
|| Claude Code | TypeScript | Single-Agent CLI | - | 1 layer | CLAUDE.md | Native CLI integration, local development | [GitHub](https://github.com/anthropics/claude-code) ||
|| CrewAI | Python | Role Collaboration | Shared Memory | 2 layers | Memory System | Human-agent collaboration, task delegation | [GitHub](https://github.com/crewAIInc/crewAI) ||
|| LangGraph | Python | State Graph | Message Passing | 1 layer | Checkpoints | Graph-based workflows, conditional edges | [GitHub](https://github.com/langchain-ai/langgraph) ||
