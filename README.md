# model-router

Claude Code skills that split multi-part work into subtasks and run each one on the cheapest Claude model that still does it well. Escalation happens only when a cheaper attempt fails verification. Plan mode and effort are chosen automatically.

여러 작업이 섞인 요청을 하위 작업으로 나누고, 각 작업을 해낼 수 있는 가장 싼 Claude 모델로 돌리는 Claude Code 스킬입니다. 싼 모델의 결과가 검증에서 실패할 때만 윗단계로 올립니다. plan 모드와 effort도 Claude가 알아서 정합니다.

## Pick your plan / 요금제에 맞게 고르세요

| Plugin | For | Models |
|---|---|---|
| **model-router** | Claude Max / Ultra | Sonnet → Opus → Fable (no Haiku, quality first) |
| **model-router-pro** | Claude Pro | Haiku → Sonnet → Opus (Fable only with your approval, billed as usage credits) |

On Pro, Fable is not included in the plan's usage, and the 5-hour and weekly limits are tighter. So `model-router-pro` sends lookups to Haiku and builds on Sonnet. It calls Opus only for the hard core and suggests `/model opusplan`.

Pro 요금제는 Fable이 기본 사용량에 포함되지 않고 한도도 빠듯합니다. 그래서 Pro용은 단순 조사는 Haiku에게 맡기고, 구현은 Sonnet으로 하고, 정말 어려운 부분만 Opus를 씁니다.

## Install / 설치

**As a plugin (recommended, works in every project):**

```
/plugin marketplace add claudedakedake-spec/claude-model-router

# Max / Ultra
/plugin install model-router@model-router

# Pro
/plugin install model-router-pro@model-router
```

Install only the one for your plan.

**As a personal skill from a local clone:**

```sh
git clone https://github.com/claudedakedake-spec/claude-model-router.git
cd claude-model-router
```

```powershell
# Windows
./install.ps1        # Max / Ultra
./install.ps1 pro    # Pro
```

```sh
# macOS / Linux
sh install.sh        # Max / Ultra
sh install.sh pro    # Pro
```

Use one method, plugin or local link, not both, or the skill will appear twice.

## How it works / 작동 방식

- The main conversation keeps its model; only you can change it with `/model`.
- Subtasks are delegated to subagents with an explicit `model` and `effort`.
- "The expensive model decides, the cheap model types": the strong model writes a short spec, Sonnet implements, results are verified.
- When verification fails, the subtask is retried once with the failure added. If it fails again, it moves up one tier.
- When the remaining work changes in kind, it suggests a `/model` switch in one line. On Pro, it recommends keeping the main conversation on Sonnet.

- **Automatic session settings:**
  - Big or ambiguous work starts in plan mode, with the routing table in the plan.
  - Subagent effort is set per tier.
  - Auto mode is never switched on by Claude; it may suggest it once for routine execution.

| Tier | Typical work |
|---|---|
| Haiku (Pro only) | file and symbol search, listing, pulling facts from logs and docs |
| Sonnet | search, summaries, implementing clear specs, repetitive edits, UI, tests (default) |
| Opus | hard design, debugging with an unknown cause, risky reviews (+ multi-file features on Max) |
| Fable (Max/Ultra only) | novel architecture, subtle correctness, problems Opus failed twice |

## Modes / 모드

```
/model-router eco        /model-router-pro eco
/model-router balanced   /model-router-pro balanced   # default
/model-router quality    /model-router-pro quality
```

The skills also trigger automatically on large multi-step requests, or when you mention tokens, cost or usage limits.

## Similar projects / 비슷한 프로젝트

- [smart-router](https://sharedcontext.ai/skills/external/gacabartosz/smart-router) classifies tasks and escalates. It routes across Haiku, Sonnet and Opus.
- [fable-advisor](https://github.com/DannyMac180/fable-advisor) has the session model write specs, GPT-6 implement via Codex CLI, and Fable review.
- [tokenwise](https://github.com/CodeShuX/tokenwise) routes across Haiku, Sonnet and Opus and logs cost per task.

This project differs from them in four ways:
- It uses Claude models only.
- It ships separate editions for Max (Sonnet floor, Fable on top) and Pro (Haiku floor, no Fable by default).
- It escalates one tier at a time after verification.
- It chooses plan mode and effort automatically.

## Notes / 참고

- If `CLAUDE_CODE_SUBAGENT_MODEL` is set, it overrides the per-subtask model.
- Usage-limit weights per model are not published, so the skills reason in tiers, not exact prices.
- Standing instructions in your `CLAUDE.md` (e.g. "never use Opus") take priority.

## License

MIT
