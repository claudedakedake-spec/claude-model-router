# model-router

A Claude Code skill that splits multi-part work into subtasks and runs each one on the cheapest Claude model that still does it well: **Sonnet**, **Opus** or **Fable**. Haiku is intentionally not used. Escalation happens only when a cheaper attempt fails verification.

여러 작업이 섞인 요청을 하위 작업으로 나누고, 각 작업을 해낼 수 있는 가장 싼 모델로 돌리는 Claude Code 스킬입니다. 싼 모델의 결과가 검증에서 실패할 때만 윗단계 모델로 올립니다.

## How it works / 작동 방식

- The main conversation keeps its model (only you can change it with `/model`).
- Subtasks are delegated to subagents with an explicit `model` and `effort`.
- "The expensive model decides, the cheap model types": Opus/Fable write the spec, Sonnet implements, results are verified.
- Failed verification → one retry with the failure added → then one tier up.
- When the remaining work changes in kind, it suggests a `/model` switch in one line.

| Tier | Typical work |
|---|---|
| Sonnet | search, summaries, implementing clear specs, repetitive edits, UI, tests (default) |
| Opus | multi-file features, debugging, refactors, review |
| Fable | novel architecture, subtle correctness, problems Opus failed twice |

## Modes / 모드

```
/model-router eco       # one tier cheaper; Fable only after Opus fails
/model-router balanced  # default
/model-router quality   # one tier higher for design, debugging, review
```

It also triggers automatically on large multi-step requests or when you mention tokens, cost or usage limits.

## Install / 설치

**As a plugin (recommended, works in every project):**

```
/plugin marketplace add claudedakedake-spec/claude-model-router
/plugin install model-router@model-router
```

**As a personal skill from a local clone:**

```sh
git clone https://github.com/claudedakedake-spec/claude-model-router.git
cd claude-model-router
```

```powershell
# Windows
./install.ps1
```

```sh
# macOS / Linux
sh install.sh
```

Either links `skills/model-router` into `~/.claude/skills/`. Use one method, not both, or the skill will appear twice.

## Notes / 참고

- If `CLAUDE_CODE_SUBAGENT_MODEL` is set, it overrides the per-subtask model.
- Usage-limit weights per model are not published. The skill reasons in tiers, not exact prices.
- Standing instructions in your `CLAUDE.md` (e.g. "never use Fable") take priority.

## License

MIT
