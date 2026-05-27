# Workflow: ParallelFleet

**Trigger phrases**: "deep loop in worktrees", "parallel agent fleet", "spawn parallel deep-loop", "worktree fleet", "overnight parallel build", "fleet of agents".

## When to use

Use this workflow when you have:
- A backlog of independent fixes/tasks (typically 5–15 items grouped into 3–8 families)
- Each family is small enough to land as one PR
- Families don't have hard dependencies on each other
- Goal is parallel throughput, not depth on a single problem

This is the *parallelization layer* over Build/Audit. Each agent in the fleet runs Build (or Audit) inside its own worktree.

## Architecture

One arbiter (you, the main session) orchestrates N parallel agents. Each agent:
1. Carves its own `git worktree` from a clean main branch (e.g., `master`)
2. Runs the per-family Build/Audit workflow inside that worktree
3. Produces ONE pull request when done
4. Reports back to arbiter with PR URL + closed task IDs + surprises

Arbiter:
- Issues structured prompts to each agent
- Holds output (no per-agent narration)
- Resolves blocking decisions when an agent surfaces them
- Reconciles cross-agent findings (e.g., two agents independently identifying the same bug)
- Produces ONE consolidated final report at the end

## Working norms — the seven invariants

These are the load-bearing rules. Skipping any of them has caused real failures.

### 1. Worktree-first (mandatory)

Every agent MUST carve its own worktree before any edit. Shared CWD across parallel agents causes branch-switch clobbering — proven 2026-04-21. Pattern:

```bash
cd $REPO_ROOT
git worktree add -b $BRANCH_NAME $REPO_ROOT/.claude/worktrees/$WORKTREE_NAME
cd $REPO_ROOT/.claude/worktrees/$WORKTREE_NAME
```

The `.claude/worktrees/` directory is project-local convention; any path under the repo works as long as worktrees are isolated.

### 2. Symlink shared dependencies (avoid disk pressure)

Parallel `npm ci` / `pip install` against fresh worktrees hits ENOSPC on macOS (proven 2026-04-25). Symlink heavy dependency dirs from the main repo:

```bash
ln -s $REPO_ROOT/frontend/node_modules frontend/node_modules
# or for Python:
ln -s $REPO_ROOT/.venv .venv
```

Caveat: only symlink dirs that don't get mutated by build steps. `node_modules` is read-mostly; `dist/` is not.

**Lockfile-staleness gotcha (added 2026-04-30):** when a recently-merged PR changed `frontend/package-lock.json` (or equivalent), the main repo's `node_modules` is stale relative to the new lockfile. Worktrees that symlink will inherit the stale state and fail with phantom missing-dep errors. **Before spawning the next fleet, the orchestrator must run `cd $REPO_ROOT/frontend && npm install` to sync `node_modules` with the post-merge lockfile.** Otherwise the next wave's agents waste cycles diagnosing a non-issue and may file false-positive findings (proven 2026-04-29 — three Wave-2 agents flagged a "vitest-axe missing" gap that was actually transient stale-symlink lag).

### 3. Verify-before-edit (MCP / task-description decay)

Task descriptions filed days/weeks ago become point-in-time fossils. File:line citations drift, fixes ship in unrelated PRs, descriptions describe "broken" code that's already been corrected. Decay rate observed: 30–50% on multi-week-old cards.

Every agent must verify each citation against current code before applying any fix. If the cited bug no longer exists, mark the card resolved-by-other-PR and move on. Don't blindly edit based on stale descriptions.

### 4. FAIL-then-PASS verification (no silent-PASS tests)

For every fix that has user-visible behavior:
1. Write the test
2. Stash the fix → run test → confirm FAILS
3. Restore the fix → run test → confirm PASSES

If the test passes both with and without the fix, the test isn't catching anything — it's noise. Skip stash step only on pure logic / pure data transformations where green-in-isolation provably equals green-in-suite.

### 5. Sweep-anti-pattern grep

When fixing one instance of a bad pattern, grep the whole file (or whole codebase) for the same pattern before opening the PR. The audit's count of "N occurrences" is usually a floor, not a ceiling. Real-world: a "13 sites" audit expanded to 26 once the agent grepped properly.

### 6. Fix side-findings in the same PR (within authorization)

If an agent uncovers a pre-existing CI failure (lint violation, type error, broken test) while working in its worktree, it should fix the side-finding in the same PR rather than:
- Opening a separate chore PR (more noise)
- Stopping to ask (slows the fleet)

The exception: if the side-finding is large, architectural, or contentious, file it as a follow-up MCP task and proceed without fixing.

### 7. Hold output until the batch lands

Arbiter does NOT narrate per-agent completions. Each `task-notification` is a private signal — arbiter updates its internal task tracker, processes inter-agent coordination (e.g., notifying overlapping agents), and stays silent toward the user. The ONLY user-facing output during the run is:

- Initial dispatch summary (1 message)
- Blocking-decision questions surfaced by an agent (only if truly blocking)
- Final consolidated report when all agents complete (1 message)

Per-agent narration is unreadable noise on overnight runs.

## Patterns that pay off (collect these)

### Chokepoints over cite-by-cite

When fixing a sweep-anti-pattern, prefer refactoring the buggy logic into a single chokepoint function and routing all call sites through it, over patching each call site separately. The next sweep miss becomes structurally impossible.

Example: `_stamp_monthly_anchor_day(rule, date_str)` instead of patching `/parse` and `/autofill` separately.

### Planning-gate stops (encourage senior pushback)

Agents should pause and surface scope tradeoffs *before* executing if the brief is mismatched to the actual code. The arbiter's response to a planning-gate stop should be: read the agent's analysis, make the call, send them back. NEVER punish a stop. NEVER force-execute over an agent's reasoned objection.

This is the difference between feature-grade and fix-grade work. A feature-grade item dressed as a fix will violate quality rules ("no parallel systems duplicate responsibility") if pushed through.

### Audit-of-audit (highest-leverage overnight pattern)

The most valuable parallel agent in any fleet is one that re-audits the recent fix-PRs of OTHER agents (or prior PRs from the same week). Sweep-anti-pattern misses are the most common shipping defect; an audit-of-audit catches them at the expected ~1/6 rate. Always include one.

### Independent triangulation

When two parallel agents identify the same bug from different evidence (one by file:line citation, one by Sentry trace, etc.), confidence in the fix should rise sharply. Surface the triangulation to the arbiter as positive signal.

### Tripwire tests vs. real fixes

If an agent CAN'T fully fix a bug in its scope (needs a schema migration, cross-system coordination, etc.), the right move is:
1. Write a test that pins the CURRENT broken behavior
2. Document it as a tripwire (test name + comment)
3. Leave the MCP card OPEN with a status note pointing to the tripwire test
4. Do NOT close the card — the user-visible bug is unfixed

The tripwire alerts whoever fixes it later that the test must be inverted at the same time.

## Common failure modes

### Cosmetic git failures

`gh pr merge --delete-branch` returns exit code 1 if a worktree still references the branch — but the server-side merge succeeded. Always re-check `gh pr view N --json state` before retrying. Don't blindly retry — you'll get "Base branch was modified" races that ARE real failures.

### Parallel-merge races

If you fire 8 `gh pr merge` calls simultaneously, the first wins; the rest get "Base branch was modified" because master moved under them. Solution: serialize the retry pass after the first parallel pass. Don't try to do it all in one parallel batch.

### Stale openapi.json on shared dev port

If multiple sessions run dev servers on the same port (e.g., uvicorn :8000), `npx orval` may fetch a stale spec from someone else's instance. Always `lsof -i :8000` before regenerating types — verify the responding server is yours.

### Parallel-CI-trigger noise

If push triggers CI, 8 parallel pushes = 8 simultaneous CI runs = wasted compute + flaky inter-run interactions. Prefer projects where CI is manual / cron-driven on the dev branch (with auto-CI on the production-gate branch). Parallel fleets work much better against manual-CI master.

## Dispatch template

For each family:

```
TASK: [Family name] — N items in ONE PR.

REPO: $REPO_ROOT

WORKTREE FIRST:
  cd $REPO_ROOT
  git worktree add -b $BRANCH_NAME .claude/worktrees/$WORKTREE_NAME
  cd .claude/worktrees/$WORKTREE_NAME
  ln -s $REPO_ROOT/frontend/node_modules frontend/node_modules

TASK IDS (verify each citation before editing):
- [list]

WORKFLOW: Read DeepLoop SKILL.md + Workflows/Build.md. Apply FAIL-then-PASS, sweep-anti-pattern grep, side-finding fixes in this PR.

LOCAL CI GATE (must pass before PR):
  [project-specific commands]

PR target main/master, conventional commit, body explains WHY. No version-file or release-notes edits.

REPORT BACK: PR URL, task IDs closed, surprises.
```

## Related workflows

- `Build.md` — what each fleet agent runs internally for code-fix families
- `Audit.md` — what an audit-of-audit agent runs (5-lens framework)
- `Investigate.md` — for read-only deep dives (no PR output)
