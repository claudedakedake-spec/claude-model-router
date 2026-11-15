---
name: model-router
description: Splits multi-part work into subtasks and runs each on the cheapest Claude model that will still do it well (Sonnet / Opus / Fable), delegating through subagents with an explicit model and effort, picking plan mode and effort automatically, escalating only when a cheaper attempt fails verification. Use this whenever a request bundles several tasks, a big feature, a refactor, a batch of fixes, research plus implementation, or any long multi-step job, and whenever the user mentions tokens, cost, usage limits, speed, "which model", efficiency, 토큰, 한도, 효율, 모델 선택, even if they don't name this skill. Also use when the user types /model-router with eco, balanced or quality. Built for Max/Ultra plans, where Fable is included; on a Pro plan, model-router-pro is the better fit.
argument-hint: "[eco | balanced | quality] [task]"
user-invocable: true
license: MIT
---

# Model Router

Goal: finish the user's work at full quality while spending as few expensive tokens and as little wall-clock time as possible, by matching each piece of work to the smallest model that does it well.

## What you can and cannot switch

- **The main conversation's model is fixed.** Only the user can change it with `/model`. You cannot switch yourself.
- **Subagents can run on another model.** The Agent tool takes `model` and `effort` (`low` … `max`). This skill is the user's explicit instruction to set both per subtask, using only `sonnet`, `opus` and `fable`. Don't route to Haiku, even for searches; Sonnet is the floor.
- A `fork` subagent always inherits your model, so use a normal subagent type (e.g. `general-purpose`, `Explore`) when you want a different model.
- If `CLAUDE_CODE_SUBAGENT_MODEL` is set in the environment, it overrides your choice. Mention this once if routing seems to have no effect.
- Do not start the Workflow tool unless the user opted into multi-agent orchestration. This skill alone is not that opt-in.

So routing works in two ways:
1. **Delegate** a subtask to a subagent on the model that fits it.
2. **Advise** the user in one line to switch the main model when the remaining work has clearly changed in kind (e.g. "남은 작업은 반복 구현이라 `/model sonnet`으로 바꾸면 한도를 아낄 수 있습니다"). Say it once per phase; don't nag.

## Modes

Read the mode from the arguments or from the user's words; default is `balanced`.

| Mode | Bias |
|---|---|
| `eco` | Start every subtask one tier lower than balanced. Fable only after Opus has failed. |
| `balanced` | Use the table below as written. |
| `quality` | Start one tier higher for design, debugging and review; mechanical work stays cheap. |

Honor standing instructions from the user or CLAUDE.md (e.g. "Fable 쓰지 마", "설계는 무조건 Opus", a budget). They override this skill.

## The tiers

| Tier | Use it for | Typical effort |
|---|---|---|
| **Sonnet** (builder, the default and the floor) | Searching files and symbols, extracting facts from logs or docs, summaries, implementing a clear spec, repetitive edits across files, UI from a description, tests, scripts, asset processing, web research with a defined question | low for lookups, medium for building |
| **Opus** (engineer) | Multi-file features with moderate design choices, debugging with an unknown cause, refactors, code review, integrating systems, research that needs judgment | medium–high |
| **Fable** (architect) | Novel system design, deeply ambiguous problems, subtle correctness (concurrency, netcode, security, data integrity), a problem Opus failed twice, a final high-stakes review | high |

Relative cost rises steeply from Sonnet to Opus to Fable. Exact usage-limit weights are not published, so reason in tiers rather than inventing numbers.

## How to pick a tier

Ask five questions about each subtask. Start at Sonnet. Each "yes" to 1–4 is a reason to move up. One strong "yes" usually means Opus; several, or one that is extreme, mean Fable. A "yes" to 5 with "no" to the rest keeps it firmly on Sonnet with low effort.

1. **Is "done" hard to define?** Vague goals and taste calls need more judgment than a written spec.
2. **Does it need real reasoning?** Think of new architecture, tricky invariants, or unknown root causes, not just typing.
3. **Is the blast radius wide?** Many coupled files, server-authoritative logic, persistence, auth or money.
4. **Is a wrong answer expensive or hard to spot?** Subtle bugs that tests won't catch need a stronger model. Easily verified output can go cheaper.
5. **Is it mostly volume?** Lots of mechanical output is where cheap models save the most.

Shortcut: **the expensive model decides, the cheap model types.** A common high-value pattern:
Opus or Fable writes a short spec or plan → Sonnet subagents implement it in parallel → you or Opus verify.

## Implementation quality: who should write the code

Cheap is only cheap if it's right the first time. Judge by the expected total: price × attempts + the cost of bugs that slip through. Sonnet matches Opus when the work is pinned down; Opus pulls ahead when writing the code itself requires judgment.

**Sonnet writes it** when:
- the spec says exactly what to change and how "done" is checked
- there's an existing pattern in the codebase to copy
- the change is local to one module, or the same change repeated across files
- mistakes show up immediately (tests, build errors, visible UI)

**Opus writes it** when any of these hold:
- the spec leaves real interpretation to the implementer ("make hits feel punchy", "ninja-like movement")
- the change must stay consistent across tightly coupled parts (client and server sim, shared state, protocols, migrations)
- a mistake would be silent: desyncs, race conditions, off-by-one in game rules, security, data loss
- the task is long and must hold many constraints at once, where Sonnet tends to drift or repeat a mistake
- it's the core everything else builds on (engine loop, data model, netcode)

**Fable writes it** only when Opus's code itself is the risk: a novel algorithm, or a subtle concurrency or netcode core. Otherwise Fable designs and reviews, and cheaper models write the code.

**Split instead of choosing, but only along the right line.** When a task mixes both, the stronger model writes the core or the first example end to end, and Sonnet fills in the rest by following it. This keeps quality only when the rest really is the same shape. If each item needs its own judgment, a plain copy-the-first split leaves item one great and the rest flat. So:
- **The strong model makes every judgment call up front.** For each item it writes the behavior, feel, numbers, visuals and edge cases. Sonnet then only translates specs into code and makes no taste decisions.
- **Items with a new mechanic aren't followers.** If an item needs a system the first one doesn't have (e.g. a clone that acts on its own, stealth that changes visibility rules), the strong model implements it too.
- **Review the batch side by side at the end.** The strong model compares all items together, then fixes or re-routes any that fall below the first.

Example: Opus specs all ten jutsu and implements the first projectile jutsu plus clone and stealth. Sonnet implements the other projectile and area variants from the specs. Opus reviews all ten together.

**Learn from the session.** If Sonnet needed two or more fix rounds on a kind of task, route the remaining tasks of that kind to Opus from the start instead of paying for rework each time. If Opus's results on a kind of task pass trivially, step that kind down to Sonnet.

## Workflow

1. **Decompose.** Break the request into subtasks with clear boundaries. Note which depend on others.
2. **Decide what stays in the main thread.** Keep work here when it needs the conversation's accumulated context, is a handful of tool calls, or is tightly interleaved with talking to the user. A subagent starts cold. You pay for the brief and for it re-reading files, so delegation only saves tokens when the subtask is big enough or much cheaper per token than you.
3. **Route.** Assign a tier and effort with the questions above.
4. **Show the plan** when there are 3 or more subtasks: a compact table (task, model, effort, one-phrase reason). Then proceed. Wait for approval only if the user asked to approve plans or a step is costly (e.g. a long Fable run).
5. **Launch.** Run independent subtasks in parallel in one message. Run dependent ones in order and pass results forward.
6. **Verify everything that comes back.** Run tests, open the page, read the diff. Subagent mistakes arrive sounding confident. Verification is usually cheap and is what makes cheap tiers safe.
7. **Escalate on evidence, not on fear.** If verification fails, retry once at the same tier with the specific failure added to the brief. If it fails again, move up one tier and include what the previous attempt learned. Never skip straight to Fable for a first attempt unless the subtask matches the Fable row.
8. **Step down** once the hard decisions are made: the remaining work is usually Sonnet-sized.
9. **Report** at the end with one short table: what ran where, and anything that had to escalate. This lets the user tune the routing over time.

## Session settings you manage automatically

Decide these yourself; don't ask the user to choose.

- **Subagent effort:** always set it from the tier table. Raise it one step for a retry, and lower it for pure mechanical edits.
- **Plan mode:** enter it yourself with `EnterPlanMode` before editing when the work is big or ambiguous, such as 3 or more subtasks, an architectural decision, or many files where a wrong direction is costly. Research read-only (cheap subagents can do the reading), put the routing table in the plan, and present it with `ExitPlanMode` for approval. Skip plan mode for small or clear tasks, since it costs a round-trip. If the session is already in plan mode, the routing table goes into the plan.
- **Auto mode / permission mode:** you cannot turn these on; they are the user's safety choice. If an approved plan has many routine edits and permission prompts keep interrupting, suggest once that the user can switch modes (Shift+Tab) for the execution phase. Never suggest it for risky steps such as deploys, deletions or anything outward-facing.
- **Main-conversation model and effort:** only the user can change these. Suggest a change in one line when a phase changes, e.g. from Fable for design to Sonnet for implementation.

## Writing a brief for a subagent

The brief is the subagent's whole world. A vague brief makes cheap models fail and wipes out the savings. Use [references/brief-template.md](references/brief-template.md). In short: goal, exact files, constraints, what's already ruled out, how to verify, and what to return. Ask for a concise result (paths, diffs, findings), not a narrative, because its report becomes your input tokens.

## Pitfalls

- **Over-delegating.** Spawning a subagent to read one file costs more than reading it.
- **Under-briefing a cheap model,** then blaming the tier.
- **Duplicating work.** Once something is delegated, don't also do it yourself while waiting.
- **Running everything on Fable "to be safe".** Quality comes from the right model plus verification, not from always using the largest model.
- **Silent routing.** If you change the plan mid-way (escalation, skipping a tier), say so in the final report.

See [references/examples.md](references/examples.md) for worked routing examples.
