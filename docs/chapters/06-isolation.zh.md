# 第六章 隔离与并发：怎么避免互相踩脚

## 6.1 并发问题的三种形态

多个Agent同时工作时，并发问题不可避免：

1. **代码冲突**：两个Agent改同一个文件
2. **资源竞争**：两个Agent同时调API被限流
3. **状态竞争**：两个Agent同时写任务队列

## 6.2 隔离方案一：Git Worktree（Overstory / Composio）

这是目前最可靠的隔离方案——每个Agent在完全独立的代码副本中工作。

### Overstory的Worktree管理

```typescript
// 创建worktree
git worktree add <path> -b overstory/{agentName}/{taskId}

// 分支命名规范
overstory/scout-1/explore-auth       // 侦察兵探索认证模块
overstory/builder-1/impl-auth        // 构建者实现认证
overstory/reviewer-1/review-auth     // 审查者审查认证
```

**Worktree管理器的职责**：
- 创建独立工作目录
- 管理分支命名规范
- 失败时回滚（`rollbackWorktree()`：remove + branch -D）
- 跟踪哪些worktree属于哪些Agent

### Composio的Worktree使用

同样基于git worktree，但更简单——Worker在独立worktree中编码，Orchestrator通过git merge整合结果。

### 4级合并策略（Overstory）

当多个Agent完成各自任务后，需要合并代码。Overstory设计了4级合并策略：

```
Level 1: clean-merge    — 无冲突，直接合并
Level 2: auto-resolve   — 自动解决简单冲突（如import排序）
Level 3: ai-resolve     — AI辅助解决冲突（利用历史模式）
Level 4: reimagine      — AI重新构思整个文件
```

**关键创新**：Level 3的AI冲突解决器会查询Mulch知识库中的历史冲突模式，预测哪些文件容易冲突，跳过历史上失败率高的策略。

```typescript
// 合并者接收 merge_ready 邮件后执行
async function merge(mergeRequest: MergeReadyPayload) {
  const strategy = await selectStrategy(conflictAnalysis, historicalPatterns);
  // Level 1-2: 自动处理
  // Level 3: 调用AI分析冲突
  // Level 4: 重新生成文件
  if (success) mail.send({ protocol: "merged", ... });
  else mail.send({ protocol: "merge_failed", ... });
}
```

**优点**：
- 完全隔离——Agent之间看不到彼此的修改
- 合并冲突有系统化处理方案
- 分支命名规范清晰，可追溯

**缺点**：
- 合并成本——每次合并都可能有冲突
- 存储成本——每个worktree是完整的代码副本
- 延迟——需要等所有相关Agent完成后才能合并

不通过代码级隔离，而是通过职责分工避免冲突——"你改后端，我改前端"。

### 职责隔离

```
架构师：只管SPRINT.md和FEATURES.md，绝不碰代码
执行者：只管代码实现，不管项目规划
```

架构师的铁律明确禁止写代码，执行者只能接收架构师的任务。这种"写/读分离"天然避免了冲突——因为两个Agent操作的文件集合完全不重叠。

### Tmux-Orchestrator的文件分配

```
PM分配任务时明确指定：
  "Engineer-1：你负责 src/auth/ 目录"
  "Engineer-2：你负责 src/api/ 目录"
```

**优点**：
- 零隔离成本——不需要额外的worktree或分支
- 简单——不需要合并策略

**缺点**：
- 依赖PM/架构师的分配智慧——如果分配不当，冲突不可避免
- 不适用于任务间有依赖的场景（如一个Agent的输出是另一个的输入）
- 难以扩展到3+个编码Agent

## 6.4 隔离方案三：会话隔离（所有tmux项目）

每个Agent运行在独立的tmux会话/窗口中，进程级隔离。

```
tmux session: project-name
  ├── window 0: Claude-Agent (架构师)
  ├── window 1: Shell
  ├── window 2: Dev-Server
  └── window 3: Codex (执行者)
```

这是最基础的隔离——Agent之间不会意外干扰彼此的终端。但它不提供文件级保护。

**safe_session()**：

```bash
# 所有tmux命令包裹timeout 10
safe_session() {
  timeout 10 tmux "$@" 2>/dev/null
}
# 防止单个tmux操作阻塞主循环
# 如果某个会话的tmux操作卡住，10秒后超时，不影响其他会话
```

## 6.5 隔离方案四：文件锁与并发控制

SPRINT.md同时被架构师（更新任务状态）和编排器（可能读取状态）访问。在单Agent场景下这没问题，但如果扩展到多Agent就会冲突。

**潜在方案**（尚未实现）：
```bash
# 用flock实现文件锁
(
  flock -x 200
  # 读写SPRINT.md
) 200>/tmp/sprint.lock
```

### todo.md的竞争条件（Composio）

多个Worker同时更新todo.md可能覆盖彼此的更新。Composio没有显式处理这个问题，依赖"Worker只更新自己那一行"的约定。

### SQLite WAL模式（Overstory）

Overstory用SQLite(WAL)解决了并发读写问题：

```
WAL(Write-Ahead Logging)模式：
- 读操作不阻塞写操作
- 写操作串行化（单写）
- 多个读操作可以并发
- 适合"多读少写"的Agent通信场景
```

## 6.6 API限流的并发管理

多个Agent同时调用同一个API（如Claude API），容易触发429限流。

### 方案

```
1. 检测429 → 进入冷却（300s）
2. 编排器在冷却期间跳过nudge，避免雪崩
3. 冷却到期 → 通知架构师恢复
4. 4次续期强制重启
5. 状态持久化到磁盘
```

### Overstory的方案

```
Watchdog检测到Agent无响应 → nudge → escalate → AI分诊
限流不是作为特殊场景处理，而是作为"卡住"的一种
```

**关键洞察**：限流处理更精细，因为它在实战中遇到了大量429场景。Overstory的通用Watchdog方案更优雅但可能不如专用方案响应及时。

## 6.7 隔离级别对比

| 隔离级别 | 方案 | 冲突可能性 | 实现成本 | 适用Agent数 |
|---------|------|-----------|---------|------------|
| Level 0 | 无隔离（agency-agents-zh） | 高 | 零 | 1 |
| Level 1 | 会话隔离 | 中 | 低 | 2-3 |
| Level 2 | 职责分工 | 低 | 低 | 2-3 |
| Level 3 | 文件分配 | 低 | 中 | 3-5 |
| Level 4 | Git worktree | 极低 | 高 | 5+ |

## 6.8 隔离设计的核心原则

### 原则一：隔离粒度要匹配并发需求

2个Agent用职责分工就够了，5个Agent需要文件分配，10个Agent必须用git worktree。不要过度设计，也不要设计不足。

### 原则二：隔离的代价是合并

git worktree提供了最强隔离，但也引入了合并成本。合并策略（4级合并）和冲突解决（AI辅助）是worktree隔离的必要配套。

### 原则三：写操作是冲突的根源

只读Agent（Scout、Reviewer）不需要隔离——它们不修改文件。将写操作集中在最少角色上是降低隔离成本的有效策略。

### 原则四：API限流是隐性并发问题

不像文件冲突那么明显，但429限流在多Agent场景下同样严重。限流状态必须持久化，冷却期间必须暂停所有请求。
