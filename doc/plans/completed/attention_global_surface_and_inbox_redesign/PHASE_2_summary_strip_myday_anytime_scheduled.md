# Plan Phase 2: Summary strip placement + hide-when-zero animation

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T01:00:44Z

## Goal

Implement the **attention summary strip** on:
- My Day (`my_day`)
- Anytime (`someday`)
- Scheduled (`scheduled`)

Rules:
- Summary is **in-content near the top** (not pinned).
- Summary **hides when counts are zero**, with a calm **fade/size** collapse.
- Summary content: **two chips** `Reviews • n` + `Alerts • n` + optional severity hint
  (conditional “C”) as previously agreed in chat.
- Tap behavior: tapping strip navigates to inbox (same as bell).

Aligned decisions:
- [doc/plans/ui_decisions/2026-01-16_attention-placement-matrix.md](../../ui_decisions/2026-01-16_attention-placement-matrix.md)

## Scope

- Add/position `attentionBannerV2` (or a new light wrapper around it) so it is
  rendered in-content near the top for the 3 target screens.
- Implement hide-when-zero as a UI concern in the renderer (no domain changes).
- Ensure summary copy does not imply it is scoped to the current screen filters.

## Design notes to capture (source: chat)

- B-001: A + conditional C
- B-002: tap navigates to inbox
- B-003: hide with fade/size animation

If any of the above are not yet captured in a UI decision log, add a short log
entry before implementing (or amend an existing accepted decision) **only if the
team wants the record**.

## Likely touch points

- `lib/presentation/screens/templates/widgets/attention_app_bar_accessory.dart`
  (may be reduced in importance or adapted)
- `lib/presentation/screens/templates/renderers/attention_banner_section_renderer_v2.dart`
- `lib/presentation/screens/templates/screen_template_widget.dart`
- Potentially `lib/domain/screens/catalog/system_screens/system_screen_specs.dart`
  to add `attentionBannerV2` header module to `scheduled`.

## Acceptance criteria

- Summary strip appears on `my_day`, `someday`, `scheduled` when counts > 0.
- Summary strip is hidden (animated collapse) when counts == 0.
- Tap on strip navigates to `review_inbox`.
- No new analyzer issues introduced.

## AI instructions

- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes.
- Do not run tests unless explicitly requested.
- When complete, update:
  - `Last updated at:` (UTC)
  - Summary of changes
  - Phase completion timestamp (UTC)

## Phase completion

Completed at: 2026-01-16T01:00:44Z

Summary:
- Added `attentionBannerV2` header module to `scheduled`.
- Forced My Day / Anytime / Scheduled to keep header accessory in-content by setting `showHeaderAccessoryInAppBar: false`.
- Updated the banner renderer to behave as the Summary Strip: Reviews/Alerts chips + optional critical hint, and animated hide-when-zero.
- Verified `flutter analyze` is clean.
