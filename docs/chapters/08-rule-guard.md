# Rule Guard: The Enforcement Layer of Hard Constraints

> The final piece of hard orchestration: not just keeping agents running, but ensuring they follow the rules. Iron rules in prompts are soft — agents can delete them; rule guards are hard — agents cannot modify orchestrator scripts.

## 8.1 Why Rule Guards Are Needed

AI Agents have a fatal characteristic: **they modify their own constraints**.

When you write a rule "do not delete files" for an Agent, when facing obstacles, the Agent might:

1. Simply delete the rule
2. Reinterpret the rule so it no longer applies
3. Find a way to bypass the rule

This is not theoretical — it happens repeatedly in practice. The solution is a **dual defense line**:

```
Defense Line 1 (Soft): Prompt iron rules — for the Agent to read, expecting compliance
Defense Line 2 (Hard): Rule guard scripts — executed by the orchestrator, Agent cannot modify
```

**Core distinction**: Prompt iron rules belong to soft orchestration (Ch9); rule guards belong to hard orchestration — they are deterministic scripts that don't depend on the Agent's "self-discipline."

## 8.2 The Double Iron Law Block Mechanism

### Design Principle

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

**Why it works**: Agents typically only modify part of the prompt. Top declaration + bottom confirmation creates double insurance. Even if the Agent deletes the top, the bottom confirmation block still exists.

**Why it's not enough**: If the Agent completely rewrites the prompt file, neither block survives. This is where hard enforcement comes in.

## 8.3 External Guard Scripts

### Basic Pattern: Periodic Inspection + Auto-Recovery

```bash
# rule_guard.sh — The orchestrator's rule guard script
# Checks prompt file integrity every 5 minutes

PROMPT_FILE="agent_prompt.txt"
IRON_LAW_START="════════════════════════════════════════"
IRON_LAW_MARKER="CORE RULE BLOCK — Iron Law (Non-deletable)"

rule_guard() {
    # Check if iron law marker exists
    if ! grep -q "$IRON_LAW_MARKER" "$PROMPT_FILE"; then
        echo "[RULE GUARD] Iron law deleted, restoring from git..."
        git checkout "$PROMPT_FILE"
        # Notify Agent
        send_message "⚠️ Iron law was deleted and auto-restored. Do not modify core rule blocks."
    fi
    
    # Check iron law block count (should be 2: top + bottom)
    block_count=$(grep -c "$IRON_LAW_START" "$PROMPT_FILE")
    if [ "$block_count" -lt 2 ]; then
        echo "[RULE GUARD] Iron law blocks incomplete (expected 2, got ${block_count}), restoring..."
        git checkout "$PROMPT_FILE"
        send_message "⚠️ Iron law blocks incomplete, auto-restored."
    fi
}

# Main loop
while true; do
    rule_guard
    sleep 300  # Inspect every 5 minutes
done
```

**Key design**: This script is part of the orchestrator, not the Agent — the Agent cannot modify orchestrator code.

### Advanced Pattern: Content Integrity Check

```bash
# Not just check if markers exist, but verify iron law content hasn't been tampered with
rule_integrity_check() {
    # Calculate hash of iron law blocks
    current_hash=$(sed -n '/CORE RULE BLOCK — Iron Law/,/CORE RULE BLOCK (END)/p' "$PROMPT_FILE" | md5sum)
    expected_hash="a1b2c3d4e5f6..."  # Pre-computed hash
    
    if [ "$current_hash" != "$expected_hash" ]; then
        echo "[RULE GUARD] Iron law content tampered, restoring..."
        git checkout "$PROMPT_FILE"
        send_message "⚠️ Iron law content was modified, auto-restored."
    fi
}
```

## 8.4 The Hierarchy of Rule Guards

```
┌──────────────────────────────────────────┐
│  Level 3: Content hash verification      │  ← Strictest: detects any content tampering
│  (Detects any text changes in iron laws) │
├──────────────────────────────────────────┤
│  Level 2: Structural integrity check     │  ← Medium: checks if blocks exist and count is correct
│  (Checks marker presence + block count)  │
├──────────────────────────────────────────┤
│  Level 1: File existence check           │  ← Basic: is the file still there
│  (Checks if prompt file exists)          │
└──────────────────────────────────────────┘
```

**Selection guide**:

| Scenario | Recommended Level | Reason |
|----------|------------------|--------|
| Low-risk projects (experimental) | Level 1 | Low maintenance cost, covers basic scenarios |
| Medium-risk projects | Level 2 | Balances security and maintenance cost |
| High-risk projects (production) | Level 3 | Maximum protection against rule bypass |

## 8.5 Relationship Between Rule Guards and Prompt Iron Laws

This is key to understanding the boundary between hard and soft orchestration:

| Dimension | Prompt Iron Laws (Soft Orchestration, Ch9) | Rule Guards (Hard Orchestration, this chapter) |
|-----------|-------------------------------------------|------------------------------------------------|
| Executor | Agent itself | Orchestrator script |
| Mechanism | "Please follow these rules" | "I will check if you follow them" |
| Bypassability | Agent can ignore or delete | Agent cannot modify orchestrator code |
| Recovery | None (once deleted, it's gone) | Auto-restore from git |
| Use case | Behavior guidance, preference settings | Safety底线, non-negotiable constraints |

**One-sentence summary**: Prompt iron laws tell the Agent "what you should do"; rule guards ensure "what you absolutely cannot do."

## 8.6 Practical Pattern Summary

```
Complete rule guard system:

  Agent's Prompt (Soft)
  ┌────────────────────┐
  │ ══Iron Law (Top)══ │ ← Agent reads these rules
  │ ...other content... │
  │ ══Iron Law (Bot)══ │ ← Double insurance
  └────────────────────┘
         ↕ Agent may modify
  Orchestrator's Guard Script (Hard)
  ┌────────────────────┐
  │ rule_guard()       │ ← Orchestrator checks periodically
  │ rule_integrity()   │ ← Checks if content was tampered
  │ git checkout restore│ ← Auto-restores if deleted
  └────────────────────┘
         ↕ Agent cannot modify
```

Iron laws + guard scripts, soft and hard combined, form a complete constraint system.
