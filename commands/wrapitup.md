You are doing a wrap-up check before the user closes this chat. Run four checks and produce a concise report. Be honest and specific — this is a safety gate, not a summary.

## Check 1: Uncommitted code

Run `git status` in the current working directory. If not a git repo, say so and skip.

Report:
- Uncommitted files (staged or unstaged)
- Untracked files that look meaningful (skip `node_modules`, `.DS_Store`, `dist`, `build`, `.next`, `target`, other obvious build artifacts)
- Any stash entries (`git stash list`)
- If clean: say so in one line

## Check 2: Active ISA state

List `~/.claude/PAI/MEMORY/WORK/` entries from this session. For each ISA:

- Read frontmatter `phase:`.
- If anything is not `complete`: either drive it to close now, OR document explicitly why it's deferred (with a follow-up task ID if needed).
- If `_ephemeral/<feature>.md` files exist alongside the master ISA: run `Skill("ISA", "reconcile <ephemeral> → <master>")` BEFORE close, so feature-context edits land back in the master ISA.

If no in-flight ISAs: say so in one line.

## Check 3: Uncaptured knowledge

Scan this conversation for content that lives only in chat and isn't yet captured anywhere persistent. For each gap, name the destination path:

- **New facts / decisions / runbooks** → `PAI/USER/<file>.md` (life domain) or `PAI/MEMORY/REFERENCE/<slug>.md` (durable how-to)
- **New behavioral rules to follow in future sessions** → `PAI/MEMORY/REFERENCE/<slug>.md`
- **New person facts** (anyone in `PAI/MEMORY/RELATIONSHIP/`) → `PAI/MEMORY/RELATIONSHIP/<slug>.md`
- **Tracked actions / actionable items** → user's task manager (e.g., Whenful via MCP) if they have one configured
- **Artifacts the user asked for that haven't been written** → `~/Documents/artifacts/YYYYMMDD_<name>.md`
- **New domain knowledge / research notes / frameworks** → `PAI/MEMORY/KNOWLEDGE/<slug>.md`
- **Durable principles / mental models** → `PAI/MEMORY/WISDOM/<slug>.md`

Skip what's already captured in `PAI/USER/`, the active ISA's `Decisions`/`Changelog`/`Verification` sections, or `PAI/MEMORY/`. Don't flag throwaway debugging steps or behavioral feedback already routed to REFERENCE.

If everything is captured: say so in one line.

## Check 4: Safety verdict

Based on checks 1–3, give a single verdict:

**✅ SAFE TO CLOSE** — nothing will be lost.

or

**⚠️ NOT SAFE — save these first:**
- [bullet list of specific things that would be lost, each with the destination path]

---

Keep the full report under 30 lines. No padding, no summary of what you checked — just the findings.
