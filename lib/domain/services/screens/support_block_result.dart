import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_acknowledgment.dart';

part 'support_block_result.freezed.dart';

/// Result of computing a support block's data.
///
/// Each variant corresponds to a SupportBlock type and contains
/// the computed runtime data needed for rendering.
@freezed
sealed class SupportBlockResult with _$SupportBlockResult {
  /// Result for WorkflowProgressBlock
  const factory SupportBlockResult.workflowProgress({
    required int currentStep,
    required int totalSteps,
    required String currentStepName,
    required double progressPercent,
  }) = WorkflowProgressResult;

  /// Result for QuickActionsBlock
  const factory SupportBlockResult.quickActions({
    required List<QuickAction> actions,
  }) = QuickActionsResult;

  /// Result for ContextSummaryBlock
  const factory SupportBlockResult.contextSummary({
    required String title,
    String? description,
    Map<String, String>? metadata,
  }) = ContextSummaryResult;

  /// Result for RelatedEntitiesBlock
  const factory SupportBlockResult.relatedEntities({
    required List<RelatedEntityInfo> entities,
    required int totalCount,
  }) = RelatedEntitiesResult;

  /// Result for StatsBlock
  const factory SupportBlockResult.stats({
    required List<ComputedStat> stats,
  }) = StatsResult;

  /// Result for ProblemSummaryBlock (DR-018)
  const factory SupportBlockResult.problemSummary({
    required List<DetectedProblem> problems,
    required bool showCount,
    required bool showList,
    required int maxListItems,
    required String title,
  }) = ProblemSummaryResult;

  /// Result for EmptyStateBlock
  const factory SupportBlockResult.emptyState({
    required String message,
    String? icon,
    String? actionLabel,
    String? actionRoute,
  }) = EmptyStateResult;

  /// Empty result for blocks handled by UI layer directly
  const factory SupportBlockResult.empty() = EmptyResult;
}

/// Information about a related entity
@freezed
abstract class RelatedEntityInfo with _$RelatedEntityInfo {
  const factory RelatedEntityInfo({
    required String id,
    required String name,
    required String entityType,
    String? route,
  }) = _RelatedEntityInfo;
}

/// A computed statistic
@freezed
abstract class ComputedStat with _$ComputedStat {
  const factory ComputedStat({
    required String label,
    required String value,
    String? icon,
    String? trend,
  }) = _ComputedStat;
}
