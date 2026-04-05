# PAI Setup — Claude Code Skills for Deep Work

Custom Claude Code skills for autonomous, iterative code work. Built for [Claude Code](https://claude.com/claude-code).

## What's Included

### DeepLoop Skills (`skills/DeepLoop/`)

Four autonomous workflows powered by a three-tier Arbiter/Investigator/Executor architecture:

| Skill | Command | What it does |
|-------|---------|-------------|
| **Deep Audit** | `/deep-audit` | Autonomous bug hunting — finds and fixes bugs across your codebase via iterative convergence (3 clean rounds to exit) |
| **Deep Build** | `/deep-build` | Feature implementation with convergence — spec, implement, wiring gate, PR. Exits when acceptance criteria are met |
| **Deep Investigate** | `/deep-investigate` | Deep dive reports with NO code changes. Produces severity-ranked findings saved to docs |
| **Deep Review** | `/deep-review` | Multi-round convergent code review, deeper than single-pass. Optionally applies fixes |

**Core files:**
- `SKILL.md` — Entry point and workflow routing
- `LoopEngine.md` — The convergence algorithm (shared by all 4 workflows)
- `ArbiterFramework.md` — Judgment criteria for approve/reject decisions

### The Algorithm (`algorithm/v3.7.0.md`)

Iterative implementation methodology: transition from CURRENT STATE to IDEAL STATE using verifiable criteria (ISC — Ideal State Criteria). Seven phases: Observe, Think, Plan, Build, Execute, Verify, Learn.

Features:
- Effort tiers from Standard (<2min) to Comprehensive (<120min)
- ISC decomposition methodology with mandatory splitting tests
- Capability selection and invocation tracking
- PRD (Product Requirements Document) as system of record

### CLAUDE.md

The global Claude Code configuration that ties everything together — mode selection (Native/Algorithm/Minimal), memory scoping, and context routing.

## Installation

1. Copy `skills/DeepLoop/` to `~/.claude/skills/Utilities/DeepLoop/`
2. Copy `algorithm/v3.7.0.md` to `~/.claude/PAI/Algorithm/v3.7.0.md`
3. Copy or merge `CLAUDE.md` into `~/.claude/CLAUDE.md`
4. Register the skills in your Claude Code settings

### Registering Skills

Add to your `~/.claude/settings.json`:

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

### Three-Tier Architecture

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

### The Algorithm's ISC System

Every task gets decomposed into atomic, verifiable criteria. The Splitting Test ensures criteria are truly independent:
1. **"And"/"With" test** — contains joining words? Split.
2. **Independent failure test** — can part A pass while B fails? Separate criteria.
3. **Scope word test** — "all", "every"? Enumerate.
4. **Domain boundary test** — crosses UI/API/data? One per boundary.

## Customization

DeepLoop checks `~/.claude/PAI/USER/SKILLCUSTOMIZATIONS/DeepLoop/` for overrides before executing. Create a `PREFERENCES.md` there to customize behavior.

## License

MIT
