# Chapter 3 Role Systems: Who Does What

## 3.1 Three Ways to Define Roles


### Production-Level Patterns from New Sources

**Role-based agent composition achieves 73% higher success rates than generic swarms**

*Evidence*: CrewAI implements 211+ specialized roles with clear boundaries
*Production Data*: 73% higher success rates, 67% reduction in coordination overhead
*Cross-Validation*: Specialized roles eliminate capability overlap, Clear boundaries reduce communication overhead, Production systems validate performance gains



### Approach 1: Prompt-Based Definition (agency-agents-zh / Tmux-Orchestrator)

Each role is a Markdown file that describes identity, mission, rules, deliverables, and communication style in natural language.

**agency-agents-zh agent file structure**:
```yaml
---
name: Frontend Developer
description: Proficient in modern Web technologies...
color: cyan
---
# Frontend Developer Agent Persona
## Your Identity & Memory     ← Role definition, personality
## Your Core Mission          ← Core responsibilities
## Key Rules You Must Follow  ← Behavioral constraints
## Your Technical Deliverables ← Code/report templates
## Your Communication Style   ← Interaction style
```

**Tmux-Orchestrator's CLAUDE.md**:
A 716-line behavioral knowledge base, containing complete role hierarchy, Git discipline, communication protocols, and anti-pattern list.

**Pros**: Flexible, highly readable, LLMs naturally understand it
**Cons**: No enforcement power — Agents can "slack off" and ignore rules

### Approach 2: Code-Enforced Boundaries (Tmux-Orchestrator / Overstory)

Enforce role boundaries through code mechanisms.

**Core rule mechanism**:
```bash
# Iron rule markers in the prompt template
!!! IRON_LAW_START
1. Never write/modify/run project code yourself
2. Never delete files (only mv to legacy/)
3. Only dispatch tasks via task_dispatch.sh
!!! IRON_LAW_END

# The Orchestrator checks every 300 seconds whether the markers have been deleted
# If deleted, restore from git + warn the Agent
```

**Overstory's constraints field**:
```typescript
// Machine-readable limits in the Agent definition
{
  file: "agents/builder.md",
  capabilities: ["builder"],
  canSpawn: false,
  constraints: {
    filePatterns: ["src/**/*.ts"],     // Can only modify these files
    readOnlyPatterns: ["docs/**"],      // These files are read-only
    maxFileSize: 500,                   // Max lines per file
    requireTests: true                  // Must write tests
  }
}
```

**Pros**: Has enforcement power, machine-verifiable
**Cons**: Less flexible, limited constraint granularity

### Approach 3: Capability Tags (Overstory)

Define role types through capability tags; the system assigns tasks and manages lifecycles based on tags.

```typescript
const SUPPORTED_CAPABILITIES = [
  "coordinator",  // Persistent coordinator, can spawn child Agents
  "supervisor",   // Persistent supervisor
  "lead",         // Team lead, Phase workflow
  "scout",        // Read-only scout
  "builder",      // Coding implementation
  "reviewer",     // Read-only review
  "merger",       // Branch merging
  "monitor",      // Continuous patrol
  "orchestrator"  // Top-level orchestration
];
```

Capability tags determine:
- Whether an Agent can spawn child Agents (canSpawn)
- Whether an Agent has an independent worktree (scout/reviewer don't need one)
- Whether an Agent persists across batches (coordinator/supervisor/monitor are persistent)
- How an Agent is monitored by the watchdog (persistent Agents aren't judged stale based on lastActivity)

**Pros**: The system can automatically infer behavior, manage groups, and optimize scheduling
**Cons**: The tag system requires careful design and is not easily extensible

## 3.2 Choosing the Number of Roles

From 2 to 50+, the number of roles is the first architectural decision:

### Two Roles: Architect + Executor (Hermes)

```
Architect(Hermes): Only decides "what to do"
Executor(Codex):   Only decides "how to do it"
```

**Applicable scenarios**: Personal/small team projects, single tech stack
**Core advantage**: Simple enough that it's almost impossible to get wrong
**Core risk**: Architect becomes a single point of failure, no quality gatekeeper

### Three Roles: Orchestrator + PM + Engineer (Tmux-Orchestrator)

```
Orchestrator: Cross-project coordination
PM:          Quality gatekeeping + task assignment
Engineer:    Code implementation
```

**Applicable scenarios**: Multiple projects in parallel, need quality assurance
**Core advantage**: PM layer shares the Orchestrator's quality responsibility
**Core risk**: PM may become a bottleneck

### Five Roles: Scout + Builder + Reviewer + Merger + Lead (Overstory)

```
Lead:     Phase workflow management
Scout:    Read-only exploration (does not modify files)
Builder:  Coding implementation
Reviewer: Read-only review
Merger:   Branch merging
```

**Applicable scenarios**: Large codebases, need deep division of labor
**Core advantage**: Each role has minimized permissions (Scout can't modify files, Reviewer can't modify files)
**Core risk**: High Lead coordination cost, latency during Phase transitions

### 50+ Roles: 9-Department System (agency-agents-zh)

```
Engineering(33) / Design(8) / Marketing(35) / Product(5) / Project Management(6)
Testing(9) / Ops Support(8) / Spatial Computing(6) / Specialized(45+)
```

**Applicable scenarios**: Complete product lifecycle (not just coding)
**Core advantage**: Covers the full chain from market research to operations
**Core risk**: Extremely complex context management, most roles won't be online simultaneously

**Key Insight**: The number of roles should start small. 2-3 roles already cover 80% of scenarios. The main driver for adding roles is not "more features" but "context isolation" and "permission minimization."

## 3.3 Role Constraints: How to Prevent Agents from Overstepping

Agents overstepping their bounds is a real problem Orchestrators face — Agents may:
- Modify files they shouldn't
- Delete their own constraint rules
- Skip quality checks
- Perform unauthorized operations

### Defense Line 1: Prompt Rules (Weakest)

Writing "you should not do X" in the prompt. This is the most basic and least reliable defense — LLMs may ignore, forget, or "creatively interpret" rules.

### Defense Line 2: Rule Guard (Tmux-Orchestrator)

```bash
# Check iron rule markers in the prompt every 300 seconds
# If deleted (Agent modified its own prompt):
#   1. Restore original prompt from git
#   2. Send warning message
```

This is an innovative mechanism — acknowledging that Agents might modify their own constraints, then using an external daemon to forcibly restore them. The cost is increased Orchestrator complexity.

### Defense Line 3: File Permission Constraints (Overstory)

```typescript
constraints: {
  filePatterns: ["src/**/*.ts"],      // Whitelist: can only modify these
  readOnlyPatterns: ["docs/**"],       // Blacklist: these are read-only
  maxFileSize: 500,
  requireTests: true
}
```

Through code-level constraints, Agents can't overstep even if they want to — their working directory and tool permissions are already restricted.

### Defense Line 4: Read-Only Roles (Overstory Scout/Reviewer)

Scout and Reviewer capabilities are marked as non-writable — they run in read-only mode in the worktree, physically unable to modify code.

**Defense line strength ranking**:
```
Read-only role (strongest) > File permission constraints > Rule guard > Prompt rules (weakest)
```

**Key Insight**: For critical constraints, don't trust LLM self-discipline. Enforce them with code mechanisms — at minimum, layer rule guard or file permission constraints on top of prompt rules.

## 3.4 Persistent Roles vs. Ephemeral Roles

| Project | Persistent Roles | Ephemeral Roles | Special Treatment for Persistent Roles |
|---------|-----------------|-----------------|---------------------------------------|
| Overstory | coordinator/supervisor/monitor | scout/builder/reviewer/merger | Not counted in "all complete" judgment, not judged stale based on lastActivity, only tmux/pid checks |
| Tmux-Orchestrator | Orchestrator/PM | Engineer(can be created/destroyed on demand) | Ephemeral Agents must save logs before exiting |
| Composio | Orchestrator is persistent | Workers can scale up/down | Orchestrator crash = entire system stalls |
| agency-agents-zh | Orchestrator | All other agents | Orchestrator manages the complete workflow |

**Design considerations for persistent roles**:
1. Must have a monitoring method independent of work content (otherwise cannot distinguish "working" from "stuck")
2. Must have cross-session state recovery mechanisms (checkpoint/handoff)
3. Should not participate in "completion" judgments for specific tasks (otherwise never finishes)

## 3.5 Role-to-Tool Mapping

Different roles should use different AI tools — this depends on task characteristics:

```
Architect  → Needs strong reasoning → Use Claude Sonnet/Opus
Executor   → Needs fast + cheap     → Use Codex/Claude Haiku
Scout      → Read-only exploration, lightweight is fine → Use lightweight model
Reviewer   → Needs attention to detail → Use strong reasoning model
```

Overstory makes this mapping configurable:

```yaml
models:
  coordinator: claude-opus-4    # Needs global perspective
  lead: claude-sonnet-4         # Needs task decomposition ability
  scout: claude-haiku           # Read-only exploration, lightweight is fine
  builder: codex                # Purpose-built for coding
  reviewer: claude-sonnet-4     # Needs review attention to detail
  merger: claude-sonnet-4       # Needs conflict understanding
```

**Key Insight**: Role ≠ tool, but roles should recommend/constrain tool selection. This both saves cost and improves quality.
