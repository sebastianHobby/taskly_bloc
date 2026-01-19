/// Feed-centric Taskly UI public API.
///
/// This entrypoint intentionally exposes only:
/// - canonical feed sections (loading/error/empty/list)
/// - canonical entity tiles (task/project list)
/// - the UI-only tile models needed to construct those tiles
///
/// Most primitives are not exported to keep the public API small and stable.
library;

export 'src/sections/feed_body.dart';
export 'src/sections/empty_state_widget.dart';
export 'src/sections/error_state_widget.dart';
export 'src/sections/loading_state_widget.dart';
export 'src/sections/task_status_filter_bar.dart';

export 'src/sections/confirmation_dialog.dart';

export 'src/primitives/swipe_to_delete.dart';
export 'src/primitives/delete_confirmation.dart';
export 'src/primitives/sparkline_painter.dart';

export 'src/tiles/entity_tile_models.dart';
export 'src/tiles/task_list_row_tile.dart';
export 'src/tiles/project_list_row_tile.dart';

// Needed because tile models expose ValueChipData in their public API.
export 'src/primitives/value_chip.dart' show ValueChipData;
