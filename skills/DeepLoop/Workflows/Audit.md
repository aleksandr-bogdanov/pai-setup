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

## Step 2.5: Audit Lenses (Mandatory Mental Model)

A thorough audit is a multi-lens review, not a checklist. Apply each lens consciously; not all lenses apply to every fix, but the auditor MUST explicitly consider each before concluding CLEAN. When a lens does not apply, say so and why ("Lens 4 N/A — backend-only fix, no user-facing surface"). That forces the conscious consideration the gate exists to require.

### Lens 1 — Correctness
Code does what the fix description claims. File:line citations match. Logic sound (no off-by-one, no silent fallthrough, no missing null checks at boundaries). Architectural invariants preserved (multitenancy, encryption, transactions, atomicity).

### Lens 2 — Sweep / regression scope
Other instances of the same pattern. Adjacent files, sibling consumers, related code paths the fix doesn't reach. When fixing one instance of a bad pattern, grep the whole codebase before declaring done.

### Lens 3 — Test quality
Do the tests actually verify the fix, or pass for unrelated reasons?
- Tests exercise the FIX, not a tangent that happens to share the code path
- Untested scenarios that should be tested are flagged
- For UI: test mounts the same parent context production uses (Drawer, Dialog, sheet, popover, provider). If the parent attaches native DOM listeners (e.g. `keydown` with `{ capture: true }`), the test replicates that listener config
- For state-restoration / lifecycle fixes: tests simulate production lifecycle (re-renders from mutations, async state transitions, query invalidations)
- For data fixes: tests cover edge values (0, null, empty, very large, unicode, RTL)

**Behavioral verification (apply when test quality has plausible doubt).** Stash the fix locally, run the test against pre-fix code, confirm it FAILS for the right reason. Restore the fix; confirm it PASSES. A test that always passes regardless of the fix is not verifying the fix.

This is the gold standard for behaviorally-sensitive fixes (UI event handling, state restoration after async operations, fixes depending on parent component context). It does NOT need to apply to every audit — pure logic, backend service code, and mathematical transformations have test/production environments that don't differ in ways that matter.

The judgment call: when does behavioral verification apply? Apply when the answer to "could this test pass while production is broken?" is plausibly yes.

### Lens 4 — UX correctness
For any fix touching a user-facing surface:
- Did the fix break a previously-working flow as a side effect?
- New behavior consistent with how similar elements work elsewhere in the app?
- Any scenario where the new behavior is surprising or wrong?
- Read the diff with a "user clicking around" lens — would you notice anything off?
- Copy / tone matches product voice
- Interaction matches user expectations from comparable apps

Not applicable to backend-only fixes or infrastructure changes — say so and skip.

### Lens 5 — Use case completeness
**More important than bugs.** What scenarios should the fix cover that it might not?
- Edge cases: slow networks, error states, partial completions, concurrent operations, timeouts
- Adjacent surfaces: sibling components affected by the same gap
- Related flows: error / cancel / timeout paths beyond the happy path
- Locale and accessibility: i18n parity, screen readers, keyboard-only nav, RTL, prefers-reduced-motion
- Roles and tiers: Free vs Pro vs lifetime, demo mode, passkey vs passphrase unlock
- Devices and contexts: web, iOS PWA, Tauri native, mobile vs desktop, with/without service worker

### Conclusion gate
An audit can only conclude CLEAN if EVERY applicable lens was consciously considered and produced no findings. Each finding gets a severity (P0–P3) and a fix-or-defer decision. Lenses that don't apply to a given fix get an explicit "N/A — reason" line in the report.

### What this gate is NOT
- NOT "always behaviorally-verify every fix" — that creates false positives on logic-only fixes
- NOT a Playwright requirement — vitest with proper test harness is the substitute
- NOT a mandate that EVERY lens find something — many audits should legitimately conclude CLEAN. The mandate is conscious consideration, not finding-creation
- NOT a substitute for code-shape audits. Both are required.

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

## Step 5: Finding Closure Gate (MANDATORY)

**The audit-leaves-follow-ups failure mode.** Every prior deep audit cycle has produced findings that the main fix didn't address — these get marked "follow-up PR" / "by design" / "engineer says no work needed" and **then never ship**. The audit is not complete until every finding has a terminal state with evidence. No exceptions.

### Terminal states for every finding

Each finding from the audit must end in exactly ONE of:

1. **FIXED** — code change shipped in a PR. Link the PR. Show the file:line that closes it.
2. **CLOSED-WITH-EVIDENCE** — verified inapplicable. **Requires positive proof** — a grep result showing the suspected path doesn't exist, a test run showing the suspected behavior doesn't manifest, a backend route handler showing the data is actually placeholder/plaintext not ciphertext. **"The engineer agent said it's fine"** is NOT evidence. **"By design"** is NOT evidence without a constitutional principle link or a prior decision doc cited inline.
3. **DEFERRED-WITH-TASK** — explicit decision NOT to ship in this audit cycle. Requires (a) one-sentence reason that survives next-week scrutiny, (b) a Whenful task created via `mcp__whenful__create_task` with the deferral context in the description, (c) task ID surfaced in the closure report. "Latent — wire when first caller appears" is a valid reason ONLY if (b) and (c) are also satisfied. Without a tracked task, the deferral is fiction.

### Closure report format (mandatory)

The audit's final user-facing report MUST include this table. No exceptions. If an audit ends without this table, it's incomplete and the user is owed the missing closure work right then, not in a future session.

| # | Finding (one line) | Severity | State | Evidence / PR / Task ID |
|---|---|---|---|---|
| 1 | Anytime instance pills show ciphertext | P0 | FIXED | PR #1646 — closed via mutator decryption (cache plaintext) |
| 2 | Activity feed leaks task titles | P0 | FIXED | PR #1646 — same architectural fix |
| 3 | `/api/v1/instances/past` ships encrypted aggregates | P3 | DEFERRED-WITH-TASK | Whenful #14872 — MCP-only today, no frontend caller |
| ... | ... | ... | ... | ... |

### Specific anti-patterns to refuse

- "Findings 9, 10 — engineer claims backend serves placeholders, no work needed" → **REJECTED.** Verify yourself with grep + Read the backend handler. State the evidence inline.
- "Finding 11 — functionally fixed transitively because cache holds plaintext now" → **REJECTED unless verified end-to-end.** Read the actual call chain that consumes the cached data and confirm plaintext flows through to the suspected exit point.
- "Latent — flag for follow-up" without a created Whenful task → **REJECTED.** Create the task in the same turn or fix it now.
- "Audit findings NOT shipped in this PR (potential follow-ups):" as a section heading in the final report → **REJECTED.** Every finding goes in the closure table with a terminal state, OR it gets fixed before the report.
- "Could be a separate PR" → either open the PR in the same turn, or convert to DEFERRED-WITH-TASK with a tracked task.

### Why this gate exists

Across multiple Whenful audit cycles (PR #1330, #1456-#1476, #1646, the Bucket E recurrence v2 audit) the pattern has repeated: the main architectural fix lands, audit findings get split into "covered transitively" + "by design" + "follow-up." The transitively-covered claims are sometimes wrong (the audit agent and the engineer agent disagreed in PR #1646 about analytics ciphertext — neither was verified before the audit closed). The follow-ups never ship because no task ever gets created.

The gate eliminates the failure mode by refusing audit closure without enumerated terminal states + verification evidence + tracked tasks for anything deferred.

### Conclusion gate (updated)

An audit can only conclude COMPLETE when:
1. Every applicable lens (Step 2.5) was consciously considered
2. Every finding has a terminal state with evidence (Step 5)
3. The closure table is in the final user-facing report
4. Any DEFERRED-WITH-TASK entries have actual Whenful task IDs, not promises

If any of those conditions fail, the audit is incomplete and the work to satisfy them happens in the same turn, not later.

---

## Parallel Execution (Overnight)

Partition domains into groups, launch each as background agent with full context per SKILL.md parallel pattern. ~650K tokens per domain budget.

---

## Autonomy Level

- **Fully autonomous within a domain** — audit, fix, PR, merge
- **Report between batches** — summary + ask to proceed
- **Escalate if:** executor fails >2 times, migration needed, architectural decision
