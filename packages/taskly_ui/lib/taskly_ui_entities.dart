/// Entity-centric Taskly UI public API.
///
/// Exposes render-only entity widgets and their UI-only input models.
///
/// This entrypoint intentionally does not export primitives.
library;

export 'src/catalog/taskly_catalog_types.dart';

export 'src/tiles/entity_tile_models.dart'
    show ProjectTileModel, TaskTileModel, ValueTileModel, ValueTileVariant;

export 'src/tiles/task_entity_tile.dart';
export 'src/tiles/project_entity_tile.dart';
export 'src/tiles/value_entity_tile.dart';

export 'src/entities/priority_flag.dart';

export 'src/tiles/task_list_row_tile.dart';
export 'src/tiles/project_list_row_tile.dart';
