import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/screens/language/models/badge_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_query_builder.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

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
    required ScreenQueryBuilder screenQueryBuilder,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _screenQueryBuilder = screenQueryBuilder;

  final ScreenQueryBuilder _screenQueryBuilder;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;

  final Map<String, Stream<int>?> _badgeStreamCache = {};

  /// Returns a stream of badge counts for the given screen.
  ///
  /// Returns null if the screen should not display a badge.
  Stream<int>? badgeStreamFor(ScreenDefinition screen) {
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
  Stream<int>? _streamForFirstSection(ScreenDefinition screen) {
    final target = _findFirstBadgeTarget(screen.sections);
    return switch (target) {
      _BadgeTask(:final query) => _taskRepository.watchAllCount(query),
      _BadgeProject(:final query) => _projectRepository.watchAllCount(query),
      _BadgeNone() || null => null,
    };
  }

  _BadgeTarget? _findFirstBadgeTarget(List<SectionRef> sections) {
    for (final ref in sections) {
      if (ref.overrides?.enabled == false) continue;

      final templateId = ref.templateId;

      if (templateId == SectionTemplateId.agendaV2) {
        final query = _screenQueryBuilder.buildTaskQueryFromAgendaSectionRef(
          section: ref,
          now: DateTime.now(),
        );

        if (query != null) {
          return _BadgeTask(query);
        }

        continue;
      }

      if (templateId != SectionTemplateId.taskListV2 &&
          templateId != SectionTemplateId.projectListV2 &&
          templateId != SectionTemplateId.valueListV2) {
        continue;
      }

      final params = ListSectionParamsV2.fromJson(ref.params);
      final config = params.config;

      switch (config) {
        case TaskDataConfig(:final query):
          return _BadgeTask(query);
        case ProjectDataConfig(:final query):
          return _BadgeProject(query);
        case ValueDataConfig() || JournalDataConfig():
          return const _BadgeNone();
      }
    }

    return null;
  }

  /// Returns the task query for badge counting if the screen has task data.
  TaskQuery? getTaskQueryForScreen(ScreenDefinition screen) {
    return switch (screen.chrome.badgeConfig) {
      NoBadge() => null,
      CustomBadgeConfig(:final taskQuery) => taskQuery,
      BadgeFromFirstSection() => _getTaskQueryFromFirstSection(screen),
    };
  }

  TaskQuery? _getTaskQueryFromFirstSection(ScreenDefinition screen) {
    final target = _findFirstBadgeTarget(screen.sections);
    return switch (target) {
      _BadgeTask(:final query) => query,
      _ => null,
    };
  }

  /// Returns the project query for badge counting if the screen has project data.
  ProjectQuery? getProjectQueryForScreen(ScreenDefinition screen) {
    return switch (screen.chrome.badgeConfig) {
      NoBadge() => null,
      CustomBadgeConfig(:final projectQuery) => projectQuery,
      BadgeFromFirstSection() => _getProjectQueryFromFirstSection(screen),
    };
  }

  ProjectQuery? _getProjectQueryFromFirstSection(ScreenDefinition screen) {
    final target = _findFirstBadgeTarget(screen.sections);
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
