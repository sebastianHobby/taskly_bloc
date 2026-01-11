# Final widget inventory (keep/replace/delete)

This file is filled in during Phase 05.

## Kept
- Canonical entity UI entrypoints:
	- `TaskView` ([lib/presentation/entity_views/task_view.dart](../../lib/presentation/entity_views/task_view.dart))
	- `ProjectView` ([lib/presentation/entity_views/project_view.dart](../../lib/presentation/entity_views/project_view.dart))
	- `ValueView` ([lib/presentation/entity_views/value_view.dart](../../lib/presentation/entity_views/value_view.dart))

- Field catalog policy implementation:
	- `DateLabelFormatter` ([lib/presentation/field_catalog/formatters/date_label_formatter.dart](../../lib/presentation/field_catalog/formatters/date_label_formatter.dart))

## Replaced
- `EnhancedValueCard` -> `ValueView`
- `TaskListTile` -> `TaskView`
- `ProjectListTile` -> `ProjectView`

## Deleted
- Legacy value card wrapper:
	- `EnhancedValueCard` (removed file: `lib/presentation/features/values/widgets/enhanced_value_card.dart`)

- Legacy task/project wrapper widgets:
	- `TaskListTile` (removed file: `lib/presentation/features/tasks/widgets/task_list_tile.dart`)
	- `ProjectListTile` (removed file: `lib/presentation/features/projects/widgets/project_list_tile.dart`)
