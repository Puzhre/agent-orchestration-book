# 第一章 导论：AI Agent编排的核心问题

## 1.1 为什么需要编排？

单个AI Agent已经很强了——Claude Code能写代码，Codex能实现功能，Aider能重构。但当你需要：

- **7×24小时无人值守推进项目**——人不能一直盯着
- **多个Agent协作完成超复杂任务**——一个Agent的上下文窗口装不下
- **保证质量而非速度**——Agent容易"差不多就行"
- **从错误中恢复而非从头来**——Agent崩溃后不能丢失所有进度

这时候就需要一个**编排器（Orchestrator）**。

编排器不是一个Agent，而是一个**让多个Agent有效协作的控制系统**。它回答三个核心问题：

1. **谁做什么**——角色与分工
2. **怎么传话**——通信与协调
3. **挂了怎么办**——容错与恢复

## 1.2 编排器要解决的五大痛点

从五个项目的源码中，我们提炼出编排器必须面对的五个痛点：

### 痛点一：上下文窗口限制

单个Agent的上下文窗口是有限的（128K、200K……），当一个项目的代码量、历史决策、任务清单加起来超过窗口容量时，Agent就开始"遗忘"。

- **Tmux-Orchestrator的方案**：三层层次架构（Orchestrator→PM→Engineer），每层只关注自己的上下文
- **agency-agents-zh的方案**：50+专业智能体，每个只负责一个窄领域
- **Overstory的方案**：Scout只读探索、Builder只管编码、Reviewer只做审查——角色即上下文隔离
- **方案**：架构师+执行者双Agent，架构师不碰代码，执行者不碰规划

**关键洞察**：上下文隔离不是可选优化，而是编排的基本约束。

### 痛点二：Agent可靠性不足

AI Agent会：
- 陷入循环（反复尝试同一方案）
- 被限流（429 Too Many Requests）
- 崩溃退出（OOM、API超时）
- 偷懒走捷径（跳过测试、用硬编码）
- 自行修改自己的约束（删掉提示词中的规则）

每个编排器都花了大量精力在**容错**上：

| 项目 | 容错层数 | 核心机制 |
|------|---------|---------|
| Overstory | 4层 | 机械守护→AI分诊→监控→Supervisor |
| Tmux-Orchestrator | 1层 | 自调度链（nohup+sleep） |
| agency-agents-zh | 4层 | 任务重试→升级协议→质量门禁→现实检验 |
| Composio | 1层 | LifecycleWorker进程监控 |

**关键洞察**：容错不是锦上添花，而是编排器的核心价值。一个没有容错的编排器比没有编排器更危险——因为它给人"自动化"的错觉。

### 痛点三：Agent间通信困难

两个独立运行的Agent进程之间怎么通信？这不是简单的函数调用：

- 它们可能在不同终端/窗口/tmux session
- 它们不理解彼此的内部状态
- 它们的输出是非结构化的自然语言

五个项目走了五条不同的路：

| 项目 | 通信方式 | 可靠性 | 延迟 |
|------|---------|--------|------|
| Tmux-Orchestrator | send-keys + capture-pane | 低 | 低 |
| Overstory | SQLite邮件系统 | 高 | 中 |
| Composio | 共享文件（todo.md） | 中 | 中 |
| agency-agents-zh | MCP记忆/copy-paste | 低 | 高 |

**关键洞察**：通信机制的可靠性决定了编排系统的上限。基于屏幕文本解析的通信（capture-pane + grep）是最脆弱的，结构化协议通信是最可靠的。

### 痛点四：并发冲突

多个Agent同时工作时，它们可能：
- 修改同一个文件
- 操作同一个git分支
- 请求同一个API（触发限流）
- 对同一任务重复工作

| 项目 | 隔离方式 | 效果 |
|------|---------|------|
| Overstory | git worktree独立工作区 | 最强——代码级完全隔离 |
| Composio | git worktree独立工作区 | 最强——同上 |
| Tmux-Orchestrator | PM分配不同文件给不同Engineer | 弱——依赖PM的分配 |
| agency-agents-zh | 无运行时隔离 | 无——纯Prompt规范 |

**关键洞察**：git worktree是目前最可靠的并发隔离方案，但需要额外的合并策略。

### 痛点五：经验无法积累

Agent每次启动都是"白纸"，上次犯的错这次还犯。如何让系统从经验中学习？

| 项目 | 知识积累方式 |
|------|------------|
| Tmux-Orchestrator | LEARNINGS.md——自然语言经验文档 |
| Overstory | Mulch知识库——结构化冲突模式+失败记录 |
| agency-agents-zh | MCP记忆服务器——remember/recall/rollback |
| Composio | 无 |
| Tmux-Orchestrator | FEATURES.md——特性追踪防重复开发 |

**关键洞察**：知识积累是编排器从"工具"升级为"系统"的关键一步。没有知识积累，编排器永远在做重复的事。

## 1.3 五大项目的设计哲学

每个项目背后都有不同的设计哲学，这决定了它的架构选择和取舍：

### Tmux-Orchestrator：极简主义

> "tmux就是操作系统，Claude CLI就是运行时，两个脚本就是基础设施"

哲学：用最少的依赖做最多的事。核心创新是**自调度**——Agent能给自己设闹钟醒来检查。缺点是所有"机制"都是自然语言约定，没有强制执行。

### agency-agents-zh：结构化治理

> "像运营一家公司一样运营AI团队"

哲学：用流程和制度保证质量。七阶段流水线流水线、质量门禁、标准化交接模板、升级协议——这不是技术方案，而是**组织管理方案**。缺点是没有运行时引擎，全靠人（或宿主AI工具）执行。

### Composio agent-orchestrator：框架化

> "让用户一行命令启动多Agent并行开发"

哲学：做框架而非应用。Agent无关设计、自动配置生成、Dashboard可视化——目标是让任何人都能快速用起来。缺点是编排深度不足，Orchestrator是单点。

### Overstory：工程完备性

> "从Tier 0机械守护到Tier 3 Supervisor，每一层都有明确的职责和恢复策略"

哲学：生产级系统必须有多层防护。4层Watchdog、ZFC健康检查、结构化邮件协议、4级合并策略——这是唯一一个真正考虑了"Agent崩溃后如何精确恢复"的项目。缺点是复杂度极高。

### ARIS：技能驱动的自演化

> "一种方法论，不是一个平台。零依赖，零锁定。整个系统就是纯Markdown文件。"

哲学：极致轻量——没有框架、没有数据库、没有Docker。62个打包技能作为SKILL.md文件，任何LLM都能读取。关键创新是**自演化**：`/meta-optimize`分析日志并生成SKILL.md补丁来改进自身。研究Wiki提供持久化知识。从Claude Code切换到Codex、Cursor或其他Agent，工作流仍然可用。

*参考：[wanshuiyin/Auto-claude-code-research-in-sleep](https://github.com/wanshuiyin/Auto-claude-code-research-in-sleep)*

## 1.4 行业视角：12-Factor Agents

[12-Factor Agents](https://github.com/humanlayer/12-factor-agents)项目由Humanlayer的Dex创建，提出了构建可靠LLM应用的12条原则。其核心洞察与我们的分析深度共鸣：

> "大多数标榜'AI Agent'的产品并没有那么自主。很多只是大部分确定性代码，在恰当的位置撒了些LLM步骤，让体验真正神奇。"

这与我们的观察一致：最好的编排器**主要是软件，不是主要是Prompt**。12个因子与我们的硬/软编排划分对应：

| 因子 | 原则 | 我们的映射 |
|------|------|-----------|
| 1 | 自然语言→工具调用 | Ch4 通信（硬接口） |
| 2 | 拥有自己的Prompt | Ch9 Prompt工程（软） |
| 3 | 拥有自己的上下文窗口 | Ch11 知识积累（软） |
| 4 | 工具就是结构化输出 | Ch10 Skill系统（软） |
| 5 | 统一执行状态与业务状态 | Ch5 容错（硬） |
| 6 | 用简单API启动/暂停/恢复 | Ch7 部署（硬） |
| 8 | 拥有自己的控制流 | Ch2 架构（硬） |
| 9 | 将错误压缩进上下文窗口 | Ch5 容错（硬） |
| 10 | 小而专注的Agent | Ch3 角色（软） |
| 12 | 让Agent成为无状态Reducer | Ch6 隔离（硬） |

**核心结论**：硬编排拥有控制流、状态管理和错误处理。软编排拥有Prompt、技能和上下文。这与"主要是软件"的洞察完美一致——可靠的Agent构建在确定性脚手架上，LLM智能在边缘。

## 1.5 本书的结构

本书分三个部分：

**Part I：硬编排** — Agent无法修改的底层逻辑：

- **Ch2** 架构——从双Agent到树形的五种拓扑
- **Ch3** 角色——谁做什么、持久角色vs临时角色
- **Ch4** 通信——从send-keys到SQLite邮件
- **Ch5** 容错——1层到4层防护的演进
- **Ch6** 隔离——并发安全的四种武器
- **Ch7** 部署与守护——systemd、tmux、cron
- **Ch8** 规则守护——约束的硬性执行

**Part II：软编排** — 写在Skill/Prompt里让Agent读的：

- **Ch9** Prompt工程——铁律、MISSION、SPRINT
- **Ch10** Skill系统——SKILL.md、模板、MCP工具
- **Ch11** 知识积累——LEARNINGS、记忆、经验
- **Ch12** 流水线编排——多步工作流、质量门禁

**Part III：实战与演化** — 搭建和演化：

- **Ch13** 反模式——硬软编排中必须避开的坑
- **Ch14** 实战——从零搭建最小编排器
- **Ch15** 演化路线——从脚本到自治系统
