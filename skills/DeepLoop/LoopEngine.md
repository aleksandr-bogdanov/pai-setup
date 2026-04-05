# LoopEngine — The Core Convergence Algorithm

> Portable algorithm for iterative autonomous code work. Shared by all DeepLoop workflows.

---

## The Algorithm

```
INPUT: domains[], mode (audit|build|investigate|review), config{}
OUTPUT: per-domain results (PRs, reports, or review findings)

FOR each domain (parallel if configured):
  round = 0
  consecutive_clean = 0

  WHILE consecutive_clean < CLEAN_THRESHOLD (default: 3):
    round += 1

    // STEP 1: Arbiter writes prompt
    prompt = arbiter_write_prompt(domain, round, mode, previous_findings)

    // STEP 2: Investigator discovers
    findings = launch_investigator(prompt, domain.files)

    // STEP 3: Arbiter judges EACH finding
    approved = []
    FOR each finding in findings:
      IF arbiter_approves(finding, mode.criteria):
        approved.append(finding)
      ELSE:
        log_rejection(finding, reason)

    // STEP 4: Act on approved findings
    IF approved.length > 0:
      IF mode.has_executor:  // audit, build
        spec = arbiter_write_spec(approved)
        result = launch_executor(spec, domain.files)
        verify(result)  // run checks, tests
        IF mode.creates_prs:
          create_pr(result)
      ELSE:  // investigate, review
        append_to_report(approved, domain)
      consecutive_clean = 0
    ELSE:
      consecutive_clean += 1

    // STEP 5: Evolve prompt for next round
    update_prompt_angles(round, approved, mode)

  // STEP 6: Dead export check (build mode, when user journey defined)
  IF mode == build AND config.has_user_journey:
    verify_all_new_exports_have_import_sites(domain)
    IF orphaned_exports_found:
      consecutive_clean = 0  // domain NOT complete
      // Feed orphaned exports as findings into next round

  domain.status = COMPLETE
  report_domain_completion(domain)
```

---

## Three-Tier Model Allocation

| Role | Model | Thinking | Why |
|------|-------|----------|-----|
| **Arbiter** | Opus (you) | High | Judgment, prompt design, convergence tracking |
| **Investigator** | Opus subagent | High | Deep code reading, multi-step tracing |
| **Executor (isolated)** | Sonnet subagent | Low/Medium | Mechanical implementation from specs |
| **Executor (integration)** | Opus subagent | High | Cross-domain wiring, call graph connections |

**Rule:** If executor work crosses domain boundaries or wires components together, use Opus. Sonnet handles isolated, single-domain implementation only.

**Exception:** If executor work requires architectural decisions, escalate to arbiter. Never let Sonnet make design choices.

---

## Agent Launch Patterns

### Investigator (Opus, read-only)

```
Agent(
    description="[Mode] [Domain] round [N]",
    prompt="[Targeted prompt with angles]",
    subagent_type="Explore",
    model="opus",
    mode="bypassPermissions",
)
```

### Executor (Sonnet, can edit)

```
Agent(
    description="Implement [Domain] round [N] findings",
    prompt="[Approved findings + implementation specs]",
    subagent_type="Engineer",
    model="sonnet",
    mode="bypassPermissions",
)
```

Use `isolation="worktree"` for large changes (e.g., test files). Copy changed files back after completion.

---

## Prompt Design

### Template

```
Read [FILES].
[Previous rounds summary: what was already found/fixed].

STRICT RULES:
- Output ONLY findings requiring [ACTION]
- Finding MUST be: [CRITERIA]
- NOT: [ANTI-CRITERIA]
- If ZERO findings, say "ROUND N: CLEAN"

Check these specific angles:
1. [Specific, traceable, falsifiable angle]
2. ...
6. ...

Output as table: Finding | Severity | Lines | Evidence
```

Each angle must be **specific** ("Does `get_schedule` handle `date_to` before `date_from`?"), **traceable** (points to code paths), and **falsifiable** (YES/NO answer).

### Evolving Angles

| Round | Focus |
|-------|-------|
| 1 | Big picture — obvious issues, parity gaps |
| 2-3 | Side effects, lifecycle, validation |
| 4-5 | Edge cases, error messages, type safety |
| 6+ | Adversarial — try to break what was built |

---

## Convergence

| Mode | Clean Threshold | Exit Condition |
|------|----------------|----------------|
| Audit | 3 clean rounds | Both code + test loops exit |
| Build | N/A | Feature complete + wiring gate passes + tests pass |
| Investigate | 2 clean rounds | Report comprehensive |
| Review | 2 clean rounds | No real concerns remain |

**Dead Export Check (build mode, when user journey defined):** After a domain completes, verify every new export has at least one import site, every new component is rendered somewhere, every new store value is read somewhere. If orphans exist, the domain is NOT complete — feed them back as findings. For standalone component builds (no user journey), exports consumed by other new files in the PR count as wired.

**False Negative Detection:** If round 1 returns 0 findings on a domain with few tests and many lines, the prompt was probably bad. Rewrite with sharper angles before counting as clean.

---

## Domain Decomposition

The arbiter decomposes the target into domains by:
1. Listing all source files in scope
2. Grouping by business capability (not file type)
3. Estimating lines + test count per domain
4. Prioritizing by: `size * (1 / test_ratio) * risk_weight`
5. Grouping into batches of 3-4 for parallel execution

Workflows can also accept a pre-defined domain map from the user.

---

## Cross-Chat State

If the loop spans multiple sessions, save to project memory on exit:
- Which domains are DONE / IN PROGRESS (round number, clean count)
- Current version and test count

On resume: read LoopEngine, ArbiterFramework, and project memory, then continue.

---

## Reporting

After each domain:
```
Domain: [name] — COMPLETE
  Rounds: [N] (X findings across Y rounds)
  Changes: [summary]
  PRs: #AAA, #BBB (if applicable)
```

After each batch:
```
[Mode] Batch [N] Complete
  [domain 1]: [1-line summary]
  Total: X findings, Y fixes, Z tests added
```
