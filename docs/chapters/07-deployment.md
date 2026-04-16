# Chapter 7 Configuration & Deployment: Making It Run

## 8.1 Choosing a Deployment Model

The five projects represent three deployment models:

| Model | Representative Projects | Core Idea |
|-------|------------------------|-----------|
| Daemon | Tmux-Orchestrator | Long-running background process |
| CLI Tool | Composio, Overstory | On-demand command-line tools |
| Pure Spec | agency-agents-zh | No runtime, just Prompt definitions |

## 8.2 Daemon Model

### systemd Approach

```
User-space systemd services:
  orchestrator.service (oneshot + RemainAfterExit)
    → Starts orchestrator.sh
    → orchestrator.sh runs Agents in tmux

  orch_watchdog.service + orch_watchdog.timer
    → Checks heartbeat file every 5 minutes
    → Restarts orchestrator.service if heartbeat times out

  loginctl linger
    → Services continue running after user logs out
```

**Why oneshot instead of simple**:
The main loop of orchestrator.sh is an infinite while, but systemd needs to know that the service has "started successfully". oneshot + RemainAfterExit makes systemd consider the service started, while the actual work proceeds in tmux.

**One-click registration with setup.sh**:

```bash
./setup.sh /path/to/project

# Automatically completes:
# 1. Scan project directory (detect description, tech stack, existing files)
# 2. Generate projects/<name>/config.sh
# 3. Copy agent_prompt.txt template
# 4. Generate task_dispatch.sh
# 5. Generate SPRINT.md / FEATURES.md
# 6. Install systemd user service
# 7. Enable loginctl linger
```

**Configuration generation**:

```bash
# config.sh is auto-generated, containing all configuration variables
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

### Manual Deployment of Tmux-Orchestrator

No automation scripts; relies on natural language guidance in CLAUDE.md:

```
1. Create project directory in ~/Coding/
2. tmux new-session -d -s <name> -c <path>
3. Create standard windows (Claude-Agent / Shell / Dev-Server)
4. Start Claude CLI and send role briefing
5. Run scheduling test: ./schedule_with_note.sh 1 "Test schedule"
```

## 8.3 CLI Tool Model

### Composio's ao Command

```bash
# Start with a single command

# Automatically completes:
# 1. Clone repository
# 2. Detect project type (Node/Python/Ruby/Go)
# 3. Auto-generate agent-orchestrator.yaml
# 4. Detect installed Agent runtimes
# 5. Create Orchestrator and Worker sessions
# 6. Start Dashboard (Web panel)
```

**Preflight mechanism**:

```typescript
async function preflight(options) {
  // Check if git/node/pnpm are installed
  // Check if Agent runtime is available
  // Check for port conflicts
  // Check for sufficient permissions
  return { ready: boolean, issues: string[] };
}
```

**agent-orchestrator.yaml configuration**:

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

### Overstory's ov Command

```bash
# Initialize
ov init

# Start coordinator
ov coordinator

# Dispatch task
ov sling --capability builder --task "Implement user authentication"

# Monitor
ov monitor

# Watchdog
ov watch
```

**Overstory configuration (overstory.yaml)**:

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

## 8.4 Pure Spec Model

### agency-agents-zh Installation Script

```bash
# One-click install to specified AI tool
./scripts/install.sh claude-code
./scripts/install.sh copilot
./scripts/install.sh cursor

# Internally: convert.sh transforms Markdown agent files to target format
# Places them in the target tool's conventional directory
```

**Supports 10+ tool platforms**:

| Tool | Install Location | Format |
|------|-----------------|--------|
| Claude Code | ~/.claude/agents/ | .md |
| GitHub Copilot | ~/.github/agents/ | .md |
| Cursor | .cursor/rules/ | .mdc |
| Aider | Project root | CONVENTIONS.md |
| Windsurf | Project root | .windsurfrules |
| AgentPlatform | ~/.agentplatform/agency-agents/ | SOUL.md |

## 8.5 Agent Runtime Detection

Both Composio and Overstory implement automatic detection of system-installed Agent runtimes:

### Composio

```typescript
function detectAvailableAgents(): DetectedAgent[] {
  // Scan PATH for claude, codex, aider, cursor, goose, etc.
  // Return id, name, runtime, command, args
}
```

### Overstory (11 Runtime Adapters)

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

Each adapter implements a unified `AgentRuntime` interface:

```typescript
interface AgentRuntime {
  start(config): Promise<Process>;     // Start Agent process
  sendInput(text): Promise<void>;      // Send input
  deployHooks(session): Promise<void>; // Deploy hooks
  getPromptCommand(text): string;      // Get send command
}
```

**Key insight**: Runtime adapters are the foundation of the Orchestrator's "Agent-agnostic" design. Without them, switching to a different Agent would require modifying the Orchestrator code.

## 8.6 Session Management Strategies

| Strategy | Projects Using It | Advantage | Disadvantage |
|----------|-------------------|-----------|--------------|
| tmux | Tmux-Orchestrator, Composio, Overstory | Session persistence, programmatic control | Depends on tmux |
| VSCode Integration | Composio | Developer-friendly | VSCode only |
| Direct Terminal | Composio | Simple | No session management |

**Composio's three session strategies**:

```typescript
type SessionStrategy = "terminal" | "vscode" | "tmux";
// tmux is recommended for multi-Agent parallelism
```

## 8.7 Visualization & Observability

### Composio Dashboard

React Web panel displaying Agent status, logs, and progress. Provides real-time data via HTTP/WebSocket.

### Overstory Event Store

```typescript
// SQLite event store, tracking all system events
type EventType = 
  | "tool_start" | "tool_end"
  | "session_start" | "session_end"
  | "mail_sent" | "mail_received"
  | "spawn" | "error"
  | "turn_start" | "turn_end"
  | "progress" | "result";
```

## 8.8 Core Principles of Deployment Design

### Principle 1: One-Click Startup Is Mandatory

From `./setup.sh` to `ao start <url>` to `ov init` — all successful projects offer a "one-click" experience. The era of manually configuring 10 variables is over.

### Principle 2: Preflight Checks Reduce Runtime Errors

Composio's preflight() checks all dependencies, which is far better than discovering "git not installed" at runtime.

### Principle 3: Configuration as Code

YAML config files > environment variables > command-line arguments > hardcoding. Config files can be version-controlled, auto-generated, and templated.

### Principle 4: systemd Is the Right Choice on Linux

For daemons that need to run 24/7, systemd user service + loginctl linger is the most reliable solution. It provides: automatic restart, log management, boot-time startup, and resource limits.

### Principle 5: Runtime Adapters Are the Key to Extensibility

Don't want to be locked into a particular AI tool? Use runtime adapters. Overstory's 11 adapters represent the most complete implementation to date.
