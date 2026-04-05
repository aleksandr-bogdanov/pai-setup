# Audit Workflow — Find and Fix All Bugs

> Autonomous bug hunting: code audit loop → test audit loop → simplify.

---

## Prerequisites

1. **Read** `LoopEngine.md` and `ArbiterFramework.md` (Mode: Audit)
2. **Identify project commands** — adapt check/test/lint to current project

---

## Step 1: Domain Decomposition

If user specifies domains, use those. Otherwise, auto-decompose per LoopEngine.md.

**Output to user:**
```
Domain Map:
  1. [Domain] — [N] files, ~[M] lines, [X] tests, [RISK] risk
  2. ...

Batch 1: [domains 1-3]
Batch 2: [domains 4-6]

Proceed with Batch 1?
```

**Wait for user confirmation.**

---

## Step 2: Code Audit Loop

Run the LoopEngine convergence loop for each domain. 3 consecutive arbiter-approved clean rounds to exit.

**Arbiter prompt pattern:**
```
Read [IMPL FILES].
[Previous rounds: what was fixed].

STRICT RULES:
- ONLY findings requiring CODE CHANGES
- MUST be: WRONG, CRASHES on valid input, LEAKS data, or MISSES side effects
- NOT: style, perf, docs, defensive measures
- If ZERO: "ROUND N: CLEAN"

Angles:
1-6. [Domain-specific, round-appropriate angles]

Output as table: Finding | Severity | Lines | Evidence
```

Each round with fixes gets its own PR. Follow project's PR conventions.

---

## Step 3: Test Audit Loop

After code loop exits, run test audit with same convergence (3 clean rounds):

```
Read [TEST FILES] and [IMPL FILES].

STRICT RULES:
- ONLY missing tests that catch REAL BUGS
- NOT: redundant pattern tests, style
- If ZERO: "ROUND N: CLEAN"

Check: all functions tested, error paths tested, assertions correct.
```

---

## Step 4: Post-Audit Polish

After both loops exit, run `/simplify` on cumulative diff (duplicated helpers, import cleanup, type annotations).

---

## Parallel Execution (Overnight)

Partition domains into groups, launch each as background agent with full context per SKILL.md parallel pattern. ~650K tokens per domain budget.

---

## Autonomy Level

- **Fully autonomous within a domain** — audit, fix, PR, merge
- **Report between batches** — summary + ask to proceed
- **Escalate if:** executor fails >2 times, migration needed, architectural decision
