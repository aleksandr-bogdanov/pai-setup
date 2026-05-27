---
name: DeepLoop
description: Autonomous iterative convergence loop — Arbiter/Investigator/Executor architecture for deep code audits, feature implementation, overnight investigation, and code review. USE WHEN deep audit, deep build, deep investigate, deep review, audit loop, overnight audit, autonomous audit, convergence loop, deep loop, run overnight, parallel audit, find all bugs, implement feature deeply, thorough review.
---

## Customization

**Before executing, check for user customizations at:**
`~/.claude/PAI/USER/SKILLCUSTOMIZATIONS/DeepLoop/`

If this directory exists, load and apply any PREFERENCES.md, configurations, or resources found there. These override default behavior. If the directory does not exist, proceed with skill defaults.

## Voice Notification

**When executing a workflow, do BOTH:**

1. **Send voice notification** (PAI v5 uses Pulse daemon on port 31337):
   ```bash
   curl -s -X POST http://localhost:31337/notify \
     -H "Content-Type: application/json" \
     -d '{"message": "Running the WORKFLOWNAME workflow in the DeepLoop skill to ACTION", "voice_enabled": true}' \
     > /dev/null 2>&1 &
   ```

2. **Output text notification**:
   ```
   Running the **WorkflowName** workflow in the **DeepLoop** skill to ACTION...
   ```

**Full documentation:** `~/.claude/PAI/DOCUMENTATION/Notifications/NotificationSystem.md`

# DeepLoop — Autonomous Iterative Convergence

Three-tier architecture: Arbiter (Opus, you) judges and orchestrates. Investigators (Opus subagents) discover. Executors (Sonnet subagents) implement. The arbiter never reads implementation files directly — it stays lean to track many domains across many rounds.

## Workflow Routing

| Workflow | Trigger | File |
|----------|---------|------|
| **Audit** | "deep audit", "find all bugs", "audit loop", "overnight audit" | `Workflows/Audit.md` (5-lens framework: Correctness, Sweep, Test quality, UX, Use case completeness) |
| **Build** | "deep build", "implement feature deeply", "build with convergence" | `Workflows/Build.md` |
| **Investigate** | "deep investigate", "overnight investigation", "deep dive report" | `Workflows/Investigate.md` |
| **Review** | "deep review", "thorough review", "convergence review" | `Workflows/Review.md` |
| **ParallelFleet** | "deep loop in worktrees", "parallel agent fleet", "spawn parallel deep-loop", "overnight parallel build" | `Workflows/ParallelFleet.md` (worktree fleet — orchestrates many Build/Audit agents in parallel; codifies seven invariants for clean parallel execution) |

## Context Files

| File | Purpose |
|------|---------|
| `LoopEngine.md` | Core convergence algorithm — shared by all workflows |
| `ArbiterFramework.md` | Judgment criteria, approval/rejection signals |

**All workflows MUST read `LoopEngine.md` before starting.**

## Parallel Execution Pattern

For overnight runs, launch multiple domain loops simultaneously:

```
FOR each domain_group in partition(domains, group_size):
  Agent(
    description="DeepLoop [mode] group [N]",
    prompt="[Arbiter instructions + LoopEngine + ArbiterFramework + domain_group + project commands]",
    subagent_type="general-purpose",
    model="opus",
    mode="bypassPermissions",
    run_in_background=true,
  )
```

Each parallel agent needs: LoopEngine algorithm, ArbiterFramework criteria, domain map, mode-specific workflow, project check commands.

## Output Requirements

- **Format:** Structured domain-by-domain progress reports
- **Must Include:** Round counts, findings per round, convergence status, PR links (for Audit/Build)
- **Must Avoid:** Raw agent output — arbiter summarizes and filters everything
