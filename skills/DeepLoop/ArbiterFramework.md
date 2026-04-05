# ArbiterFramework — Judgment Criteria

> How the arbiter decides APPROVE vs REJECT for each finding.

---

## Universal Rejection Signals (All Modes)

| Signal | Example |
|--------|---------|
| **Invented consistency requirement** | "All tools should have encryption check" |
| **Redundant pattern testing** | "Need 13 more multitenancy tests" — 3 prove the pattern |
| **Defensive measure framed as bug** | Query length limits, past date validation |
| **Agent filling space** | Vague finding, no line numbers or crash scenario |
| **Performance/style/speculative** | Naming, import order, "if someone later changes X" |

---

## Mode: Audit

**APPROVE:** Code crashes on valid input, returns wrong results, leaks data, misses side effects, accepts invalid data, or has a test gap that catches a real regression.

**REJECT:** "Inconsistent with X" when both paths allow the same thing (design choice). Missing test for a pattern already proven by 3+ existing tests.

**Grey area (arbiter judgment):** Missing test for recently added code, docstring lies an AI agent would act on, batch silently differs from single.

---

## Mode: Build

**APPROVE:** Spec item not yet implemented, implementation diverges from spec, missing validation on new inputs, missing tests for new code, integration gap, **new export with zero import sites** (wiring hole).

**REJECT:** Scope creep, over-engineering, premature optimization.

---

## Mode: Investigate

**APPROVE:** Real, verifiable finding with specific file/line and practical impact. Clear what to fix.

**REJECT:** Theoretical risk only, already documented limitation, requires architectural rewrite.

---

## Mode: Review

**APPROVE:** Correctness bug, security issue, contract violation, missing error handling at system boundaries.

**REJECT:** Stylistic preference, hypothetical edge case callers never trigger, nits.

---

## Arbiter Anti-Patterns

1. **Rubber-stamping** — Approving everything. Your job is to filter.
2. **Over-filtering** — Rejecting real bugs because they're "minor."
3. **Anchoring on round 1** — Don't let early findings bias later rounds.
4. **Counting wrong** — Clean = arbiter-approved clean, not investigator-reported.
5. **Letting executor design** — Sonnet implements specs, it doesn't design.

---

## Escalation to User

Escalate (don't decide autonomously) when:
- Finding requires database migration or breaking API change
- Executor fails >2 times on same fix
- Finding touches security-critical auth flow
- Architectural decision not covered by existing patterns
