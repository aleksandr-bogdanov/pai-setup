Spawn a new Kitty terminal window running Claude Code with /remote-control auto-enabled.

Arguments: $ARGUMENTS

## Parameter Parsing

Parse `$ARGUMENTS` as positional: `[directory] [command]`

| Parameter | Default | Description |
|-----------|---------|-------------|
| directory | current working directory (`$PWD`) | Where the new session starts |
| command | `pai` | Command to execute in the new terminal |

Examples:
- `/spawn` → current dir, runs `pai`
- `/spawn ~/Projects/other` → that dir, runs `pai`
- `/spawn . "pai --local"` → current dir, runs `pai --local`
- `/spawn ~/Projects/other "claude --model sonnet"` → that dir, that command

## Execution

Run the spawn script via Bash:

```
~/.claude/scripts/spawn-session.sh "<directory>" "<command>"
```

Report the output to the user. If it fails, show the error and suggest checking `allow_remote_control` in kitty.conf.
