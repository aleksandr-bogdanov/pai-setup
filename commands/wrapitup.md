You are doing a wrap-up check before the user closes this chat. Run through three checks and produce a concise report. Be honest and specific — this is a safety gate, not a summary.

## Check 1: Uncommitted code

Run `git status` in the current working directory. If not a git repo, say so and skip.

Report:
- Uncommitted files (staged or unstaged)
- Untracked files that look meaningful (skip node_modules, .DS_Store, build artifacts)
- Any stash entries (`git stash list`)
- If clean: say so in one line

## Check 2: Uncommitted PAI knowledge

Review this conversation for structured domain knowledge that is NOT yet indexed in the knowledge base.

Read `~/.claude/PAI/MEMORY/KNOWLEDGE/INDEX.md` to see what's already indexed. Then check for:
- New systems, tools, or services learned about
- Runbooks or failure patterns encountered
- Processes or workflows clarified or documented
- Architecture or data model insights
- Decisions that will affect future work in this domain

Do NOT flag: user feedback, behavioral corrections, references, or personal preferences — those have their own intentional flows and are rarely forgotten.

For each gap found: state what it is and which knowledge subdirectory it belongs in (e.g. `KNOWLEDGE/dh/systems/`).

If everything is already indexed: say so in one line.

## Check 3: Safety verdict

Based on checks 1 and 2, give a single verdict:

**✅ SAFE TO CLOSE** — nothing will be lost.

or

**⚠️ NOT SAFE — save these first:**
- [bullet list of specific things that would be lost]

Keep the full report under 30 lines. No padding.
