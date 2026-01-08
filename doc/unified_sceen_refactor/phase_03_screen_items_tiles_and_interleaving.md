# Phase 03 — Typed `ScreenItem` + Tile Registry + `interleaved_list`

## Goal

- Remove `List<dynamic>` + string discriminators from section results.
- Introduce `ScreenItem` sealed union used by list-based templates.
- Add a tile registry so mixed items render correctly.
- Implement a first-class `interleaved_list` template that merges multiple sources with per-screen ordering.

Repo-verified motivation (must be eliminated in this phase):

- `lib/domain/services/screens/section_data_result.dart` uses `List<dynamic>` + `primaryEntityType: String`.
- `lib/domain/services/screens/section_data_service.dart` produces `(List<dynamic>, String)`.
- `lib/presentation/widgets/section_widget.dart` branches on `primaryEntityType == 'task'/'project'`.
- `lib/presentation/features/screens/renderers/task_list_renderer.dart` and `project_list_renderer.dart` do runtime casts.

## Step-by-step

### 1) Add ScreenItem union

Create: `lib/domain/models/screens/screen_item.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/value.dart';

part 'screen_item.freezed.dart';

@freezed
sealed class ScreenItem with _$ScreenItem {
  const factory ScreenItem.task(Task task) = ScreenItemTask;
  const factory ScreenItem.project(Project project) = ScreenItemProject;
  const factory ScreenItem.value(Value value) = ScreenItemValue;

  // optional structural items
  const factory ScreenItem.header(String title) = ScreenItemHeader;
  const factory ScreenItem.divider() = ScreenItemDivider;
}
```

### 2) Replace list section VMs to use `List<ScreenItem>`

- Update TaskList/ProjectList/ValueList template VMs:
  - output `List<ScreenItem>`.
- Remove any `primaryEntityType` string or dynamic casting.

Concrete files you should expect to update/remove in this step:

- `lib/domain/services/screens/section_data_result.dart`
- `lib/domain/services/screens/section_data_service.dart`
- `lib/presentation/widgets/section_widget.dart`
- `lib/presentation/features/screens/renderers/task_list_renderer.dart`
- `lib/presentation/features/screens/renderers/project_list_renderer.dart`

### 3) Add tile registry (presentation)

Create:
- `lib/presentation/features/screens/tiles/screen_item_tile_registry.dart`

Responsibilities:
- Given a `ScreenItem` and a per-type tile variant, return a widget.

Must support:
- Tasks rendered via existing `TaskListTile`
- Projects rendered via existing `ProjectListTile`

#### Value rendering consistency (accepted 2026-01-08)

For both **tasks** and **projects**, value metadata must render using the shared
`ValuesFooter` semantics:

- Primary value: solid chip
- Secondary values: outlined chips

This rule applies anywhere the user sees task/project values:

- `TaskListTile`
- `ProjectListTile`
- Any project summary card (e.g., `ProjectCard`)
- Project detail header (`EntityHeader.project`)

Avoid diverging value renderers (e.g., “all values as identical chips” or
custom `Chip` rows) because it breaks visual meaning (primary vs secondary)
and makes screens feel inconsistent once items are interleaved.

#### Why list tiles and cards both exist (guidance)

Both are intentionally kept because they serve different UI roles:

- **List tiles**: high-density scanning in long lists; predictable shape and
  interaction; best for interleaved feeds.
- **Cards**: richer, “module-like” summaries (progress/next action/extra
  metadata) used when an entity is featured, not when it’s one of many.

Do not force everything into one widget with many flags; pick the right
representation per template and keep the tile registry mapping explicit.

### 4) Implement `interleaved_list`

Template params include:
- sources: list of (type, query)
- orderStrategy: enum (persisted)
- tile variants per entity type

Interpreter responsibilities:
- watch each source stream
- map to ScreenItems
- merge + sort by strategy

### 5) Make Agenda rendering use tile registry

Agenda currently renders task tile and a placeholder project tile.
- Replace with the shared tile registry.

Concrete agenda renderer target(s):

- `lib/presentation/features/screens/renderers/agenda_section_renderer.dart`

## Validation
- `flutter analyze`

## Completion criteria
- No dynamic list casting for list templates.
- Interleaved list works for tasks+projects.
- Agenda uses same item tile registry.

Repo-verified grep checks for completion:

- `primaryEntityType\b|List<dynamic>\s+primaryEntities`
