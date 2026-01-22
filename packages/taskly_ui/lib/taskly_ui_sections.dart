/// Section-centric Taskly UI public API.
///
/// Exposes reusable sections (composed UI chunks) and screen-agnostic overlays.
///
/// This entrypoint intentionally does not export primitives.
library;

export 'src/sections/feed_body.dart';
export 'src/sections/empty_state_widget.dart';
export 'src/sections/error_state_widget.dart';
export 'src/sections/loading_state_widget.dart';
export 'src/sections/task_status_filter_bar.dart';

export 'src/sections/confirmation_dialog.dart';
export 'src/sections/icon_picker_dialog.dart';
export 'src/sections/settings_section_card.dart';

export 'src/sections/taskly_agenda_section.dart';
export 'src/sections/taskly_standard_tile_list_section.dart';

export 'src/sections/taskly_timeline_day_section.dart';
export 'src/sections/taskly_overdue_stack_section.dart';

export 'src/sections/my_day_plan_picker_task_list_section.dart';
