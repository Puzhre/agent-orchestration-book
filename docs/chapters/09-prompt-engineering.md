# Chapter 9: Prompt Engineering — Iron Rules and Constraints

> Hard orchestration ensures the Agent keeps running, but doing what? The first line of defense in soft orchestration is the Prompt — shaping Agent behavior through carefully designed instructions. Note: Prompt iron rules are "soft" — they depend on Agent compliance. To ensure Agents don't delete rules, you need hard orchestration's Rule Guard (Ch8).

## 9.1 Why Prompts Need "Iron Rules"

AI Agents have a fatal characteristic: **they will modify their own constraints**.

When you write a rule for an Agent saying "do not delete files," the Agent, when encountering obstacles, might:

1. Directly delete this rule
2. Reinterpret the rule so it no longer applies
3. Find a path to bypass the rule

This is not theoretical — it happens repeatedly in practice. Iron rules cannot rely on the Prompt alone — they must be backed by external guard scripts (Ch8) for integrity assurance. This chapter focuses on Prompt writing techniques; for hard enforcement, see Ch8.

## 9.2 Iron Rule Writing Patterns

### Pattern 1: Double Iron Law Block

Place a core rule block at both the top and bottom of the prompt file:

```
════════════════════════════════════════
CORE RULE BLOCK — Iron Law (Non-deletable)
════════════════════════════════════════
1. Never delete project files, only move to legacy/
2. Never modify model configuration
3. Must commit+push after every change
════════════════════════════════════════
... (other prompt content) ...
════════════════════════════════════════
CORE RULE BLOCK (END) — Iron Law Confirmation
════════════════════════════════════════
```

**Principle**: Top declaration + bottom confirmation. Even if the Agent modifies middle content, the iron rules at both ends remain.
**Limitation**: Cannot prevent the Agent from completely rewriting the prompt file — this requires Ch8's external guard.

### Pattern 2: Layered Constraints

| Layer | Constraint Method | Can be modified by Agent? | Example |
|-------|-------------------|--------------------------|---------|
| L0 | System prompt | No (injected by Orchestrator) | "You are the Agent for project XX" |
| L1 | Core rule block | Yes (in user messages) | "Never delete files" |
| L2 | MISSION injection | Yes | "Your mission is..." |
| L3 | SPRINT-driven | Yes | "Current sprint goal..." |
| L4 | Creative hints | Yes | "You can try..." |

**Key insight**: The more important the constraint, the lower the layer it should be placed in (making it harder to modify).

**Hard-Soft Division**:
- L0 injected by orchestrator → Hard orchestration controls
- L1 iron law blocks → Written by Prompt soft orchestration, but protected by Ch8 Rule Guard (hard)
- L2-L4 → Pure soft orchestration, depends on Agent compliance

## 9.3 MISSION Injection: Persistent Sense of Direction

Agents gradually forget initial instructions during long conversations. The MISSION mechanism injects a concise mission description at the start of each conversation:

```bash
# MISSION injected at Agent startup, providing long-term direction
PROJECT_MISSION="You are a strict product creative gatekeeper. Few but refined, kill rather than let through.
Always check active/ for 3 items first. Graduation requires 92 points + 50 rounds + 7.5+ on all dimensions."
```

**Comparison**:

| Project | MISSION Carrier | Injection Frequency | Effect |
|---------|----------------|--------------------|----|
| Tmux-Orchestrator | CLAUDE.md | Agent maintains itself | Weak |
| Overstory | Initial prompt | Not re-injected | Weak |
| agency-agents-zh | Markdown prompt file | Every conversation | Strong |

## 9.4 SPRINT-Driven: Structured Work Goals

An Agent without clear goals will repeat the same action. SPRINT.md provides structured current goals:

```markdown
# Sprint Status
## Current Goal
- Analyze CrewAI's role orchestration mechanism
## In Progress
- [ ] Clone repository
- [ ] Extract architecture patterns
## Completed
- [x] 5 project analyses
```

**Difference from MISSION**: MISSION is long-term direction, SPRINT is short-term goals. They are used together.

## 9.5 Anti-Patterns: Common Prompt Pitfalls

### Pitfall 1: Rule Explosion

```
❌ 50-rule prompt
→ Agent can only remember the first 10 and last 5 rules
→ The middle 35 rules are effectively useless

✅ 5 iron rules + MISSION + SPRINT
→ Iron rules are inviolable
→ MISSION gives direction
→ SPRINT gives goals
```

### Pitfall 2: Positive Rules vs. Negative Rules

```
❌ "Write good code" — Too vague, each Agent has its own interpretation
✅ "Must run tests after every change" — Specific and verifiable

❌ "Don't make mistakes" — Unenforceable
✅ "Escalate after 3 consecutive failures" — Executable strategy
```

### Pitfall 3: One-Shot Prompt

```
❌ Give a long prompt only once at startup
→ After 50 rounds of conversation, the Agent has forgotten 80%

✅ Inject MISSION every round + periodically check iron rules
→ Constraints in the context window are always present
```

## 9.6 Summary

Prompt engineering is the cornerstone of soft orchestration. A good prompt is not a one-time long document, but rather:

1. **Iron Rules**: Inviolable baseline constraints (double block writing, Ch8 external guard protection)
2. **MISSION**: Persistent sense of direction (injected every time)
3. **SPRINT**: Structured short-term goals (updated with progress)
4. **Layering**: Important constraints placed in lower layers to prevent being overridden

Remember: Prompt iron rules themselves are soft — they tell the Agent "what you should do." To ensure the Agent won't delete rules, you need Ch8 Rule Guard's hard protection.

In the next chapter, we will discuss the Skill system — how to encapsulate repeatedly used prompt patterns into reusable capabilities.
