import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/screens/templates/params/screen_item_tile_variants.dart';

part 'entity_style_v1.freezed.dart';
part 'entity_style_v1.g.dart';

/// Density policy for entity tiles.
///
/// This replaces the legacy style-pack density knob.
enum EntityDensityV1 {
  @JsonValue('comfortable')
  comfortable,

  @JsonValue('compact')
  compact,
}

/// Declarative styling contract for how entities should be rendered.
///
/// Resolved in the domain layer (keyed by template + module type) and passed
/// through USM runtime outputs to ensure renderers consistently honor it.
@freezed
abstract class EntityStyleV1 with _$EntityStyleV1 {
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory EntityStyleV1({
    @Default(EntityDensityV1.comfortable) EntityDensityV1 density,

    @Default(TaskTileVariant.listTile) TaskTileVariant taskVariant,
    @Default(ProjectTileVariant.listTile) ProjectTileVariant projectVariant,
    @Default(ValueTileVariant.compactCard) ValueTileVariant valueVariant,

    /// When true, renderers may show small agenda tag pills (Starts/Due/In progress)
    /// when enrichment provides them.
    @Default(false) bool showAgendaTagPills,
  }) = _EntityStyleV1;

  factory EntityStyleV1.fromJson(Map<String, dynamic> json) =>
      _$EntityStyleV1FromJson(json);
}

/// Rare, explicit overrides on top of module defaults.
@freezed
abstract class EntityStyleOverrideV1 with _$EntityStyleOverrideV1 {
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory EntityStyleOverrideV1({
    EntityDensityV1? density,
    TaskTileVariant? taskVariant,
    ProjectTileVariant? projectVariant,
    ValueTileVariant? valueVariant,
    bool? showAgendaTagPills,
  }) = _EntityStyleOverrideV1;

  factory EntityStyleOverrideV1.fromJson(Map<String, dynamic> json) =>
      _$EntityStyleOverrideV1FromJson(json);
}
