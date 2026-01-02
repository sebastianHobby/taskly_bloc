import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';

part 'view_definition.freezed.dart';
part 'view_definition.g.dart';

/// Date field for agenda grouping
enum DateField {
  @JsonValue('deadline_date')
  deadlineDate,
  @JsonValue('start_date')
  startDate,
  @JsonValue('scheduled_for')
  scheduledFor,
}

/// Grouping strategy for agenda views
enum AgendaGrouping {
  @JsonValue('today')
  today,
  @JsonValue('tomorrow')
  tomorrow,
  @JsonValue('this_week')
  thisWeek,
  @JsonValue('next_week')
  nextWeek,
  @JsonValue('later')
  later,
  @JsonValue('overdue')
  overdue,
}

/// Configuration for agenda views
@freezed
abstract class AgendaConfig with _$AgendaConfig {
  const factory AgendaConfig({
    required DateField dateField,
    required AgendaGrouping groupingStrategy,
  }) = _AgendaConfig;

  factory AgendaConfig.fromJson(Map<String, dynamic> json) =>
      _$AgendaConfigFromJson(json);
}

/// Parent type for detail views
enum DetailParentType {
  @JsonValue('project')
  project,
  @JsonValue('label')
  label,
}

/// Sealed class defining the core view types
@freezed
sealed class ViewDefinition with _$ViewDefinition {
  /// Simple list view (Inbox, Projects list, Labels list)
  const factory ViewDefinition.collection({
    required EntitySelector selector,
    required DisplayConfig display,
    List<SupportBlock>? supportBlocks,
  }) = CollectionView;

  /// Date-grouped view (Today, Upcoming)
  const factory ViewDefinition.agenda({
    required EntitySelector selector,
    required DisplayConfig display,
    required AgendaConfig agendaConfig,
    List<SupportBlock>? supportBlocks,
  }) = AgendaView;

  /// Single entity detail view (Project detail, Value detail)
  const factory ViewDefinition.detail({
    required DetailParentType parentType,
    ViewDefinition? childView,
    List<SupportBlock>? supportBlocks,
  }) = DetailView;

  /// Allocation-based view (Next Actions)
  const factory ViewDefinition.allocated({
    required EntitySelector selector,
    required DisplayConfig display,
    List<SupportBlock>? supportBlocks,
  }) = AllocatedView;

  factory ViewDefinition.fromJson(Map<String, dynamic> json) =>
      _$ViewDefinitionFromJson(json);
}
