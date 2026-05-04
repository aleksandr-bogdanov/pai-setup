You are doing a wrap-up check before the user closes this chat. Run through three checks and produce a concise report. Be honest and specific — this is a safety gate, not a summary.

## Check 1: Uncommitted code

Run `git status` in the current working directory. If not a git repo, say so and skip.

Report:
- Uncommitted files (staged or unstaged)
- Untracked files that look meaningful (skip node_modules, .DS_Store, build artifacts)
- Any stash entries (`git stash list`)
- If clean: say so in one line

## Check 2: Uncommitted PAI knowledge

Review this conversation for anything that was learned, decided, or discovered that is NOT yet in PAI memory (`~/.claude/PAI/MEMORY/`).

Read `~/.claude/PAI/MEMORY/MEMORY.md` to see what's already indexed. Then check for:
- New people mentioned (name, role, team) not in the org chart
- New systems, tools, or services not in memory
- Decisions made that affect future work
- Action items assigned to Alex
- Corrections to existing memory (things that turned out to be wrong)
- Feedback given to you (behavioral corrections, preferences) not yet saved

For each gap found: state what it is and which memory file it belongs in.

If everything is already persisted: say so in one line.

## Check 3: Safety verdict

Based on checks 1 and 2, give a single verdict:

**✅ SAFE TO CLOSE** — nothing will be lost.

or

**⚠️ NOT SAFE — save these first:**
- [bullet list of specific things that would be lost]

Keep the full report under 30 lines. No padding.
