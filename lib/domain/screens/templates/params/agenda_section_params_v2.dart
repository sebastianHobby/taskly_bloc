import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';

part 'agenda_section_params_v2.freezed.dart';
part 'agenda_section_params_v2.g.dart';

/// Params for the V2 agenda template.
@freezed
abstract class AgendaSectionParamsV2 with _$AgendaSectionParamsV2 {
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory AgendaSectionParamsV2({
    required AgendaDateFieldV2 dateField,
    required TilePolicyV2 tiles,
    required SectionLayoutSpecV2 layout,
    @Default(EnrichmentPlanV2()) EnrichmentPlanV2 enrichment,
    @NullableTaskQueryConverter() TaskQuery? additionalFilter,
  }) = _AgendaSectionParamsV2;

  factory AgendaSectionParamsV2.fromJson(Map<String, dynamic> json) =>
      _$AgendaSectionParamsV2FromJson(json);
}
