# Worked routing examples (Claude Pro)

These show the reasoning, not fixed rules. Main conversation assumed on Sonnet.

## 1. Game overhaul (several big features at once)

Request: "Redesign the ninja mode: new shorter characters from free assets, a hand-seal jutsu system with combos listed in the codex, a parkour/stealth map with traps, flashier multi-hit combat."

| Subtask | Model | Effort | Why |
|---|---|---|---|
| Find CC0/CC-BY ninja sprite pack candidates and their license pages | Haiku | low | Narrow search; Sonnet double-checks the licenses |
| Design the jutsu and combat systems: data model, seal input, server sync | Opus | high | New architecture on a server-authoritative sim. One focused call that produces a spec |
| Design the map layout format (layers, ledges, hiding spots, trap sockets) | Sonnet | medium | Real choices, but it follows the spec and can be tried and tested. Opus only if it fails |
| Write a per-jutsu spec for all ten (behavior, feel, numbers, visuals, edge cases), done in the same call as the system design | Opus | high | All taste and balance decisions in one call; specs are cheap compared to code |
| Implement the first projectile jutsu end to end (input → sim → server → render) | Opus | high | Coupled client/server code; it becomes the template |
| Implement clone and stealth jutsu | Opus | high | New mechanics the template doesn't cover |
| Implement the other projectile and area jutsu from their specs | Sonnet ×3 at a time | medium | Same shape as the template; the specs carry the judgment |
| Multi-hit combat feel (hit-stop, combos, knockback) | Sonnet first, Opus if two rounds fail | medium | Judgment-heavy, but Pro saves Opus for when Sonnet proves it needs it |
| Codex UI page listing seal combos | Sonnet | low | Follows existing UI patterns |
| Adapt sprites (crop, recolor, crouched run frames) | Sonnet | medium | Mechanical, verified visually |
| Review all jutsu side by side and the integrated diff for desync | Opus | high | Keeps the batch at the level of the first, and catches risky networking logic, in one call |

Four Opus calls planned (design and specs, first jutsu, clone and stealth, final review), plus one more only if combat feel needs it. Split the work into phases across sessions so one phase fits in a 5-hour window.

## 2. Bug with unknown cause

Request: "Players sometimes get stuck after respawn in multiplayer."

- Haiku: collect the respawn code paths and recent related changes.
- Sonnet, medium effort: try to reproduce and fix with those findings.
- If that fails twice, Opus, high effort, with both attempts' findings.
- If Opus fails twice, stop and ask the user (more info, or Fable via paid credits).

## 3. Small, single-file change

Request: "Change the victory music file."

No routing. Do it in the main thread on Sonnet.

## 4. Research then write

Request: "Compare three auth libraries and then integrate the best one."

- Haiku ×3, one per library, with a fixed factual question list (license, last release, stars) and short structured answers; Sonnet only if the answers need judgment.
- Main thread decides; it is a judgment call but a well-informed one.
- Sonnet implements. Opus reviews only because auth is security-sensitive.

## 5. User says the limit is almost used up

Switch to eco. Use no Opus unless the user agrees. Finish the current subtask cleanly, then summarize where things stand so a fresh session can continue.
