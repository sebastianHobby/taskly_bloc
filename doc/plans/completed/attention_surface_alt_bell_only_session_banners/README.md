# Plan: Attention surface ALT — Bell-only + session-dismiss banners

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T02:24:35Z
Status: Completed

## Summary

Implement an alternative attention surface UX:

- **Bell-only global indicator** (count badge + halo for max severity). No persistent summary strips.
- **On-enter banners** on selected screens, with **session-scoped dismiss**.
- **No persisted snooze** for banners (no AttentionResolution writes); dismiss is ephemeral UI session state.
- Severity escalation uses **color + icon only** (no size/layout shift).

Locked decisions:
- ALT-001B: Session-scoped dismiss
- ALT-002B: My Day banner (critical only), Anytime banner (warning+critical), Scheduled (none)
- ALT-003A: Escalation styling is icon+tint only

Architecture clarifications (locked):
- UX-ALT-101A: Store banner dismiss in an **app-session scoped** presentation store (survives screen disposal; clears on app restart).
- UX-ALT-102A: Render banner at the **screen template level**, driven by `ScreenSpecBloc` state (avoid per-screen widget special-cases).
- UX-ALT-103: Remove summary strips by changing **typed** system `ScreenSpec`s (no string IDs); keep `screenKey` stable.

## Screen rules

- My Day (`my_day`): show banner only when `criticalCount > 0`.
- Anytime (`someday`): show banner when `criticalCount > 0` OR `warningCount > 0`.
- Scheduled (`scheduled`): no banner.
- All screens: bell shows count + max severity halo, unaffected by banner dismiss.

## UX constraints

- Banner must be **obvious but not alarming**.
- Banner must have stable height; no animated emphasis that feels alarmist.
- Banner dismiss hides it until the app session ends.

## Architecture alignment

- Presentation boundary: widgets do not subscribe to domain/data streams directly; BLoCs own subscriptions.
  - [doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md](../../architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md)
- Attention evaluation stays in domain; presentation consumes derived counts/severity.
  - [doc/architecture/ATTENTION_SYSTEM_ARCHITECTURE.md](../../architecture/ATTENTION_SYSTEM_ARCHITECTURE.md)

## Phases

- Phase 1: Remove/disable summary strips; ensure bell-only indicator
- Phase 2: Add session-dismiss banners on My Day + Anytime (severity icon+tint)
- Phase 3: Polish + a11y + final analyzer pass (last phase)
