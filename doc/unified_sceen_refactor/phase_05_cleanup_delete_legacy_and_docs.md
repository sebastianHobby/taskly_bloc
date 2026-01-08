# Phase 05 — Cleanup, Delete Legacy, Update Docs

## Goal

- Delete all legacy code paths, dead models, and obsolete renderers.
- Ensure the codebase is clean and consistent.

## Delete candidates (verify before deleting)

- Any remaining legacy section renderers that are no longer used.
- Any dead screen creator logic that constructs old models.
- Any leftover converters for deleted models.

## Amendments (2026-01-08)

- Delete any remaining legacy “evaluated alert” / allocation-alert UI surfaces that
	duplicate attention-based banners/sections.
- After this phase, allocation warnings and check-in/review surfacing must exist only
	via attention-driven templates.

## Verified delete/retire list (as of 2026-01-08)

These are concrete files/widgets identified during the unified-screen audit.

### Unused today (no callsites)

- `lib/presentation/features/screens/widgets/review_banner.dart` (`ReviewBanner`)
- `lib/presentation/features/screens/widgets/persona_banner.dart` (`PersonaBanner`)
- `lib/presentation/features/screens/widgets/persona_selector.dart` (`PersonaSelector`)
- `lib/presentation/features/screens/widgets/workflow_item_card.dart` (`WorkflowItemCard`)
- `lib/presentation/features/screens/widgets/workflow_progress_bar.dart` (`WorkflowProgressBar`)
- `lib/presentation/widgets/allocation_alert_banner.dart` (`AllocationAlertBanner`)
- `lib/presentation/widgets/outside_focus_section.dart` (`OutsideFocusSection`)
- `lib/presentation/widgets/focus_hero_card.dart` (`FocusHeroCard`)
- `lib/presentation/widgets/my_day_prototype_settings.dart` (`MyDayPrototypeSettings`)

### Used only by legacy allocation-alert rendering (delete once “everything is attention”)

These are currently used via `AllocationSectionRenderer` / `SectionWidget`, but should
be replaced by attention-driven templates/tiles/sections.

- `lib/presentation/features/screens/widgets/urgent_banner.dart` (`UrgentBanner`, `WarningBanner`)
- `lib/presentation/features/screens/widgets/value_balance_chart.dart` (`ValueBalanceChart`)
- `lib/presentation/features/screens/widgets/focus_mode_banner.dart` (`FocusModeBanner`)

### Used only by screen-creator/custom-builder UI (delete once custom builders are removed)

- `lib/presentation/features/screens/widgets/allocation_preview_widget.dart` (`AllocationPreviewWidget`)
- `lib/presentation/features/screens/view/focus_screen_creator_page.dart` (`FocusScreenCreatorPage`)

### Renderers expected to be retired once attention-driven sections replace legacy summaries

- `lib/presentation/features/screens/renderers/allocation_alerts_section_renderer.dart`
- `lib/presentation/features/screens/renderers/check_in_summary_section_renderer.dart`
- `lib/presentation/features/screens/renderers/issues_summary_section_renderer.dart`
- `lib/presentation/features/screens/renderers/attention_support_section_widgets.dart`

### Keep (still referenced)

- `lib/presentation/features/screens/widgets/focus_mode_selector.dart` (`FocusModeSelector`) is used by `UnifiedScreenPage`.

## Repo-wide sweep report (2026-01-08)

See `doc/unified_sceen_refactor/phase_05_unused_presentation_widgets_sweep.md` for a
repo-wide list of **41** presentation files whose public classes appear to have no
references from any other `lib/**/*.dart` file.

Notes:
- This is a heuristic scan (string-based) intended to accelerate Phase 05.
- The scan ignores `test/**` references; a file can be “unused in app” but still used
	by tests.

## Required checks

Repository-wide searches must return 0 matches:
- `supportBlocks|support_blocks`
- `SupportBlockComputer|SupportBlock\b`
- `primaryEntityType`
- `List<dynamic> primaryEntities`
- `registerScreenBuilders|_screenBuilders`
- `NavigationOnlyScreenDefinition`
- `RenderMode\.custom|renderMode\b`

Suggested single search pattern (regex) to run repeatedly until clean:

- `SupportBlockComputer|SupportBlock\b|supportBlocks\b|support_blocks\b|primaryEntityType\b|registerScreenBuilders\b|_screenBuilders\b|NavigationOnlyScreenDefinition|RenderMode\.custom|renderMode\b`

## Validation
- `flutter analyze`

## Completion criteria
- End-state architecture matches Phase 00.
- `flutter analyze` clean.
