# 第四章 通信机制：Agent之间怎么说话

## 4.1 通信是编排器的命脉

Agent间的通信质量直接决定了编排系统的上限。一个不可靠的通信系统意味着：任务丢失、状态不同步、容错失效。

五大项目走了五条截然不同的路：

**原理**：利用tmux的bracket-paste协议，将多行文本作为"粘贴"注入到目标终端，最后单独发送Enter提交。

```bash
# 核心实现
send_message() {
  local msg="$1"
  local tmp=$(mktemp)
  printf '\e[200~%s\e[201~' "$msg" > "$tmp"  # bracket-paste包裹
  tmux load-buffer "$tmp"
  tmux paste-buffer -t "$GENERIC_SESSION"
  sleep 0.5                                    # 等待UI注册输入
  tmux send-keys -t "$GENERIC_SESSION" Enter   # 单独提交
  rm "$tmp"
}
```

**为什么不用tmux send-keys**：
send-keys会将多行文本中的每一行都解析为一次Enter，导致命令被分割成碎片。这是tmux的已知行为，不是bug。

**通信路径**：
```
编排器 → 架构师：send_message()（nudge/警告/恢复通知）
编排器 → 执行者：send_to_exec()（/compact等运维指令）
架构师 → 执行者：task_dispatch.sh（任务派发）
编排器 → 两者：tmux capture-pane（状态感知，只读）
```

**优点**：
- 可靠：多行文本不会丢失
- 低延迟：直接写入终端
- 无依赖：不需要消息队列或数据库

**缺点**：
- 无ACK机制：不知道消息是否被处理
- 无结构化：发送的是自然语言，接收方可能误解
- 0.5秒延迟是经验值：不同终端/网络可能需要不同延迟
- 只能单向：Agent无法主动向编排器发送结构化消息

## 4.3 方案二：send-keys + capture-pane（Tmux-Orchestrator）

**原理**：用tmux send-keys发送消息，用tmux capture-pane读取Agent的屏幕输出。

```bash
# 发送
./send-claude-message.sh "session:window" "message content"
# 内部：发送文本 → sleep 0.5s → 发送Enter

# 接收
tmux capture-pane -t "session:window" -p -S -100  # 读取最近100行
```

**监控式通信**：Orchestrator通过capture-pane被动"看"Agent的输出，而不需要Agent主动报告：

```bash
# 查看开发服务器窗口发现错误
tmux capture-pane -t "project:Dev-Server" -p | grep -i error

# 跨窗口获取上下文
tmux capture-pane -t "project:Claude-Agent" -p -S -50
```

**优点**：
- 极简：一个脚本实现所有通信
- 人类可读：直接看终端输出

**缺点**：
- 不可靠：send-keys的0.5秒延迟是经验值，可能丢失消息
- 解析脆弱：grep屏幕文本容易误判
- 无法区分"正在处理"和"卡住了"
- 终端缓冲区有限，历史消息可能被刷掉

## 4.4 方案三：SQLite邮件系统（Overstory）

**原理**：用SQLite数据库实现异步消息队列，Agent通过CLI命令收发邮件。

```typescript
// 发送
mail.send({
  to: "lead-1",
  protocol: "dispatch",          // 协议类型
  payload: { task: "...", files: [...] }
});

// 接收
const msgs = mail.check("builder-1");  // 检查并标记已读

// 回复（线程化）
mail.reply(originalMsg.id, { status: "done", summary: "..." });
```

**9种协议消息类型**（强类型Payload）：

| 类型 | 方向 | 用途 |
|------|------|------|
| `dispatch` | Coordinator → Lead | 任务分发 |
| `assign` | Supervisor → Worker | 工作分配 |
| `worker_done` | Worker → Supervisor | 工作者完成 |
| `merge_ready` | Supervisor → Merger | 请求合并 |
| `merged` | Merger → Supervisor | 合并成功 |
| `merge_failed` | Merger → Worker | 合并失败需返工 |
| `escalation` | Any → Upper | 问题升级 |
| `health_check` | Watchdog → Agent | 健康探针 |
| `decision_gate` | Agent → Human | 人机决策门 |

**组地址广播**：`@all`、`@builders`、`@scouts`等组地址，自动解析为对应能力的活跃Agent列表。

**Hook注入**：通过运行时的UserPromptSubmit hook，将邮件内容注入到Agent的上下文中：

```bash
# 当Agent提交prompt时，自动检查并注入未读邮件
ov mail check --inject
```

**优点**：
- 可靠：SQLite WAL模式保证消息持久化
- 结构化：强类型协议避免自然语言歧义
- 可查询：可搜索历史消息、追踪线程
- 异步：不阻塞发送方

**缺点**：
- 拉取模式：Agent需要主动check，延迟取决于hook触发频率
- SQLite单写限制：高并发写入可能成为瓶颈
- 复杂度高：需要理解9种协议类型

## 4.5 方案四：共享文件协调（Composio）

**原理**：Orchestrator和Worker通过共享的todo.md和scratchpad文件协调工作。

```
Orchestrator写入todo.md：
  - [ ] 实现用户认证模块 (@worker-1)
  - [ ] 实现API端点 (@worker-2)
  - [x] 搭建项目脚手架 (completed)

Worker读取并更新：
  - [→] 实现用户认证模块 (@worker-1)  ← 标记进行中
  - [ ] 实现API端点 (@worker-2)
```

**优点**：
- 极简：不需要数据库或消息队列
- 人类可读：直接查看Markdown文件了解进度
- Agent天然支持：所有AI Agent都能读写文件

**缺点**：
- 无并发保护：多个Worker同时写todo.md可能冲突
- 无实时通知：需要轮询文件变化
- 语义模糊：Markdown格式缺乏严格的解析规则
- 丢失风险：文件损坏意味着进度信息全部丢失

## 4.6 方案五：MCP记忆 + Copy-Paste交接（agency-agents-zh）

**默认模式**：人工驱动的Copy-Paste交接。

```
用户在前一个Agent的输出和后一个Agent的输入之间复制粘贴：

Activate Backend Architect.
Here's our sprint plan: [粘贴 Sprint Prioritizer 输出]
Here's our research brief: [粘贴 UX Researcher 输出]
```

**增强模式**：通过MCP记忆服务器实现自动上下文传递。

```
1. 智能体A完成工作 → remember(决策+交付物+标签)
2. 智能体B启动 → recall(按标签搜索上下文)
3. 失败时 → rollback(回到检查点)
```

**7种标准化交接模板**：标准交接、QA通过、QA不通过、升级报告、阶段门禁、Sprint交接、事故交接。

**优点**：
- MCP模式支持语义搜索和自动上下文传递
- 交接模板规范化了信息传递格式
- rollback机制是独特亮点

**缺点**：
- 默认模式完全依赖人工
- MCP需要外部服务器
- 无运行时执行保证

## 4.7 五种通信方案的深度对比

| 维度 | Bracket-Paste | send-keys | SQLite邮件 | 共享文件 | MCP记忆 |
|------|-------------|-----------|-----------|---------|--------|
| **可靠性** | 中 | 低 | 高 | 中 | 中 |
| **延迟** | 低 | 低 | 中 | 中 | 高 |
| **结构化** | 无 | 无 | 强类型 | Markdown | 语义 |
| **可查询** | 否 | 否 | 是 | 是 | 是 |
| **并发安全** | 无 | 无 | WAL模式 | 无 | 取决于实现 |
| **实现复杂度** | 低 | 极低 | 中 | 低 | 高 |
| **人可读性** | 是 | 是 | 需工具 | 是 | 是 |
| **离线支持** | 否 | 否 | 是 | 是 | 取决于实现 |

## 4.8 通信设计的核心原则

从五大项目中提炼的通信设计原则：

### 原则一：关键操作用结构化协议，日常交互可用自然语言

Overstory的做法是正确的——任务分发、完成通知、合并请求这些关键操作用强类型协议，而Agent内部的工作日志、思考过程用自然语言。

### 原则二：推送优于拉取

拉取模式（capture-pane轮询、mail.check()）的问题是延迟不可控。理想方案是：
- 关键事件（完成、失败、升级）用推送通知
- 状态查询用拉取

### 原则三：消息必须持久化

基于内存/屏幕的通信在Agent崩溃后全部丢失。SQLite、文件系统、MCP记忆——任何持久化方案都比"读屏幕"强。

### 原则四：通信路径要显式声明

不要让Agent"猜"该和谁说话。显式的通信路由（如Overstory的mail地址系统）比隐式的"读屏幕猜状态"可靠得多。

### 原则五：组地址是必要的

当Agent数量超过3个时，点对点通信的复杂度爆炸。`@all`、`@builders`这种组地址是必要的抽象。
