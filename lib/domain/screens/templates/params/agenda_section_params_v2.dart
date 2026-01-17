import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_domain/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/templates/params/entity_style_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';

part 'agenda_section_params_v2.freezed.dart';
part 'agenda_section_params_v2.g.dart';

/// Declares which agenda UI layout to render for an agenda section.
enum AgendaLayoutV2 {
  /// Legacy timeline-style Scheduled UI.
  ///
  /// Deprecated: kept only for backward compatibility with persisted specs.
  @JsonValue('timeline')
  timeline,

  /// Day cards feed (Today / Next 7 / Later).
  @JsonValue('day_cards_feed')
  dayCardsFeed,
}

/// Params for the V2 agenda template.
@freezed
abstract class AgendaSectionParamsV2 with _$AgendaSectionParamsV2 {
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory AgendaSectionParamsV2({
    required AgendaDateFieldV2 dateField,
    EntityStyleOverrideV1? entityStyleOverride,
    @Default(AgendaLayoutV2.dayCardsFeed) AgendaLayoutV2 layout,
    @Default(EnrichmentPlanV2()) EnrichmentPlanV2 enrichment,
    @NullableTaskQueryConverter() TaskQuery? additionalFilter,
  }) = _AgendaSectionParamsV2;

  factory AgendaSectionParamsV2.fromJson(Map<String, dynamic> json) =>
      _$AgendaSectionParamsV2FromJson(json);
}
