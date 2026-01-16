# UI Decision: Attention placement matrix across navigation screens

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T00:00:00Z
Status: Accepted
Owner: Taskly (UX)

## Context

- Attention (“Reviews/Alerts”) is **global triage**, not scoped to the current
  screen’s filters or hierarchy.
- We want attention to be **noticed but not overwhelming**.
- We want a consistent mental model:
  - A single global entrypoint (bell).
  - Optional glanceable summary only on the screens where it helps planning and
    execution.

## Unified Screen Model Alignment

- Screens:
  - `my_day`, `scheduled`, `someday` (Anytime), `journal`, `values`,
    `statistics`, `settings`, `review_inbox`
- Template(s): `standardScaffoldV1` plus non-standard templates (settings,
  statistics, etc.)
- Section(s) / module(s):
  - Summary: `ScreenModuleSpec.attentionBannerV2`
  - Inbox: `ScreenModuleSpec.attentionInboxV1`
- Presentation chrome:
  - AppBar accessory strip (optional): `spec.chrome.showHeaderAccessoryInAppBar`
    + `AttentionAppBarAccessory`

## Current behavior (as of 2026-01-16)

- The attention summary module (`attentionBannerV2`) is included in system specs
  for:
  - `my_day` (header slot)
  - `someday` ("Anytime"; header slot)
- The Attention inbox is a system screen:
  - `review_inbox` (screen name: “Attention”) rendering `attentionInboxV1`

## Impact Summary

- Other screens affected: any screen that adds `attentionBannerV2` to header
  modules.
- Shared components/widgets affected:
  - AppBar bell action (new or existing)
  - `AttentionBannerSectionRendererV2` (summary)
  - `AttentionInboxSectionRendererV1` (inbox)
- Design tokens/theme impacts: may add tokens for severity halo/badge styling.

## Options

### UX-MTX-001 — Global entrypoint (bell) behavior

- A) Bell opens an intermediate summary surface, then links to inbox.
- B) Bell navigates **directly** to the Attention inbox.
- C) Bell behavior depends on count (e.g., no-op at zero).

Recommendation: B

### UX-MTX-002 — Where to show the summary module (`attentionBannerV2`)

- A) Show on every navigation screen.
- B) Show only on “planning + execution” screens.
- C) Show only on planning screens.

Recommendation: B + include `scheduled`.

### UX-MTX-003 — Visibility rules

- A) Summary is always visible (even at zero).
- B) Summary hides when counts are zero; bell remains (no badge).
- C) Summary collapses to an “All caught up” state.

Recommendation: B

### UX-MTX-004 — Summary placement relative to filters/scope

- A) Summary is an AppBar accessory strip.
- B) Summary is in-content near the top (not pinned).
- C) Summary is pinned with filters/scope.

Recommendation: B

## Decision

- Chosen:
  - UX-MTX-001B
  - UX-MTX-002B + `scheduled`
  - UX-MTX-003B
  - UX-MTX-004B

## Placement matrix (accepted baseline)

Key:
- **Bell** = global AppBar affordance; tap → Attention inbox (`review_inbox`).
- **Summary** = compact in-content strip/card; tap → inbox.
- **Inbox** = the Attention screen itself.

1) My Day (`my_day`) — execution + gentle planning
- Bell: Yes
- Summary: Yes (near top; can be integrated into the hero area)

2) Anytime (`someday`) — backlog grooming + planning
- Bell: Yes
- Summary: Yes (below scope/filter row; above list)

3) Scheduled (`scheduled`) — date review + planning
- Bell: Yes
- Summary: Yes (above agenda feed)

4) Journal (`journal`) — reflection / wellbeing
- Bell: Yes
- Summary: No

5) Values (`values`) — identity/priority definition
- Bell: Yes
- Summary: No

6) Statistics (`statistics`) — insight dashboard
- Bell: Yes
- Summary: No

7) Settings (`settings`) — configuration
- Bell: Yes
- Summary: No

8) Attention inbox (`review_inbox`) — triage workspace
- Bell: No (avoid self-navigation)
- Summary: No (redundant)

## Visual/interaction mocks (text wireframes)

Notation:
- `🔔` bell icon
- `◉` subtle halo ring (severity)
- `•n` badge count

### My Day (`my_day`) — bell + summary (calm header)

Mock A (recommended):

```text
[AppBar: My Day                              ◉🔔•3 ]

[Hero Card]
  Focus: <name>                         [Change]
  Reviews • 2     Alerts • 1                    >
  Progress: 3/9 done   [----●-----]   [Day Summary ⌄]
------------------------------------------------------
[Primary content]
  Today’s mix …
  Task list …
```

Mock B (alt):

```text
[AppBar: My Day                              ◉🔔•3 ]

[Hero Card]
  Focus: <name>                         [Change]
  Progress: 3/9 done   [----●-----]   [Day Summary ⌄]

[Summary strip]  Reviews • 2    Alerts • 1                 >
-----------------------------------------------------------
[Primary content] …
```

### Anytime (`someday`) — bell + summary below filters

Mock A (recommended):

```text
[AppBar: Anytime                             ◉🔔•3 ]

[Scope/Filter Row]  [Value ▼] [Focus only] [Include future] [Clear]
[Summary strip]     Reviews • 2    Alerts • 1                 >
--------------------------------------------------------------
[Backlog list / hierarchy / grouped content...]
```

### Scheduled (`scheduled`) — bell + summary above agenda

Mock A (recommended):

```text
[AppBar: Scheduled                           ◉🔔•3 ]

[Summary strip]  Reviews • 2    Alerts • 1                 >
-----------------------------------------------------------
[Agenda feed]
  Today
   - item…
  Tomorrow
   - item…
```

### Journal (`journal`) — bell only

```text
[AppBar: Journal                              ◉🔔•3 ]

[Journal header modules...]
[Today entries...]
```

### Values (`values`) — bell only

```text
[AppBar: My Values                            ◉🔔•3   + ]

[Values list...]
[Create value CTA...]
```

### Statistics (`statistics`) — bell only

```text
[AppBar: Statistics                           ◉🔔•3 ]

[Dashboard content...]
```

### Settings (`settings`) — bell only

```text
[AppBar: Settings                             ◉🔔•3 ]

[Settings menu...]
```

### Attention inbox (`review_inbox`) — no bell, no summary

```text
[AppBar: Attention                              (no bell) ]

[Inbox filters/tabs: Reviews | Alerts | All]
[List of attention items...]
```

## Consequences

- Positive:
  - Consistent global behavior: bell → inbox everywhere.
  - Calm default chrome; summary only where it aids planning/execution.
  - Summary placement avoids competing with screen titles.
- Trade-offs / risks:
  - Summary not visible on every screen; mitigated via severity-aware bell badge
    and consistent navigation.

## Follow-ups

- Confirm the final visual spec for severity halo/badge (colors/intensity and
  thresholds) without layout shift.
- Ensure summary copy/structure does not imply scoping to the current screen.
- Revisit whether any non-navigation screens should opt into summary (likely no
  by default).
