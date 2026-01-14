# Attention overflow analysis

Created at: 2026-01-14T00:00:00Z
Last updated at: 2026-01-14T00:00:00Z

## Context
Taskly currently has multiple “attention banner” style modules:
- `checkInSummary` (reviews)
- `issuesSummary` (issues)
- `allocationAlerts` (allocation warnings)

The goal of the broader workstream is to unify/standardize how “attention” is surfaced, especially in screen headers, and define consistent overflow behavior when there are too many items to show inline.

This doc captures analysis and options discussed so far. It is intentionally design-focused (not an implementation plan).

## Current state: what exists and what does not

### Attention engine supports a unified model
The attention engine produces `AttentionItem` values via `AttentionEngineContract.watch(AttentionQuery)`.
Existing filter axes in `AttentionQuery`:
- `domains`
- `categories`
- `entityTypes`
- `minSeverity`

This supports the “one attention channel with filters” mental model.

### Reviews: scheduled review sessions exist in attention rules
The repo seeds scheduled review-session templates in `SystemAttentionRules`, including:
- Values alignment (`review_type: values_alignment`)
- Progress review (`review_type: progress`)
- Journal check-in (`review_type: journal`)
- Balance (`review_type: balance`)
- Pinned tasks (`review_type: pinned_tasks`)

These are `AttentionRuleType.review` rules with `entity_type = review_session`.

### No dedicated UI “review workflow” found (yet)
We did not find UI screens that implement a multi-step “review workflow” for progress/values-alignment/etc.
Current `check_in` was only a wrapper around `checkInSummary` (a summary surface), not a workflow.

### Allocation alerts and issues are already real attention items
Both `allocationAlerts` and `issuesSummary` are backed by `AttentionItem` streams, so they can be surfaced together in a unified banner.

## Project-health review rules (project entity type)

### Templates exist
The repo includes 3 project-health review templates:
- `review_project_high_value_neglected`
- `review_project_no_allocated_recently`
- `review_project_no_allocatable_tasks`

They are defined in `SystemAttentionRules` and included in the seeded template list.

### They are not producing items today
`AttentionEngine._evaluateReviewRule()` currently returns early unless `entity_type == review_session`.
Therefore, any review rule targeting `entity_type = project` produces zero `AttentionItem`s until the engine is extended.

### UI/Settings references exist but don’t surface items
- Focus setup UI has icon visuals for these rule keys.
- Focus setup review rule list currently filters to `entity_type == review_session`, so project-health review rules are hidden there as well.

## Overflow problem framing

When attention counts are small, a banner can expand inline (e.g., show up to 5 items).
When attention counts are large, the UI needs an overflow destination.

A key product constraint emerged:
- Reviews (the “check-in” concept) should route to a dedicated review experience.
- Non-review attention (issues, allocation warnings) should route to a different experience.

This implies overflow should not always be a single destination.

## Options for overflow destinations

### Option 1: Two destinations (strict separation)
- Reviews CTA navigates to a reviews-only destination.
- Issues/allocation CTA navigates to a separate “attention inbox” destination.

Pros:
- Matches the “reviews are different” constraint.
- Lets each destination evolve independently (workflow vs inbox).

Cons:
- Banner may need multiple CTAs (or a chooser) when multiple domains overflow.

### Option 2: Single destination with tabs (soft separation)
- One overflow destination screen with tabs: Reviews | Issues | Allocation.
- Reviews tab can host a workflow launcher; other tabs host inbox lists.

Pros:
- Single consistent entry point.
- Easy to scale to more domains later.

Cons:
- Still a shared destination (even if tabbed), which may feel less “separate”.

### Option 3: Keep legacy check-in summary as destination (not recommended)
- Leave `check_in` as “summary only” and add a new workflow elsewhere.

Pros:
- Lowest risk/least disruption.

Cons:
- Users may bounce between summary and workflow; unclear navigation semantics.

## Review workflow options (given current repo state)

Because a dedicated workflow is not implemented today, the “reviews overflow” destination must start as one of:

1) **Placeholder** (minimal): a screen that says “Review inbox not implemented yet”.
2) **Review launcher**: a list of due `review_session` attention items; tapping one marks it `reviewed` (records an `AttentionResolution`) and/or opens a placeholder step page.
3) **True workflows** (future): implement separate experiences per `review_type`:
   - Values alignment review
   - Progress review
   - Journal insights review
   - Balance review
   - Pinned tasks check

A common enabling mechanism:
- Use `AttentionItem.metadata['review_type']` to route to the appropriate workflow.

## Enabling project-health reviews (design considerations)

The backlog proposal outlines how to enable project-health review rules by extending review evaluation:
- Dispatch review evaluation based on `entity_type`:
  - `review_session`: keep scheduled/frequency logic
  - `project`: predicate-driven (reactive) logic

Key design questions:
- Definition of “allocatable tasks” for `noAllocatableTasks`
- Gating persistence location (attention runtime state vs allocation settings)
- Importance scoring formula for `highValueNeglected`
- Sorting/top-K behavior per rule
- UI grouping (project reviews together with review sessions vs separated)

## Recommended next steps (sequencing)
1) Treat “attention overflow destination” as its own feature.
2) Start with an overflow placeholder to unblock banner UX.
3) Separately design and implement:
   - Review workflows per review type
   - Project-health review evaluation
   - A non-review attention inbox (issues/allocation)

## Notes
- This doc reflects analysis as of 2026-01-14.
- It can be converted into a formal plan once the product decisions (destination structure, workflow scope) are confirmed.
