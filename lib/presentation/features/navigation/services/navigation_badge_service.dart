import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/screens/language/models/badge_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/data_config.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_definition.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_ref.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/params/data_list_section_params.dart';
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
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;

  /// Returns a stream of badge counts for the given screen.
  ///
  /// Returns null if the screen should not display a badge.
  Stream<int>? badgeStreamFor(ScreenDefinition screen) {
    return switch (screen.chrome.badgeConfig) {
      NoBadge() => null,
      CustomBadgeConfig(:final taskQuery, :final projectQuery) =>
        _streamForCustomConfig(taskQuery, projectQuery),
      BadgeFromFirstSection() => _streamForFirstSection(screen),
    };
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
    final dataConfig = _findFirstDataConfig(screen.sections);
    if (dataConfig == null) {
      return null;
    }

    // Get the query from the data config and return appropriate stream
    return switch (dataConfig) {
      TaskDataConfig(:final query) => _taskRepository.watchAllCount(query),
      ProjectDataConfig(:final query) => _projectRepository.watchAllCount(
        query,
      ),
      ValueDataConfig() => null, // Values don't show counts
      JournalDataConfig() => null, // Journals don't show counts in badge
    };
  }

  DataConfig? _findFirstDataConfig(List<SectionRef> sections) {
    for (final ref in sections) {
      if (ref.overrides?.enabled == false) continue;

      if (ref.templateId != SectionTemplateId.taskList &&
          ref.templateId != SectionTemplateId.projectList &&
          ref.templateId != SectionTemplateId.valueList) {
        continue;
      }

      final params = DataListSectionParams.fromJson(ref.params);
      return params.config;
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
    final dataConfig = _findFirstDataConfig(screen.sections);
    if (dataConfig == null) return null;

    return switch (dataConfig) {
      TaskDataConfig(:final query) => query,
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
    final dataConfig = _findFirstDataConfig(screen.sections);
    if (dataConfig == null) return null;

    return switch (dataConfig) {
      ProjectDataConfig(:final query) => query,
      _ => null,
    };
  }
}
