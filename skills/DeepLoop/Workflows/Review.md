# Review Workflow — Convergent Code Review

> Multi-round review with arbiter-filtered findings. Deeper than single-pass.

---

## Prerequisites

1. **Read** `LoopEngine.md` and `ArbiterFramework.md` (Mode: Review)
2. **Identify target** — branch, PR, specific files, or module

---

## Step 1: Identify Scope

| User says | Scope |
|-----------|-------|
| "review PR #123" | `gh pr diff [number]` |
| "review the calendar module" | All files in module |
| "review this branch" | `git diff [base]...[branch] --name-only` |

---

## Step 2: Review Loop

2 consecutive clean rounds to exit.

```
Run LoopEngine(mode=review, clean_threshold=2)
// Each round: investigator reviews with angles,
// arbiter filters, approved findings accumulate
```

**Investigator prompt pattern:**
```
Read [FILES].
Review round [N]. [Previous: summary].

STRICT RULES:
- ONLY: correctness bugs, security issues, contract violations, missing error handling at boundaries
- NOT: style, nits, hypothetical edge cases
- If ZERO: "ROUND N: CLEAN"

Angles:
1. Does code do what it claims? (docs vs behavior)
2. Logic errors? (off-by-one, wrong comparison)
3. Security? (injection, auth bypass, data exposure)
4. Error handling at system boundaries?
5. Breaks existing contracts? (return types, side effects)
6. Race conditions or state issues?

Output as table: Finding | Severity | File:Line | Evidence | Suggested Fix
```

---

## Step 3: Review Report

```markdown
## Code Review: [target]
> Rounds: [N] | Findings: [count] | Files: [count]

### Critical ([count])
- **[Finding]** — `file:line` — [evidence + suggested fix]

### High / Medium ...

### Summary
[2-3 sentences: quality assessment, key concerns]
```

---

## Step 4: Optional — Apply Fixes

If user says "fix them": switch to executor pattern, write specs per finding, launch Sonnet, create PR.

---

## Autonomy Level

- **Fully autonomous for review** — no code changes, safe to run
- **Ask before applying fixes**
