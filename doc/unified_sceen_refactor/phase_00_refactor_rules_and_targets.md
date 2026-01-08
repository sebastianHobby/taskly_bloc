# Phase 00 — Refactor Rules & Targets (Hard Enforcement)

This folder contains an **AI-first implementation plan** for refactoring Taskly’s unified screen system.

The plan is intentionally **non-backwards-compatible**.

## AI Instructions (read first)

- Work phase-by-phase. Do **not** start a later phase until the current phase finishes with:
  - `flutter analyze` reporting **0 errors** (for non-test code).
  - Fix **all warnings** that are directly caused by the refactor (don’t chase unrelated pre-existing warnings unless unavoidable).
  - Run `dart fix --apply` when it reduces churn, then run `dart format` (or use editor formatting).
- Do **not** run tests.
- Delete legacy code as specified in each phase. Do **not** keep compatibility layers.
- Prefer small, mechanical commits per phase (even though commits are not required).

## Amendments (2026-01-08)

These are product/UX decisions that must be treated as constraints during the refactor.
They do not change the refactor architecture, but they do change the semantics of certain
section templates.

### Attention is the single surfacing system

- **Everything is attention.** All surfaced warnings/alerts must be represented as
  `AttentionItem`s (computed from rules + data + resolutions).
- Avoid running parallel UI pipelines that duplicate the same user-facing signal.

**Workflows:**

- Remove `workflowStep` as a first-class attention concept.
- The triage flow is computed only from attention item state (no `workflowStep` rules/items).

### Naming: "Review" vs "Resolve" (accepted)

- **Review**: the periodic ritual (values/progress/balance/etc.) surfaced as a single
  global-cadence attention item.
- **Resolve**: the computed triage flow used when attention volume is high.
- Avoid using the term "workflow" in user-facing copy for these. "Workflow" may remain
  as an internal implementation detail until refactor phases remove/replace it.

### Review UX shape: Hybrid (1C) (accepted)

- Review is a **single consolidated experience** (one canonical Review entry point and
  one consolidated surface), composed of multiple section templates.
- The Review surface is **hybrid**: it may contain multiple heterogeneous sections
  (e.g., progress/balance/wellbeing/pinned tasks), but it must not fragment into
  per-type review subflows that feel like separate screens.

### Reviews are a single global ritual (not per-type schedules)

- Reviews/check-ins are a single **Review ritual** with **one global cadence**.
- The ritual bundles all enabled review types.
- Review type enable/disable is handled via **existing attention rule toggles**
  (`AttentionRule.active`) — no new review-type settings UI.
- Completion semantics (V2): completing occurs **on open** of the review workflow.

**Recommended persistence approach (accepted):**

- Persist the global cadence + last completion using the existing attention tables by
  introducing (or seeding) a single dedicated attention rule row:
  - `ruleKey: "review_ritual"`
  - `ruleType: review`
  - `triggerConfig: { "cadence_days": <int> }`
  - Resolutions use a constant `entityId: "review_ritual"` (global ritual identity).
- Keep the existing per-review-type rules as **toggles only** (their `frequency_days`
  becomes non-authoritative under the global cadence model).

**Defaults + canonical persistence keys (accepted):**

- If `review_ritual` is missing on an existing profile, seed it with a sensible default
  cadence:
  - `triggerConfig: { "cadence_days": 7 }` (weekly)
- Use these exact `action_details` JSON keys in `attention_resolutions`:
  - Snooze: `{ "snooze_until": "<ISO-8601 timestamp>" }`
  - Dismiss: `{ "state_hash": "<stable fingerprint string>" }`

Implementation note: the repository dismissal comparison uses `action_details.state_hash`,
so the key must remain `state_hash` (not `stateHash`).

### Banner/workflow behavior (click-only)

- A separate **Review banner** exists and always launches **Review** on click.
- A **Main attention banner** exists for all other attention types:
  - click expands inline if $\le \texttt{workflow\_threshold}$ items
  - click launches **Resolve** if $> \texttt{workflow\_threshold}$ items
- Navigation is **only on click** (no auto-navigation).

**Configurable threshold (accepted):**

- The $5$ threshold is a template parameter on `attention_banner` with default `5`.

### Workflow grouping (accepted)

- Group workflow items by **entity type**, grouping by **project** where possible so
  a project and its linked tasks appear together.
- Unparented tasks appear under a pseudo parent project group named "Inbox".

Terminology alignment:
- Apply this grouping to the **Resolve** experience.

### Allocation attention is not streamed (accepted)

- Allocation-related attention items follow a different evaluation model:
  - Allocation engine computes excluded tasks/settings.
  - Allocation service calls an evaluator method, passing the allocation inputs.
  - Evaluator returns attention items for allocation.
- Allocation warnings/errors are not part of the unified attention streaming source.

### Allocation warnings surface as normal attention (accepted)

- Allocation warnings must surface as normal attention items/sections (dismissable via
  resolution state-hash like other attention items).
- Screen definitions/templates may opt into which attention types they surface.
  Avoid hardcoding a single global “allocation warnings UI” pipeline outside the
  attention surfacing model.

### Values footer is the canonical value UI (accepted)

For both tasks and projects, value metadata must use the shared `ValuesFooter`
semantics everywhere it appears:

- Primary value: solid chip
- Secondary values: outlined chips

Avoid alternate renderers (e.g., “all values are identical chips” or custom
`Chip` rows) to keep meaning consistent across list tiles, cards, and entity
headers.

## Scope / UX constraints

- Implement exactly the UX described by the phases.
- Do **not** add new pages, flows, filters, modals, animations, or “nice-to-have” features.
- Refactors may move code, but must not introduce new product behavior beyond what’s required to preserve existing capabilities.

## Hard Enforcement Rules

### Rule A — NO `supportBlocks`

**No `supportBlocks` field remains anywhere**.

- Delete the `supportBlocks` field from screen models.
- Delete `SupportBlock` models, computers, and interpreter logic.
- All prior support behavior must be represented as **section templates** (via `SectionRef` + template registry), rendered inline within the `sections` list.

Verification commands:

- Search repository (regex) and require **0 matches** at the end of Phase 01 and beyond:
  - `SupportBlockComputer|SupportBlock\b|supportBlocks\b|support_blocks\b`

### Rule B — Single screen rendering pipeline

All navigable screens must flow through the same screen rendering path:

`route /:segment` → `ScreenDefinition` lookup → `sections` list → template interpreters/renderers.

No "navigation-only" screen variant that bypasses section rendering.

Repo-verified anti-targets (must be deleted by end of Phase 04):

- `NavigationOnlyScreenDefinition`
- `RenderMode.custom` / persisted `renderMode`
- `registerScreenBuilders` / `_screenBuilders`

### Rule C — Declarative sections only

Persisted screen configuration must reference sections as:

- `SectionRef(templateId, params, overrides)`

Templates are defined in code; users select templates and configure parameters.

Repo-verified anti-targets (must be deleted by end of Phase 02):

- `Section` union-based persisted screens
- Switch/when-based section interpretation (replace with registries)

### Rule D — Mixed entity lists are first-class

The system must support a single section producing a list of mixed entities (e.g. tasks + projects) that render differently.

Repo-verified anti-targets (must be deleted by end of Phase 03):

- `primaryEntityType` string discriminators
- `List<dynamic> primaryEntities`

## Target Architecture (end-state)

### Data model
- `ScreenDefinition`
  - screen metadata (key/name/icon/badge/fab/appbar)
  - `sections: List<SectionRef>` (no legacy `Section` union)

- `ScreenChrome`
  - groups screen metadata (icon/badge/fab/appbar/etc.) as a single field on
    `ScreenDefinition`.

- `SectionRef`
  - `templateId: String`
  - `params: Map<String, dynamic>` (typed per template via Freezed models)
  - `overrides` (optional: title, enabled, etc.)

### Execution model
- `ScreenDataInterpreter` becomes a coordinator:
  - iterates `SectionRef`s
  - resolves template interpreter from registry
  - emits `ScreenData(sections: List<SectionVm>)`

- Presentation rendering:
  - `UnifiedScreenPage` renders `SectionVm`s using a renderer registry keyed by `templateId`.

### Support behaviors
Support behaviors previously implemented as `SupportBlock`s become **section templates**:
- `issues_summary`
- `check_in_summary`
- `allocation_alerts`
- `entity_header`

## Phase list (files in this folder)

- Phase 01: Remove SupportBlocks entirely; introduce equivalent support-section templates.
- Phase 02: Replace `Section` with `SectionRef` and introduce template registries.
- Phase 03: Introduce typed `ScreenItem` + tile registry; implement `interleaved_list`.
- Phase 04: Unify all “custom screens” as specialized templates; remove custom routing builders.
- Phase 05: Cleanup + delete legacy files, update docs.

## Per-phase verification checklist (repeat every phase)

At the end of every phase:

1. Run `flutter analyze` and fix all issues caused by the refactor.
2. Run a repository search with this regex; keep iterating until matches are expected for the current phase only:

- `SupportBlockComputer|SupportBlock\b|supportBlocks\b|support_blocks\b|primaryEntityType\b|registerScreenBuilders\b|_screenBuilders\b|NavigationOnlyScreenDefinition|RenderMode\.custom|renderMode\b`

Expected zero-match milestones:

- End of Phase 01: no support block symbols.
- End of Phase 03: no `primaryEntityType` / `List<dynamic>` list payloads.
- End of Phase 04: no custom render mode / screen builders.
- End of Phase 05: all patterns above are zero-match.
