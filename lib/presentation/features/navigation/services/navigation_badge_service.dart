import 'package:taskly_domain/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_domain/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/screens/language/models/badge_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_spec.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_domain/domain/queries/project_query.dart';
import 'package:taskly_domain/domain/queries/query_filter.dart';
import 'package:taskly_domain/domain/queries/task_predicate.dart';
import 'package:taskly_domain/domain/queries/task_query.dart';

/// Service for computing badge counts for navigation screens.
///
/// Badge counts are computed based on the screen's [BadgeConfig]:
/// - [BadgeFromFirstSection]: Uses the first data section's query
/// - [CustomBadgeConfig]: Uses a custom task or project query
/// - [NoBadge]: No badge shown
class NavigationBadgeService {
  NavigationBadgeService({
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;

  final Map<String, Stream<int>?> _badgeStreamCache = {};

  /// Returns a stream of badge counts for the given screen.
  ///
  /// Returns null if the screen should not display a badge.
  Stream<int>? badgeStreamFor(ScreenSpec screen) {
    final screenKey = screen.screenKey;
    if (_badgeStreamCache.containsKey(screenKey)) {
      return _badgeStreamCache[screenKey];
    }

    final stream = switch (screen.chrome.badgeConfig) {
      NoBadge() => null,
      CustomBadgeConfig(:final taskQuery, :final projectQuery) =>
        _streamForCustomConfig(taskQuery, projectQuery),
      BadgeFromFirstSection() => _streamForFirstSection(screen),
    };

    _badgeStreamCache[screenKey] = stream;
    return stream;
  }

  /// Get badge stream from a custom badge config.
  Stream<int>? _streamForCustomConfig(
    TaskQuery? taskQuery,
    ProjectQuery? projectQuery,
  ) {
    if (taskQuery != null) {
      return _taskRepository.watchAllCount(taskQuery);
    }
    if (projectQuery != null) {
      return _projectRepository.watchAllCount(projectQuery);
    }
    return null;
  }

  /// Get badge stream from the first data section of a screen.
  Stream<int>? _streamForFirstSection(ScreenSpec screen) {
    final target = _findFirstBadgeTarget(screen.modules);
    return switch (target) {
      _BadgeTask(:final query) => _taskRepository.watchAllCount(query),
      _BadgeProject(:final query) => _projectRepository.watchAllCount(query),
      _BadgeNone() || null => null,
    };
  }

  _BadgeTarget? _findFirstBadgeTarget(SlottedModules modules) {
    final ordered = <ScreenModuleSpec>[...modules.header, ...modules.primary];

    for (final module in ordered) {
      final target = switch (module) {
        ScreenModuleTaskListV2(:final params) => _badgeTargetFromListParams(
          params,
        ),
        ScreenModuleValueListV2(:final params) => _badgeTargetFromListParams(
          params,
        ),
        ScreenModuleAgendaV2(:final params) => _BadgeTask(
          _buildTaskQueryFromAgendaParams(params, now: DateTime.now()),
        ),
        _ => null,
      };

      if (target != null) return target;
    }

    return null;
  }

  TaskQuery _buildTaskQueryFromAgendaParams(
    AgendaSectionParamsV2 params, {
    required DateTime now,
  }) {
    final baseFilter =
        params.additionalFilter?.filter ?? const QueryFilter.matchAll();

    final alreadyHasCompletionPredicate = baseFilter.shared.any(
      (p) =>
          p is TaskBoolPredicate &&
          p.field == TaskBoolField.completed &&
          p.operator == BoolOperator.isFalse,
    );

    final withCompletion = alreadyHasCompletionPredicate
        ? baseFilter
        : baseFilter.copyWith(
            shared: [
              const TaskBoolPredicate(
                field: TaskBoolField.completed,
                operator: BoolOperator.isFalse,
              ),
              ...baseFilter.shared,
            ],
          );

    final dateField = switch (params.dateField) {
      AgendaDateFieldV2.deadlineDate => TaskDateField.deadlineDate,
      AgendaDateFieldV2.startDate => TaskDateField.startDate,
      AgendaDateFieldV2.scheduledFor => TaskDateField.deadlineDate,
    };

    // Only include tasks that have the date field set.
    final withDateFilter = withCompletion.copyWith(
      shared: [
        ...withCompletion.shared,
        TaskDatePredicate(
          field: dateField,
          operator: DateOperator.onOrAfter,
          date: DateTime(now.year - 1, now.month, now.day),
        ),
      ],
    );

    return TaskQuery(filter: withDateFilter);
  }

  _BadgeTarget? _badgeTargetFromListParams(ListSectionParamsV2 params) {
    final config = params.config;

    return switch (config) {
      TaskDataConfig(:final query) => _BadgeTask(query),
      ProjectDataConfig(:final query) => _BadgeProject(query),
      AllocationSnapshotTasksTodayDataConfig() => const _BadgeNone(),
      ValueDataConfig() || JournalDataConfig() => const _BadgeNone(),
    };
  }

  /// Returns the task query for badge counting if the screen has task data.
  TaskQuery? getTaskQueryForScreen(ScreenSpec screen) {
    return switch (screen.chrome.badgeConfig) {
      NoBadge() => null,
      CustomBadgeConfig(:final taskQuery) => taskQuery,
      BadgeFromFirstSection() => _getTaskQueryFromFirstSection(screen),
    };
  }

  TaskQuery? _getTaskQueryFromFirstSection(ScreenSpec screen) {
    final target = _findFirstBadgeTarget(screen.modules);
    return switch (target) {
      _BadgeTask(:final query) => query,
      _ => null,
    };
  }

  /// Returns the project query for badge counting if the screen has project data.
  ProjectQuery? getProjectQueryForScreen(ScreenSpec screen) {
    return switch (screen.chrome.badgeConfig) {
      NoBadge() => null,
      CustomBadgeConfig(:final projectQuery) => projectQuery,
      BadgeFromFirstSection() => _getProjectQueryFromFirstSection(screen),
    };
  }

  ProjectQuery? _getProjectQueryFromFirstSection(ScreenSpec screen) {
    final target = _findFirstBadgeTarget(screen.modules);
    return switch (target) {
      _BadgeProject(:final query) => query,
      _ => null,
    };
  }
}

sealed class _BadgeTarget {
  const _BadgeTarget();
}

final class _BadgeTask extends _BadgeTarget {
  const _BadgeTask(this.query);

  final TaskQuery query;
}

final class _BadgeProject extends _BadgeTarget {
  const _BadgeProject(this.query);

  final ProjectQuery query;
}

final class _BadgeNone extends _BadgeTarget {
  const _BadgeNone();
}
