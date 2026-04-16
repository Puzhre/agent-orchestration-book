# 编排Agent：从硬守护到软约束

> 系统化探索AI Agent编排——当Agent 7×24运行时，谁来守护守护者？

[Star on GitHub](https://github.com/Puzhre/agent-orchestration-book){: .md-button .md-button--primary }

## 本书内容

本书系统化探索如何编排AI Agent进行自主、长时间运行的工作。从实战项目中提炼可复用的模式。

**Part I: 硬编排** — 底层硬逻辑，确保Agent持续运行（Agent无法修改）：

| 章节 | 主题 | 核心内容 |
|------|------|---------|
| 1 | 导论 | 为什么需要编排、五大痛点 |
| 2 | 架构模式 | 从双Agent到树形的五种拓扑 |
| 3 | 角色体系 | 谁做什么、持久角色vs临时角色 |
| 4 | 通信机制 | send-keys、bracket-paste、SQLite邮件 |
| 5 | 容错与恢复 | Watchdog、渐进恢复、快速崩溃保护 |
| 6 | 隔离与并发 | git worktree、进程隔离、文件锁 |
| 7 | 部署与守护 | systemd、tmux、nohup、cron |
| 8 | 规则守护 | 铁律块、外部守护脚本、完整性校验 |

**Part II: 软编排** — 写在Skill/Prompt里让Agent读取（引导Agent行为）：

| 章节 | 主题 | 核心内容 |
|------|------|---------|
| 9 | Prompt工程 | 铁律、MISSION注入、SPRINT驱动 |
| 10 | Skill系统 | 可复用技能、SKILL.md、模板、MCP工具 |
| 11 | 知识积累 | LEARNINGS.md、MCP记忆、经验文档 |
| 12 | 流水线编排 | 多步工作流、质量门禁 |

**Part III: 实战与演化** — 搭建和演化你自己的编排器：

| 章节 | 主题 | 核心内容 |
|------|------|---------|
| 13 | 反模式 | 硬软编排中必须避开的坑 |
| 14 | 实战 | 从零搭建最小编排器 |
| 15 | 演化路线 | 从脚本到自治系统 |

## 硬编排 vs 软编排：核心区别

**硬编排** = 底层硬逻辑。以基础设施方式运行（守护进程、脚本、cron），Agent无法修改。外部强制约束——Agent崩溃了，Watchdog重启它；Agent删了规则，守护脚本恢复它。

**软编排** = 写在Skill和Prompt里让Agent读取。通过提供指令、经验、可复用模板来引导行为。依赖Agent的配合——Agent读并遵守，但理论上可以忽略。

最健壮的系统是两者结合：硬编排守住不可妥协的底线，软编排引导其他一切。
