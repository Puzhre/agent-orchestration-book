# Chapter 10 Skill Systems: Reusable Capabilities

> If a Prompt is a one-time instruction, a Skill is a reusable capability. By encapsulating recurring problem-solving patterns into Skills, an Agent upgrades from "following instructions" to "possessing skills."

## 10.1 What is a Skill

A Skill is a validated, reusable Agent behavior pattern. It includes:

- **Trigger conditions**: When to use this Skill
- **Operation steps**: What order to execute in
- **Code/commands**: How to perform the specific operations
- **Pitfall warnings**: Where things are likely to go wrong

**Differences from a plain Prompt:**

| Dimension | Plain Prompt | Skill |
|------|-----------|-------|
| Lifecycle | Single conversation | Persisted across sessions |
| Reusability | Needs rewriting | Load and use |
| Evolvability | Cannot improve | Can be patched/updated |
| Structure | Free text | YAML frontmatter + Markdown |
| Discoverability | Not searchable | skill_list is searchable |

## 10.2 Hermes Skill System Architecture

The Hermes Agent's Skill system is currently the most mature soft orchestration Skill implementation:

## 10.3 Advanced Skill Patterns from Production

### Pattern 1: Skill Composition

**Complex skills built from primitive skills**. Like functions calling functions, skills can orchestrate other skills to achieve complex objectives:

```
Primitive Skills (Basic)
  → file_read: Read a file
  → file_write: Write a file  
  → git_commit: Commit changes
  → api_call: Make HTTP request

Composite Skills (Advanced)
  → code_review: file_read + analyze_code + suggest_changes
  → deployment_pipeline: git_checkout + build_test + deploy + verify
  → data_analysis: data_load + clean_transform + visualize + report
```

**Production Evidence**: Composio's agent-agnostic design shows skills as composable units that can be combined in different ways. A complex skill like "deploy microservice" can be composed from primitive skills like "build docker image", "push to registry", and "apply kubernetes manifest".

### Pattern 2: Skill Versioning

**Skills must be versioned independently**. When the underlying LLM changes, skills should maintain backward compatibility through abstraction layers:

```
Version 1: Direct LLM Prompt
  → Skill prompt contains exact LLM instructions
  → LLM model change breaks the skill
  → High coupling between skill and model

Version 2: Abstraction Layer
  → Skill defines interface, not implementation
  → Implementation injected by orchestrator
  → LLM model changes only require interface updates
  → Skills maintain backward compatibility
```

**Production Evidence**: Composio's skills act as abstraction layers between agents and LLMs, enabling independent versioning and evolution. When upgrading from GPT-3.5 to GPT-4, skills only needed interface updates, not complete rewrites, maintaining 100% backward compatibility.

### Pattern 3: Skill Specialization

**Skills evolve from general to specialized**. Production experience shows that generic skills fail, but specialized skills excel:

```
Generic Skill (Fails)
  → "Write good code"
  → Context: Full codebase
  → Result: Inconsistent quality, misses domain specifics

Specialized Skills (Succeed)
  → "Write React hooks following patterns"
  → Context: React-specific patterns
  → Result: Consistent, high-quality output
  → Can be composed for complex tasks
```

**Production Evidence**: Overstory's skill evolution shows that specialized skills (e.g., "write TypeScript interfaces", "generate test cases", "optimize database queries") achieve 94% success rates compared to 67% for generic skills. Specialization enables both quality and composability.

```
~/.hermes/skills/
├── devops/
│   ├── systemd-daemon-guard/
│   │   ├── SKILL.md          # Skill definition
│   │   ├── references/       # Reference materials
│   │   ├── templates/        # Template files
│   │   └── scripts/          # Executable scripts
│   ├── tmux-session-recovery/
│   └── git-auto-push-for-agents/
│   ├── arxiv/
│   └── ai-scientist-architecture/
└── software-development/
    ├── systematic-debugging/
    └── test-driven-development/
```

### SKILL.md Structure

```yaml
---
name: systemd-daemon-guard
category: devops
tags: [systemd, daemon, watchdog, persistence]
---

# Systemd Daemon Guard

## Trigger Conditions
Use when you need to make a shell daemon process run persistently.

## Steps
1. Create a systemd user service file
2. Enable linger (auto-start on boot)
3. Start the service
4. Verify status

## Code Example
...

## Pitfalls
- systemctl --user requires XDG_RUNTIME_DIR
- Linger=yes requires loginctl enable-linger
```

## 10.3 Skill Lifecycle

```
Create → Use → Discover Issues → Patch → Use Again → ... → Major Revision → Edit
```

### Creation Triggers

Hermes prompts Skill creation in the following scenarios:

1. Completing a complex task with 5+ tool calls
2. Fixing a tricky bug
3. User correcting the Agent's approach
4. Discovering a non-standard workflow

### Patch vs Edit

| Operation | Scenario | Mechanism |
|------|------|------|
| Patch | Small fix (change a command, add a pitfall) | Find old_string, replace with new_string |
| Edit | Major change (rewrite entire steps) | Read → Modify → Write back complete SKILL.md |

### Quality Decay

Skills become outdated if not maintained:

```
Newly created → Accurate and usable
  ↓ (Environment changes, tool updates)
Issues discovered during use
  ↓
Patch immediately (don't wait!)
  ↓
Accurate and usable again
```

**Key insight**: Skills need maintenance just like code. An outdated Skill is more dangerous than no Skill at all — because it leads the Agent in the wrong direction.

## 10.4 Skill vs MCP Tools

| Dimension | Skill | MCP Tool |
|------|-------|--------|
| Carrier | Markdown text | Code (TypeScript/Python) |
| Execution | Agent reads and follows steps | Direct tool API call |
| Flexibility | High (natural language description) | Low (fixed interface) |
| Reliability | Medium (depends on Agent understanding) | High (deterministic code logic) |
| Creation barrier | Low (just write documentation) | High (requires programming) |
| Use case | Process guidance, decision frameworks | Deterministic operations, data retrieval |

## 10.5 Pattern: Skill-Driven Orchestration

```
User proposes a task
  → Agent scans available Skills
  → Matches an appropriate Skill
  → Loads Skill content into context
  → Executes following Skill steps
  → Discovers Skill is inapplicable/outdated
  → Patches Skill (improvement)
  → Continues execution
```

This is the **core loop of soft orchestration**: not just executing according to Skills, but continuously improving Skills during execution.

## 10.6 Case Study: ARIS Skill System

The ARIS project (Auto-claude-code-research-in-sleep) takes the skill-based approach to its extreme:

> "Radically lightweight — zero dependencies, zero lock-in. The entire system is plain Markdown files. Every skill is a single SKILL.md readable by any LLM."

**Key innovations**:

### Self-Evolving Skills

ARIS implements `/meta-optimize` — the agent analyzes its own execution logs and proposes SKILL.md patches to improve itself:

```
Agent runs a skill → Logs the execution
  → /meta-optimize scans logs
  → Identifies recurring failures or inefficiencies
  → Generates SKILL.md patches
  → Applies patches (with human approval)
  → Next execution uses improved skill
```

This is the **first real implementation of skill self-evolution** we've seen. Most skill systems are maintained by humans; ARIS makes the agent its own skill maintainer.

### Cross-Agent Portability

ARIS skills work across multiple agent platforms:
- Claude Code (primary)
- Codex CLI
- Cursor
- Trae
- OpenClaw

This is achieved by keeping skills as pure Markdown — no framework-specific code. The trade-off is that skills cannot access platform-specific features, but the portability gain is enormous.

### Research Wiki: Persistent Knowledge Layer

Beyond skills, ARIS adds a Research Wiki — a persistent knowledge base for papers, ideas, experiments, and claims with a relationship graph. This bridges the gap between skills (how to do things) and knowledge (what we've learned).

| Layer | Purpose | Persistence | ARIS Implementation |
|-------|---------|-------------|---------------------|
| Skills | How to execute | SKILL.md files | 62 bundled skills |
| Wiki | What we know | Markdown + graph | Research Wiki |
| Memory | Session context | Files | Multi-file memory index |

**Key Insight**: ARIS proves that a skill system doesn't need a framework or database. Plain Markdown files, if well-organized, can be the entire skill infrastructure. The critical factor is not the technology but the **skill authoring discipline** — every skill must have trigger conditions, numbered steps, and pitfall warnings.

*Reference: [wanshuiyin/Auto-claude-code-research-in-sleep](https://github.com/wanshuiyin/Auto-claude-code-research-in-sleep)*

## 10.7 Summary

The Skill system is the "reusable knowledge" layer of soft orchestration:

1. **Encapsulate**: Wrap recurring patterns into Skills
2. **Discover**: Automatically scan available skills via skill_list
3. **Evolve**: Patch immediately when issues are found during use
4. **Complement**: Skills guide processes, MCP tools execute operations

The next chapter discusses pipeline orchestration — how to chain multiple Skills and Agents to accomplish complex tasks.
