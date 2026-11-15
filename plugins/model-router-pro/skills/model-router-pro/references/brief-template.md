# Subagent brief template

Copy, fill in, delete lines that don't apply. Cheaper models need this more, not less.

```
Goal: <one sentence: the outcome, not the activity>

Context:
- Project: <what it is, language/framework, how it runs>
- Relevant files: <exact paths; say which to edit and which are read-only>
- Already decided / ruled out: <so it doesn't re-litigate or retry dead ends>

Task:
1. <step>
2. <step>

Constraints:
- <style, APIs to use or avoid, files not to touch, no new dependencies, etc.>

Done when:
- <objective check: test passes, command output, behavior in browser>

Return (keep it short):
- Files changed and a one-line summary each
- Anything you could not finish or were unsure about
- <specific facts the orchestrator needs>
```

## Tips by tier

- **Haiku (lookups):** Give it a narrow question and the place to look. Ask for raw findings (paths, line numbers), not conclusions.
- **Sonnet (building):** Give it a spec with concrete examples of the desired result. Point to an existing file to imitate when one exists.
- **Opus:** Give it the problem, the constraints and what Sonnet already tried, and let it choose the approach. Ask it to state the approach before large edits if the change is risky.
