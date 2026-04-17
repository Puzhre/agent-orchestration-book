# Chapter 13 Antipatterns: Pitfalls You Must Avoid

> Design patterns tell you how to do things right; antipatterns tell you how to avoid doing things wrong. In AI Agent orchestration, the cost of falling into a pit far exceeds the benefit of optimization—because Agents will automatically amplify your mistakes.

## 13.1 Antipattern 1: Automation Without a Watchdog

```
❌ Start an Agent and forget about it
→ Agent crashes → Nobody notices → Progress lost → Start over from scratch

✅ Dual-layer Watchdog guard
→ Inner layer: Agent's own heartbeat
→ Outer layer: Independent systemd monitoring
→ Automatic recovery within 15 seconds of crash
```

**Real-world Evidence**: Overstory's 4-layer fault tolerance system shows that agents without external monitoring can crash silently for hours, losing all progress. Production data shows 87% of agent failures are caught only by external watchdogs, not by the agents themselves.

**Lesson**: Automation without a watchdog is more dangerous than manual operation—it gives the illusion that "it's running."

## 13.2 Antipattern 2: Agent Modifies Its Own Rules

```
❌ Write "do not delete files" in the Prompt
→ Agent encounters an obstacle → Deletes this rule → Deletes files → "Problem solved"

✅ Iron rule dual blocks + External guardian
→ Iron rule at top + bottom → Agent can hardly delete both at once
→ Orchestrator checks periodically → If deleted, restore via git checkout
```

**Lesson**: Do not trust an Agent's self-restraint; enforcement must be external.

## 13.3 Antipattern 3: Single-Point Orchestrator

```
❌ One Orchestrator manages all Agents
→ Orchestrator crashes → All Agents stall

✅ Decentralize or layer
→ Each Agent can self-schedule (Tmux-Orchestrator's nohup+sleep)
→ Or layer: Global Orchestrator + Local PM
```

**Lesson**: The Orchestrator itself also needs fault tolerance.

## 13.4 Antipattern 4: Natural Language Communication

```
❌ Agent A outputs natural language → Agent B parses screen text
→ Inconsistent format → Parse failure → Message lost

✅ Structured protocol
→ SQLite mail system (Overstory)
→ JSON file handoff (Composio)
→ bracket-paste injection
```

**Lesson**: The more structured the communication between Agents, the more reliable the system.

## 13.5 Antipattern 5: Infinite Retries

```
❌ Agent fails → Retry → Fails again → Retry again → ...
→ API quota exhausted → 429 rate limiting → Vicious cycle

✅ Progressive recovery
→ Level 0: Warning
→ Level 1: Restart Agent
→ Level 2: Degraded processing
→ Level 3: Stop and report
→ On 429, persist cooldown state; continue countdown after restart
```

**Lesson**: Retries must have backoff strategies and upper limits.

## 13.6 Antipattern 6: Shared Workspace

```
❌ Multiple Agents on the same git branch / working directory
→ Agent A modifies a file → Agent B overwrites it → Lost in conflict

✅ git worktree isolation (Overstory/Composio)
→ Each Agent has its own independent workspace
→ Consolidate via merge strategy upon completion
```

**Lesson**: Concurrent Agents must be physically isolated; you cannot rely on Prompt constraints.

## 13.7 Antipattern 7: Context Window Fragmentation

```
❌ Stuff 100K of full project documentation into the Agent
→ Agent can only focus on the first 20K and last 10K
→ The middle 70K burns tokens for nothing

✅ Layered context
→ MISSION: 200-word direction (must-read)
→ SPRINT: 500-word current goal (must-read)
→ Chapter content: Load on demand
→ Historical decisions: LEARNINGS.md summary
```

**Real-world Evidence**: Context window fragmentation causes information loss in multi-agent systems. The problem exists in one unified context (human understanding) but swarms fragment it across many agents, causing critical insights to be lost in translation between agents.

**Production Data**: A 20-agent swarm completing 15 tasks over 6 hours consumed 8M tokens ($60) while a single agent completing the same tasks sequentially consumed 1.2M tokens ($9) - the 2-hour speedup cost $51 in coordination overhead.

**Lesson**: The context window is a scarce resource; it must be budgeted carefully. Fragmentation across multiple agents often costs more than sequential processing.

## 13.8 Antipattern 8: Stateless Restarts

```
❌ Agent crashes → Restarts → Starts from scratch
→ Where did it leave off last time? No idea → Duplicate work

✅ State persistence
→ Rate limit cooldown state written to file
→ Heartbeat file records last active time
→ FEATURES.md records completed features
→ SPRINT.md records current progress
```

**Lesson**: Any state that needs to survive a restart must not live only in memory.

## 13.9 Antipattern 9: Over-Engineering

```
❌ Build 4 layers of Watchdog + mail system + 11 runtimes for 5 Agents
→ Complexity explosion → Harder to maintain yourself than the Agents

✅ Progressive enhancement
→ Start with the simplest approach (tmux + bash)
→ Add mechanisms only when real problems arise
→ Every mechanism has a corresponding pitfall story behind it
```

**Lesson**: Over-engineering is as dangerous as no engineering. A good Orchestrator is honed, not designed.

## 13.10 Advanced Antipatterns from Production

### Antipattern 10: Compounding Error Rates

```
❌ Assume individual agent error rates add up linearly
→ 3 agents × 5% error = 15% expected failure rate

✅ Understand error multiplication in complex systems
→ 3 agents with 5% error rate = 1-(0.95³) ≈ 14.3% aggregate failure
→ Integration points where conflicts emerge cause exponential complexity
```

**Real-world Evidence**: Three parallel agents refactoring a shared type system. Each agent updates imports and type definitions in their scope. All tests pass locally. At merge time, the type hierarchy is internally inconsistent because no agent saw the full dependency graph.

**Lesson**: Multi-agent systems multiply failure probabilities rather than adding them. The compounding is worst at integration boundaries where no single agent has full context.

### Antipattern 11: Expertise Illusion

```
❌ Assume exploration and implementation separate cleanly
→ Scout explores auth system → Writes OAuth spec
→ Builder implements exactly as specified
→ Result: suboptimal design due to unknown dependencies

✅ Accept that right approaches are discovered during implementation
→ Single agent explores while implementing
→ Discovers better approach during coding
→ Adjusts course immediately with zero coordination overhead
```

**Real-world Evidence**: Scout explores the auth system and writes a spec for adding OAuth. The builder starts implementing and discovers the session management is tightly coupled to the existing password flow. The refactor needed is different from what the spec describes.

**Lesson**: The scout-spec-build pipeline assumes exploration and implementation separate cleanly, but right approaches are often discovered during implementation, not before.

## 13.11 Antipattern Quick Reference

|| Antipattern | Symptom | Fix |
||-------------|---------|-----||
|| No watchdog | Agent stopped and nobody noticed | Add Watchdog ||
|| Self-modifying rules | Iron rule deleted | Dual blocks + external guardian ||
|| Single-point Orchestrator | One crash takes down everything | Layering / self-scheduling ||
|| Natural language communication | Messages lost | Structured protocol ||
|| Infinite retries | 429 loop | Progressive recovery + cooldown ||
|| Shared workspace | File conflicts | git worktree ||
|| Context fragmentation | Information loss across agents | Layered context + MISSION injection ||
|| Stateless restart | Duplicate work | State persistence ||
|| Over-engineering | Maintenance harder than development | Progressive enhancement ||
|| Compounding errors | Integration conflicts | Sequential complex tasks or better isolation ||
|| Expertise illusion | Suboptimal specs | Single-agent exploration + implementation ||

## 13.11 Summary

Antipatterns are lessons distilled from repeatedly falling into pits in practice. Remember:

1. **Do not trust an Agent's self-restraint** — Enforcement must be external
2. **Do not trust natural language** — Structured protocols are mandatory
3. **Do not trust single points** — There must be backups and recovery
4. **Do not over-design** — Start simple, enhance as needed