import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/screen_category.dart';
import 'package:taskly_bloc/domain/models/screens/screen_definition.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

/// Service for computing badge counts for navigation screens.
///
/// Badge counts are computed based on the first section of a screen that
/// contains task or project data. Only workspace screens (not wellbeing
/// or settings) show badge counts.
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
  /// Returns null if the screen should not display a badge (e.g., settings).
  Stream<int>? badgeStreamFor(ScreenDefinition screen) {
    // Only show badges for workspace screens (task lists, projects, etc.)
    // Wellbeing and settings screens don't need task count badges
    if (screen.category != ScreenCategory.workspace) {
      return null;
    }

    // Only data-driven screens can have badges
    if (screen is! DataDrivenScreenDefinition) {
      return null;
    }

    // Find the first data section to use for badge counting
    final dataSection = _findFirstDataSection(screen.sections);
    if (dataSection == null) {
      return null;
    }

    // Get the query from the data config and return appropriate stream
    return switch (dataSection.config) {
      TaskDataConfig(:final query) => _taskRepository.watchCount(query),
      ProjectDataConfig(:final query) => _projectRepository.watchCount(query),
      ValueDataConfig() => null, // Values don't show counts
      JournalDataConfig() => null, // Journals don't show counts in badge
    };
  }

  /// Finds the first data section in the list.
  DataSection? _findFirstDataSection(List<Section> sections) {
    for (final section in sections) {
      if (section is DataSection) {
        return section;
      }
    }
    return null;
  }

  /// Returns the task query for badge counting if the screen has task data.
  TaskQuery? getTaskQueryForScreen(ScreenDefinition screen) {
    if (screen.category != ScreenCategory.workspace) {
      return null;
    }

    if (screen is! DataDrivenScreenDefinition) {
      return null;
    }

    final dataSection = _findFirstDataSection(screen.sections);
    if (dataSection == null) {
      return null;
    }

    return switch (dataSection.config) {
      TaskDataConfig(:final query) => query,
      _ => null,
    };
  }

  /// Returns the project query for badge counting if the screen has project data.
  ProjectQuery? getProjectQueryForScreen(ScreenDefinition screen) {
    if (screen.category != ScreenCategory.workspace) {
      return null;
    }

    if (screen is! DataDrivenScreenDefinition) {
      return null;
    }

    final dataSection = _findFirstDataSection(screen.sections);
    if (dataSection == null) {
      return null;
    }

    return switch (dataSection.config) {
      ProjectDataConfig(:final query) => query,
      _ => null,
    };
  }
}
