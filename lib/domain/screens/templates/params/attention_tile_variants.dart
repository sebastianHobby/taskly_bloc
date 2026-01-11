import 'package:freezed_annotation/freezed_annotation.dart';

/// Tile variants for rendering an [AttentionItem] as an issue/alert.
///
/// Currently only a single variant is supported.
enum AttentionItemTileVariant {
  @JsonValue('standard')
  standard,
}

/// Tile variants for rendering a review item in check-in summary.
///
/// Currently only a single variant is supported.
enum ReviewItemTileVariant {
  @JsonValue('standard')
  standard,
}
