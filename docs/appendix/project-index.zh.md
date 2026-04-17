# 项目索引

> 本书分析的所有编排器项目汇总

## 详细项目档案

### Tmux-Orchestrator

| 维度 | 详情 |
|------|------|
| **语言/技术栈** | Bash + tmux |
| **核心架构** | 三层层次结构（Orchestrator → Architect → Executor） |
| **通信方式** | bracket-paste 注入 + capture-pane 监控 |
| **容错机制** | 2 层（内置心跳 + systemd watchdog） |
| **知识积累** | CLAUDE.md + LEARNINGS.md + FEATURES.md |
| **隔离机制** | 角色分离（Architect 管理计划，Executor 编写代码） |
| **部署方式** | systemd 用户服务 + loginctl linger |
| **核心特性** | 自触发 Agent、git 纪律、跨项目协调 |
| **仓库** | [GitHub](https://github.com/Jedward23/Tmux-Orchestrator) |
| **演进阶段** | 第 2 阶段（可靠运行，正向第 3 阶段推进） |

**突出创新**：bracket-paste 协议解决了一个真实的 tmux 问题——通过 send-keys 发送多行文本时的字符损坏。这是一种只能来自生产经验的"战斗伤疤"模式。

### agency-agents-zh

| 维度 | 详情 |
|------|------|
| **语言/技术栈** | Markdown + MCP Memory Server |
| **核心架构** | 七阶段流水线（Recon → Plan → Review → Build → Test → Deploy → Monitor） |
| **通信方式** | MCP Memory（语义搜索 + 回滚）+ 复制粘贴交接 |
| **容错机制** | 4 层（每个流水线阶段设有质量门禁） |
| **知识积累** | MCP Memory（remember/recall/rollback） |
| **隔离机制** | 最小化（仅基于提示词的角色指定） |
| **部署方式** | install.sh 脚本可部署为 10+ 种 AI 工具格式 |
| **核心特性** | 211 个专家 Agent、DAG 工作流、断点续传、32 个交接模板、跨平台部署 |
| **仓库** | [GitHub](https://github.com/jnMetaCode/agency-agents-zh) |
| **演进阶段** | 第 1 阶段（已运行，但缺乏自主容错能力） |

**突出创新**：跨平台 Agent 部署——单个 Agent 定义可安装为 Claude Code、GitHub Copilot、Cursor、Aider、Windsurf 等多种格式。这种"一次编写，到处部署"的方式在生态中独树一帜。

### Composio (agent-orchestrator)

| 维度 | 详情 |
|------|------|
| **语言/技术栈** | TypeScript + pnpm |
| **核心架构** | Orchestrator-Worker（1:N 配合仪表盘） |
| **通信方式** | 共享文件（todo.md、scratchpad）+ JSON 交接 |
| **容错机制** | 2 层（LifecycleWorker + 仪表盘监控） |
| **知识积累** | 无（Agent 每次会话无状态） |
| **隔离机制** | git worktree（Worker 在独立 worktree 中工作） |
| **部署方式** | `ao start <url>` 一键 CLI |
| **核心特性** | CI/CD 集成、基于 PR 的工作流、运行时无关、React 仪表盘、预检机制 |
| **仓库** | [GitHub](https://github.com/ComposioHQ/agent-orchestrator) |
| **演进阶段** | 第 2 阶段（可靠运行，但知识积累缺失限制了向第 3 阶段发展） |

**突出创新**：Preflight 预检机制——在启动前检查所有依赖，而非在运行时才发现"git 未安装"。这是将 DevOps 最佳实践应用于 Agent 编排的典范。

### Overstory

| 维度 | 详情 |
|------|------|
| **语言/技术栈** | TypeScript + Bun 运行时 |
| **核心架构** | Coordinator → Lead → Worker 树状层次结构 |
| **通信方式** | SQLite Mail（9 种协议类型 + 组地址） |
| **容错机制** | 4 层（分层 watchdog：bash 定时器 + AI 分诊） |
| **知识积累** | Mulch 知识库（冲突模式、失败模式、项目知识） |
| **隔离机制** | git worktree（由 WorktreeManager 管理）+ 4 级合并策略 |
| **部署方式** | `ov init` + `ov coordinator` CLI |
| **核心特性** | 11 个运行时适配器、基于能力的调度、Overlay 注入、事件存储、检查点交接 |
| **仓库** | [GitHub](https://github.com/jayminwest/overstory) |
| **演进阶段** | 第 3 阶段（智能增强，最为成熟） |

**突出创新**：Overlay 注入——一个三层渲染系统（角色定义 + 项目画像 + 任务分配），确保每个 Agent 启动时都拥有正确的上下文。这是知识积累的"消费端"。

### 参考项目（未深入分析）

| 项目 | 语言 | 架构 | 核心贡献 |
|------|------|------|---------|
| Claude Code | TypeScript | 单 Agent CLI | 原生 CLI 集成、CLAUDE.md 惯例 |
| CrewAI | Python | 角色协作 | 人-Agent 协作、共享记忆 |
| LangGraph | Python | 状态图 | 基于图的工作流、条件边、检查点 |
| AutoGen | Python | 多 Agent 对话 | 对话式编排、代码执行 |
| OpenAI Swarm | Python | Agent 交接 | 最小化交接框架、轻量级 |

## 跨项目对比矩阵

| 维度 | Tmux-Orch | agency-zh | Composio | Overstory |
|------|-----------|-----------|----------|-----------|
| **设置复杂度** | 中 | 低 | 低 | 中 |
| **最大 Agent 数** | 3-5 | 211（目录） | 5-10 | 5-20 |
| **自主水平** | 高 | 低（人工驱动） | 中 | 高 |
| **生产就绪度** | 实战检验 | 仅模板 | 早期阶段 | 最为完善 |
| **跨运行时** | 否 | 是（10+ 格式） | 部分（4 运行时） | 是（11 适配器） |
| **知识持久化** | LEARNINGS.md | MCP Memory | 无 | Mulch + Event Store |
| **合并策略** | 无 | 无 | 基础 | 4 级 AI 辅助 |
