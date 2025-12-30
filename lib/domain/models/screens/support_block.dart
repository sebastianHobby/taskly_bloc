import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/analytics/date_range.dart';
import 'package:taskly_bloc/domain/models/analytics/task_stat_type.dart';

part 'support_block.freezed.dart';
part 'support_block.g.dart';

/// Support blocks provide contextual information during workflow reviews
@freezed
sealed class SupportBlock with _$SupportBlock {
  /// Task statistics using existing TaskStatsCalculator
  const factory SupportBlock.taskStats({
    required TaskStatType statType,
    DateRange? range,
  }) = TaskStatsBlock;

  /// Workflow progress (3 of 7 reviewed)
  const factory SupportBlock.workflowProgress() = WorkflowProgressBlock;

  /// Breakdown by dimension (project, label, etc.)
  const factory SupportBlock.breakdown({
    required TaskStatType statType,
    required BreakdownDimension dimension,
    DateRange? range,
    @Default(10) int maxItems,
  }) = BreakdownBlock;

  /// Filtered list of related items
  const factory SupportBlock.filteredList({
    required String title,
    required String entityType,
    required Map<String, dynamic> filterJson,
    @Default(5) int maxItems,
  }) = FilteredListBlock;

  /// Mood correlation analysis
  const factory SupportBlock.moodCorrelation({
    required TaskStatType statType,
    DateRange? range,
  }) = MoodCorrelationBlock;

  factory SupportBlock.fromJson(Map<String, dynamic> json) =>
      _$SupportBlockFromJson(json);
}

/// Dimensions for breakdown analysis
enum BreakdownDimension {
  @JsonValue('project')
  project,
  @JsonValue('label')
  label,
  @JsonValue('value')
  value,
  @JsonValue('priority')
  priority,
  @JsonValue('status')
  status,
}
