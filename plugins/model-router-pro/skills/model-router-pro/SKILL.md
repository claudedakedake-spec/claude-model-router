---
name: model-router-pro
description: Model routing for Claude Pro plans, where Fable is not in the included usage and the 5-hour and weekly limits are tight. Splits multi-part work into subtasks, sends pure lookups to Haiku, keeps building on Sonnet, sends only genuinely hard design, debugging and review to Opus subagents with an explicit model and effort, picks plan mode and effort automatically, and never spends on Fable without the user's approval. Use this whenever a Pro user gives a request that bundles several tasks, a big feature, a refactor, a batch of fixes, research plus implementation, or any long multi-step job, and whenever they mention tokens, cost, usage limits, hitting the limit, speed, "which model", efficiency, 토큰, 한도, 효율, 모델 선택, Pro 요금제, even if they don't name this skill. Also use when the user types /model-router-pro with eco, balanced or quality. On Max or Ultra plans, model-router (with Fable) is the better fit.
argument-hint: "[eco | balanced | quality] [task]"
user-invocable: true
license: MIT
---

# Model Router for Claude Pro

Goal: get the user's work done at full quality without running out of the Pro plan's 5-hour session limit or weekly limit. Each piece of work goes to the cheapest model that does it well, and verification is what makes the cheap model safe.

## What Pro changes

- **Three models: Haiku, Sonnet and Opus.** Fable is not included in Pro usage; it can only be paid for with usage credits at API rates. Don't route to Fable on your own. If a problem truly needs it (see "When Opus fails"), ask the user first and say it will cost extra money.
- **Haiku is the scout.** Every lookup Haiku does instead of Sonnet or Opus stretches the allowance. Keep Haiku to narrow questions with a clear answer, because a vague Haiku result that has to be redone wastes the savings.
- **Limits are tight.** Opus drains the Pro allowance much faster than Sonnet. Treat every Opus call as something to justify, and every token of context as something to keep small.

## What you can and cannot switch

- **The main conversation's model is fixed.** Only the user can change it with `/model`.
- **Subagents can run on another model.** The Agent tool takes `model` and `effort`. This skill is the user's explicit instruction to set both per subtask, using `haiku`, `sonnet` and `opus`.
- A `fork` subagent always inherits your model, so use a normal subagent type (e.g. `general-purpose`, `Explore`) when you want a different model.
- If `CLAUDE_CODE_SUBAGENT_MODEL` is set, it overrides your choice. Mention this once if routing seems to have no effect.
- Do not start the Workflow tool unless the user opted into multi-agent orchestration. This skill alone is not that opt-in.

**The best setup on Pro: main conversation on Sonnet, Opus only as a subagent for the hard parts.** If the main conversation is on Opus, tell the user once, in one line, that `/model sonnet` will make the allowance last much longer, and that you will still call Opus for the hard parts.

## Modes

Read the mode from the arguments or the user's words; default is `balanced`.

| Mode | Opus is used for |
|---|---|
| `eco` | Only after Sonnet has failed twice with a good brief, or for one final review of risky changes. |
| `balanced` | Hard design, debugging with an unknown cause, and review of risky changes. |
| `quality` | Those, plus multi-file features with real design choices, from the first attempt. |

Honor standing instructions from the user or CLAUDE.md (e.g. "Opus 쓰지 마", a budget). They override this skill.

## The tiers

| Tier | Use it for | Typical effort |
|---|---|---|
| **Haiku** (scout) | Finding files and symbols, listing, grep sweeps, pulling facts out of logs or docs, checking whether something exists, simple summaries, format conversion | low (leave unset if the model rejects effort) |
| **Sonnet** (default for building) | Lookups that need judgment, implementing a clear spec, repetitive edits across files, UI from a description, tests, scripts, asset processing, web research with a defined question, multi-file features that follow existing patterns | low–medium |
| **Opus** (the hard core only) | New system design, root-causing a bug that resisted a first look, subtle correctness (concurrency, netcode, security, data integrity), refactors that change structure, reviewing a risky diff | medium–high |

## How to pick a tier

Start at Sonnet.

**Down to Haiku** when the subtask is a lookup with a narrow question and a checkable answer ("where is X defined", "list files that call Y", "what does this log say about Z"). If it needs interpretation or a decision, it is Sonnet work.

**Up to Opus** only when the answer to at least one of these is a clear "yes":

1. **Does it need real reasoning?** New architecture, tricky invariants, or an unknown root cause, not just a lot of typing.
2. **Is a wrong answer expensive and hard to spot?** Subtle bugs that tests won't catch, or server, persistence, auth or money logic.
3. **Did Sonnet already fail it twice** with a clear brief and the failure details?

"It's long" or "it touches many files" alone is not a reason for Opus. Volume is exactly where Sonnet saves the most.

The pattern that stretches Pro the furthest: **Opus writes a short spec once → Sonnet implements it → Sonnet runs the checks → Opus reviews only if the change is risky.** One focused Opus call that removes ambiguity is worth more than many Opus calls that type code.

## Workflow

1. **Decompose.** Break the request into subtasks with clear boundaries. Note which depend on others.
2. **Keep small things in the main thread.** A subagent starts cold. You pay for the brief and for it re-reading files. On Pro, delegating to *Sonnet* mostly pays off for large, separable chunks or to keep the main conversation short. Delegating to *Opus* pays off when the subtask is hard.
3. **Route** with the questions above.
4. **Show the plan** when there are 3 or more subtasks: a compact table (task, model, effort, one-phrase reason). Then proceed. Ask for approval first only if the user wants to approve plans or the plan includes several Opus calls in eco mode.
5. **Launch.** Run independent subtasks in one message. Keep parallel bursts moderate, around 3 subagents at a time, because a large burst can exhaust the 5-hour session limit before you can check results.
6. **Verify everything that comes back.** Run tests, open the page, read the diff. Verification on Sonnet is cheap and is what lets you avoid Opus.
7. **Escalate on evidence.** If a Haiku result is incomplete or wrong, redo it on Sonnet; don't retry Haiku. If Sonnet's verification fails, retry once on Sonnet with the specific failure added. If it fails again, move to Opus and include what was learned.
8. **Report** at the end with one short table: what ran where, and how many Opus calls were used.

## Session settings you manage automatically

Decide these yourself; don't ask the user to choose.

- **Subagent effort:** always set it from the tier table. Raise it one step for a retry, and lower it for pure mechanical edits.
- **Plan mode:** enter it yourself with `EnterPlanMode` before editing when the work is big or ambiguous, such as 3 or more subtasks, an architectural decision, or many files where a wrong direction is costly. Research read-only, put the routing table in the plan, and present it with `ExitPlanMode` for approval. Skip plan mode for small or clear tasks, since it costs a round-trip. If the session is already in plan mode, the routing table goes into the plan.
- **`opusplan`:** if the main conversation is on Opus, or the user wants Opus-quality planning, suggest `/model opusplan` once. It uses Opus while in plan mode and Sonnet for execution, which fits Pro well.
- **Auto mode / permission mode:** you cannot turn these on; they are the user's safety choice. If an approved plan has many routine edits and permission prompts keep interrupting, suggest once that the user can switch modes (Shift+Tab) for the execution phase. Never suggest it for risky steps such as deploys, deletions or anything outward-facing.
- **Main-conversation model and effort:** only the user can change these. Suggest a change in one line when a phase changes, e.g. "남은 건 반복 구현이라 `/model sonnet`으로 바꾸면 한도가 오래갑니다."

## When Opus fails

If Opus fails twice with good briefs, stop instead of looping. Tell the user what was tried and what is unclear, and offer these options:
- They give more information or a reproduction.
- They narrow the scope.
- They approve Fable through usage credits. Make clear this is billed at API rates on top of the Pro plan.

## Saving the allowance

- **Ask for short returns.** Have subagents report paths, diffs and findings, not narratives. Their report becomes your input tokens.
- **Use the cheapest tier and the lowest effort that works.** Send lookups to Haiku, and use `low` effort for mechanical edits. Save `high` for Opus design and debugging.
- **Don't re-read.** Don't re-read files a subagent already summarized unless you need to edit them.
- **Mind the session limit.** If the session is long and the remaining work is large, suggest finishing a phase and continuing in a fresh session, or say it is a good point to check `/usage`. You cannot see the user's remaining limit yourself.

## Writing a brief for a subagent

A vague brief makes Sonnet fail and forces an Opus call, which costs far more than writing the brief well. Use [references/brief-template.md](references/brief-template.md): goal, exact files, constraints, what's ruled out, how to verify, what to return.

## Pitfalls

- **Opus "to be safe".** On Pro, this is the fastest way to hit the limit mid-task.
- **Over-delegating** tiny lookups. Reading one file yourself is cheaper than briefing even a Haiku subagent; Haiku pays off for sweeps across many files.
- **Duplicating work.** Once something is delegated, don't also do it yourself while waiting.
- **Silent escalation.** If you used Opus more than planned, say so in the final report.

See [references/examples.md](references/examples.md) for worked routing examples.
