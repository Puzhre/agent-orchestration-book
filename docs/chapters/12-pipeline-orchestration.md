# Chapter 12: Pipeline Orchestration: From Hypothesis to Paper

> When a task is too complex for a single Skill to cover, you need to chain multiple steps into a pipeline. A pipeline is the "production line" of soft orchestration — each step has clear inputs, outputs, and quality gates.

## 11.1 Why Pipelines Are Needed

A single Agent has limited capabilities, but by breaking the task into multiple steps, each handled by a dedicated Agent/Skill:

```
❌ One Agent doing everything from start to finish
→ Context explosion, uncontrollable quality, no parallelism

✅ Pipeline: dedicated steps, quality gates, rollback support
→ Context isolation, layered quality, traceability
```

## 11.2 Case Study: AI Scientist Pipeline

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

## 11.3 Case Study: Seven-Stage Pipeline

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

## 11.4 Case Study: Lightweight Research Pipeline

A streamlined design for a five-step research pipeline:

```
Hypothesis → Theory → Simulation → Analysis → Paper
    ↓          ↓         ↓          ↓         ↓
 Human      AI-assisted  Human      AI-assisted  AI-assisted
                        decision
```

**Core principle**: Don't trust full automation; keep steps controllable, with AI assistance plus human decision-making at each step.

## 11.5 Pipeline Design Patterns

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

## 11.6 Quality Gate Design

Quality gates are the core of a pipeline — a pipeline without gates is just serial execution:

| Gate Type | Decision Method | Rollback Strategy |
|-----------|----------------|-------------------|
| Automated check | Test pass/fail | Automatic rollback to previous step |
| AI review | Score ≥ threshold | AI suggests revision points |
| Human approval | Human approves/rejects | Wait for human decision |
| Hybrid | Automated check + AI review + Human approval | Tiered rollback |

## 11.7 Summary

Pipeline orchestration is the "production system" of soft orchestration:

1. **Decompose**: Break complex tasks into independent steps
2. **Dedicate**: Each step has a dedicated Agent/Skill
3. **Gate**: Each step has quality checks
4. **Rollback**: Return to the previous step when standards are not met
5. **Iterate**: The entire pipeline can run multiple rounds

The next chapter discusses anti-patterns — the pitfalls you must avoid.
