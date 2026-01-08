import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/models/screens/templates/screen_item_tile_variants.dart';

part 'agenda_section_params.freezed.dart';
part 'agenda_section_params.g.dart';

/// Params for the agenda template.
@freezed
abstract class AgendaSectionParams with _$AgendaSectionParams {
  const factory AgendaSectionParams({
    required AgendaDateField dateField,
    required TaskTileVariant taskTileVariant,
    required ProjectTileVariant projectTileVariant,
    @Default(AgendaGrouping.standard) AgendaGrouping grouping,
    @NullableTaskQueryConverter() TaskQuery? additionalFilter,
  }) = _AgendaSectionParams;

  factory AgendaSectionParams.fromJson(Map<String, dynamic> json) =>
      _$AgendaSectionParamsFromJson(json);
}

/// Date field for agenda grouping.
enum AgendaDateField {
  @JsonValue('deadline_date')
  deadlineDate,
  @JsonValue('start_date')
  startDate,
  @JsonValue('scheduled_for')
  scheduledFor,
}

/// Grouping strategy for agenda sections.
enum AgendaGrouping {
  @JsonValue('standard')
  standard,
  @JsonValue('by_date')
  byDate,
  @JsonValue('overdue_first')
  overdueFirst,
}
