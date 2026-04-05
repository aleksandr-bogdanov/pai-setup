# Build Workflow — Implement Features with Convergence

> Decompose → spec → implement → wiring gate → PR.

---

## Prerequisites

1. **Read** `LoopEngine.md` and `ArbiterFramework.md` (Mode: Build)
2. **Get feature description** from user (what to build, acceptance criteria, constraints)

---

## Step 1: Feature Decomposition

The arbiter breaks the feature into domains:

1. **Understand the feature** — what it does, who uses it, how it integrates
2. **Identify affected areas** — files, modules, layers
3. **Create implementation domains** — each independently implementable
4. **Define ordering** — dependencies between domains
5. **Define acceptance criteria per domain**
6. **Define at least one user journey** — a concrete path from entry point (user action / API call) through every domain to exit point (visible result). This journey becomes the integration test.

**Output to user:**
```
Feature: [name]

User Journey: [entry point] → [domain A] → [domain B] → ... → [exit point]

Domains:
  1. [Domain] — [files] — depends on: [none / domain N]
  2. ...

Acceptance Criteria:
  - [criterion 1]
  - ...

Proceed?
```

**Wait for user confirmation.**

---

## Step 2: Implementation Loop (per domain)

Build converges on "feature complete," not "no bugs found."

```
FOR each domain (in dependency order):
  round = 0

  WHILE NOT domain_complete:
    round += 1

    // Arbiter writes spec (round 1: initial, round 2+: refined from feedback)
    spec = write_spec(domain, round, previous_feedback)

    // Investigator reads current code + spec, identifies gaps
    gaps = launch_investigator(spec, domain.files)

    // Arbiter filters gaps
    approved_work = arbiter_filter(gaps, mode="build")

    // Executor implements approved work
    IF approved_work:
      result = launch_executor(approved_work, domain.files)
      verify(result)

    // Investigator reviews implementation
    issues = launch_investigator(review_prompt, domain.files)
    issues = arbiter_filter(issues, mode="build")

    IF issues.length == 0 AND acceptance_criteria_met(domain):
      domain_complete = true
```

**Key difference from Audit:** No "3 clean rounds" exit. The loop exits when acceptance criteria are met. The spec evolves each round. The investigator both discovers what to build and reviews what was built.

**Arbiter prompts:** Send FILE PATHS to subagents, not inline specs. The investigator/executor reads the plan document and affected files directly. Keep prompts under 500 words.

---

## Step 3: Wiring Gate

After all domains are implemented, before PR creation, run this gate. **Scope adapts to the deliverable:**

- **Full feature** (user journey defined in Step 1): run all 4 checks.
- **Standalone components** (no user journey — e.g., "build the plugin, integration comes later"): run checks 1 and 3 only (internal consistency). Exports consumed by *other new files in this PR* count as wired. Exports intentionally left for future integration are fine — the arbiter notes them in the PR description as "awaiting integration."

**Launch an Opus investigator:**

1. **Export audit:** Every new export must have at least one import site — either within this PR's files or in existing code.
2. **User journey trace** (when journey defined): Walk entry → exit. At each boundary, verify the call/render exists in code, not just "planned."
3. **Settings contract:** Every new setting must have both a writer (UI/API) AND a reader (runtime code). If you're building settings UI without the runtime consumer, defer creating the setting until the consumer exists.
4. **Dead code sweep** (when journey defined): Any new file not imported anywhere is a wiring failure.

Gaps go back to the executor. The feature is NOT complete until the gate passes.

---

## Step 4: Test Coverage

After the wiring gate passes:

1. **Investigator** identifies untested new code paths
2. **Executor** writes tests for critical paths
3. **1 round of review** — verify tests are meaningful

---

## Step 5: PR Creation

- Branch: `feat/[feature-name]`
- PR body: feature description, domains, acceptance criteria status, user journey verification
- Follow project's PR conventions

---

## Reporting

After each domain:
```
Domain: [name] — COMPLETE
  Rounds: [N]
  Changes: [new files, modified files, tests]
  Acceptance criteria: [all met / remaining]
```

After feature complete:
```
Feature: [name] — COMPLETE
  Domains: [N] in [M] rounds
  Wiring gate: PASSED (all exports consumed, journey traced)
  Tests added: [count]
  PR: #NNN
```

---

## Autonomy Level

- **Autonomous within a domain** — implement, test, iterate
- **Confirm with user** before starting each domain
- **Escalate if:** criteria ambiguous, breaking changes needed, circular dependencies
