# Future Enhancements — Task `estimated_effort`

> Audience: developers + architects
>
> Scope: introducing an optional task effort/size signal to improve allocation,
> analytics, and coaching.

## 1) Motivation

To produce robust, user-trustworthy stats and better allocations, it helps to
have a lightweight estimate of task “size”.

This enables:

- Better daily focus composition (avoid allocating too many large tasks).
- More accurate “overwhelming/complex task” detection.
- Better positive feedback (“you completed 3 medium tasks” vs raw counts).

## 2) Proposed Data Model

Add an optional field on tasks:

- `estimated_effort`

Recommended representation (stable + simple):

- enum-like string: `tiny | small | medium | large | huge`

Alternative representation:

- integer points (e.g., 1/2/3/5/8) if you want Fibonacci sizing.

## 3) How It Improves Allocation

Allocation can incorporate effort in either scoring or post-processing:

- Penalize very large tasks when daily capacity is low.
- Ensure a balanced mix (e.g., 1 large + several small/medium).
- Increase probability of “finishable today” task sets.

This is especially useful when allocation produces both project anchors and task
“doables”.

## 4) How It Improves Analytics & Coaching

### 4.1 Completion stats become more meaningful

Instead of only tracking counts, you can track effort-weighted completion:

- `completed_effort_points_today`
- `allocated_effort_points_today`
- completion rate by effort bucket

### 4.2 Detect “overwhelming” tasks more accurately

A strong signal for “break this down” is:

- task is frequently allocated but not completed

With `estimated_effort`, you can refine it:

- high-effort tasks that repeatedly fail to complete
- tasks whose “effort” is inconsistent with observed completion patterns

### 4.3 Reduce false negatives

Without effort, a task that is repeatedly allocated but not completed could be:

- genuinely too big, or
- blocked/ambiguous

Effort helps disambiguate and improve nudges.

## 5) UX Considerations (Minimal)

- Default to `unknown` (null) to avoid forcing users.
- Allow quick tagging via a small selector.
- Consider auto-suggesting effort based on historical completion time later.

## 6) Open Questions

- Should effort be required for tasks included in allocation, or purely optional?
- Should project-level effort exist (sum of child tasks, or independent signal)?
- Should effort influence “load more” behavior (avoid adding more large tasks)?
