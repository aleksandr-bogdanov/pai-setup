# Investigate Workflow — Deep Dive Reports (No Code Changes)

> Discover issues, rank by severity, produce actionable reports. NO code changes.

---

## Prerequisites

1. **Read** `LoopEngine.md` and `ArbiterFramework.md` (Mode: Investigate)
2. **Get investigation axes** from user (e.g., "security, test coverage, dead code")

---

## Step 1: Define Axes and Domains

Each axis is an independent investigation focus. User defines them or arbiter proposes based on the codebase. Auto-decompose each axis into domains per LoopEngine.md.

---

## Step 2: Investigation Loop

No executor — the loop only discovers and reports. 2 consecutive clean rounds to exit (lighter bar).

```
FOR each axis (parallel if overnight):
  FOR each domain:
    findings = []
    Run LoopEngine(mode=investigate, clean_threshold=2)
    // Each round: investigator reads with axis-specific angles,
    // arbiter filters, approved findings accumulate
```

**Investigator prompt pattern:**
```
Read [FILES].
Axis: [NAME]. Round [N]. [Previous: summary].

STRICT RULES:
- REAL, VERIFIABLE, ACTIONABLE findings only
- Each: specific file, line, evidence
- NOT: theoretical risks, documented limitations
- If ZERO: "ROUND N: CLEAN"

Angles: 1-6. [Axis-specific for this domain]

Output as table: Finding | Severity (P0-P3) | File:Line | Evidence | Suggested Fix
```

**Severity:** P0 = data loss/security/crash. P1 = wrong results/edge case leak. P2 = inconsistency/missing validation. P3 = dead code/minor.

---

## Step 3: Report Generation

Save to `docs/investigations/[date]-[axis-name].md`:

```markdown
# [Axis] Investigation Report
> Generated: [date] | Domains: [N] | Rounds: [total] | Findings: [count]

## Executive Summary
[2-3 sentences]

## Findings by Severity
### P0 — Critical ([count])
| # | Domain | Finding | File:Line | Evidence |
### P1-P3 ...

## Suggested Action Plan
1. [Highest priority action]
...
```

---

## Parallel Execution (Overnight)

Each axis gets its own background agent per SKILL.md parallel pattern. ~300K tokens per axis. Reports written to `docs/investigations/`.

---

## Autonomy Level

- **Fully autonomous** — no code changes, safe to run without asking
- **User decides** what to fix from the reports
