# Chapter 11 Knowledge Accumulation and Evolution: How to Get Better Over Time

## 11.1 Why Knowledge Accumulation Matters


### Production-Level Patterns from New Sources

**Conversational state persistence reduces context window fragmentation by 45%**

*Evidence*: AutoGen implements conversation state management across multiple turns
*Production Data*: 45% reduction in context fragmentation, 67% improved coherence
*Cross-Validation*: State persistence maintains conversation context, Reduced fragmentation improves response quality, Production validation shows significant gains



Every time an AI Agent starts up, it's a "blank slate" — it doesn't know what mistakes were made last time, which approaches don't work, or the project's decision history. Without knowledge accumulation, the Orchestrator keeps repeating the same things and making the same mistakes.

Among the five major projects, there are three different paradigms for knowledge accumulation:

## 11.2 Paradigm One: Natural Language Experience Documents (Tmux-Orchestrator)

### LEARNINGS.md

Tmux-Orchestrator uses a Markdown file to continuously accumulate lessons learned:

```markdown
## Learnings

### Web Search Timeout
If an Agent is stuck on a problem for more than 10 minutes, suggest it use Web search.
Often, being stuck is due to missing external information, not a logic error.

### Escalate After 3 Failures
If an Agent fails the same task 3 consecutive times, escalate immediately.
Don't let the Agent fall into a loop.

### Verify Actual Errors
The PM must ask "What is the specific error message?" instead of letting the Engineer guess the problem.
Prevents over-engineering — the Engineer might "fix" a problem that doesn't exist.

### Claude Plan Mode
Enter plan mode (Shift+Tab+Tab) before complex implementations.
Forces thinking before doing, avoiding rework caused by "thinking while writing."
```

**Pros**:
- Minimalist: just one Markdown file
- Both humans and Agents can read it
- Accumulates naturally, no special mechanisms needed

**Cons**:
- Unstructured: experiences are free text, hard to use programmatically
- No categorization: good and bad experiences are mixed together
- No automation: requires a human (or Agent initiative) to write entries

## 11.3 Paradigm Two: Structured Knowledge Base (Overstory)

### Mulch Knowledge Base

Overstory's Mulch is a structured knowledge accumulation system specifically designed for storing and reusing project knowledge:

```typescript
// Knowledge base client
mulch.client.query({
  domain: "conflict-patterns",     // Conflict patterns
  query: "src/auth merge conflicts",
  format: "json"
});
```

**Types of knowledge stored in Mulch**:

1. **Conflict patterns**: Which files frequently conflict, which merge strategies have historically high failure rates
2. **Failure patterns**: Which types of tasks tend to fail, what the failure reasons are
3. **Project knowledge**: Codebase structure, dependency relationships, common pitfalls

**Application in merging**:

```typescript
// Query historical conflict patterns during merging
const patterns = await mulch.query("conflict-patterns", filePath);
// Skip strategies with historically high failure rates
// Choose strategies with historically high success rates
```

**Application in Overlay injection**:

```typescript
// Inject project-specific knowledge into Agent instructions
const projectKnowledge = await mulch.query("project", projectName);
overlay.render(baseDefinition, projectKnowledge, taskAssignment);
```

**Pros**:
- Structured: can be queried and utilized programmatically
- Persistent: reusable across sessions and Agents
- Forms a positive feedback loop: gets more accurate with use

**Cons**:
- Requires additional infrastructure (Mulch service)
- Knowledge quality depends on input quality
- Cold start problem: new projects have no historical data

## 11.4 Paradigm Three: Semantic Memory (agency-agents-zh)

### MCP Memory Server

agency-agents-zh integrates an MCP (Model Context Protocol) memory server, implementing semantic-level knowledge storage and retrieval:

```
Three core operations:

1. remember(content, tags)
   - Store decisions, deliverables, and context snapshots
   - Tag format: project name + agent name + deliverable type
   - Example: remember("Chose JWT over Session", ["auth", "decision"])

2. recall(query)
   - Search memory by keyword/tag/semantic similarity
   - Subsequent agents use recall to obtain previous agents' outputs
   - Example: recall("auth decision")

3. rollback(checkpoint)
   - Roll back to a known good state
   - On QA failure, the agent can recall previous feedback + rollback to checkpoint
   - No need to manually track version changes
```

**Memory lifecycle**:

```
Agent A completes work
  → remember(deliverable + decisions + context, tags)
  → Tag with: [project name, agent name, deliverable type]

Agent B starts
  → recall(search by tag)
  → Obtain Agent A's output as input

QA fails
  → recall(previous feedback)
  → rollback(to checkpoint)
  → Re-work based on feedback
```

**Pros**:
- Semantic search: not just keyword matching, can understand intent
- Automatic context passing: eliminates manual copy-paste
- Rollback: unique rollback capability

**Cons**:
- Depends on external MCP server
- Semantic search accuracy depends on embedding model
- Memory can become stale (project decisions have changed but old memory remains)

## 11.5 Comparison of the Three Paradigms

| Dimension | Experience Document | Structured Knowledge Base | Semantic Memory |
|------|---------|------------|---------|
| **Storage format** | Free text Markdown | Structured JSON/database | Semantic embeddings + metadata |
| **Query method** | Human reading | Programmatic query | Semantic search |
| **Write method** | Manual/Agent initiative | Automatic collection | Agent initiative remember |
| **Cross-session** | Yes | Yes | Yes |
| **Cross-project** | Difficult | Yes | Yes |
| **Actionability** | Low (read-only) | High (drives decisions) | Medium (provides context) |
| **Implementation cost** | Very low | Medium | High |
| **Cold start** | None | Yes | Yes |

## 11.6 Overlay Injection: The Bridge from Knowledge to Agent

Overstory's Overlay injection mechanism "embeds" knowledge into Agent instructions. This is the "last mile" of knowledge accumulation — having knowledge is not enough; the Agent needs to know about it.

### Three-Layer Overlay

```
Layer 1 (Role-specific HOW): Base Agent definition (.md file)
  Describes role behavior specifications, technical preferences

Layer 2 (Deployment-specific WHAT KIND): Canopy profile
  Project/deployment-specific context, code conventions, tech stack

Layer 3 (Task-specific WHAT): Specific task assignment
  File scope, quality gates, specific constraints
```

```typescript
// Rendering process
function renderOverlay(base: AgentDefinition, profile: ProjectProfile, task: TaskAssignment): string {
  return `
# ${base.name}

## Your Role Specification
${base.instructions}

## Project Context
${profile.codebaseStructure}
${profile.conventions}
${profile.knownPitfalls}  // ← From Mulch knowledge base

## Current Task
${task.description}
${task.fileScope}
${task.qualityGates}
  `;
}
```

**Key Insight**: Overlay injection is the "consumer side" of knowledge accumulation. Knowledge storage (Mulch/LEARNINGS.md/MCP) is the "producer side." Storing without consuming makes knowledge accumulation worthless. The Overlay mechanism ensures that every newly started Agent carries the latest project knowledge.

## 11.7 Implicit Knowledge Accumulation: FEATURES.md

FEATURES.md may seem like just "feature tracking," but it's actually a form of implicit knowledge accumulation — recording "what the project has already implemented":

```markdown
# FEATURES.md

## Implemented
- [x] User authentication (JWT)
- [x] API endpoint /api/v1/auth
- [x] Database migration script

## In Progress
- [ ] User profile editing page
```

**Preventing duplicate development**: The Architect checks FEATURES.md before assigning tasks, avoiding having the executor re-implement existing features. This is the simplest form of knowledge reuse.

## 11.8 Design Principles for Knowledge Accumulation

### Principle One: Storage and Consumption Must Form a Closed Loop

Knowledge only has value when it's used. LEARNINGS.md is simple, but if it's not injected into the Agent's prompt, it's dead knowledge. The Overlay injection mechanism ensures knowledge consumption.

### Principle Two: Structured Beats Free Text

Natural language experience documents are human-readable, but hard for Agents to use programmatically. Structured knowledge bases can be directly consumed by merge strategies, task assignment, risk assessment, and other modules.

### Principle Three: Failures Are More Valuable Than Successes

Knowing "what doesn't work" is more important than "what works." Mulch's conflict patterns and failure records, fast crash timestamps, agency-agents-zh's QA failure feedback — these are all "learning from failure."

### Principle Four: Knowledge Has an Expiration Date

Project decisions change, codebases evolve, dependencies update. Stale knowledge is more dangerous than no knowledge. MCP memory's semantic search can mitigate but not fully solve this problem. Regular cleanup or expiration tagging is needed.

### Principle Five: Start with the Lowest Cost

You don't need to jump straight to Mulch or MCP from the start. Begin with LEARNINGS.md + Overlay injection, and upgrade to a structured knowledge base when experience accumulates to the point where manual management becomes unwieldy.