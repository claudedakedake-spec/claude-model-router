# Links this repo's skill into ~/.claude/skills so every Claude Code session on this PC can use it.
# Uses a directory junction (no admin rights needed); edits in the repo apply immediately.
$src = Join-Path $PSScriptRoot 'skills\model-router'
$dstDir = Join-Path $HOME '.claude\skills'
$dst = Join-Path $dstDir 'model-router'
New-Item -ItemType Directory -Force $dstDir | Out-Null
if (Test-Path $dst) {
  Write-Host "Already exists: $dst (remove it first to reinstall)"
  exit 0
}
cmd /c mklink /J "$dst" "$src" | Out-Null
Write-Host "Installed: $dst -> $src"
