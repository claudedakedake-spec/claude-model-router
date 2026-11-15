# Worked routing examples

These show the reasoning, not fixed rules. Adjust to the mode and the project.

## 1. Game overhaul (several big features at once)

Request: "Redesign the ninja mode: new shorter characters from free assets, a hand-seal jutsu system with combos listed in the codex, a parkour/stealth map with traps, flashier multi-hit combat."

| Subtask | Model | Effort | Why |
|---|---|---|---|
| Find CC0/CC-BY ninja sprite packs, report licenses and URLs | Sonnet | low | Search and extraction; easy to verify |
| Design the combat and jutsu systems: data model, seal input, server sync | Fable (or Opus in eco) | high | New architecture on a server-authoritative sim; mistakes are expensive |
| Design the map layout format (layers, ledges, hiding spots, trap sockets) | Opus | high | Real design choices, moderate coupling |
| Implement jutsu effects from the spec (fire, clone, stealth, …) | Sonnet ×N in parallel | medium | Clear spec, high volume |
| Codex UI page listing seal combos | Sonnet | low | Follows existing UI patterns |
| Adapt sprites (crop, recolor, crouched run frames) | Sonnet | medium | Mechanical, verified visually |
| Review the integrated diff for desync and edge cases | Opus | high | Cross-cutting review |

Main thread: decompose, hold the conversation, run the game, verify. Advise `/model sonnet` for the main thread once the specs are written.

## 2. Bug with unknown cause

Request: "Players sometimes get stuck after respawn in multiplayer."

- Sonnet, low effort: collect the respawn code paths and recent related changes (file and line list).
- Opus, high effort: reproduce, find the root cause, propose a fix.
- If Opus fails twice with good briefs, escalate to Fable with both attempts' findings.
- Sonnet: add a regression test once the cause is known.

## 3. Small, single-file change

Request: "Change the victory music file."

No routing. Do it in the main thread. Delegating would cost more than the work itself.

## 4. Research then write

Request: "Compare three auth libraries and then integrate the best one."

- Sonnet ×3 in parallel, one per library: a fixed question list (license, maintenance, API fit), short structured answers.
- Main thread or Opus: decide, since that is a judgment call.
- Sonnet: implement the integration following the decision. Opus reviews if the change touches security-sensitive code.

## 5. User says "eco" and has a weekly limit concern

Shift the whole table down one tier, with Sonnet as the floor. Sonnet does all searching and the design drafts, and Opus only reviews them. Fable is used only after an Opus failure, and you ask the user before running it.
