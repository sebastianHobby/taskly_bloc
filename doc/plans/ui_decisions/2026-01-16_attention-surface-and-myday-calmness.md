# UI Decision: Attention surface + calm My Day

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T00:00:00Z
Status: Accepted
Owner: Taskly (UX)

## Context

- We need a **global** way to surface “Reviews/Alerts” (attention items) without
  competing with screen titles, while keeping the UX calm and wellbeing-aligned.
- Attention is **not scoped** to the current screen’s filters/scope. It is an
  app-wide triage queue.
- We want a consistent mental model:
  - **See** attention status quickly.
  - **Act** by going to the Attention inbox.
  - Don’t let attention chrome dominate day execution.

## Unified Screen Model Alignment

- Screen(s): `my_day`, `someday`, `review_inbox`
- Template(s): `standardScaffoldV1`
- Section(s) / module(s):
  - `ScreenModuleSpec.attentionBannerV2` (summary)
  - `ScreenModuleSpec.attentionInboxV1` (inbox)
  - Presentation hoist behavior: `spec.chrome.showHeaderAccessoryInAppBar` +
    `AttentionAppBarAccessory`

## Current behavior (as of 2026-01-16)

- Attention summary module (`attentionBannerV2`) is included in system specs for:
  - `my_day` (header slot)
  - `someday` ("Anytime"; header slot)
- Attention inbox is a system screen:
  - `review_inbox` (screen name: “Attention”) rendering `attentionInboxV1`
- The standard scaffold can optionally hoist the attention banner into the AppBar
  bottom (`AttentionAppBarAccessory`) when
  `spec.chrome.showHeaderAccessoryInAppBar` is true.

## Impact Summary

- Other screens affected: any screen using `standardScaffoldV1` and/or adding
  `attentionBannerV2` to header modules.
- Shared components/widgets affected:
  - `AttentionAppBarAccessory`
  - `AttentionBannerSectionRendererV2`
  - filter/scope rows that may host an attention affordance
- Design tokens/theme impacts: none required for the decision; follow-ups may add
  tokens for severity halo/badge.

## Options

### UX-011 — Global placement rule (summary vs icon)

- A) Always show attention summary in AppBar (accessory strip).
- B) Always show attention summary as an in-content header module.
- C) Always show a **single bell icon** in the AppBar; show summary module only
  on selected screens where it supports the user’s workflow.

Recommendation: C — consistent access everywhere, minimal chrome by default.

### UX-014 — Visibility rule (hide when zero)

- A) Always show “Reviews/Alerts” UI even at zero.
- B) Hide the attention summary row/module when review+alert counts are zero;
  keep the bell icon (no badge) available.

Recommendation: B — reduces noise and supports a calm baseline.

### UX-022/027/028/029/030 — My Day layout (calm, values-aligned)

- A) “Hero card” header: focus choice + day summary entry point + subtle
  progress + bell (attention).
- B) “Command bar” header: dense controls + multiple chips.

Recommendation: A — calmer, less performative, more wellbeing-oriented.

### UX-028 — Attention navigation (tap model)

- A) Bell opens an intermediate summary sheet.
- B) Bell navigates **directly** to the Attention inbox.

Recommendation: B — fewer steps for triage; keeps My Day calm.

### UX-030 — Severity signaling (noticeable but non-alarming)

- A) Change layout/size based on severity.
- B) Fixed-size bell with severity-driven badge/halo (no layout shift).

Recommendation: B — stable layout + clear escalation.

## Decision

- Chosen: UX-011C + UX-014B + UX-022A + UX-028B + UX-030B
- Rationale:
  - Keeps attention global and always reachable, without hijacking the screen.
  - Uses minimal, consistent affordances; promotes calm “default” states.
  - Avoids layout jitter while still making critical items hard to miss.

## Consequences

- Positive:
  - Consistent cross-screen interaction: bell → Attention inbox.
  - Lower cognitive load on execution screens (My Day).
  - Works naturally with USM: attention remains a module where appropriate.
- Trade-offs / risks:
  - If we reduce summary visibility too much, some users may miss attention
    counts; mitigated via badge/halo and selective summary on key screens.
  - AppBar accessory strip becomes less central; may need migration/cleanup.

## Follow-ups

- Define “where summary appears” rule-of-thumb:
  - Show summary module on: `my_day`, `someday` (Anytime) (planning + execution).
  - Do not show summary module on: settings/trackers/statistics/journal screens
    (configuration/insights flows); keep only the bell.
  - Re-evaluate `scheduled` once we confirm whether attention materially helps
    that workflow.
- Decide whether to disable `showHeaderAccessoryInAppBar` for screens using the
  calm direction (prefer in-content placement or hero integration).
- Ensure the attention summary wording does not imply it is scoped to the
  current screen’s filters.
