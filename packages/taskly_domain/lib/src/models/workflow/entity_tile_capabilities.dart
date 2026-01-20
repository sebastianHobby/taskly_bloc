import 'package:freezed_annotation/freezed_annotation.dart';

part 'entity_tile_capabilities.freezed.dart';
part 'entity_tile_capabilities.g.dart';

/// Scope of a completion mutation.
///
/// - [entity]: completion applies to the base entity.
/// - [occurrence]: completion applies to a specific expanded occurrence.
enum CompletionScope {
  @JsonValue('entity')
  entity,

  @JsonValue('occurrence')
  occurrence,
}

/// Domain-sourced capability policy for an entity tile.
///
/// This is the source of truth for which actions a tile may expose.
@freezed
abstract class EntityTileCapabilities with _$EntityTileCapabilities {
  const factory EntityTileCapabilities({
    /// Whether the tile can toggle completion.
    @Default(false) bool canToggleCompletion,

    /// The required completion scope when [canToggleCompletion] is true.
    ///
    /// For expanded recurring occurrences, this is [CompletionScope.occurrence].
    @Default(CompletionScope.entity) CompletionScope completionScope,

    /// Whether the tile can toggle the entity's pinned status.
    @Default(false) bool canTogglePinned,

    /// Whether the tile can request deletion.
    @Default(false) bool canDelete,

    /// Whether the tile can open the editor.
    @Default(false) bool canOpenEditor,

    /// Whether the tile can open the detail view.
    @Default(false) bool canOpenDetails,

    /// Whether the tile can open the "move to project" UX.
    @Default(false) bool canOpenMoveToProject,

    /// Whether the tile can perform a quick move-to-project mutation.
    @Default(false) bool canQuickMoveToProject,
  }) = _EntityTileCapabilities;

  factory EntityTileCapabilities.fromJson(Map<String, dynamic> json) =>
      _$EntityTileCapabilitiesFromJson(json);
}

/// Optional module-level overrides to hide/disable certain actions.
///
/// Interpreters should apply these overrides in the domain layer and emit the
/// resolved [EntityTileCapabilities] on the renderable item model.
@freezed
abstract class EntityTileCapabilitiesOverride
    with _$EntityTileCapabilitiesOverride {
  const factory EntityTileCapabilitiesOverride({
    bool? canToggleCompletion,
    bool? canTogglePinned,
    bool? canDelete,
    bool? canOpenEditor,
    bool? canOpenDetails,
    bool? canOpenMoveToProject,
    bool? canQuickMoveToProject,
  }) = _EntityTileCapabilitiesOverride;

  factory EntityTileCapabilitiesOverride.fromJson(Map<String, dynamic> json) =>
      _$EntityTileCapabilitiesOverrideFromJson(json);
}

extension EntityTileCapabilitiesOverrideX on EntityTileCapabilities {
  EntityTileCapabilities applyOverride(
    EntityTileCapabilitiesOverride? override,
  ) {
    if (override == null) return this;
    return copyWith(
      canToggleCompletion: override.canToggleCompletion ?? canToggleCompletion,
      canTogglePinned: override.canTogglePinned ?? canTogglePinned,
      canDelete: override.canDelete ?? canDelete,
      canOpenEditor: override.canOpenEditor ?? canOpenEditor,
      canOpenDetails: override.canOpenDetails ?? canOpenDetails,
      canOpenMoveToProject:
          override.canOpenMoveToProject ?? canOpenMoveToProject,
      canQuickMoveToProject:
          override.canQuickMoveToProject ?? canQuickMoveToProject,
    );
  }
}
