# 第五章 容错与恢复：系统挂了怎么办

## 5.1 容错是编排器的核心价值

一个没有容错的编排器比没有编排器更危险——它给人"自动化"的错觉，让你以为系统在正常运转，其实Agent可能已经卡死半小时了。

五大项目在容错上的投入差异极大，从1层到4层不等。本章系统性地拆解每层容错机制。

## 5.2 第一层：进程存活监控

最基础的容错——Agent进程是否还活着？

### tmux会话检测

所有基于tmux的项目都用这个方式：

```bash
# 精确匹配（=前缀防止前缀匹配bug）
tmux has-session -t "=$SESSION" 2>/dev/null

# Overstory：ZFC原则（Zero Failure Crash）
# 信号优先级：tmux liveness > PID liveness > 记录状态
# tmux dead + recorded "working" → 立即标记zombie
# tmux alive + recorded "zombie" → investigate（不自动杀）
```

**进程存活检测细节**：
```bash
is_generic_process_alive() {
  local pane_pid=$(tmux list-panes -t "$SESSION" -F "#{pane_pid}" 2>/dev/null)
  pstree -p "$pane_pid" | grep -qE "hermes|codex"
}
```

关键：不是只检查tmux会话是否存在，而是检查会话里是否有Agent进程。tmux会话可能存在但Agent已经退出了。

### PID进程检测

Overstory的ZFC健康检查状态机进一步区分了：

```
可观察状态（tmux/pid存活）优于记录状态
这是健康判断的真实来源

状态只允许向前转换：
  booting → working → completed/stalled/zombie
  
tmux dead + recorded "working" → 立即 zombie
pid dead + tmux alive → 视为 zombie
```

### LifecycleWorker（Composio）

```typescript
// 后台Worker持续监控Agent进程
ensureLifecycleWorker(config): void;
// 检测到异常退出时尝试恢复或通知
// 防止重复启动：isAlreadyRunning(id)
// 防止系统休眠：preventIdleSleep()
```

## 5.3 第二层：行为异常检测

Agent可能进程活着但行为异常——卡住了、陷入循环、被限流了。

```bash
# 每轮capture-pane取最后30行算MD5
# 与上次对比，判断是否"卡住"
SCREEN_MD5=$(tmux capture-pane ... | tail -30 | md5sum)

# 早停检测：3次检查无变化 + Agent在提示符 + 执行Agent空闲
# → nudge推送

# 硬超时：STALE_THRESHOLD(3600s)无变化 → 强制重启
```

这是最精细的限流处理方案：

```
检测：capture-pane最后3行扫描429/rate.limit等关键词

首次触发 → 进入RATE_LIMIT_COOLDOWN(300s)
          ↓
状态持久化到磁盘（重启后恢复）
          ↓
衰减续期：每次续期缩短冷却时间 cooldown/renew_count
          ↓
4次续期强制重启：打破无限限流循环
          ↓
冷却到期 → 通知架构师恢复派发
```

为什么需要"4次续期强制重启"？因为Agent可能反复请求被限流→等待→再请求→再限流，形成死循环。衰减续期打破了这个循环。

### AI分诊（Overstory Tier 1）

当机械监控无法判断时，调用一个短暂的AI Agent来分析：

```typescript
// Tier 1：AI分诊代理
// 读取Agent的最近输出
// 判断是卡住/等待/还是真正崩溃
// 返回 TriageResult：continue / restart / kill
```

这是一个聪明的混合策略——机械守护处理确定性场景（进程死了），AI分诊处理模糊场景（进程活着但不知道在干嘛）。

## 5.4 第三层：自愈与恢复

检测到问题后，怎么恢复？

### 渐进式恢复（Overstory 4层Watchdog）

```
Tier 0 — 机械守护进程
  Level 0 (warn):      日志警告
  Level 1 (nudge):     发送tmux nudge（按键唤醒）
  Level 2 (escalate):  调用Tier 1 AI分诊
  Level 3 (terminate): 杀死tmux会话

渐进式处理：先轻后重，不要上来就杀进程
```

### 自调度链（Tmux-Orchestrator）

```bash
schedule_with_note.sh <minutes> "<note>" [target_window]

# 工作原理：
# 1. 将调度信息写入 next_check_note.txt
# 2. nohup后台sleep进程
# 3. sleep结束后，tmux send-keys发送唤醒命令
```

这是Tmux-Orchestrator最核心的创新——Agent能给自己设闹钟。Orchestrator调度自身检查、PM调度自身复查、Engineer调度自身同步。

**脆弱性**：依赖nohup+sleep，系统重启后调度链断裂。

```
第一层：内置Watchdog（fork子进程）
  - 检查心跳文件（每60s更新）
  - 心跳超过600s未更新 → TERM信号 → 等30s → KILL → 重启

第二层：外部Watchdog（systemd timer）
  - 每5分钟检查心跳文件
  - 作为最后防线：内置Watchdog也挂了时触发

为什么需要两层？
  safe_session()可能全部超时（每个10s，多个会话），导致内置Watchdog卡死
  此时心跳文件不更新，systemd timer触发外部重启
```

### 会话交接与恢复（Overstory）

```typescript
// Checkpoint：保存完整会话状态
{
  agentName, taskId, progressSummary,
  filesModified, pendingWork, currentBranch,
  lastCommit, openQuestions
}

// Handoff：记录交接历史
{ fromSessionId, toSessionId, reason, timestamp }

// 恢复：找到最近的未完成handoff，加载checkpoint
resumeFromHandoff(agentName)
```

这是唯一一个支持"精确恢复"的方案——不是简单重启Agent，而是恢复到之前的工作进度继续。

```bash
crash_restart() {
  CRASH_TIMESTAMPS+=(now_ts)
  # 保留最近10次崩溃时间戳
  # 120秒内3次崩溃 → 强制120s冷却
  # 防止Agent反复崩溃导致无限重启循环
}
```

## 5.5 第四层：质量保障

即使Agent没崩溃，也可能产出低质量结果。质量保障是容错的最高形态。

### 开发-测试循环（agency-agents-zh）

```
开发者实现 → 证据收集者测试 → 决策逻辑
  ├── PASS → 下一个任务
  ├── FAIL + 重试<3 → 带反馈回到开发者
  └── FAIL + 重试=3 → 升级给编排者
```

核心规则：
- 每个任务必须在推进之前通过QA
- 每个任务最多3次重试
- 重试必须携带具体的QA反馈

### 现实检验者（agency-agents-zh）

```
默认判定：NEEDS WORK（需要改进）
只有在压倒性证据下才给出 READY（就绪）

三种判定：
  READY → 可以上线
  NEEDS WORK → 回到第3阶段修改
  NOT READY → 回到第1/2阶段重新设计
```

这是防止"过早上生产"的最后一道防线。首次实现预期需要2-3轮修改，这是正常的。

```bash
# 每300秒检查prompt中的IRON_LAW标记
# 如果标记被删除（Agent自己改了规则）：
#   1. git checkout HEAD -- scripts/auto_push.sh  # 从git恢复
#   2. 发送警告消息给架构师
```

### PM质量保证协议（Tmux-Orchestrator）

- 代码审查在合并前进行
- 测试覆盖率监控
- 性能基准测试
- 安全扫描
- 强制git纪律：每30分钟提交、特性分支、有意义提交信息

## 5.6 五大项目容错能力对比

|| 容错能力 |---------|-----------------|-------------------|----------|-----------|-----------------||
|| 进程监控 | tmux+pid | tmux | LifecycleWorker | ZFC状态机 | 无运行时 ||
|| 限流处理 | 持久化+衰减+4次重启 | 无 | 无 | 无 | 无 ||
|| 卡住检测 | MD5快照+早停+硬超时 | 自调度链 | 无 | 4层Watchdog | 质量门禁 ||
|| AI辅助诊断 | 无 | 无 | 无 | Tier 1分诊 | 无 ||
|| 会话恢复 | 无（重启） | 无（重启） | git回滚 | checkpoint+handoff | MCP rollback ||
|| 崩溃保护 | 快速崩溃限速 | 无 | 无 | 渐进式nudge | 升级协议 ||
|| 规则守护 | 规则守护 | CLAUDE.md约定 | 无 | constraints字段 | Prompt规则 ||
|| 质量保障 | 无（信任架构师） | PM审查 | Orchestrator审查 | Reviewer角色 | 证据收集+现实检验 ||
|| 双层保护 | 内置+systemd | 无 | LifecycleWorker | 4层Watchdog | 4级容错 ||

### 实战中的容错模式

**Tmux-Orchestrator的Git纪律作为容错：**
- 强制每30分钟提交，防止工作成果丢失
- 特性分支和稳定标签创建恢复点
- 项目经理作为第一道防线执行质量标准
- 自调度链确保Agent不会永久卡住

**agency-agents-zh的多阶段QA作为容错：**
- 七阶段流水线，配备强制质量门禁
- 证据收集者测试每次实现
- 现实检验者提供三层判定（READY/NEEDS WORK/NOT READY）
- 每个任务最多3次重试，携带具体反馈

**Composio的CI/CD集成作为容错：**
- Agent自主修复CI失败
- 基于PR的工作流提供人工监督
- 每个Agent在独立的git worktree中工作，防止冲突
- 仪表盘监控实时状态

**Overstory的4层Watchdog系统：**
- Tier 0：机械守护进程（日志记录、nudge唤醒）
- Tier 1：AI分诊（分析模糊情况）
- Tier 2：渐进式升级（warn → nudge → escalate → terminate）
- Tier 3：带检查点恢复的会话交接

## 5.7 容错设计的核心原则

### 原则一：机械监控优于AI判断

ZFC原则的核心——用确定性信号（进程是否活着、心跳是否更新）而非不确定信号（AI觉得卡了）作为恢复触发器。AI分诊只在机械监控无法判断时介入。

### 原则二：渐进式恢复

不要上来就杀进程。warn → nudge → escalate → terminate，逐步加重。很多"卡住"只是Agent在思考，nudge一下就好。

### 原则三：状态必须持久化

限流状态、崩溃记录、检查点——这些必须写入磁盘。重启后丢失状态意味着重复犯同样的错。

### 原则四：防循环机制

快速崩溃保护、4次续期强制重启——这些看似边缘的场景，在7×24小时运行中一定会发生。没有防循环机制，编排器会陷入"崩溃→重启→崩溃"的死循环。

### 原则五：质量是最高级容错

防止低质量产出比防止崩溃更重要。崩溃可以重启，但低质量代码合入了主分支，回退成本远高于重新运行。
