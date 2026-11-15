#!/usr/bin/env sh
# Links one of this repo's skills into ~/.claude/skills so every Claude Code session can use it.
# Usage:  sh install.sh       -> model-router      (Claude Max / Ultra, uses Fable)
#         sh install.sh pro   -> model-router-pro  (Claude Pro, Sonnet + Opus)
set -e
name="model-router"
[ "$1" = "pro" ] && name="model-router-pro"
src="$(cd "$(dirname "$0")" && pwd)/plugins/$name/skills/$name"
dst="$HOME/.claude/skills/$name"
mkdir -p "$HOME/.claude/skills"
if [ -e "$dst" ]; then
  echo "Already exists: $dst (remove it first to reinstall)"
  exit 0
fi
ln -s "$src" "$dst"
echo "Installed: $dst -> $src"
