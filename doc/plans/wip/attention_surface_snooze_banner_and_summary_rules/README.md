# Plan: Attention surface — Snooze banner + summary placement rules

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T00:00:00Z
Status: WIP

## Summary

Implement the agreed attention surface behavior (post UX101B):

- Global bell uses **UX101B**: count badge + severity halo (no layout shift).
- **Anytime (`someday`)** keeps the in-content summary strip, positioned **below filters and above task list**.
- **Scheduled (`scheduled`)** removes the in-content summary strip (capacity/agenda focus), relying on the global bell for discovery.
- **My Day (`my_day`)** removes the summary strip and instead shows a **critical-only banner** that requires user action:
  - Actions: `Review` (go to inbox) and `Snooze` (time-based Snooze A)
  - No silent dismiss; banner hides only via `Review`/`Snooze` or when critical count reaches zero.
- Copy for the critical banner and snooze sheet uses **UX-COPY-002**.

## Key UX decisions captured

- **UX101B**: Bell shows count + severity halo.
- **Summary placement rule**:
  - Anytime: yes (below filters)
  - Scheduled: no
  - My Day: no (critical-only banner instead)
- **Escalation rule** (My Day): critical-only, obvious but not alarming; must `Review` or `Snooze`.
- **Snooze A** (time-based): `Later (2h)`, `Later today (4h)`, `Tomorrow morning`, `Pick time…`.
- **Copy (UX-COPY-002)**:
  - Banner title: “Something needs attention”
  - Banner subtitle: “Critical items are waiting. Review or snooze for later.”
  - Snooze sheet title: “Snooze for later”
  - Snooze helper: “We’ll hide this banner until your chosen time.”

## Architecture alignment (must keep)

- Unified Screen Model invariants (presentation boundary, module/template rendering):
  - [doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md](../../architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md)
- Attention System evaluation + suppression semantics:
  - [doc/architecture/ATTENTION_SYSTEM_ARCHITECTURE.md](../../architecture/ATTENTION_SYSTEM_ARCHITECTURE.md)

## Recommended persistence approach for snooze

Use an attention-system-aligned suppression record (not UI-local state).

- Preferred approach: implement snooze using a **synthetic “surface prompt” AttentionRule** (system rule), so snooze is stored as an `AttentionResolution` (action: snoozed) with a `snooze_until` timestamp and/or runtime `nextEvaluateAfter`.
- The banner visibility should be derived from:
  - `criticalCount > 0`, AND
  - `now >= snoozeUntil` (or no active snooze record)

## Phases

- Phase 1: Summary strip placement rules (Anytime vs Scheduled)
- Phase 2: My Day critical banner (UX-COPY-002) + Snooze A UI
- Phase 3: Snooze persistence via Attention System suppression semantics
- Phase 4: Polish + a11y + verify analyzer clean (final phase)
