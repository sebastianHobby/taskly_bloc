/// Entity-centric Taskly UI public API.
///
/// Exposes render-only entity widgets and their UI-only input models.
///
/// This entrypoint intentionally does not export primitives.
library;

export 'src/tiles/entity_tile_intents.dart'
    show
        ProjectTileActions,
        ProjectTileIntent,
        TaskTileActions,
        TaskTileIntent,
        TaskTileMarkers,
        ValueTileActions,
        ValueTileIntent;

export 'src/tiles/entity_tile_models.dart'
    show EntityMetaLineModel, ProjectTileModel, TaskTileModel, ValueTileModel;

export 'src/tiles/task_entity_tile.dart';
export 'src/tiles/project_entity_tile.dart';
export 'src/tiles/value_entity_tile.dart';

export 'src/entities/priority_flag.dart';
