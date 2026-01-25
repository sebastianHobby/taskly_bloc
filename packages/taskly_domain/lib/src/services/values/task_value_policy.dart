import 'package:taskly_domain/src/core/editing/validation_error.dart';

/// Central policy for task value overrides.
///
/// Tasks inherit their primary value from the project. Any task values are
/// additional tags and must:
/// - belong to a project with a primary value
/// - be unique
/// - exclude the project's primary value
/// - contain at most [maxOverrides] entries
final class TaskValuePolicy {
  TaskValuePolicy._();

  static const int maxOverrides = 2;

  static TaskValueValidationResult validate({
    required List<String>? valueIds,
    required String? projectId,
    required String? projectPrimaryValueId,
  }) {
    final normalized = _normalizeValueIds(valueIds);
    final issues = <TaskValueIssue>{};

    if (normalized.isNotEmpty) {
      final hasProject = (projectId ?? '').trim().isNotEmpty;
      if (!hasProject) {
        issues.add(TaskValueIssue.projectRequired);
      }

      final primary = (projectPrimaryValueId ?? '').trim();
      final hasPrimary = primary.isNotEmpty;
      if (!hasPrimary) {
        issues.add(TaskValueIssue.projectPrimaryRequired);
      } else if (normalized.contains(primary)) {
        issues.add(TaskValueIssue.matchesProjectPrimary);
      }
    }

    if (normalized.length > maxOverrides) {
      issues.add(TaskValueIssue.maxOverrides);
    }

    if (_hasDuplicates(normalized)) {
      issues.add(TaskValueIssue.duplicate);
    }

    return TaskValueValidationResult(
      normalizedIds: normalized,
      issues: issues.toList(growable: false),
    );
  }

  /// Normalizes overrides for storage by removing empty and conflicting IDs.
  ///
  /// This is intended for automatic cleanup when project primary values change.
  static List<String> normalizeOverrides({
    required List<String>? valueIds,
    required String? projectPrimaryValueId,
  }) {
    final normalized = _normalizeValueIds(valueIds);
    final primary = (projectPrimaryValueId ?? '').trim();
    final seen = <String>{};
    final result = <String>[];

    for (final id in normalized) {
      if (id == primary) continue;
      if (seen.contains(id)) continue;
      seen.add(id);
      result.add(id);
      if (result.length >= maxOverrides) break;
    }

    return result;
  }

  static List<ValidationError> toValidationErrors(
    List<TaskValueIssue> issues,
  ) {
    if (issues.isEmpty) return const <ValidationError>[];

    return [
      for (final issue in issues)
        ValidationError(
          code: issue.code,
          messageKey: issue.messageKey,
        ),
    ];
  }

  static List<String> _normalizeValueIds(List<String>? valueIds) {
    return (valueIds ?? const <String>[])
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList(growable: false);
  }

  static bool _hasDuplicates(List<String> ids) {
    final seen = <String>{};
    for (final id in ids) {
      if (seen.contains(id)) return true;
      seen.add(id);
    }
    return false;
  }
}

enum TaskValueIssue {
  projectRequired,
  projectPrimaryRequired,
  maxOverrides,
  duplicate,
  matchesProjectPrimary;

  String get code => switch (this) {
    TaskValueIssue.projectRequired => 'project_required',
    TaskValueIssue.projectPrimaryRequired => 'project_primary_required',
    TaskValueIssue.maxOverrides => 'max_items',
    TaskValueIssue.duplicate => 'duplicate',
    TaskValueIssue.matchesProjectPrimary => 'matches_project_primary',
  };

  String get messageKey => switch (this) {
    TaskValueIssue.projectRequired => 'taskFormValuesRequireProject',
    TaskValueIssue.projectPrimaryRequired =>
      'taskFormValuesRequireProjectPrimary',
    TaskValueIssue.maxOverrides => 'taskFormValuesMaxTwo',
    TaskValueIssue.duplicate => 'taskFormValuesMustBeUnique',
    TaskValueIssue.matchesProjectPrimary =>
      'taskFormValuesCannotMatchProjectPrimary',
  };
}

final class TaskValueValidationResult {
  const TaskValueValidationResult({
    required this.normalizedIds,
    required this.issues,
  });

  final List<String> normalizedIds;
  final List<TaskValueIssue> issues;

  bool get isValid => issues.isEmpty;
}
