/// Catalogue-style Taskly UI public API.
///
/// This entrypoint exposes:
/// - canonical entity renderers (task/project tiles with curated options)
/// - canonical section layouts (agenda / standard list)
/// - minimal typed specs (badges, trailing affordances)
///
/// It intentionally avoids exporting low-level primitives.
library;

export 'src/catalog/taskly_catalog_types.dart';
export 'src/sections/taskly_standard_tile_list_section.dart';

export 'src/tiles/task_entity_tile.dart';
export 'src/tiles/project_entity_tile.dart';
export 'src/tiles/value_entity_tile.dart';

// Reuse existing UI-only models.
export 'src/tiles/entity_tile_models.dart'
    show ProjectTileModel, TaskTileModel, ValueTileModel, ValueTileVariant;
