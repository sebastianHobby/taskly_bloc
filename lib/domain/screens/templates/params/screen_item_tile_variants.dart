import 'package:freezed_annotation/freezed_annotation.dart';

/// Task tile variant for list rendering.
///
/// Currently only the standard list tile is supported.
enum TaskTileVariant {
  @JsonValue('list_tile')
  listTile,

  /// Agenda-style tile (supports title-prefix tags when enrichment provides
  /// them).
  @JsonValue('agenda')
  agenda,
}

/// Project tile variant for list rendering.
///
/// Currently only the standard list tile is supported.
enum ProjectTileVariant {
  @JsonValue('list_tile')
  listTile,

  /// Agenda-style tile/card.
  @JsonValue('agenda')
  agenda,
}

/// Value tile variant for list rendering.
///
/// Currently only the compact card is supported.
enum ValueTileVariant {
  @JsonValue('compact_card')
  compactCard,
}
