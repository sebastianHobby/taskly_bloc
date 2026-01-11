import 'package:freezed_annotation/freezed_annotation.dart';

/// Task tile variant for list rendering.
///
/// Currently only the standard list tile is supported.
enum TaskTileVariant {
  @JsonValue('list_tile')
  listTile,
}

/// Project tile variant for list rendering.
///
/// Currently only the standard list tile is supported.
enum ProjectTileVariant {
  @JsonValue('list_tile')
  listTile,
}

/// Value tile variant for list rendering.
///
/// Currently only the compact card is supported.
enum ValueTileVariant {
  @JsonValue('compact_card')
  compactCard,
}
