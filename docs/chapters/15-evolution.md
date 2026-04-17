# Chapter 15: Evolution Roadmap — From Running to Intelligent

> The evolution of an Orchestrator is not linear, but spiral. Each cycle of "hitting a pitfall → fixing → optimizing" elevates the system's reliability and intelligence.

## 15.1 Three-Stage Evolution Model

```
Stage One: Getting It Running
  → Manual startup, script daemons, basic fault tolerance
  → Key metric: uptime > 1 hour without crashing

Stage Two: Reliable Operation
  → Auto-restart, state persistence, multi-layer protection
  → Key metric: uptime > 24 hours without losing control

Stage Three: Intelligent Enhancement
  → Adaptive scheduling, experiential learning, ecosystem expansion
  → Key metric: keeps getting better, stops repeating mistakes
```

## 15.2 Current Position Assessment

| Orchestrator | Stage One | Stage Two | Stage Three |
|--------|--------|--------|--------|
| Tmux-Orchestrator | ✅ | 🔄 | ❌ |
| Overstory | ✅ | ✅ | 🔄 |
| Composio | ✅ | 🔄 | ❌ |
| agency-agents-zh | ✅ | ❌ | ❌ |

**Overstory is closest to Stage Three** because it already implements:
- Structured knowledge accumulation (Mulch)
- AI-assisted conflict resolution (merge Level 3)
- Tiered watchdog monitoring (Bash timer + AI triage)
- Capability-based dispatch (decoupled from agent identity)

## 15.3 Key Technologies for Stage Three

### Adaptive Scheduling

Current: fixed-interval polling (every 60 seconds)
Goal: dynamically adjust based on Agent state

```
Agent active → check every 5 minutes (save resources)
Agent possibly stuck → check every 1 minute
Agent definitely stuck → intervene immediately
Agent in 429 cooldown → wait until cooldown ends before checking
```

**Overstory's approach**: The tiered watchdog already implements a primitive form of adaptive scheduling — Tier 0 does fixed polling, but Tier 1 (AI triage) makes intelligent decisions about when and how to intervene.

### Experiential Learning

Current: LEARNINGS.md maintained manually
Goal: Agent automatically extracts experience from errors

```
Agent crashes → record crash reason
Agent retries 3 times → extract commonalities → write to LEARNINGS.md
Next encounter with similar issue → automatically apply experience
```

**Mulch as experiential learning seed**: Overstory's Mulch knowledge base already stores conflict patterns and failure patterns. The next step is to make pattern extraction automatic rather than requiring explicit writes.

### Cross-Project Coordination

Current: each project orchestrated independently
Goal: Orchestrator network, cross-project resource sharing

```
Agent in Project A idle → lend it to Project B
Project A hits 429 → Agent in Project B takes over
Global Supervisor → coordinates all Orchestrators
```

**The supervisor pattern**: Our own Supervisor agent (see Chapter 3) already implements a primitive form of this — it monitors multiple projects and can restart/stop agents across projects. But it lacks dynamic resource reallocation.

### Multi-Runtime Orchestration

Current: most orchestrators are locked to a single runtime
Goal: seamlessly mix different AI runtimes in one pipeline

```
Coordinator: claude-opus-4 (complex reasoning)
Scout: claude-haiku (fast exploration)
Builder: codex (code generation)
Reviewer: claude-sonnet-4 (balanced quality)
```

**Overstory's 11 runtime adapters** represent the most complete implementation of this vision. The key architectural decision is the `AgentRuntime` interface — a unified API that abstracts away runtime differences.

### Ecosystem Interoperability

Current: each orchestrator is an island
Goal: orchestrators share agents, skills, and knowledge

```
Hermes skills → available to Overstory agents
Overstory Mulch knowledge → queryable by Tmux-Orchestrator
agency-agents-zh agent definitions → deployable to any runtime
```

**agency-agents-zh's cross-platform deployment** is a step in this direction — its `install.sh` converts agent definitions to 10+ tool formats. But true interoperability requires shared protocols (not just shared definitions).

## 15.4 The Maturity Matrix

| Dimension | Stage One | Stage Two | Stage Three |
|-----------|-----------|-----------|-------------|
| **Fault Tolerance** | Manual restart | Auto-restart + watchdog | Self-healing + predictive |
| **Communication** | tmux send-keys | SQLite mail | Protocol-agnostic bus |
| **Knowledge** | None | LEARNINGS.md | Structured + auto-extraction |
| **Isolation** | Session isolation | git worktree | Dynamic worktree pools |
| **Dispatch** | Manual assignment | Script-based | Capability-based + adaptive |
| **Observability** | tmux capture-pane | Event store + dashboard | Real-time analytics + alerts |
| **Security** | Prompt rules | Iron law + external guard | Sandboxed execution + audit |
| **Deployment** | Manual tmux setup | systemd + one-click scripts | Cloud-native + auto-scaling |

## 15.5 Open Questions

1. **Agent Reliability Ceiling**: The reliability of the LLM itself determines the upper bound of the Orchestrator. No amount of orchestration can compensate for a model that consistently hallucinates.

2. **Context Window Limits**: Is 128K/200K enough to support complex projects? Overstory's overlay injection is one approach to this problem — inject only what's needed, not everything.

3. **Cost Control**: 7x24 operation means 7x24 API costs. Tiered monitoring (haiku for routine checks, opus for complex decisions) is Overstory's approach to cost optimization.

4. **Security Boundaries**: What can and can't an Agent do? Who decides? The iron-law + external-guard pattern is a pragmatic solution, but formal security models are needed.

5. **Human-Agent Collaboration Model**: Full autonomy vs. human-in-the-loop — which is better? agency-agents-zh's decision_gate protocol and Overstory's escalation paths suggest the answer is "both, depending on context."

6. **Merge Intelligence**: How smart can AI-assisted merging become? Overstory's Level 3 merge (query Mulch for historical patterns) is promising, but merge conflicts remain one of the hardest problems in multi-agent systems.

## 15.6 Predictions

Based on current trends, AI Agent orchestration will move toward the following in the next 1–2 years:

1. **Standardization**: Industry-standard Agent communication protocols will emerge (beyond MCP). The 9 Overstory mail protocols could become a de facto standard.

2. **Cloud-Native**: Orchestrators will evolve from single-machine Bash scripts to K8s Operators. Composio's dashboard is already cloud-aware; the next step is full K8s integration.

3. **Observability**: Agent behavior visualization — monitoring Agents like monitoring microservices. Overstory's event store and Composio's dashboard are early examples.

4. **Marketplace Ecosystem**: Skill/Agent marketplaces — tradable and composable. agency-agents-zh's catalog structure is a prototype for this.

5. **Self-Evolution**: Orchestrators will automatically optimize their own parameters and strategies. Mulch's conflict pattern learning is the first step toward this.

6. **Multi-Model Pipelines**: Pipelines that deliberately use different models for different stages (fast model for scouting, smart model for reviewing) will become the default. Cost-effectiveness and quality both improve.

7. **Human-AI Telemetry**: Real-time dashboards showing not just agent health, but decision quality, cost efficiency, and human oversight metrics.

## 15.7 Summary

The evolution path of an Orchestrator:

```
Running → Reliable → Intelligent → Ecosystem
  ↑                                   |
  └───────── Continuous Iteration ────┘
```

Core belief: **A good Orchestrator is honed, not designed.** Every crash, every 429, every time an Agent slacks off — they're all telling you what to improve next.

The practical progression for any team:

1. **Start with tmux + bash** (Stage One, days to implement)
2. **Add systemd + watchdog + LEARNINGS.md** (Stage Two, weeks to stabilize)
3. **Introduce structured communication + knowledge base + multi-runtime** (Stage Three, months to mature)
4. **Contribute back to the ecosystem** — share your patterns, your skills, your hard-won lessons

The future belongs to orchestrators that learn, adapt, and cooperate — not just run.
