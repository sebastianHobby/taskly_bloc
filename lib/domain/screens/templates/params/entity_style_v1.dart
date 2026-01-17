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

/// How much metadata an agenda tile should show by default.
enum AgendaMetaDensityV1 {
  /// Show the full meta line (legacy behavior).
  @JsonValue('full')
  full,

  /// Show a calmer, minimal meta line.
  @JsonValue('minimal')
  minimal,

  /// Show minimal meta by default, with an affordance to expand.
  @JsonValue('minimal_expandable')
  minimalExpandable,
}

/// How to encode entity priority in the UI.
enum AgendaPriorityEncodingV1 {
  /// Show an explicit P# pill in the meta line.
  @JsonValue('explicit_pill')
  explicitPill,

  /// Show a subtle dot glyph near the title.
  @JsonValue('subtle_dot')
  subtleDot,

  /// Encode priority via slightly stronger title typography.
  @JsonValue('subtle_title_weight')
  subtleTitleWeight,

  /// Do not show priority in the default row presentation.
  @JsonValue('none')
  none,
}

/// Controls how row actions are surfaced on agenda tiles.
enum AgendaActionsVisibilityV1 {
  /// Always show the overflow menu button.
  @JsonValue('always')
  always,

  /// Only show actions on hover/focus (desktop), while remaining visible on touch.
  @JsonValue('hover_or_focus')
  hoverOrFocus,
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

    /// When true, renderers may show small agenda tag pills (Starts/Due/Ongoing)
    /// when enrichment provides them.
    @Default(false) bool showAgendaTagPills,

    /// Agenda-only: controls default meta density for agenda card tiles.
    @Default(AgendaMetaDensityV1.full) AgendaMetaDensityV1 agendaMetaDensity,

    /// Agenda-only: controls how priority should be presented.
    @Default(AgendaPriorityEncodingV1.explicitPill)
    AgendaPriorityEncodingV1 agendaPriorityEncoding,

    /// Agenda-only: controls how row actions should be surfaced.
    @Default(AgendaActionsVisibilityV1.always)
    AgendaActionsVisibilityV1 agendaActionsVisibility,

    /// Agenda-only: render the primary value as icon-only, filled.
    @Default(false) bool agendaPrimaryValueIconOnly,

    /// Agenda-only: how many secondary values to show before summarizing.
    @Default(2) int agendaMaxSecondaryValues,

    /// Agenda-only: on Ongoing rows, show a deadline date chip (not start date).
    @Default(true) bool agendaShowDeadlineChipOnOngoing,
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

    AgendaMetaDensityV1? agendaMetaDensity,
    AgendaPriorityEncodingV1? agendaPriorityEncoding,
    AgendaActionsVisibilityV1? agendaActionsVisibility,
    bool? agendaPrimaryValueIconOnly,
    int? agendaMaxSecondaryValues,
    bool? agendaShowDeadlineChipOnOngoing,
  }) = _EntityStyleOverrideV1;

  factory EntityStyleOverrideV1.fromJson(Map<String, dynamic> json) =>
      _$EntityStyleOverrideV1FromJson(json);
}
