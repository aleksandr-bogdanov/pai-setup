#!/usr/bin/env bash
set -euo pipefail

# spawn-session.sh — Open a new Kitty window, run a command, auto-send /remote-control
#
# Usage: spawn-session.sh [directory] [command] [delay]
#   directory  — working directory (default: $PWD)
#   command    — command to run in the new window (default: pai)
#   delay      — seconds before sending /remote-control (default: 12)

DIR="${1:-$PWD}"
CMD="${2:-pai}"
DELAY="${3:-12}"

# Resolve to absolute path
DIR=$(cd "$DIR" 2>/dev/null && pwd) || { echo "ERROR: Directory '$1' not found"; exit 1; }

# Verify kitty remote control is available
if ! command -v kitty &>/dev/null; then
  echo "ERROR: kitty not found in PATH"
  exit 1
fi

# Launch new Kitty OS window with default shell
WINDOW_ID=$(kitty @ launch --type=os-window --cwd="$DIR" 2>&1) || {
  echo "ERROR: kitty @ launch failed. Is allow_remote_control enabled in kitty.conf?"
  echo "  Add: allow_remote_control yes"
  exit 1
}

if [[ -z "$WINDOW_ID" ]]; then
  echo "ERROR: Got empty window ID from kitty"
  exit 1
fi

# Brief pause for shell to initialize
sleep 1

# Type the command into the new window
kitty @ send-text --match "id:$WINDOW_ID" -- "$CMD"$'\r'

# Background: wait for command to initialize, then send /remote-control
(
  sleep "$DELAY"
  kitty @ send-text --match "id:$WINDOW_ID" -- '/remote-control'$'\r'
) &
disown

echo "✓ Spawned kitty window $WINDOW_ID"
echo "  Directory: $DIR"
echo "  Command:   $CMD"
echo "  /remote-control will be sent in ${DELAY}s"
