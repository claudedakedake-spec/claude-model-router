#!/usr/bin/env sh
# Links this repo's skill into ~/.claude/skills so every Claude Code session can use it.
set -e
src="$(cd "$(dirname "$0")" && pwd)/skills/model-router"
dst="$HOME/.claude/skills/model-router"
mkdir -p "$HOME/.claude/skills"
if [ -e "$dst" ]; then
  echo "Already exists: $dst (remove it first to reinstall)"
  exit 0
fi
ln -s "$src" "$dst"
echo "Installed: $dst -> $src"
