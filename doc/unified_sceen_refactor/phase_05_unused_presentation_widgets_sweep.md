# Repo-wide unused presentation widgets sweep

Generated: 2026-01-08 13:33:13

Heuristic: a presentation file is listed if *none* of its public class names (PascalCase) are referenced from any other lib/**/*.dart file.

Future-state pruning: if the unified-screen refactor plan explicitly calls out a widget as part of the intended end-state, it is removed from this candidate list even if it is currently unused.

Second pass (Phase 00–04 scan): candidates are pruned when any of their class names (word-boundary match) appear in Phase 00–04 refactor docs.

Composition sanity check:
- In Dart, if a widget is part of another widget’s composition, its class name
	must appear somewhere in `lib/**` (you can’t “use” a widget without referring
	to its symbol).
- Therefore, if something like `ValuesFooter` were required by a future-state
	`ProjectCard`, it would not be listed here.
- As an extra guard, we verified there are no `import ...values_section.dart`,
	`import ...truncated_value_chips.dart`, or `import ...value_emoji_icons.dart`
	statements anywhere under `lib/**`.

Found 41 candidate files.

## Candidates

- lib\presentation\features\analytics\widgets\distribution_chart.dart (DistributionChart)
- lib\presentation\features\analytics\widgets\insight_card.dart (InsightCard)
- lib\presentation\features\analytics\widgets\stat_card.dart (StatCard)
- lib\presentation\features\next_action\widgets\pinned_section.dart (PinnedSection)
- lib\presentation\features\next_action\widgets\reflector_info_banner.dart (ReflectorInfoBanner)
- lib\presentation\features\next_action\widgets\values_required_gateway.dart (ValuesRequiredGateway)
- lib\presentation\features\screens\models\workflow_screen.dart (WorkflowScreen)
- lib\presentation\features\screens\widgets\persona_banner.dart (PersonaBanner)
- lib\presentation\features\screens\widgets\persona_selector.dart (PersonaSelector)
- lib\presentation\features\screens\widgets\review_banner.dart (ReviewBanner)
- lib\presentation\features\screens\widgets\workflow_item_card.dart (WorkflowItemCard)
- lib\presentation\features\screens\widgets\workflow_progress_bar.dart (WorkflowProgressBar)
- lib\presentation\features\tasks\services\upcoming_tasks_grouper.dart (TaskDateEntry, ProjectDateEntry, UpcomingTaskEntry, UpcomingProjectEntry, UpcomingTasksGrouper)
- lib\presentation\features\values\widgets\value_detail_modal.dart (ValueDetailModal)
- lib\presentation\features\values\widgets\values_list.dart (ValuesListView)
- lib\presentation\features\wellbeing\widgets\mood_selector.dart (MoodSelector)
- lib\presentation\features\workflow\bloc\workflow_definition_bloc.dart (WorkflowDefinitionBloc)
- lib\presentation\theme\allocation_theme.dart (AllocationTheme)
- lib\presentation\widgets\allocated_task_tile.dart (AllocatedTaskTile)
- lib\presentation\widgets\allocation_alert_banner.dart (AllocationAlertBanner)
- lib\presentation\widgets\entity_card.dart (EntityCard)
- lib\presentation\widgets\filters\date_range_filter.dart (DateRangeFilter)
- lib\presentation\widgets\filters\entity_multi_select.dart (EntityMultiSelect)
- lib\presentation\widgets\filters\selection_mode_choice.dart (SelectionModeChoice)
- lib\presentation\widgets\focus_hero_card.dart (FocusHeroCard)
- lib\presentation\widgets\form_fields\form_builder_completion_toggle_modern.dart (FormBuilderCompletionToggleModern)
- lib\presentation\widgets\form_fields\form_builder_date_picker_modern.dart (FormBuilderDatePickerModern)
- lib\presentation\widgets\form_fields\form_builder_entity_type_picker.dart (FormBuilderEntityTypePicker)
- lib\presentation\widgets\form_fields\form_builder_enum_field.dart (FormBuilderEnumRadioGroup, FormBuilderSegmentedField)
- lib\presentation\widgets\form_fields\form_builder_mood_rating_field.dart (FormBuilderMoodRatingField)
- lib\presentation\widgets\form_fields\form_builder_number_field.dart (FormBuilderNumberField, NumberInputTile)
- lib\presentation\widgets\form_fields\form_builder_project_picker_modern.dart (FormBuilderProjectPickerModern)
- lib\presentation\widgets\form_fields\form_builder_radio_card_group.dart (FormBuilderRadioCardGroup, RadioCardOption)
- lib\presentation\widgets\form_shell.dart (FormShell)
- lib\presentation\widgets\my_day_prototype_settings.dart (MyDayPrototypeSettings)
- lib\presentation\widgets\outside_focus_section.dart (OutsideFocusSection)
- lib\presentation\widgets\problem\task_preview_list.dart (TaskPreviewList)
- lib\presentation\widgets\settings_section_card.dart (SettingsSectionCard, SettingsDivider)
- lib\presentation\widgets\truncated_value_chips.dart (TruncatedValueChips)
- lib\presentation\widgets\value_emoji_icons.dart (ValueEmojiIcons)
- lib\presentation\widgets\values_section.dart (ValuesSection)

## Pruned by plan references (Phase 00–04)

(none)
