# 模式速查表

> 一页纸速查所有编排模式

## 架构模式

| 模式 | 拓扑 | 适用场景 | 代表项目 |
|------|------|---------|---------|
| 双Agent循环 (Dual-Agent Loop) | A↔B | 小型项目，紧耦合 | Claude Code |
| 三层层次 (Three-Layer Hierarchy) | O→PM→E | 多任务并行 | Tmux-Orchestrator |
| 多阶段流水线 (Multi-Stage Pipeline) | 线性7阶段 | 质量优先工作流 | agency-agents-zh |
| Orchestrator-Worker | 1:N | 框架化编排 | Composio |
| 协调树 (Coordinator Tree) | Root→Lead→Worker | 大规模、分层场景 | Overstory |
| 分层看门狗 (Layered Watchdog) | 4层守护 | 生产级容错 | Overstory |

## 容错模式

| 模式 | 机制 | 恢复速度 | 适用场景 |
|------|------|---------|---------|
| 自调度 (Self-Scheduling) | nohup+sleep 循环 | 慢（分钟级） | 简单单Agent |
| 内置看门狗 (Built-in Watchdog) | 心跳检查 + nudge | 快（秒级） | 中等项目 |
| 双层看门狗 (Dual-Layer Watchdog) | 内循环 + systemd 外层 | 极快（15s） | 关键项目 |
| 分层看门狗 (Tiered Watchdog) | Bash 定时器 + AI 分诊 | 自适应 | 复杂多Agent |
| 渐进恢复 (Progressive Remediation) | 4级升级（nudge→重启→AI分诊→人工） | 按需 | 通用 |
| 检查点续跑 (Checkpoint Resume) | 崩溃时保存/恢复状态 | 即时 | 长时间流水线 |

## 通信模式

| 模式 | 可靠性 | 延迟 | 复杂度 | 代表项目 |
|------|--------|------|--------|---------|
| send-keys | 低 | 低 | 低 | Tmux-Orchestrator |
| bracket-paste | 中 | 低 | 中 | Tmux-Orchestrator |
| 共享文件 (Shared Files) | 中 | 中 | 低 | Composio |
| SQLite 邮件 (SQLite Mail) | 高 | 中 | 高 | Overstory |
| MCP 记忆 (MCP Memory) | 中 | 高 | 中 | agency-agents-zh |
| 事件存储 (Event Store) | 高 | 低 | 高 | Overstory |

## 隔离模式

| 模式 | 隔离强度 | 复杂度 | 代表项目 |
|------|---------|--------|---------|
| Prompt 规范 (Prompt Specification) | 弱 | 低 | agency-agents-zh |
| 角色分工 (Role Division) | 中 | 低 | Tmux-Orchestrator |
| 文件分配 (File Assignment) | 中 | 中 | Tmux-Orchestrator |
| 会话隔离 (Session Isolation) | 中 | 低 | 所有 tmux 项目 |
| Git Worktree | 强 | 高 | Overstory / Composio |

## 知识积累模式

| 模式 | 结构化 | 可查询 | 自动提取 | 代表项目 |
|------|--------|--------|---------|---------|
| 自然语言文档 (Natural Language Docs) | 低 | 否 | 否 | Tmux-Orchestrator (LEARNINGS.md) |
| 特性追踪 (Feature Tracking) | 中 | 否 | 否 | Tmux-Orchestrator (FEATURES.md) |
| MCP 记忆服务 (MCP Memory Service) | 高 | 是（语义） | 否 | agency-agents-zh |
| 结构化知识库 (Structured Knowledge Base) | 高 | 是（查询） | 部分 | Overstory (Mulch) |
| 事件存储 (Event Store) | 高 | 是（时序） | 是 | Overstory |

## 调度模式

| 模式 | 耦合度 | 可扩展性 | 代表项目 |
|------|--------|---------|---------|
| 手动分配 (Manual Assignment) | 紧 | 差 | agency-agents-zh |
| 脚本调度 (Script-Based Dispatch) | 中 | 中 | Tmux-Orchestrator |
| 能力调度 (Capability-Based Dispatch) | 松 | 好 | Overstory |
| 市场竞价 (Market-Based Bidding) | 极松 | 优 | （理论） |

## 合并模式

| 模式 | 冲突处理 | 自动化程度 | 代表项目 |
|------|---------|-----------|---------|
| 不合并（单写入者）(No Merge) | 无需处理 | N/A | agency-agents-zh |
| 手动合并 (Manual Merge) | 人工解决 | 无 | Composio（基础） |
| 自动+AI辅助合并 (Auto + AI-Assisted Merge) | 4级策略 | 高 | Overstory |

## 反模式速查

| 反模式 | 一句话 | 修复 |
|--------|--------|------|
| 无看门狗 (No Watchdog) | 自动化 ≠ 可靠 | 加看门狗 |
| 自改规则 (Self-Modifying Rules) | Agent 不可信 | 外部守护进程 |
| 单点 Orchestrator (Single-Point Orchestrator) | 一挂全挂 | 分层 / 自调度 |
| 自然语言通信 (Natural Language Communication) | 消息必丢 | 结构化协议 |
| 无限重试 (Infinite Retry) | 429 死循环 | 渐进恢复 |
| 共享空间 (Shared Space) | 文件冲突不可避免 | 物理隔离（worktree） |
| 上下文浪费 (Context Waste) | Token 烧钱 | 分层上下文 / 叠加注入 |
| 无状态重启 (Stateless Restart) | 崩溃后重复工作 | 状态持久化 |
| 过度工程化 (Over-Engineering) | 自己比 Agent 更难维护 | 渐进增强 |
| 能力耦合 (Capability Coupling) | 硬编码 Agent 分配 | 能力调度 |
| 知识失忆 (Knowledge Amnesia) | 每次会话从零开始 | 结构化知识库 |
