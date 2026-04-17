# 第二章 架构模式：从双Agent到分层树形

## 2.1 五种架构拓扑

架构是编排器的骨架。五大项目呈现了从最简单到最复杂的五种拓扑：

### 拓扑一：双Agent循环

```
┌─────────────┐     task_dispatch.sh     ┌─────────────┐
│  Architect   │ ──────────────────────→│   Worker     │
│  (Hermes)   │ ←── capture-pane poll ──│  (Codex)    │
└──────┬──────┘                        └─────────────┘
       │
   Orchestrator Daemon (patrol, fault tolerance, driving)
```

**特点**：
- 最简单的拓扑，两个角色各司其职
- 架构师是唯一决策者，执行者被动接受任务
- 编排器不是Agent，是纯脚本守护进程
- 通信路径只有2条：编排器↔架构师、编排器↔执行者、架构师→执行者

**适用场景**：中小项目，单一技术栈，任务线性推进

### 拓扑二：三层层次架构（Tmux-Orchestrator）

```
┌──────────────────┐
│   Orchestrator    │  ← 全局监控与协调
└───────┬──────────┘
        │
   ┌────┴────┐
   │         │
┌──┴──┐  ┌──┴──┐
│ PM1 │  │ PM2 │       ← 项目经理，任务分配与质量把关
└──┬──┘  └──┬──┘
   │        │
┌──┴──┐  ┌──┴──┐
│Eng1 │  │Eng2 │       ← 工程师，代码实现
└─────┘  └─────┘
```

**真实实现**（来自Tmux-Orchestrator研究）：
- **自触发 (Self-Triggering)**：Agent自行安排检查时间并自主继续工作
- **跨项目协调**：项目经理在多个代码库之间为工程师分配任务
- **Git纪律**：强制30分钟提交一次，特性分支，有意义的提交信息
- **括号粘贴通信 (Bracket-Paste Communication)**：通过tmux bracket-paste发送多行消息以实现干净传输
- **状态监控**：多个Agent并行工作时的实时状态更新

**特点**：
- 在双Agent基础上增加了PM中间层
- PM承担质量把关，Orchestrator专注于跨项目协调
- Hub-and-Spoke通信：开发者只向PM报告，PM向Orchestrator报告
- 可按需扩展更多PM和Engineer

**适用场景**：多项目并行，需要质量把关的中大型项目

### 拓扑三：Prompt流水线（agency-agents-zh）

```
┌─────────────────────────────────────────────┐
│              七阶段流水线                     │
│                                              │
│ Stage0→Stage1→Stage2→Stage3↔Stage4→Stage5→Stage6 │
│ (情报) (策略) (基础) (构建) (质量) (上线) (运营)│
│                                              │
│ 每个阶段激活不同的智能体子集                   │
│ 阶段间有强制质量门禁                          │
└─────────────────────────────────────────────┘
```

**真实实现**（来自agency-agents-zh研究）：
- **大规模**：18个部门共211个专家Agent（165个翻译+46个中国特有）
- **零代码编排**：纯自然语言或YAML规范
- **DAG工作流**：自动依赖检测，独立步骤并行执行
- **断点续跑**：失败的步骤可独立重跑，无需从头开始
- **多工具支持**：16种AI编程工具，包括Claude Code、Gemini CLI、Copilot、Codex
- **模板系统**：32个现成模板，覆盖开发、营销、设计、运营

**特点**：
- 不是运行时架构，而是Prompt定义的流程规范
- 50+智能体按阶段激活，非同时在线
- 流水线是线性的，但每阶段内部可并行
- 三种部署模式：Full(50+agents)、Sprint(15-25)、Micro(5-10)

**适用场景**：需要严格质量流程的产品开发，非纯编码场景

### 拓扑四：Orchestrator-Worker（Composio）

```
┌─────────────────────────────────┐
│       Orchestrator Agent        │  ← 任务分解+进度监控+结果整合
│   (通过 --append-system-prompt  │
│    注入编排指令)                 │
└───────┬────────┬────────┬───────┘
        │        │        │
   ┌────┴──┐ ┌──┴───┐ ┌──┴───┐
   │Worker1│ │Worker2│ │Worker3│    ← 独立git worktree
   │(编码) │ │(编码) │ │(编码) │       并行执行子任务
   └───────┘ └──────┘ └──────┘
```

**真实实现**（来自Composio研究）：
- **CI/CD集成**：Agent自主修复CI失败、处理审查意见、开PR
- **基于PR的工作流**：每个Agent有自己的分支和PR，通过Dashboard实现人工监督
- **运行时无关**：支持Claude Code、Codex、Aider，后端可用tmux/Docker
- **Tracker集成**：GitHub/Linear集成，仅在需要时升级由人工判断
- **并行处理**：多个Agent同时处理代码库的不同部分

**特点**：
- 经典的主从模式，Orchestrator不写代码只协调
- 每个Worker有独立的git worktree，完全隔离
- 通信基于共享文件（todo.md/scratchpad）
- Orchestrator本身就是AI Agent（通过prompt注入编排能力）

**适用场景**：大型代码库的并行开发，子任务间低依赖

### 拓扑五：Coordinator-Lead-Worker树形（Overstory）

```
┌─────────────────┐
│   Coordinator   │  ← 持久协调者，跨批次运行
└───────┬─────────┘
        │ mail dispatch
   ┌────┴────┐
   │         │
┌──┴──┐  ┌──┴──┐
│Lead1│  │Lead2│         ← 团队领队，Phase流程管理
└─┬─┬─┘  └─┬─┬─┘
  │ │      │ │
 S B R    S B R          ← Scout/Builder/Reviewer
```

**真实实现**（来自Overstory研究）：
- **SQLite邮件系统**：自定义基于SQLite的消息传递用于Agent间通信
- **11种运行时支持**：Claude Code、Pi、Gemini CLI、Aider、Goose、Amp等
- **分层冲突解决**：三层合并冲突处理
- **预警系统**：针对Agent群体的全面风险分析
- **Phase流程**：Lead按Scout→Build→Review→Merge阶段推进
- **持久角色**：Coordinator和Supervisor跨批次存在

**特点**：
- 最复杂的拓扑，三层委托+专项角色
- Lead按Phase流程推进：Scout→Build→Review→Merge
- Coordinator和Supervisor是持久角色，跨批次存在
- 每个Lead可独立管理自己的子团队

**适用场景**：超大型项目，需要深度分工和持续运营

## 2.2 架构选型的关键权衡

### 权衡一：简单性 vs 扩展性

| 拓扑 | 角色数 | 代码量 | 扩展到10个Agent |
|------|--------|--------|----------------|
| 双Agent循环 | 2 | ~700行Bash | 不支持 |
| 三层层次 | 3-6 | ~1000行Bash+Markdown | 需人工配置 |
| Prompt流水线 | 50+ | 纯Markdown | 天然支持 |
| Orchestrator-Worker | 1+N | TS monorepo | 配置文件指定 |
| 树形 | 1+M+N×3 | TS/Bun大工程 | 自动派生 |

**结论**：对于2-4个Agent的团队，双Agent或三层层次最实际。超过5个Agent时，需要Orchestrator-Worker或树形拓扑。

### 权衡二：编排器的角色——是Agent还是脚本？

| 项目 | 编排器是什么 | 优势 | 劣势 |
|------|------------|------|------|
| Tmux-Orchestrator | Claude Agent | 能理解复杂情况做判断 | 消耗Token、可能误判 |
| Composio | Claude Agent (prompt注入) | Agent无关设计 | 编排质量取决于LLM |
| Overstory | 混合：脚本做监控+Agent做分诊 | 兼顾可靠性和智能 | 实现复杂 |
| agency-agents-zh | 无（纯规范） | 无实现成本 | 无执行保证 |

**关键洞察**：编排器的"智能程度"应该和容错需求成反比。监控和恢复这类关键操作应该用确定性脚本，任务分解和异常诊断可以用AI Agent。Overstory的"Tier 0机械守护+Tier 1 AI分诊"是这个原则的最佳体现。

### 权衡三：状态存储——文件 vs 数据库 vs 无状态

| 项目 | 状态存储 | 优势 | 劣势 |
|------|---------|------|------|
| Tmux-Orchestrator | 文本文件 + next_check_note.txt | 极简 | 重启后丢失 |
| Composio | YAML配置 + running-state文件 | 结构化 | 单机限制 |
| Overstory | SQLite (WAL模式) | 并发安全、可查询 | 依赖SQLite |
| agency-agents-zh | MCP记忆服务器 | 语义搜索、rollback | 外部依赖 |

**关键洞察**：对于多Agent并发场景，SQLite (WAL) 是目前最佳实践——它提供了文件系统没有的并发安全和查询能力，又不需要引入Redis/PostgreSQL这种重依赖。

## 2.3 新模式：基于交接的编排（OpenAI Swarm/Agents SDK）

OpenAI的Swarm（现已演化为[Agents SDK](https://github.com/openai/openai-agents-python)）引入了一种不同的范式：**基于交接的编排 (Handoff-Based Orchestration)**。不是由中央编排器分发任务，而是Agent之间互相交接对话。

```python
from swarm import Swarm, Agent

def transfer_to_agent_b():
    return agent_b

agent_a = Agent(
    name="Agent A",
    instructions="You are a helpful agent.",
    functions=[transfer_to_agent_b],
)

agent_b = Agent(
    name="Agent B",
    instructions="Only speak in Haikus.",
)
```

**关键特征**：
- 两个原语：`Agent`（指令+工具）和**handoffs**（交接给另一个Agent）
- 没有中央编排器——Agent自行决定何时交接
- 调用之间无状态（对应12-Factor Agents的第12条）
- 轻量、高度可控、易于测试

**与编排器模式的对比**：

| 维度 | 交接模式 (Swarm) | 编排器-Worker模式 (Composio) |
|------|-----------------|---------------------------|
| 控制 | 分布式（Agent自行决定） | 集中式（编排器决定） |
| 复杂度 | 很低 | 中等 |
| 可靠性 | 取决于Agent判断 | 确定性监控 |
| 扩展性 | 有限（2-5个Agent） | 高（N个Worker） |
| 最佳场景 | 客服、路由 | 并行编码、CI/CD |

**关键洞察**：基于交接的编排是最纯粹的软编排——"编排"完全在Prompt中（指令告诉Agent何时交接）。没有硬编排层。这对于简单路由有效，但在需要确定性监控和恢复的长时间自主工作中会崩溃。

*参考：[openai/swarm](https://github.com/openai/swarm) → [openai/openai-agents-python](https://github.com/openai/openai-agents-python)*

## 2.4 架构演进路径

从五大项目的经验中，我们总结出编排器架构的演进路径：

```
Level 0: 手动协调（无编排器）
  人手动在多个AI工具间复制粘贴
  ↓
Level 1: 脚本驱动（Tmux-Orchestrator）
  Bash脚本管理Agent生命周期，简单的巡检+重启
  ↓
Level 2: 框架驱动（Composio）
  结构化配置+自动Agent检测+会话管理
  ↓
Level 3: 协议驱动（Overstory）
  结构化消息协议+多层容错+知识积累
  ↓
Level 4: 自治系统（终极形态）
  Agent自动派生/销毁+动态拓扑调整+跨项目学习
```

每升一级，系统可靠性提高，但复杂度也指数增长。**选择哪一级取决于你的场景和团队能力**——Level 1已经能解决80%的问题。
