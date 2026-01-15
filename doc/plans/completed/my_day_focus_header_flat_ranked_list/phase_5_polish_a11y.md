# WIP Plan — Phase 5: Polish, accessibility, and guardrails

Created at: 2026-01-15T05:09:10.4635911Z
Last updated at: 2026-01-15T06:30:00Z

## Purpose
Ensure the new My Day experience is polished, mobile-first, and doesn’t regress other screens.

## Items
- Accessibility:
  - Ensure `Change` has a clear semantic label (e.g., “Change focus mode”).
  - Ensure value dots/badges have semantics (“Aligned to <value>”).
  - Ensure tap targets >= 44px.
- Visual density:
  - Ensure header card height stays compact on mobile.
  - Ensure the list remains the primary visual focus.
- Regression guardrails:
  - Confirm other screens using hierarchy/value grouping remain unchanged.
  - Prefer scoping My Day behavior by rendering a dedicated My Day `SectionVm` variant (rather than `screenKey == my_day` branching).
  - Keep My Day-only widgets/private helpers in the My Day section renderer/widget unless reuse becomes obvious.
- Documentation:
  - Add/update a small note in the relevant architecture/product doc if behavior changes are meaningful.

## Notes (implemented)
- Expansion behavior: implemented as **single-expanded (accordion)** for simplicity and to keep the ranked list scannable on mobile.

## Acceptance criteria
- My Day reads clearly on a narrow viewport.
- No accidental behavior changes in Anytime/Scheduled.

## AI instructions
- Review `doc/architecture/` before implementing this phase.
- Run `flutter analyze` for this phase.
- In this last phase, fix any `flutter analyze` error or warning (even unrelated).
