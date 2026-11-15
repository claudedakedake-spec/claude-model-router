# model-router

**English** · [한국어](README.ko.md)

Claude Code skills that split a big request into smaller tasks and give each task to the cheapest Claude model that can still do it well. The result: the same quality, with less of your usage limit spent.

> **The core idea:** *the expensive model decides, the cheap model types.*
> A strong model (Opus or Fable) makes the hard decisions and writes clear specs. A cheaper model (Sonnet, or Haiku on Pro) does the volume work by following those specs. Every result is checked before it counts.

---

## Contents

- [Why this exists](#why-this-exists)
- [Pick your edition](#pick-your-edition)
- [Install](#install)
- [How to use it](#how-to-use-it)
- [What you'll see](#what-youll-see)
- [How it picks a model](#how-it-picks-a-model)
- [Implementation quality rules](#implementation-quality-rules)
- [When something fails](#when-something-fails-escalation)
- [Settings it manages for you](#settings-it-manages-for-you)
- [Modes](#modes)
- [Extra rules on Pro](#extra-rules-on-pro)
- [Customizing](#customizing)
- [Limitations](#limitations)
- [FAQ](#faq)
- [Repository layout](#repository-layout)
- [Similar projects](#similar-projects)

---

## Why this exists

There are two common ways to work with Claude Code, and both waste something:

- **Everything on the biggest model.** Quality is high, but simple work like searching files, repetitive edits or boilerplate burns through the 5-hour and weekly limits fast.
- **Everything on a smaller model.** It's cheap per token, but hard parts get done wrong. You pay again in rework, and some bugs slip through unnoticed.

This skill does what an experienced tech lead does. It hands each piece of work to the right person, writes clear instructions, and reviews everything that comes back.

## Pick your edition

The repository contains two plugins. Install the one that matches your Claude plan.

| | **model-router** | **model-router-pro** |
|---|---|---|
| For | Claude **Max / Ultra** | Claude **Pro** |
| Models used | Sonnet → Opus → Fable | Haiku → Sonnet → Opus |
| Haiku | Not used. Sonnet is the floor, because quality comes first | Used as a "scout" for simple lookups |
| Fable | Used for the hardest problems | Only with your approval. On Pro, Fable isn't in the plan's usage and is billed as extra usage credits |
| Priority | Quality first, while saving usage | Making the tight Pro limits last |

## Install

### Option A: as a plugin (recommended)

Run these inside Claude Code:

```
/plugin marketplace add claudedakedake-spec/claude-model-router

# Max / Ultra
/plugin install model-router@model-router

# Pro
/plugin install model-router-pro@model-router
```

Once installed, it works in every project.

### Option B: link a local copy

```sh
git clone https://github.com/claudedakedake-spec/claude-model-router.git
cd claude-model-router
```

```powershell
# Windows (creates a directory junction; no admin rights needed)
./install.ps1        # Max / Ultra
./install.ps1 pro    # Pro
```

```sh
# macOS / Linux (creates a symlink)
sh install.sh        # Max / Ultra
sh install.sh pro    # Pro
```

This links the skill into `~/.claude/skills/`, so edits to your clone take effect immediately.

> ⚠️ Use **one** option, not both. Otherwise the skill shows up twice.

## How to use it

**It turns on by itself** when you:
- give a request that bundles several tasks: a big feature, a refactor, a batch of fixes, or research plus implementation
- mention tokens, cost, usage limits, speed, efficiency or "which model". Korean keywords like 토큰, 한도, 효율 and 모델 선택 also work

**Or call it directly**, optionally with a mode:

```
/model-router                       # Max / Ultra, balanced mode
/model-router eco add dark mode and fix the login bug
/model-router-pro quality redesign the settings page
```

Small requests, like changing one file or answering a quick question, are handled directly without any routing. Splitting those up would cost more than it saves.

## What you'll see

For work with 3 or more parts, it first shows a plan like this, then gets going:

```
| Task                                   | Model  | Effort | Why                                   |
|----------------------------------------|--------|--------|---------------------------------------|
| Find all callers of the old auth API   | Sonnet | low    | Search; easy to verify                |
| Design the new session/token model     | Opus   | high   | Architecture decision, security       |
| Update 14 call sites to the new API    | Sonnet | medium | Same change repeated, spec is clear   |
| Review the full diff                   | Opus   | high   | Silent security bugs are expensive    |
```

When it's done, it reports what actually ran where, and anything that had to move up to a stronger model.

## How it picks a model

### The tiers

| Tier | Typical work | Effort |
|---|---|---|
| **Haiku** *(Pro only)* | Finding files and symbols, listing, pulling facts out of logs or docs, simple summaries | low |
| **Sonnet** *(the default)* | Implementing a clear spec, repetitive edits across files, UI from a description, tests, scripts, research with a defined question. On Max it also does lookups | low–medium |
| **Opus** | Hard design, debugging with an unknown cause, refactors, reviewing risky changes. On Max it also takes multi-file features with real design choices | medium–high |
| **Fable** *(Max/Ultra)* | New system architecture, very ambiguous problems, subtle correctness (concurrency, netcode, security, data integrity), problems Opus failed twice | high |

### The questions it asks about each task

It starts every task at Sonnet, then asks:

1. **Is "done" hard to define?** Vague goals and taste calls need more judgment.
2. **Does it need real reasoning?** New architecture, tricky rules, or an unknown root cause, not just a lot of typing.
3. **Is the blast radius wide?** Many tightly connected files, server logic, saved data, login, payments.
4. **Is a wrong answer expensive or hard to spot?** Bugs that tests won't catch.
5. **Is it mostly volume?** Lots of mechanical output is where cheap models save the most.

Each "yes" to questions 1–4 pushes the task toward a stronger model. A "yes" only to question 5 keeps it on the cheap tier. Length or file count alone is **not** a reason to use a bigger model; tight coupling and silent failures are.

### Doing it here vs. handing it off

A helper agent (subagent) starts from zero. It needs instructions and has to re-read files. So the skill keeps work in the main conversation when it's only a few steps, needs the conversation's history, or is closely tied to talking with you. It hands work off when the task is big, separable, or much cheaper to run on another model.

## Implementation quality rules

A cheap model is only cheap if it gets it right the first time. The skill compares the **expected total cost**: price × number of attempts + the cost of bugs that slip through.

**Sonnet writes the code when:**
- the spec says exactly what to change and how to check it's done
- there's an existing pattern in the codebase to copy
- the change stays in one place, or is the same change repeated
- mistakes show up immediately (tests, build errors, visible UI)

**Opus writes the code when any of these is true:**
- the spec leaves real interpretation ("make hits feel punchy")
- the change must stay consistent across tightly connected parts (client and server, shared state, protocols)
- a mistake would be silent (desyncs, race conditions, game-rule bugs, security, data loss)
- it's a long task with many rules to keep in mind at once
- it's the core everything else depends on (engine loop, data model, netcode)

**Fable writes the code** only when even Opus's code would be the risk, like a new algorithm or a subtle concurrency core. Otherwise Fable designs and reviews.

### Splitting work without losing quality

When one task has a hard part and a repetitive part, the strong model does the hard part and Sonnet follows its example. But a plain "copy the first one" split can leave item #1 great and the rest flat. So the skill follows three rules:

1. **The strong model makes every judgment call up front.** For each item it writes the behavior, feel, numbers, visuals and edge cases. Sonnet only turns specs into code.
2. **Items with a new mechanic aren't followers.** If an item needs a system the first one doesn't have, the strong model builds it too.
3. **The whole batch is reviewed side by side at the end.** Anything weaker than the first gets fixed or redone.

**Example: 10 spells in a game**

| Task | Model |
|---|---|
| Specs for all 10 spells (behavior, feel, numbers, visuals, edge cases) | Opus |
| Spell input system + the first projectile spell, end to end | Opus |
| Clone and stealth spells (new mechanics) | Opus |
| The other projectile and area spells (same shape, from specs) | Sonnet, several in parallel |
| Review all 10 together and check for multiplayer desync | Opus |

**It learns during the session.** If Sonnet needed two or more fix rounds on a kind of task, the rest of that kind goes to Opus from the start. If Opus breezes through a kind of task, that kind moves down to Sonnet.

## When something fails (escalation)

Every result is checked: tests run, pages opened, diffs read. Helper agents can be wrong while sounding confident, so verification is what makes cheap models safe to use.

```
Max / Ultra:
  Sonnet ─fail→ Sonnet again (with the error details) ─fail→ Opus ─fail ×2→ Fable

Pro:
  Haiku ─incomplete→ Sonnet (no Haiku retry)
  Sonnet ─fail→ Sonnet again (with the error details) ─fail→ Opus ─fail ×2→ stop and ask you
```

On Pro, when Opus fails twice it stops instead of looping, explains what's unclear, and offers three options: you give more information, you narrow the scope, or you approve Fable as paid usage credits.

## Settings it manages for you

| Setting | What the skill does |
|---|---|
| **Effort** for each helper task | Set automatically: low for lookups and mechanical edits, high for design and debugging, one step higher on a retry |
| **Plan mode** | For big or unclear work (3+ parts, architecture decisions, many files), it enters plan mode by itself, researches without editing, and shows the plan with the model table for your approval. Small tasks skip this |
| **Auto / permission mode** | It **cannot** turn this on; that's your safety choice. If an approved plan has many routine edits and permission prompts keep interrupting, it suggests once that you switch with Shift+Tab. It never suggests this for deploys, deletions or anything public |
| **Main conversation model** | Only you can change it with `/model`. When the work changes, say from design to routine implementation, it suggests a switch in one line |

## Modes

| Mode | Max / Ultra (`model-router`) | Pro (`model-router-pro`) |
|---|---|---|
| `eco` | Every task starts one tier lower (Sonnet is the floor). Fable only after Opus fails | Opus only after Sonnet fails twice, or for one final review of risky changes |
| `balanced` *(default)* | The tier table as written | Opus for hard design, unknown-cause debugging and risky reviews |
| `quality` | One tier higher for design, debugging and review; mechanical work stays cheap | Also gives Opus multi-file features with real design choices from the start |

## Extra rules on Pro

- **Best setup: main conversation on Sonnet**, with Opus called only as a helper for the hard parts. If your main conversation is on Opus, it suggests `/model sonnet` once. `/model opusplan`, which uses Opus while planning and Sonnet while executing, is also suggested.
- **About 3 helpers at a time.** Large parallel bursts can hit the 5-hour limit before results can be checked.
- **Opus does the most valuable thing: specs.** One Opus call that writes all the specs is worth more than many Opus calls that type code.
- **Short reports.** Helpers return paths, diffs and findings, not essays, since their reports also cost tokens.
- **Session awareness.** It can't see your remaining usage. In long sessions it suggests finishing a phase and continuing in a fresh session, or checking `/usage`.

## Customizing

**Your instructions always win.** Put standing rules in your `CLAUDE.md`, for example:

```markdown
- Never use Fable.
- Always use Opus for anything touching payments.
- Ask me before any Opus call.
```

**Change the rules themselves** by editing `SKILL.md` in your clone (Option B), or by forking this repo.

## Limitations

Please read these before relying on the skill:

- **It can't switch the main conversation's model.** Claude Code doesn't allow that. Only you can, with `/model`. The skill routes by handing tasks to helper agents on other models.
- **No published price ratios.** Anthropic doesn't publish how much each model counts against your limits, so the skill reasons in tiers, not exact numbers.
- **Not benchmarked yet.** The routing rules are based on how these model tiers generally behave. They haven't been measured head to head on the same tasks. To measure it yourself, check `/usage` before and after.
- **`CLAUDE_CODE_SUBAGENT_MODEL` overrides it.** If this environment variable is set, it overrides the model the skill picks for helpers.
- **The Pro edition hasn't been tested on a Pro account yet,** and `opusplan` availability may vary by Claude Code version.
- **Helper agents still cost something.** Instructions and re-reading files add overhead, which is why small tasks aren't split up.

## FAQ

**Does it make Claude slower?**
Usually faster on big tasks, because independent parts run in parallel. On small tasks it doesn't split anything, so nothing changes.

**Why no Haiku in the Max edition?**
On Max, a failed cheap attempt costs more in rework than Haiku saves, and quality comes first. On Pro the limits are tight enough that Haiku is worth it for narrow lookups.

**Will it use Fable without asking?**
On Max/Ultra, yes, but only for problems that match the Fable tier or after Opus fails twice. On Pro, never; it always asks first.

**Can I see what it decided?**
Yes. For bigger tasks it shows the routing plan before starting and a summary table at the end.

## Repository layout

```
claude-model-router/
├── .claude-plugin/marketplace.json      # lists both plugins
├── plugins/
│   ├── model-router/                    # Max / Ultra edition
│   │   ├── .claude-plugin/plugin.json
│   │   └── skills/model-router/
│   │       ├── SKILL.md                 # the rules Claude follows
│   │       └── references/
│   │           ├── brief-template.md    # how to write instructions for helpers
│   │           └── examples.md          # worked routing examples
│   └── model-router-pro/                # Pro edition (same layout)
├── install.ps1 / install.sh             # local install (Option B)
├── README.md / README.ko.md
└── LICENSE (MIT)
```

## Similar projects

- [smart-router](https://sharedcontext.ai/skills/external/gacabartosz/smart-router) classifies tasks and escalates across Haiku, Sonnet and Opus.
- [fable-advisor](https://github.com/DannyMac180/fable-advisor) has the session model write specs, GPT models implement via Codex CLI, and Fable review.
- [tokenwise](https://github.com/CodeShuX/tokenwise) routes across Haiku, Sonnet and Opus and logs cost per task.

**What's different here:**
- It uses Claude models only.
- There are separate editions for Max and Pro.
- It weighs implementation quality, not just task type.
- It has rules that keep a split batch at even quality.
- It escalates one tier at a time after verification.
- It chooses plan mode and effort automatically.

## License

MIT
