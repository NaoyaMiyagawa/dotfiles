---
name: custom-empirical-prompt-tuning
description: Run agent-facing text instructions (skills, slash commands, task prompts, CLAUDE.md sections, code-generation prompts) through a bias-free executor, evaluate on both sides (executor self-report plus instruction-side metrics), and iterate until gains flatten. Use right after creating or heavily revising a prompt or skill, or when you want to attribute unexpected agent behavior to ambiguous instructions rather than tooling.
---

# Empirical Prompt Tuning (Custom)

Prompt quality is invisible to the author. What reads as “clear” to the writer often blocks another agent. **The core of this skill is to run instructions through a fresh executor without bias, evaluate from both sides, and repeat** until improvement stalls—do not stop early.

## When to use

- Right after creating or substantially revising a skill, slash command, task prompt, or similar.
- When the agent does not behave as expected and you want to test whether the cause is ambiguous instructions.
- When you need to harden high-impact instructions (frequently used skills, core automation prompts).

**Do not use when:**

- One-off disposable prompts (evaluation cost exceeds payoff).
- You mainly want subjective preference, not higher success rate.

## Workflow

0. **Iteration 0 — description vs body alignment** (static; no dispatch)
   - Read the frontmatter `description` (claimed triggers / use cases).
   - Read what the body actually covers.
   - If they diverge, fix description or body before iteration 1.
   - Example gap: description says “navigation / form filling / data extraction” but the body is only a `npx playwright test` CLI reference—catch that mismatch.
   - Skipping this lets a subagent “reinterpret” the body to match the description, yielding **false positives** while the skill still fails real requirements.

1. **Baseline prep**: Lock the target prompt and prepare:
   - **Evaluation scenarios** — 2–3 kinds (one median case + 1–2 edge cases). Ground them in realistic tasks where this prompt would apply.
   - **Requirements checklist** — for scoring accuracy. Per scenario, list 3–7 items the deliverable must satisfy. Accuracy % = satisfied items / total items. **Freeze upfront** (do not move goalposts later).

2. **Bias-free read**: Have a “blank slate” executor read the instructions. **Dispatch a new subagent** via the Task tool—do not substitute self-rereading (you cannot objectively read what you just wrote). To run multiple scenarios in parallel, issue multiple Agent invocations in a single message. If you cannot dispatch, see **Environment constraints**.

3. **Execute**: Give the subagent a prompt that follows the **Subagent launch contract** below; have them run the scenario and produce output, ending with the self-report.

4. **Dual-sided evaluation** — record from the returned result:
   - **Executor self-report** (from the subagent report): unclear spots / discretion-filled gaps / where templates failed.
   - **Instruction-side measurement** (rules for this section are authoritative; elsewhere point here):
     - Success / failure: **success** only if **every** `[critical]` requirement is fully satisfied (○). If any `[critical]` is × or partial, **failure** (×). Labels are ○ / × only for the row.
     - **Accuracy**: checklist satisfaction % (○ = full credit, × = 0, partial = 0.5, sum / total items).
     - **Step count**: use Task tool return metadata `usage.tool_uses` as-is (include Read, Grep, etc.—do not exclude).
     - **Duration**: `usage.duration_ms` from the Task tool.
     - **Retries**: how many times the subagent redid the same decision (from self-report only; not measurable from the parent).
     - **On failure**, add one line under the “Unclear points” section listing **which `[critical]` item(s) failed** (for root cause tracking).
   - Include **at least one** `[critical]` item per checklist (zero makes success vacuous). Do not relabel `[critical]` after the fact.

5. **Apply minimal diffs**: Fix unclear points with the smallest prompt change. **One theme per iteration** (related multi-line edits OK; unrelated fixes defer).

   - **Before editing**, state **which checklist / criterion text** the change is meant to satisfy (guessing from axis names often misses; see “Propagation patterns”).

6. **Re-evaluate**: Dispatch a **new** subagent and repeat steps 2–5 (do not reuse the same agent—it has learned). Increase parallelism only when improvement plateaus across iterations.

7. **Stop condition**: Roughly **two consecutive iterations** with **no new unclear points** and **metrics gains below threshold** (below). For very important prompts, require three consecutive passes.

## Evaluation axes

| Axis                           | How                                                | Meaning                           |
| ------------------------------ | -------------------------------------------------- | --------------------------------- |
| Success / failure              | Did the executor produce the intended deliverable? | Floor                             |
| Accuracy                       | What % of requirements met?                        | Degree of partial success         |
| Step count                     | `tool_uses`                                        | Waste / verbosity of instructions |
| Duration                       | `duration_ms`                                      | Proxy for cognitive load          |
| Retries                        | How often the same decision was redone             | Ambiguity signal                  |
| Unclear points (self-report)   | Bulleted by executor                               | Qualitative fix input             |
| Discretion fills (self-report) | Judgments not fixed by the prompt                  | Surfacing implicit spec           |

**Weighting**: prioritize qualitative (unclear points, discretion); treat time/steps as secondary. Optimizing only for shorter runs can strip prompts until they break.

### Qualitative reading of `tool_uses`

Accuracy alone can hide skill issues. Compare **relative** `tool_uses` across scenarios:

- If one scenario is **3–5×** higher than others, the skill may be **decision-tree/index-like with low self-containment**—the executor is forced into deep reference descent.
- Typical pattern: most scenarios 1–3 `tool_uses`, one scenario 15+ → no inline recipe for that path; cross-folder `references/` search.
- Mitigation: add a **minimal complete example inline** or **when to read references** guidance at the top of `SKILL.md`; `tool_uses` often drops sharply.

High `tool_uses` dispersion can justify another iteration even at 100% accuracy. **Stopping on accuracy alone** misses structural gaps.

### Propagation patterns (conservative / upside / zero)

Effect of edits is not linear. Expect:

- **Conservative**: you aimed at several axes but only one moved—**multi-axis patches often under-deliver**.
- **Upside**: one structural fact (command + config + expected output) satisfies several criteria at once—**bundled information hits multiple axes**.
- **Zero**: you changed something inferred from an axis name but it matched **no** criterion text—**axis names ≠ criterion wording**.

To stabilize: **before** applying a diff, spell out which criterion sentences the change satisfies. Without sentence-level linkage, estimates stay noisy. When adding axes, make each criterion concrete enough that a subagent can score it (e.g. “full explicit minimal runnable example”).

## Subagent launch contract

The prompt you pass to the executor should follow this shape (input contract for dual-sided evaluation):

```
You are a fresh executor reading <target prompt name> with no prior context.

## Target prompt
<full text of the target prompt, or a path to Read>

## Scenario
<one paragraph setting>

## Requirements checklist (what the deliverable must satisfy)
1. [critical] <floor requirement>
2. <normal item>
3. <normal item>
...
(Success rules: see "Workflow → Dual-sided evaluation / instruction-side measurement". At least one [critical] item is mandatory.)

## Task
1. Follow the target prompt and execute the scenario; produce the deliverable.
2. Respond using the report structure below.

## Report structure
- Deliverable: <artifact or execution summary>
- Requirements: for each item, ○ / × / partial (with reason)
- Unclear points: where the target prompt blocked you or was ambiguous (bullets)
- Discretion fills: what you decided that the prompt did not specify (bullets)
- Retries: how many times you redid the same decision and why
```

The caller extracts self-report fields and fills the evaluation table using `tool_uses` and `duration_ms` from Agent usage metadata.

## Environment constraints

If you **cannot** dispatch a new subagent (already running as a subagent, Task tool disabled, etc.), this skill **does not apply**.

- **Alternative 1**: Ask the user to start another session and run the evaluation there.
- **Alternative 2**: Report explicitly: `empirical evaluation skipped: dispatch unavailable`.
- **Do not** substitute self-rereading (biased; do not trust the scores).

**Structure-only mode**: When you only want a **consistency / clarity review** of a skill or prompt—not execution—state **structure review mode: no execution, text consistency check only** in the prompt to the subagent. That sidesteps the skip above and returns static review. Structure review **supplements** empirical runs; it **cannot** replace them for consecutive-clear stopping rules.

## When to stop iterating

- **Converge (stop)** — **all** of the following for **two** consecutive iterations:
  - New unclear points: **0**
  - Accuracy delta vs prior: **≤ +3 percentage points** (e.g. 5% → 8% saturation)
  - Step count delta: **within ±10%**
  - Duration delta: **within ±15%**
  - **Overfitting check**: at stop, add **one hold-out scenario** never used before. If accuracy drops **≥15 points** vs recent average, treat as overfitting—revisit baseline scenario design and add edge cases.

- **Diverge (redesign)** — after **3+** iterations, unclear points still do not shrink: the **design** may be wrong. Stop micro-patches; rewrite structure.

- **Resource cap**: stop when importance no longer justifies cost (shipping at “good enough”).

## Per-iteration report format

```
## Iteration N

### Changes since last run
- <one-line summary>

### Results (per scenario)
| Scenario | Pass/Fail | Accuracy | steps | duration | retries |
| -------- | --------- | -------- | ----- | -------- | ------- |
| A        | ○         | 90%      | 4     | 20s      | 0       |
| B        | ×         | 60%      | 9     | 41s      | 2       |

### New unclear points
- <Scenario B>: [critical] item N × — <one-line reason>   # required on failure
- <Scenario B>: <other note>
- <Scenario A>: (none)

### New discretion fills
- <Scenario B>: <what was guessed>

### Next patch
- <minimal one-line fix>

(Convergence: X consecutive clears / Y iterations until stop criteria)
```

## Red flags (rationalizations to reject)

| Rationalization                                   | Reality                                                                                                                      |
| ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| “Rereading myself is enough”                      | You cannot objectively review text you just wrote. Dispatch a new subagent.                                                  |
| “One scenario is enough”                          | Single scenarios overfit. Minimum two; preferably three.                                                                     |
| “Unclear points hit zero once, we’re done”        | Could be luck. Require **two** consecutive clean passes.                                                                     |
| “Fix every unclear point in one go”               | You won’t know what worked. One theme per iteration.                                                                         |
| “Split every tiny related edit across iterations” | Wrong extreme—“one theme” is semantic; 2–3 related micro-edits in one iter is fine. Over-splitting explodes iteration count. |
| “Metrics look good; ignore qualitative notes”     | Shorter runs can mean over-pruning. Lead with qualitative.                                                                   |
| “Rewrite from scratch is faster”                  | Valid only after **3+** iterations with no shrink in unclear points—not before.                                              |
| “Reuse the same subagent”                         | It learned. Always dispatch fresh.                                                                                           |

## Common failures

- **Scenarios too easy or too hard** — neither yields signal. Use one realistic median + edges.
- **Metrics-only tuning** — chasing duration strips robustness.
- **Too many edits per iteration** — cannot attribute what worked.
- **Tuning scenarios to match the patch** — making scenarios easier to fake progress. That invalidates the method.

## Related work

- **`superpowers:writing-skills`** — TDD-style skill authoring; “subagent baseline → fix → rerun” is the same core loop.
- **`retrospective-codify`** — captures learning after tasks; use empirical tuning **during** prompt development and retrospectives **after**.
- **`superpowers:dispatching-parallel-agents`** — patterns for parallel scenario runs.

## Source

Adapted from [mizchi/chezmoi-dotfiles — empirical-prompt-tuning](https://github.com/mizchi/chezmoi-dotfiles/blob/main/dot_claude/skills/empirical-prompt-tuning/SKILL.md) (translated to English)
