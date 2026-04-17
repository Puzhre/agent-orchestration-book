# Chapter 12: Pipeline Orchestration — From Task Dispatch to Delivery

> When a task is too complex for a single Skill to cover, you need to chain multiple steps into a pipeline. A pipeline is the "production line" of soft orchestration — each step has clear inputs, outputs, and quality gates.

## 12.1 Why Pipelines Are Needed

A single Agent has limited capabilities, but by breaking the task into multiple steps, each handled by a dedicated Agent/Skill:

```
❌ One Agent doing everything from start to finish
→ Context explosion, uncontrollable quality, no parallelism

✅ Pipeline: dedicated steps, quality gates, rollback support
→ Context isolation, layered quality, traceability
```

## 12.2 Case Study: AI Scientist Pipeline

AI Scientist is an automated pipeline for academic research:

```
Ideation → Experiment → Paper Writing → Peer Review
   ↓           ↓             ↓              ↓
 Hypothesis   Code          Paper Draft    Review Feedback
   ↓           ↓             ↓              ↓
 Quality     Quality       Quality        Quality
 Gate 1      Gate 2        Gate 3         Gate 4
```

Each step has:
- **Input specification**: the output format from the previous step
- **Quality gate**: rollback if standards are not met
- **Independent execution**: each step uses a different Prompt/Skill

## 12.3 Case Study: Seven-Stage Pipeline

The multi-stage pipeline from agency-agents-zh is more complex:

```
1. Recon → 2. Plan → 3. Review
     ↓          ↓          ↓
 Quality     Quality     Quality
 Gate 1      Gate 2      Gate 3
     ↓          ↓          ↓
4. Build → 5. Test → 6. Deploy → 7. Monitor
```

Each stage has standardized:
- Handoff templates (Markdown format)
- Quality gates (scoring system)
- Escalation protocol (3 failures → escalation)

## 12.4 Case Study: Lightweight Research Pipeline

A streamlined design for a five-step research pipeline:

```
Hypothesis → Theory → Simulation → Analysis → Paper
    ↓          ↓         ↓          ↓         ↓
 Human      AI-assisted  Human      AI-assisted  AI-assisted
                        decision
```

**Core principle**: Don't trust full automation; keep steps controllable, with AI assistance plus human decision-making at each step.

## 12.5 Overstory's Task Dispatch Pipeline

Overstory implements a production-grade dispatch pipeline with the `ov sling` command as its entry point:

### Capability-Based Dispatch

```typescript
// Dispatch by capability, not by agent name
ov sling --capability builder --task "Implement user authentication"
ov sling --capability scout --task "Research auth libraries"

// The coordinator resolves capability → agent mapping via manifest
interface AgentManifest {
  name: string;
  capabilities: string[];    // ["builder", "backend", "auth"]
  model: string;             // "claude-sonnet-4"
  maxConcurrentTasks: number;
  worktree: string;
}
```

**Key insight**: Dispatching by capability rather than by agent name decouples task assignment from agent identity. This means you can swap out agents without changing dispatch logic.

### Full Dispatch Lifecycle

```
ov sling → Coordinator receives dispatch
  → Check agent manifest for matching capability
  → Select least-busy agent (maxConcurrentTasks)
  → Create worktree branch: overstory/{agent}/{task}
  → Send dispatch mail to agent
  → Agent starts work in worktree
  → Watchdog monitors progress (tiered)
  → Agent completes → sends worker_done mail
  → Merger receives merge_ready mail
  → 4-level merge strategy
  → Merge complete → merged mail sent
  → Or merge_failed → agent reworks
```

### Tiered Watchdog Monitoring

```
Tier 0 (Bash timer):
  → Every 60 seconds: check agent heartbeat
  → After 120s of inactivity: send nudge
  → After 300s: escalate to Tier 1

Tier 1 (AI triage):
  → Launch lightweight model (claude-haiku)
  → Analyze agent's recent output
  → Determine: stuck? waiting? making progress?
  → Decide: nudge content, restart, or escalate to human
```

This two-tier approach avoids the common pitfall of either over-monitoring (wasting resources) or under-monitoring (missing real issues).

## 12.6 Pipeline Design Patterns

### Pattern 1: Linear Pipeline

```
A → B → C → D
```

The simplest form, where each step depends on the previous one. Suitable for tasks with clear causal relationships.

### Pattern 2: Branching Pipeline

```
A → B → C1 → D
       ↘ C2 ↗
```

Step C can execute different approaches in parallel, and D merges the results.

### Pattern 3: Iterative Pipeline

```
A → B → C → (Quality Check)
              ↓ Not passed
              → B (rollback and redo)
              ↓ Passed
              → D
```

Incorporates quality gates and rollback mechanisms.

### Pattern 4: Adaptive Pipeline

```
A → Router → B1 (Simple task)
           → B2 (Complex task)
           → B3 (Research task)
```

Dynamically selects the execution path based on task characteristics.

### Pattern 5: Fan-Out/Fan-In Pipeline

```
           → Scout-1 (explore auth) →
Coordinator → Scout-2 (explore db)   → Builder (implement chosen approach)
           → Scout-3 (explore api)  →
```

Overstory uses this pattern for its scout-discover-build cycle. Multiple scouts explore in parallel, then a builder implements the best approach found. This is a specialization of the branching pattern where parallel branches serve a reconnaissance purpose.

## 12.7 Quality Gate Design

Quality gates are the core of a pipeline — a pipeline without gates is just serial execution:

| Gate Type | Decision Method | Rollback Strategy |
|-----------|----------------|-------------------|
| Automated check | Test pass/fail | Automatic rollback to previous step |
| AI review | Score ≥ threshold | AI suggests revision points |
| Human approval | Human approves/rejects | Wait for human decision |
| Hybrid | Automated check + AI review + Human approval | Tiered rollback |

### Overstory's Quality Gate Implementation

```yaml
# overstory.yaml
project:
  qualityGates: [tests-pass, lint-clean, type-check]

# At merge time, all gates must pass before code reaches canonical branch
```

The Merger agent does not just merge code — it enforces quality gates. If tests fail, the merge is rejected with `merge_failed` mail sent back to the worker, requiring rework.

### agency-agents-zh Stage Gate

```markdown
# Stage Gate Template
## Stage: [N] — [Name]
### Entry Criteria
- [ ] Previous stage deliverables received
- [ ] Quality score ≥ 7/10
### Exit Criteria
- [ ] All deliverables produced
- [ ] QA passed with no P0 issues
- [ ] Handoff document completed
```

## 12.8 Merge as a Pipeline Stage

In multi-agent systems, merging is not an afterthought — it's a pipeline stage with its own quality gates and failure handling.

### Overstory's 4-Level Merge Strategy

```
Level 1: clean-merge    — No conflicts, merge directly (automated)
Level 2: auto-resolve   — Automatically resolve simple conflicts
                            (import ordering, trailing whitespace)
Level 3: ai-resolve     — AI-assisted conflict resolution
                            (query Mulch for historical patterns)
Level 4: reimagine      — AI re-imagines the entire file
                            (nuclear option, rarely needed)
```

### Mail-Driven Merge Protocol

```
Worker completes task
  → Sends worker_done mail to Supervisor
  → Supervisor sends merge_ready mail to Merger
  → Merger attempts merge (4-level strategy)
  → Success: sends merged mail → worktree cleaned up
  → Failure: sends merge_failed mail → Worker reworks
```

This is a pipeline within a pipeline — the merge step itself has stages, quality checks, and rollback capabilities.

## 12.9 Summary

Pipeline orchestration is the "production system" of soft orchestration:

1. **Decompose**: Break complex tasks into independent steps
2. **Dedicate**: Each step has a dedicated Agent/Skill
3. **Gate**: Each step has quality checks
4. **Rollback**: Return to the previous step when standards are not met
5. **Iterate**: The entire pipeline can run multiple rounds
6. **Merge**: In multi-agent systems, merging is a pipeline stage with its own gates
7. **Monitor**: Tiered watchdog ensures pipeline health without over-monitoring

The next chapter discusses anti-patterns — the pitfalls you must avoid.
