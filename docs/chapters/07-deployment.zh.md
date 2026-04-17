# 第七章 配置与部署：怎么跑起来

## 7.1 部署模型的选择

五大项目代表了三种部署模型：

| 模型 | 代表项目 | 核心思路 |
|------|---------|---------|
| 守护进程 | Tmux-Orchestrator | 长期运行的后台进程 |
| CLI工具 | Composio、Overstory | 按需启动的命令行工具 |
| 纯规范 | agency-agents-zh | 无运行时，只是Prompt定义 |

## 7.2 守护进程模型

### systemd方案

```
用户空间systemd服务：
  orchestrator.service (oneshot + RemainAfterExit)
    → 启动orchestrator.sh
    → orchestrator.sh在tmux中运行Agent

  orch_watchdog.service + orch_watchdog.timer
    → 每5分钟检查心跳文件
    → 心跳超时则restart orchestrator.service

  loginctl linger
    → 用户注销后服务继续运行
```

**为什么用oneshot而非simple**：
orchestrator.sh的主循环是无限while，但systemd需要知道服务"启动完成"。oneshot + RemainAfterExit让systemd认为服务已启动，而实际工作在tmux中进行。

**setup.sh的一键注册**：

```bash
./setup.sh /path/to/project

# 自动完成：
# 1. 扫描项目目录（检测描述、技术栈、已有文件）
# 2. 生成 projects/<name>/config.sh
# 3. 复制 agent_prompt.txt 模板
# 4. 生成 task_dispatch.sh
# 5. 生成 SPRINT.md / FEATURES.md
# 6. 安装 systemd user service
# 7. 启用 loginctl linger
```

**配置生成**：

```bash
# config.sh 自动生成，包含所有配置变量
PROJECT_DIR="/path/to/my-project"
GENERIC_CMD="hermes chat --yolo"
EXEC_CMD="codex"
GENERIC_SESSION="my-project-generic"
EXEC_SESSION="my-project-exec"
CHECK_INTERVAL=60
NUDGE_INTERVAL=600
STALE_THRESHOLD=3600
RATE_LIMIT_COOLDOWN=300
# ...
```

### Tmux-Orchestrator的手动部署

没有自动化脚本，依赖CLAUDE.md中的自然语言指导：

```
1. 在 ~/Coding/ 中创建项目目录
2. tmux new-session -d -s <name> -c <path>
3. 创建标准窗口（Claude-Agent / Shell / Dev-Server）
4. 启动Claude CLI并发送角色简报
5. 运行调度测试：./schedule_with_note.sh 1 "Test schedule"
```

## 7.3 CLI工具模型

### Composio的ao命令

```bash
# 一行命令启动

# 自动完成：
# 1. 克隆仓库
# 2. 检测项目类型（Node/Python/Ruby/Go）
# 3. 自动生成 agent-orchestrator.yaml
# 4. 检测已安装的Agent运行时
# 5. 创建Orchestrator和Worker会话
# 6. 启动Dashboard（Web面板）
```

**预检机制**：

```typescript
async function preflight(options) {
  // 检查 git/node/pnpm 是否安装
  // 检查 Agent 运行时是否可用
  // 检查端口是否冲突
  // 检查权限是否充足
  return { ready: boolean, issues: string[] };
}
```

**agent-orchestrator.yaml配置**：

```yaml
projects:
  my-project:
    name: "My Project"
    path: ~/projects/my-project
    orchestrator:
      agent: claude-code
      model: claude-sonnet-4-20250514
      strategy: tmux
    workers:
      - agent: claude-code
        count: 3
    tools:
      enabled: true
      toolkit: [github, filesystem]
    projectType: auto
```

### Overstory的ov命令

```bash
# 初始化
ov init

# 启动协调者
ov coordinator

# 投递任务
ov sling --capability builder --task "实现用户认证"

# 监控
ov monitor

# 看门狗
ov watch
```

**Overstory配置（overstory.yaml）**：

```yaml
project:
  name: my-project
  root: ~/projects/my-project
  canonicalBranch: main
  qualityGates: [tests-pass, lint-clean, type-check]

agents:
  manifest: agent-manifest.json
  maxConcurrent: 5
  maxDepth: 3
  maxSessionsPerRun: 10

worktrees:
  baseDir: .overstory/worktrees

watchdog:
  tier0:
    enabled: true
    interval: 60s
    nudgeAfter: 120s
  tier1:
    enabled: true
    model: claude-haiku

models:
  coordinator: claude-opus-4
  scout: claude-haiku
  builder: codex
  reviewer: claude-sonnet-4

runtime:
  default: claude
  capabilities:
    builder: codex
    scout: claude
```

## 7.4 纯规范模型

### agency-agents-zh的安装脚本

```bash
# 一键安装到指定AI工具
./scripts/install.sh claude-code
./scripts/install.sh copilot
./scripts/install.sh cursor

# 内部：convert.sh 将Markdown智能体文件转换为目标格式
# 放置到目标工具的约定目录
```

**支持10+工具平台**：

| 工具 | 安装位置 | 格式 |
|------|---------|------|
| Claude Code | ~/.claude/agents/ | .md |
| GitHub Copilot | ~/.github/agents/ | .md |
| Cursor | .cursor/rules/ | .mdc |
| Aider | 项目根目录 | CONVENTIONS.md |
| Windsurf | 项目根目录 | .windsurfrules |
| AgentPlatform | ~/.agentplatform/agency-agents/ | SOUL.md |

## 7.5 Agent运行时检测

Composio和Overstory都实现了自动检测系统已安装的Agent运行时：

### Composio

```typescript
function detectAvailableAgents(): DetectedAgent[] {
  // 扫描PATH中的 claude, codex, aider, cursor, goose 等
  // 返回 id, name, runtime, command, args
}
```

### Overstory（11种运行时适配器）

```typescript
const RUNTIME_REGISTRY = {
  claude:  new ClaudeRuntime(),
  aider:   new AiderRuntime(),
  amp:     new AmpRuntime(),
  codex:   new CodexRuntime(),
  copilot: new CopilotRuntime(),
  cursor:  new CursorRuntime(),
  gemini:  new GeminiRuntime(),
  goose:   new GooseRuntime(),
  opencode: new OpenCodeRuntime(),
  pi:      new PiRuntime(),
  sapling: new SaplingRuntime(),
};
```

每个适配器实现统一的`AgentRuntime`接口：

```typescript
interface AgentRuntime {
  start(config): Promise<Process>;     // 启动Agent进程
  sendInput(text): Promise<void>;      // 发送输入
  deployHooks(session): Promise<void>; // 部署hook
  getPromptCommand(text): string;      // 获取发送命令
}
```

**关键洞察**：运行时适配器是编排器"Agent无关"设计的基础。没有它，每换一个Agent就要改编排器代码。

## 7.6 会话管理策略

| 策略 | 使用项目 | 优势 | 劣势 |
|------|---------|------|------|
| tmux | Tmux-Orchestrator、Composio、Overstory | 会话持久化、程序化控制 | 依赖tmux |
| VSCode集成 | Composio | 开发者友好 | 仅限VSCode |
| 直接终端 | Composio | 简单 | 无会话管理 |

**Composio的三种会话策略**：

```typescript
type SessionStrategy = "terminal" | "vscode" | "tmux";
// 推荐 tmux 用于多Agent并行
```

## 7.7 可视化与可观测性

### Composio Dashboard

React Web面板，展示Agent状态、日志、进度。通过HTTP/WebSocket提供实时数据。

### Overstory事件存储

```typescript
// SQLite事件存储，追踪所有系统事件
type EventType = 
  | "tool_start" | "tool_end"
  | "session_start" | "session_end"
  | "mail_sent" | "mail_received"
  | "spawn" | "error"
  | "turn_start" | "turn_end"
  | "progress" | "result";
```

## 7.8 部署设计的核心原则

### 原则一：一键启动是必须的

从`./setup.sh`到`ao start <url>`到`ov init`——所有成功的项目都有"一键"体验。手动配置10个变量的时代已经过了。

### 原则二：预检减少运行时错误

Composio的preflight()检查所有依赖，比运行时才发现"git没装"好得多。

### 原则三：配置即代码

YAML配置文件 > 环境变量 > 命令行参数 > 硬编码。配置文件可以被版本控制、被自动生成、被模板化。

### 原则四：systemd是Linux上的正确选择

对于需要7×24运行的守护进程，systemd user service + loginctl linger是最可靠的方案。它提供了：自动重启、日志管理、开机自启、资源限制。

### 原则五：运行时适配器是扩展性的关键

不想被绑定在某个AI工具上？就用运行时适配器。Overstory的11种适配器是目前最完整的实现。
