# PAI Setup — Claude Code Skills & Commands

Custom Claude Code skills and commands. Built for [Claude Code](https://claude.com/claude-code).

## What's Included

### Spawn Command (`commands/spawn.md` + `scripts/spawn-session.sh`)

Spawn a new Kitty terminal window running Claude Code with `/remote-control` auto-enabled. Lets you multiply Claude Code sessions from a single conversation — great for mobile.

| Command | What it does |
|---------|-------------|
| `/spawn` | New kitty window, current dir, runs `pai` |
| `/spawn ~/Projects/foo` | Same, but in that directory |
| `/spawn . "pai --local"` | Current dir, custom command |
| `/spawn ~/Projects/foo "claude"` | Custom dir + custom command |

**Requires:** [Kitty terminal](https://sw.kovidgoyal.net/kitty/) with `allow_remote_control yes` in `kitty.conf`.

**How it works:** Uses `kitty @` IPC to launch a new OS window, type your command, then auto-send `/remote-control` after 12 seconds.

### DeepLoop Skills (`skills/DeepLoop/`)

Four autonomous workflows powered by a three-tier Arbiter/Investigator/Executor architecture:

| Skill | Command | What it does |
|-------|---------|-------------|
| **Deep Audit** | `/deep-audit` | Autonomous bug hunting — iterative convergence (3 clean rounds to exit) |
| **Deep Build** | `/deep-build` | Feature implementation with convergence — spec, implement, wiring gate, PR |
| **Deep Investigate** | `/deep-investigate` | Deep dive reports with NO code changes. Severity-ranked findings |
| **Deep Review** | `/deep-review` | Multi-round convergent code review, optionally applies fixes |

**Core files:**
- `SKILL.md` — Entry point and workflow routing
- `LoopEngine.md` — The convergence algorithm (shared by all 4 workflows)
- `ArbiterFramework.md` — Judgment criteria for approve/reject decisions

## Prerequisites

| Tool | Required for | Install |
|------|-------------|---------|
| [Claude Code](https://claude.com/claude-code) | Everything | `npm install -g @anthropic-ai/claude-code` |
| [Kitty](https://sw.kovidgoyal.net/kitty/) | Spawn command | `brew install --cask kitty` |

Kitty must have remote control enabled. Add to `~/.config/kitty/kitty.conf`:
```
allow_remote_control yes
```

## Installation

### Spawn Command

```bash
cp commands/spawn.md ~/.claude/commands/spawn.md
cp scripts/spawn-session.sh ~/.claude/scripts/spawn-session.sh
chmod +x ~/.claude/scripts/spawn-session.sh
```

### DeepLoop Skills

```bash
cp -r skills/DeepLoop/ ~/.claude/skills/Utilities/DeepLoop/
```

Register in `~/.claude/settings.json`:

```json
{
  "skills": {
    "deep-build": "~/.claude/skills/Utilities/DeepLoop/Workflows/Build.md",
    "deep-audit": "~/.claude/skills/Utilities/DeepLoop/Workflows/Audit.md",
    "deep-investigate": "~/.claude/skills/Utilities/DeepLoop/Workflows/Investigate.md",
    "deep-review": "~/.claude/skills/Utilities/DeepLoop/Workflows/Review.md"
  }
}
```

## How It Works

### Spawn — Kitty Remote Control

The script uses Kitty's `kitty @` IPC protocol:
1. `kitty @ launch --type=os-window` opens a new window, returns its ID
2. `kitty @ send-text --match id:$ID` types into that specific window
3. A backgrounded timer sends `/remote-control` after 12 seconds

### DeepLoop — Three-Tier Architecture

| Role | Model | Purpose |
|------|-------|---------|
| **Arbiter** | Opus (primary agent) | Judgment, prompt design, convergence tracking |
| **Investigator** | Opus subagent | Deep code reading, multi-step tracing |
| **Executor** | Sonnet subagent | Mechanical implementation from specs |

The arbiter never reads implementation files directly — it stays lean to track many domains across many rounds. Investigators discover issues. Executors fix them.

### Convergence

Each workflow runs iterative rounds until findings converge to zero:
- **Audit**: 3 consecutive clean rounds (arbiter-approved)
- **Build**: Acceptance criteria met + wiring gate passes
- **Investigate**: 2 consecutive clean rounds
- **Review**: 2 consecutive clean rounds

## Customization

DeepLoop checks `~/.claude/PAI/USER/SKILLCUSTOMIZATIONS/DeepLoop/` for overrides before executing. Create a `PREFERENCES.md` there to customize behavior.

## License

MIT
