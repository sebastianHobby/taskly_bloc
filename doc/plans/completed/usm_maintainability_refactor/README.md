# USM Maintainability Refactor (WIP)

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15T00:00:00Z

## Goal
Implement a set of refactors to improve maintainability and create a clean, consistent mental model for the Unified Screen Model (USM) pipeline.

This plan implements the following approved design decisions:
- USM-001: **Option B** (dedicated Actions BLoC/Cubit)
- USM-002: **Option B + A** (renderer registry in presentation + interpreter/module registry in domain)
- USM-003: **Option A** (sealed `SectionVm` hierarchy)
- USM-004: **Option B** (localized section errors; reserve screen-level errors for truly fatal cases)
- USM-005: **Option A** (value types for identity: screen key, template id, persistence keys)

## Non-goals / constraints
- No UI/UX redesign in this plan; behavior should remain stable (unless explicitly called out).
- No new architectural pattern beyond the approved choices.
- Follow the presentation boundary rule: widgets/pages must not call repositories/domain services directly and must not own cross-layer stream subscriptions.

## Planning principle (important)
This plan is intentionally **strict about responsibilities and invariants** (what must be true), but **flexible about exact class/file names and method lists** (how to achieve it) so it stays correct even if code shape shifts during refactors.

Implementation guidance:
- Derive required public APIs from current call sites (grep-driven) instead of pre-adding speculative methods.
- Follow existing DI/logging conventions in the repo over hardcoded snippets.
- Minor reordering within a phase is allowed if it reduces churn, as long as it does not change the approved design decisions.

## Files (phases)
- Phase 01 — Actions: `phase_01_actions_bloc.md`
- Phase 02 — Registries: `phase_02_registries.md`
- Phase 03 — Identity value types: `phase_03_identity_value_types.md`
- Phase 04 — Sealed SectionVm: `phase_04_sealed_section_vm.md`
- Phase 05 — Error semantics + cleanup: `phase_05_error_semantics_and_cleanup.md`

## Definition of done
- `flutter analyze` passes with 0 errors and 0 warnings.
- Typed USM path (`ScreenSpec`) has:
  - presentation-only widgets (no domain/service calls)
  - clear interpreter/renderer registration
  - strongly-typed section VMs
  - localized section-level errors
  - value-type IDs for stable identity.
- Architecture docs updated where responsibilities/flows changed.
