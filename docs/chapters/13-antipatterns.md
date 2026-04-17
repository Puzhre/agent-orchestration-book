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

## 13.7 Antipattern 7: Context Window Waste

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

**Lesson**: The context window is a scarce resource; it must be budgeted carefully.

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

## 13.10 Antipattern Quick Reference

| Antipattern | Symptom | Fix |
|-------------|---------|-----|
| No watchdog | Agent stopped and nobody noticed | Add Watchdog |
| Self-modifying rules | Iron rule deleted | Dual blocks + external guardian |
| Single-point Orchestrator | One crash takes down everything | Layering / self-scheduling |
| Natural language communication | Messages lost | Structured protocol |
| Infinite retries | 429 loop | Progressive recovery + cooldown |
| Shared workspace | File conflicts | git worktree |
| Context waste | Tokens burning money | Layered context |
| Stateless restart | Duplicate work | State persistence |
| Over-engineering | Maintenance harder than development | Progressive enhancement |

## 13.11 Summary

Antipatterns are lessons distilled from repeatedly falling into pits in practice. Remember:

1. **Do not trust an Agent's self-restraint** — Enforcement must be external
2. **Do not trust natural language** — Structured protocols are mandatory
3. **Do not trust single points** — There must be backups and recovery
4. **Do not over-design** — Start simple, enhance as needed