# Summary — global attention surfaces + inbox redesign

Implementation date (UTC): 2026-01-16T01:00:44Z

## What shipped

- Global bell entrypoint in app chrome that navigates to `review_inbox` (hidden on the inbox itself).
- Summary strip (“Reviews” + “Alerts”) placed in-content on My Day / Anytime / Scheduled with hide-when-zero animation.
- Calm My Day hero integration (focus choice + subtle progress) coordinated with the summary strip placement.
- Attention inbox redesign: no tabs, entity-first list with multi-reason support and per-entity action flows.
- Severity-aware bell signaling: fixed-size button with warning/critical badge + halo and no layout shift.

## Known issues / follow-ups

- Verify UI behavior on-device (spacing, overflow, accessibility) for the entity-first inbox and bell across all target screens.
- Consider tightening consistency of plan timestamps (Phase 3 uses fractional seconds; Phase 1/2 were finalized during close-out).
