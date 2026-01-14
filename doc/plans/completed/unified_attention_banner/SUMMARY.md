# Unified Attention Banner + Inbox — Summary

Implementation date (UTC): 2026-01-14

## What shipped

- New unified screen module: `attention_banner_v1`
  - Domain: `SectionTemplateId.attentionBannerV1`, `ScreenModuleSpec.attentionBannerV1`, `SectionDataResult.attentionBannerV1`.
  - Interpreter: `AttentionBannerSectionInterpreterV1` (counts + preview driven by `AttentionEngineContract.watch`).
  - Presentation: `AttentionBannerSectionRendererV1` wired via `SectionWidget`.
- Overflow screen replacement: “Attention Inbox”
  - Replaced the placeholder `review_inbox` template with a functional inbox page featuring Action/Review tabs and resolution actions.
  - Resolutions recorded via `AttentionRepositoryContract` with `actionDetails` populated for snooze/dismiss.
- System screen migration
  - My Day + Someday header modules migrated to render `attention_banner_v1`.
- Dismiss behavior correctness
  - `AttentionEngine` now exposes computed `state_hash` on `AttentionItem.metadata` so “Dismiss” can persist suppression correctly.

## Validation

- `flutter analyze` clean.
- Recorded test run passed: `build_out/test_runs/20260114_050649Z/summary.md`.

## Known follow-ups / gaps

- Consider wiring `JournalRepositoryContract` into `SectionDataService` if journal-backed sections should be supported in tests/runtime (currently tolerated as optional).
