# 编排Agent：从硬守护到软约束

> AI Agent编排的系统化指南——让Agent持续工作，且做对的事

[:fontawesome-brands-github: GitHub Star](https://github.com/Puzhre/agent-orchestration-book){: .md-button .md-button--primary }

## 你将学到什么

本书从多个开源AI Agent编排器项目和真实生产系统中系统化整合知识：

**Part I: 硬编排** — 用基础设施让Agent持续工作：
- 进程守护（systemd、tmux）
- 定时调度（cron、自调度循环）
- 状态持久化与故障恢复
- Agent间通信（bracket-paste、结构化邮件、文件协调）
- 并发隔离（git worktree、进程隔离、文件锁）

**Part II: 软编排** — 用提示词和技能模板编排Agent行为：
- Agent的Prompt工程（规则块、任务注入、SPRINT驱动）
- Skill系统（可复用模板、MCP工具）
- 流水线编排（多阶段流程、质量门禁）
- 反模式与失败模式

**Part III: 实战与演化** — 搭建和演化你自己的编排器：
- 实战：从零搭建你的第一个编排器
- 演化路线：从"勉强能跑"到"智能自愈"

## 研究素材

| 项目 | 核心特点 |
|------|----------|
| [Tmux-Orchestrator](https://github.com/Jedward23/Tmux-Orchestrator) | 极简自调度，层次分工 |
| [agency-agents-zh](https://github.com/jnMetaCode/agency-agents-zh) | 50+智能体多阶段流水线 |
| [Composio agent-orchestrator](https://github.com/ComposioHQ/agent-orchestrator) | Orchestrator-Worker，git worktree |
| [Overstory](https://github.com/jayminwest/overstory) | 分层Watchdog，结构化邮件 |

## 贡献

欢迎贡献！Fork [本仓库](https://github.com/Puzhre/agent-orchestration-book)，创建特性分支，提交Pull Request。

## 许可证

[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) — 欢迎转载，请注明出处。
