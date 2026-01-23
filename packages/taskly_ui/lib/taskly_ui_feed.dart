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

export 'src/tiles/entity_tile_models.dart';
export 'src/tiles/project_entity_tile.dart';
