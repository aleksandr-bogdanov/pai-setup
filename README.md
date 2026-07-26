# PAI Setup - Claude Code Skills & Commands

Custom Claude Code skills and commands. Built for [Claude Code](https://claude.com/claude-code) and [PAI v5](https://github.com/danielmiessler/PAI).

## What's Included

### Spawn Command (`commands/spawn.md` + `scripts/spawn-session.sh`)

Spawn a new Kitty terminal window running Claude Code with `/remote-control` auto-enabled. Lets you multiply Claude Code sessions from a single conversation - great for mobile.

| Command | What it does |
|---------|-------------|
| `/spawn` | New kitty window, current dir, runs `pai` |
| `/spawn ~/Projects/foo` | Same, but in that directory |
| `/spawn . "pai --local"` | Current dir, custom command |
| `/spawn ~/Projects/foo "claude"` | Custom dir + custom command |

**Requires:** [Kitty terminal](https://sw.kovidgoyal.net/kitty/) with `allow_remote_control yes` in `kitty.conf`.

**How it works:** Uses `kitty @` IPC to launch a new OS window, type your command, then auto-send `/remote-control` after 12 seconds.

### Wrap-it-up Command (`commands/wrapitup.md`)

Pre-close safety gate that runs 4 checks before you close a chat session:

| Check | What it does |
|-------|-------------|
| **1. Uncommitted code** | `git status` in cwd, surfaces meaningful unstaged/untracked/stashed work |
| **2. Active ISA state** | Lists `PAI/MEMORY/WORK/` entries; drives non-`complete` phases to close OR documents deferral; runs ephemeral feature reconcile via `Skill("ISA", "reconcile")` |
| **3. Uncaptured knowledge** | Scans conversation for facts/decisions/rules/artifacts not yet in `PAI/USER/` or `PAI/MEMORY/{REFERENCE,RELATIONSHIP,KNOWLEDGE,WISDOM}/`; routes actionables to the user's task manager (e.g., Whenful via MCP) |
| **4. Safety verdict** | ✅ SAFE TO CLOSE - or - ⚠️ NOT SAFE: bulleted gaps with destination paths |

Report capped at 30 lines.

### DeepLoop Skill (`skills/DeepLoop/`)

Four autonomous workflows powered by a three-tier Arbiter/Investigator/Executor architecture:

| Workflow | Slash command | What it does |
|----------|--------------|-------------|
| **Audit** | `/deep-audit` | Autonomous bug hunting - iterative convergence (3 clean rounds to exit) |
| **Build** | `/deep-build` | Feature implementation with convergence - spec, implement, wiring gate, PR |
| **Investigate** | `/deep-investigate` | Deep dive reports with NO code changes. Severity-ranked findings |
| **Review** | `/deep-review` | Multi-round convergent code review, optionally applies fixes |

**Core files:**
- `SKILL.md` - Entry point and workflow routing
- `LoopEngine.md` - The convergence algorithm (shared by all 4 workflows)
- `ArbiterFramework.md` - Judgment criteria for approve/reject decisions

The four wrapper command files in `commands/deep-*.md` are thin shims that load the skill and run the named workflow. They exist so the slash commands are auto-discovered by Claude Code without any `settings.json` registration.

## Prerequisites

| Tool | Required for | Install |
|------|-------------|---------|
| [Claude Code](https://claude.com/claude-code) | Everything | `npm install -g @anthropic-ai/claude-code` |
| [Kitty](https://sw.kovidgoyal.net/kitty/) | Spawn command | `brew install --cask kitty` |
| [PAI v5](https://github.com/danielmiessler/PAI) | DeepLoop voice notifications + wrapitup ISA/MEMORY checks | `curl -sSL https://ourpai.ai/install.sh \| bash` |

Kitty must have remote control enabled. Add to `~/.config/kitty/kitty.conf`:
```
allow_remote_control yes
```

## Installation

Claude Code auto-discovers slash commands from `~/.claude/commands/*.md` and skills from `~/.claude/skills/**/SKILL.md` at session start. **No `settings.json` registration needed.**

### All-in-one install

```bash
# Commands
cp commands/*.md ~/.claude/commands/

# Helper script
mkdir -p ~/.claude/scripts
cp scripts/spawn-session.sh ~/.claude/scripts/spawn-session.sh
chmod +x ~/.claude/scripts/spawn-session.sh

# DeepLoop skill
mkdir -p ~/.claude/skills/Utilities
cp -r skills/DeepLoop ~/.claude/skills/Utilities/DeepLoop
```

After install, start a fresh Claude Code session - `/spawn`, `/wrapitup`, `/deep-audit`, `/deep-build`, `/deep-investigate`, `/deep-review` will be available.

### Selective install

Each piece works independently:

```bash
# Just spawn
cp commands/spawn.md ~/.claude/commands/
mkdir -p ~/.claude/scripts && cp scripts/spawn-session.sh ~/.claude/scripts/
chmod +x ~/.claude/scripts/spawn-session.sh

# Just wrapitup
cp commands/wrapitup.md ~/.claude/commands/

# Just DeepLoop (commands + skill together)
cp commands/deep-*.md ~/.claude/commands/
mkdir -p ~/.claude/skills/Utilities
cp -r skills/DeepLoop ~/.claude/skills/Utilities/DeepLoop
```

## How It Works

### Spawn - Kitty Remote Control

The script uses Kitty's `kitty @` IPC protocol:
1. `kitty @ launch --type=os-window` opens a new window, returns its ID
2. `kitty @ send-text --match id:$ID` types into that specific window
3. A backgrounded timer sends `/remote-control` after 12 seconds

### Wrap-it-up - v5-native safety gate

The command exists in `commands/wrapitup.md` and is auto-discovered as `/wrapitup`. It assumes a PAI v5 layout: `PAI/MEMORY/WORK/<slug>/ISA.md` for active work, `PAI/MEMORY/{REFERENCE,RELATIONSHIP,KNOWLEDGE,WISDOM}/` for the memory hierarchy, `PAI/USER/<file>.md` for life-context. If your install differs, edit the destination paths in Check 3.

### DeepLoop - Three-Tier Architecture

| Role | Model | Purpose |
|------|-------|---------|
| **Arbiter** | Opus (primary agent) | Judgment, prompt design, convergence tracking |
| **Investigator** | Opus subagent | Deep code reading, multi-step tracing |
| **Executor** | Sonnet subagent | Mechanical implementation from specs |

The arbiter never reads implementation files directly - it stays lean to track many domains across many rounds. Investigators discover issues. Executors fix them.

### Convergence

Each workflow runs iterative rounds until findings converge to zero:
- **Audit**: 3 consecutive clean rounds (arbiter-approved)
- **Build**: Acceptance criteria met + wiring gate passes
- **Investigate**: 2 consecutive clean rounds
- **Review**: 2 consecutive clean rounds

## Customization

DeepLoop checks `~/.claude/PAI/USER/SKILLCUSTOMIZATIONS/DeepLoop/` for overrides before executing. Create a `PREFERENCES.md` there to customize behavior.

## PAI v5 compatibility notes

- Voice notifications route to the Pulse daemon on port `31337` (PAI v5 default). PAI v4 used port `8888` - this repo now targets v5.
- Wrap-it-up's ISA check expects v5's `ISA.md` format with `phase:` frontmatter. PAI v4 used `PRD.md` - this command no longer reads PRDs.
- Memory paths follow v5's hierarchical `PAI/MEMORY/{REFERENCE,KNOWLEDGE,...}` layout, not v4's flat `~/.claude/memory/`.

If you're still on PAI v4, pin this repo to a commit before the v5 migration or update the paths manually.

## License

MIT

---

<img src=".github/mark.svg" height="15" alt=""> built by [bogdanov.wtf](https://bogdanov.wtf)
