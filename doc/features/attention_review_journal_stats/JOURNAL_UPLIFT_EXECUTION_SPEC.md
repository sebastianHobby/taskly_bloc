# Journal Uplift Execution Spec

Status: Active
Owner: Codex (implementation session)
Last updated: 2026-02-26

## Objective

Iteratively align Journal UI/UX with `doc/journal_uplift/*` mockups while
preserving existing architectural and product constraints.

## Hard constraints

- No database/schema changes.
- No significant backend functionality changes.
- Respect user-selected Material theme; no hardcoded colors.
- Keep BLoC-only presentation boundary and all architecture invariants.
- If mockup behavior conflicts with the feature spec, follow confirmed decisions:
  - Keep spec and do not introduce minimum mood filter.
  - Keep spec structure for editor flows; adapt visuals only.
  - Add dedicated insights screen flow.
  - Keep single-screen journal history (no separate history screen).
  - Keep factor-group filtering in UI.

## Scope

Target mockup surfaces:

- `journal_home_dark/screen.png`
- `journal_filters/screen.png`
- `quick_capture_moment/screen.png`
- `moment_detail_edit/screen.png`
- `edit_day_card/screen.png`
- `behavioral_insights_dashboard/screen.png`

## Delivery phases and progress

### Phase 1: Golden harness baseline

- [x] Add deterministic golden harness for journal home + insights.
- [x] Add global test font loading for golden stability.
- [x] Add initial golden baselines.

### Phase 2: Home/feed visual uplift

- [x] Restyle journal home header, section hierarchy, and cards toward mockup.
- [x] Improve timeline card visual density and chip styling.
- [x] Preserve summary-first + single-screen history behavior.
- [x] Golden update and review.

### Phase 3: Filter sheet visual uplift

- [x] Restyle filter sheet to match mockup presentation.
- [x] Keep factor tracker filter + factor-group filter controls.
- [x] Do not add minimum mood filtering.
- [x] Golden update and review.

### Phase 4: Quick capture/edit visual uplift

- [x] Restyle quick-capture entry editor to match mockup appearance.
- [x] Keep grouped accordion and daily-first editor structure per spec.
- [x] Keep save behavior and existing BLoC event semantics.
- [x] Golden update and review.

### Phase 5: Insights visual uplift

- [x] Restyle dedicated insights page cards and hierarchy to match mockup.
- [x] Keep association/evidence copy contract from feature spec.
- [x] Golden update and review.

### Phase 6: Validation and release prep

- [x] `dart analyze` green.
- [x] Relevant journal bloc/widget/golden tests green.
- [x] Summarize residual visual gaps (if any).
- [ ] Commit and push with hooks enabled.

## Progress log

- 2026-02-26: Phase 1 completed with deterministic golden harness + baseline.
- 2026-02-26: Phase 2 completed with home/feed hierarchy + timeline restyle.
- 2026-02-26: Phase 3 completed with filter-sheet uplift while retaining factor group/filter contracts.
- 2026-02-26: Phase 4 completed with quick-capture/editor visual uplift preserving existing behavior semantics.
- 2026-02-26: Phase 5 completed with dedicated insights page visual uplift.
- 2026-02-26: Phase 6 validation complete (analyze + targeted journal tests + goldens); commit/push pending.

## Validation commands

- `dart analyze`
- `flutter test test/presentation/features/journal/bloc/journal_history_bloc_test.dart`
- `flutter test test/presentation/features/journal/journal_hub_page_widget_test.dart`
- `flutter test test/presentation/features/journal/journal_visual_golden_test.dart`
- `flutter test test/presentation/features/journal/journal_visual_golden_test.dart --update-goldens` (when intentionally updating baselines)
