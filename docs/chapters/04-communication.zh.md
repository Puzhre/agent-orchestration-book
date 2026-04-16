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

## 4.7 深度解析：群体交接 vs SQLite邮件 - 详细对比

### 架构分歧

**群体交接（agency-agents-zh）**代表了人机协同的工作流，其中上下文传递通过结构化交接模板完成，而**SQLite邮件（Overstory）**实现了带类型化协议消息的机器间协调系统。

### 实现架构

#### 群体交接：基于记忆的上下文传递

```typescript
// 核心交接工作流
interface HandoffContext {
  decisions: string[];        // 决策记录
  deliverables: string[];    // 交付物清单
  tags: string[];            // 标签用于搜索
  checkpoint: string;        // 检查点位置
}

// MCP记忆操作
1. 智能体A完成工作 → remember(决策 + 交付物 + 标签)
2. 智能体B启动 → recall(按标签搜索上下文)
3. 失败时 → rollback(回到检查点)
```

**核心组件：**
- **7种标准化交接模板**：标准交接、QA通过、QA不通过、升级报告、阶段门禁、Sprint交接、事故交接
- **MCP记忆服务器**：提供语义搜索和自动上下文传递
- **回滚机制**：独特的能力可以返回到之前的检查点
- **人工驱动默认模式**：在智能体输出和输入之间复制粘贴

#### SQLite邮件：基于协议的协调

```typescript
// 带强类型的邮件系统
interface MailMessage {
  id: string;                // 消息ID
  from: string;              // 发送方智能体
  to: string;                // 接收方智能体或"orchestrator"
  subject: string;           // 主题
  body: string;              // 正文
  type: MailProtocolType;    // 协议类型
  priority: "low" | "normal" | "high" | "urgent"; // 优先级
  threadId: string | null;   // 会话线程ID
  payload: string | null;    // JSON编码的结构化数据
  read: boolean;             // 是否已读
  createdAt: string;         // 创建时间戳
}

// 9种协议类型及其结构化载荷
type MailProtocolType = 
  | "dispatch"      // 协调者 → 组长：任务分发
  | "assign"        // 监督者 → 工作者：工作分配
  | "worker_done"    // 工作者 → 监督者：任务完成
  | "merge_ready"    // 监督者 → 合并者：请求合并
  | "merged"         // 合并者 → 监督者：合并成功
  | "merge_failed"   // 合并者 → 工作者：合并失败
  | "escalation"     // 任何智能体 → 上级：问题升级
  | "health_check"   // 监控者 → 智能体：健康检查
  | "decision_gate"  // 智能体 → 人类：人机决策门
```

**核心组件：**
- ** SQLite WAL模式**：确保并发访问安全
- **Hook注入**：通过UserPromptSubmit hook自动注入消息
- **组地址**：`@all`、`@builders`、`@scouts`自动解析为智能体列表
- **线程化会话**：跨消息保持会话上下文

### 详细对比矩阵

| 维度 | 群体交接 | SQLite邮件 |
|------|----------|-----------|
| **主要用例** | 人机协同工作流 | 机器间协调 |
| **上下文传递** | 基于标签的语义搜索 | 带载荷的结构化协议 |
| **错误恢复** | 回滚到检查点 | 带升级路径的重试 |
| **可扩展性** | 受人工交接容量限制 | 高（自动协议路由） |
| **实时性能** | 中等（取决于人工速度） | 高（1-5ms邮件操作） |
| **复杂度管理** | 模板减少认知负荷 | 类型系统防止歧义 |
| **多智能体编排** | 人工协调 | 自动分层调度 |
| **故障处理** | 需要人工干预 | 自动化升级工作流 |

### 选择何种时机

#### 选择群体交接当：
- 工作流中需要人工监督
- 上下文传递需要语义理解
- 项目涉及创造性决策
- 团队规模小（< 10个智能体）
- 质量控制需要人工判断
- 需要回滚能力进行迭代工作

#### 选择SQLite邮件当：
- 需要完全自动化的多智能体协调
- 需要结构化协议保证可靠性
- 大规模部署（> 10个智能体）
- 机器间通信占主导
- 实时协调至关重要
- 需要分层组织

### 实现模式

#### 群体交接实现
```markdown
# 标准交接模板
## 元数据
- 发送方: [智能体名称]（[部门]）
- 接收方: [智能体名称]（[部门]）
- 阶段: 第 [N] 阶段 — [阶段名称]
- 任务引用: [任务 ID]
- 优先级: [紧急 / 高 / 中 / 低]

## 上下文
- 项目: [项目名称]
- 当前状态: [具体进展]
- 相关文件: [文件列表]
- 依赖: [依赖关系]
- 约束: [技术约束]

## 交付要求
- 需要什么: [具体交付物]
- 验收标准: [可衡量的标准]
- 参考材料: [相关链接]

## 质量预期
- 必须通过: [质量标准]
- 需要的证据: [完成证明]
- 下一步: [接收方要求]
```

#### SQLite邮件实现
```typescript
// 发送任务分发
mail.sendProtocol({
  from: "coordinator",
  to: "lead-1",
  subject: "实现用户认证",
  type: "dispatch",
  priority: "high",
  payload: {
    taskId: "auth-001",
    specPath: "specs/auth-spec.md",
    capability: "backend",
    fileScope: ["src/auth/", "tests/auth/"],
    skipScouts: true
  }
});

// 接收和处理
const messages = mail.check("lead-1");
for (const msg of messages) {
  if (msg.type === "dispatch") {
    const payload = parsePayload(msg, "dispatch");
    // 处理任务分发
  }
}
```

### 性能特征

#### 群体交接
- **延迟**：可变（取决于人工速度）
- **可靠性**：高（人工监督）
- **吞吐量**：低（受人工速度限制）
- **可扩展性**：小团队外表现不佳

#### SQLite邮件
- **延迟**：每次操作1-5ms
- **可靠性**：高（WAL模式，类型安全）
- **吞吐量**：高（并发访问）
- **可扩展性**：优秀（分层路由）

### 集成模式

#### 混合方法
许多成功的编排器结合两种方法：

1. **SQLite邮件**用于机器间协调
2. **群体交接**用于人机决策点
3. **MCP记忆**用于跨会话上下文持久化

### 真实世界示例

#### agency-agents-zh NEXUS系统
- 使用交接模板进行质量门禁
- MCP记忆用于跨会话上下文
- 关键决策点的人工监督
- 迭代改进的回滚能力

#### Overstory系统
- 所有智能体间通信使用SQLite邮件
- 不同协调需求的协议类型
- 无缝集成的hook注入
- 广播消息的组地址

## 4.8 五种通信方案的深度对比

|| 维度 | Bracket-Paste | send-keys | SQLite邮件 | 共享文件 | MCP记忆 |
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
