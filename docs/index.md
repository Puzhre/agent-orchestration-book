# Orchestrating Agents: From Hard Guards to Soft Constraints

> A systematic guide to AI Agent orchestration — when agents run 24/7, who watches the watchers?

[Star on GitHub](https://github.com/Puzhre/agent-orchestration-book){: .md-button .md-button--primary }

## What This Book Covers

This book systematically explores how to orchestrate AI Agents for autonomous, long-running work. It draws from real-world projects and distills them into reusable patterns.

**Part I: Hard Orchestration** — Low-level hard logic that keeps agents running:

| Chapter | Topic | Key Content |
|---------|-------|-------------|
| 1 | Introduction | Why orchestration, five core pain points |
| 2 | Architecture Patterns | Five topologies from dual-agent to tree |
| 3 | Role Systems | Who does what, persistent vs ephemeral roles |
| 4 | Communication | send-keys, bracket-paste, SQLite mail |
| 5 | Fault Tolerance | Watchdog, progressive recovery, fast-crash protection |
| 6 | Isolation & Concurrency | git worktree, process isolation, file locks |
| 7 | Deployment & Daemons | systemd, tmux, nohup, cron |
| 8 | Rule Guard | Iron law blocks, external guard scripts, integrity checks |

**Part II: Soft Orchestration** — Skills and prompts that shape agent behavior (agents read these):

| Chapter | Topic | Key Content |
|---------|-------|-------------|
| 9 | Prompt Engineering | Iron laws, mission injection, SPRINT-driven |
| 10 | Skill Systems | Reusable skills, SKILL.md, templates, MCP tools |
| 11 | Knowledge Accumulation | LEARNINGS.md, MCP memory, experience docs |
| 12 | Pipeline Orchestration | Multi-step workflows, quality gates |

**Part III: Practice & Evolution** — Build and evolve your own orchestrator:

| Chapter | Topic | Key Content |
|---------|-------|-------------|
| 13 | Antipatterns | Must-avoid pitfalls across hard and soft orchestration |
| 14 | Hands-On | Build a minimal orchestrator from scratch |
| 15 | Evolution Roadmap | From scripts to autonomous systems |

## Hard vs Soft: The Core Distinction

**Hard orchestration** = low-level hard logic. It runs as infrastructure (daemons, scripts, cron jobs) that agents cannot modify. It enforces constraints externally — if an agent crashes, the watchdog restarts it; if an agent deletes its rules, the guard script restores them.

**Soft orchestration** = written in skills and prompts for agents to read. It shapes behavior by providing instructions, experience, and reusable templates. It depends on the agent's compliance — the agent reads and follows, but could theoretically ignore it.

The most robust systems combine both: hard orchestration enforces the non-negotiables, soft orchestration guides everything else.
