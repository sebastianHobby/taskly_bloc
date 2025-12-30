import 'package:freezed_annotation/freezed_annotation.dart';

part 'workflow_progress.freezed.dart';
part 'workflow_progress.g.dart';

/// Progress tracking for workflow screens
@freezed
abstract class WorkflowProgress with _$WorkflowProgress {
  const factory WorkflowProgress({
    @Default(0) int total,
    @Default(0) int completed,
    @Default(0) int skipped,
    @Default(0) int pending,
  }) = _WorkflowProgress;

  factory WorkflowProgress.fromJson(Map<String, dynamic> json) =>
      _$WorkflowProgressFromJson(json);
}

extension WorkflowProgressX on WorkflowProgress {
  /// Returns percentage of items reviewed (completed + skipped)
  double get percentageReviewed {
    if (total == 0) return 0;
    return ((completed + skipped) / total) * 100;
  }

  /// Returns percentage of items completed (excluding skipped)
  double get percentageCompleted {
    if (total == 0) return 0;
    return (completed / total) * 100;
  }

  /// Whether all items have been reviewed or skipped
  bool get isComplete => pending == 0 && total > 0;
}
