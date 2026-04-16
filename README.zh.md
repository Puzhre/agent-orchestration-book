# 编排 Agent：从硬守护到软约束

**中文** | [English](./README.md)

[![GitHub Pages](https://img.shields.io/badge/网站-在线-brightgreen)](https://puzhre.github.io/agent-orchestration-book)
[![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC%20BY--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)
[![GitHub stars](https://img.shields.io/github/stars/Puzhre/agent-orchestration-book?style=social)](https://github.com/Puzhre/agent-orchestration-book)

AI Agent 编排的系统化指南——从基础设施层的硬编排到提示词层的软编排。

## 这本书有什么不同？

这不是项目分析报告合集，而是一本**按知识主题整合**的系统性书籍。从多个开源编排器项目和真实生产系统中提取关键知识点，按主题重新组织，每章讲透一个问题，用多项目做例证对比。

## Part I: 硬编排

用基础设施手段让 Agent 持续工作：

- **进程守护**：systemd、tmux、supervisor —— 让 Agent 7×24 运行
- **调度驱动**：cron、自调度循环、bracket-paste 注入 —— 驱动 Agent 工作循环
- **故障恢复**：双层 Watchdog、渐进式恢复、快速崩溃保护 —— 系统挂了怎么办
- **通信机制**：send-keys、bracket-paste、结构化邮件、文件协调 —— Agent 间如何交流
- **并发隔离**：git worktree、进程隔离、文件锁 —— 避免互相踩脚

## Part II: 软编排

用提示词、技能模板、流程规范编排 Agent 行为：

- **Prompt 工程**：规则块、任务注入、SPRINT 驱动工作流
- **Skill 系统**：可复用能力模板、MCP 工具集成
- **流水线编排**：带质量门禁和升级机制的多阶段流程
- **反模式**：循环检测、偷懒防护、规则自删守护

## Part III: 实战与演化

- **实战**：从零搭建你的编排器
- **演化路线图**：从"勉强能跑"到"智能自愈"

## 研究素材

| 项目 | 技术栈 | 核心特点 | 链接 |
|------|--------|----------|------|
| Tmux-Orchestrator | Bash + tmux + Claude CLI | 极简自调度，层次分工 | [GitHub](https://github.com/Jedward23/Tmux-Orchestrator) |
| agency-agents-zh | Markdown Prompt + MCP | 50+智能体多阶段流水线 | [GitHub](https://github.com/jnMetaCode/agency-agents-zh) |
| Composio agent-orchestrator | TypeScript + pnpm monorepo | Orchestrator-Worker，git worktree | [GitHub](https://github.com/ComposioHQ/agent-orchestrator) |
| Overstory | TypeScript/Bun + 11种运行时 | 分层Watchdog，结构化邮件 | [GitHub](https://github.com/jayminwest/overstory) |

## 在线阅读

🌐 **[https://puzhre.github.io/agent-orchestration-book](https://puzhre.github.io/agent-orchestration-book)**

## 贡献

欢迎贡献！请：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/your-topic`)
3. 用清晰的原子化 commit 提交更改
4. 提交 Pull Request

请确保所有引用内容包含来源链接。

## 许可证

本书采用 [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) 许可。欢迎转载，请注明出处。

---

⭐ 如果这本书对你有帮助，请给个 star！
