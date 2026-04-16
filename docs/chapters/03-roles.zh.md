# 第三章 角色体系：谁做什么

## 3.1 角色定义的三种方式

### 方式一：Prompt定义（agency-agents-zh / Tmux-Orchestrator）

每个角色是一个Markdown文件，用自然语言描述身份、使命、规则、交付物、沟通风格。

**agency-agents-zh的智能体文件结构**：
```yaml
---
name: 前端开发者
description: 精通现代Web技术...
color: cyan
---
# 前端开发者 Agent 人格
## 你的身份与记忆     ← 角色定义、性格
## 你的核心使命       ← 核心职责
## 你必须遵循的关键规则 ← 行为约束
## 你的技术交付物     ← 代码/报告模板
## 你的沟通风格       ← 交互风格
```

**Tmux-Orchestrator的CLAUDE.md**：
716行的行为知识库，包含完整的角色层级、Git纪律、通信协议、反模式列表。

**优点**：灵活、可读性强、LLM天然理解
**缺点**：无强制执行力——Agent可以"偷懒"不遵守规则

通过代码机制强制执行角色边界。

**核心规则机制**：
```bash
# prompt模板中的铁律标记
!!! IRON_LAW_START
1. 绝不自己写/改/运行项目代码
2. 绝不删文件（只能mv到legacy/）
3. 只用task_dispatch.sh派任务
!!! IRON_LAW_END

# 编排器每300秒检查标记是否被删除
# 删除则从git恢复 + 警告Agent
```

**Overstory的constraints字段**：
```typescript
// Agent定义中的机器可读限制
{
  file: "agents/builder.md",
  capabilities: ["builder"],
  canSpawn: false,
  constraints: {
    filePatterns: ["src/**/*.ts"],     // 只能改这些文件
    readOnlyPatterns: ["docs/**"],      // 这些文件只读
    maxFileSize: 500,                   // 单文件最大行数
    requireTests: true                  // 必须写测试
  }
}
```

**优点**：有强制执行力、可机器验证
**缺点**：灵活性差、约束粒度有限

### 方式三：能力标签（Overstory）

通过capability标签定义角色类型，系统根据标签分配任务和管理生命周期。

```typescript
const SUPPORTED_CAPABILITIES = [
  "coordinator",  // 持久协调者，可派生子Agent
  "supervisor",   // 持久监督者
  "lead",         // 团队领队，Phase流程
  "scout",        // 只读侦察
  "builder",      // 编码实现
  "reviewer",     // 只读审查
  "merger",       // 分支合并
  "monitor",      // 持续巡逻
  "orchestrator"  // 顶层编排
];
```

能力标签决定了：
- Agent能否派生子Agent（canSpawn）
- Agent是否有独立worktree（scout/reviewer不需要）
- Agent是否跨批次持久存在（coordinator/supervisor/monitor是持久的）
- Agent如何被看门狗监控（持久Agent不基于lastActivity判定stale）

**优点**：系统可自动推断行为、分组管理、调度优化
**缺点**：标签体系需要精心设计，不易扩展

## 3.2 角色数量的选择

从2个到50+，角色数量是第一个架构决策：

```
架构师(Hermes)：只管"做什么"
执行者(Codex)：只管"怎么做"
```

**适用场景**：个人/小团队项目，技术栈单一
**核心优势**：简单到不可能出错
**核心风险**：架构师成为单点，没有质量把关人

### 三角色：编排者+PM+工程师（Tmux-Orchestrator）

```
编排者：跨项目协调
PM：质量把关+任务分配
工程师：代码实现
```

**适用场景**：多项目并行，需要质量保障
**核心优势**：PM层分担了编排者的质量责任
**核心风险**：PM可能成为瓶颈

### 五角色：Scout+Builder+Reviewer+Merger+Lead（Overstory）

```
Lead：Phase流程管理
Scout：只读探索（不修改文件）
Builder：编码实现
Reviewer：只读审查
Merger：分支合并
```

**适用场景**：大型代码库，需要深度分工
**核心优势**：每个角色权限最小化（Scout不能改文件，Reviewer不能改文件）
**核心风险**：Lead协调成本高，Phase切换有延迟

### 50+角色：9部门体系（agency-agents-zh）

```
工程(33) / 设计(8) / 营销(35) / 产品(5) / 项目管理(6)
测试(9) / 运维支持(8) / 空间计算(6) / 专项(45+)
```

**适用场景**：完整产品生命周期（不只是编码）
**核心优势**：覆盖了从市场研究到运营的全链路
**核心风险**：上下文管理极其复杂，大部分角色不会同时在线

**关键洞察**：角色数量的选择应该从少开始。2-3个角色已经能覆盖80%的场景。增加角色的主要驱动力不是"功能更多"，而是"上下文隔离"和"权限最小化"。

## 3.3 角色约束：如何防止Agent越界

Agent越界是编排器面临的现实问题——Agent可能：
- 修改不该改的文件
- 删除自己的约束规则
- 跳过质量检查
- 越权执行操作

### 防线一：Prompt规则（最弱）

在提示词中写"你不应该做X"。这是最基础也最不可靠的防线——LLM可能无视、遗忘或"创造性解读"规则。

```bash
# 每300秒检查prompt中的铁律标记
# 如果被删除（Agent自己改了prompt）：
#   1. 从git恢复原始prompt
#   2. 发送警告消息
```

这是一个创新机制——承认Agent可能会修改自己的约束，然后用外部守护进程强制恢复。代价是增加了编排器的复杂度。

### 防线三：文件权限约束（Overstory）

```typescript
constraints: {
  filePatterns: ["src/**/*.ts"],      // 白名单：只能改这些
  readOnlyPatterns: ["docs/**"],       // 黑名单：这些只读
  maxFileSize: 500,
  requireTests: true
}
```

通过代码级约束，Agent想越界也没能力——它的工作目录和工具权限已经被限制了。

### 防线四：只读角色（Overstory Scout/Reviewer）

Scout和Reviewer的capability标记为不可写——它们在worktree中以只读模式运行，物理上不可能修改代码。

**防线强度排序**：
```
只读角色(最强) > 文件权限约束 > 规则守护 > Prompt规则(最弱)
```

**关键洞察**：对于关键约束，不要信任LLM的自律。用代码机制强制执行，至少要在Prompt规则之上叠加规则守护或文件权限约束。

## 3.4 持久角色 vs 临时角色

| 项目 | 持久角色 | 临时角色 | 持久角色特殊待遇 |
|------|---------|---------|----------------|
| Overstory | coordinator/supervisor/monitor | scout/builder/reviewer/merger | 不计入"所有完成"判断，不基于lastActivity判stale，仅用tmux/pid检查 |
| Tmux-Orchestrator | Orchestrator/PM | Engineer(可按需创建/销毁) | 临时Agent退出前必须保存日志 |
| Composio | Orchestrator是持久的 | Worker可按需增减 | Orchestrator崩溃=整个系统停滞 |
| agency-agents-zh | 编排者 | 其他所有智能体 | 编排者管理完整工作流 |

**持久角色的设计考量**：
1. 必须有独立于工作内容的监控方式（否则无法区分"在工作中"和"卡住了"）
2. 必须有跨会话状态恢复机制（checkpoint/handoff）
3. 不应参与具体任务的"完成"判定（否则永远不会结束）

## 3.5 角色与工具的映射

不同角色应该使用不同的AI工具——这取决于任务特点：

```
架构师 → 需要强推理能力 → 用Claude Sonnet/Opus
执行者 → 需要快+便宜 → 用Codex/Claude Haiku
侦察兵 → 只读探索，轻量即可 → 用轻量模型
审查者 → 需要细节注意力 → 用强推理模型
```

Overstory把这个映射做成了配置：

```yaml
models:
  coordinator: claude-opus-4    # 需要全局视野
  lead: claude-sonnet-4         # 需要任务分解能力
  scout: claude-haiku           # 只读探索，轻量即可
  builder: codex                # 编码专用
  reviewer: claude-sonnet-4     # 需要审查细节
  merger: claude-sonnet-4       # 需要冲突理解
```

**关键洞察**：角色≠工具，但角色应该推荐/约束工具选择。这既节省成本，又提高质量。
