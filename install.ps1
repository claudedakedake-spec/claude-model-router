# Links one of this repo's skills into ~/.claude/skills so every Claude Code session on this PC can use it.
# Usage:  ./install.ps1        -> model-router      (Claude Max / Ultra, uses Fable)
#         ./install.ps1 pro    -> model-router-pro  (Claude Pro, Sonnet + Opus)
# Uses a directory junction (no admin rights needed); edits in the repo apply immediately.
param([string]$Plan = 'max')
$name = if ($Plan -eq 'pro') { 'model-router-pro' } else { 'model-router' }
$src = Join-Path $PSScriptRoot "plugins\$name\skills\$name"
$dstDir = Join-Path $HOME '.claude\skills'
$dst = Join-Path $dstDir $name
New-Item -ItemType Directory -Force $dstDir | Out-Null
if (Test-Path $dst) {
  Write-Host "Already exists: $dst (remove it first to reinstall)"
  exit 0
}
cmd /c mklink /J "$dst" "$src" | Out-Null
Write-Host "Installed: $dst -> $src"
