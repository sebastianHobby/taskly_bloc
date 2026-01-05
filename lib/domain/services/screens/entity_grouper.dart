import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';

/// Groups entities by various dimensions for display in screens
class EntityGrouper {
  /// Groups tasks by the specified field
  Map<String, List<Task>> groupTasks(
    List<Task> tasks,
    GroupByField field,
  ) {
    return switch (field) {
      GroupByField.none => {'All': tasks},
      GroupByField.project => _groupTasksByProject(tasks),
      GroupByField.label => _groupTasksByLabel(tasks),
      GroupByField.value => _groupTasksByValue(tasks),
      GroupByField.date => _groupTasksByDate(tasks),
      GroupByField.priority => _groupTasksByPriority(tasks),
    };
  }

  /// Groups projects by the specified field
  Map<String, List<Project>> groupProjects(
    List<Project> projects,
    GroupByField field,
  ) {
    return switch (field) {
      GroupByField.none => {'All': projects},
      GroupByField.label => _groupProjectsByLabel(projects),
      GroupByField.value => _groupProjectsByValue(projects),
      GroupByField.priority => _groupProjectsByPriority(projects),
      _ => {'All': projects}, // Fallback for unsupported groupings
    };
  }

  Map<String, List<Task>> _groupTasksByProject(List<Task> tasks) {
    final grouped = <String, List<Task>>{};
    for (final task in tasks) {
      final key = task.project?.name ?? 'No Project';
      grouped.putIfAbsent(key, () => []).add(task);
    }
    return _sortMapByKey(grouped);
  }

  Map<String, List<Task>> _groupTasksByLabel(List<Task> tasks) {
    return {'No Labels': tasks};
  }

  Map<String, List<Task>> _groupTasksByValue(List<Task> tasks) {
    final grouped = <String, List<Task>>{};
    for (final task in tasks) {
      if (task.values.isEmpty) {
        grouped.putIfAbsent('No Values', () => []).add(task);
      } else {
        for (final value in task.values) {
          grouped.putIfAbsent(value.name, () => []).add(task);
        }
      }
    }
    return _sortMapByKey(grouped);
  }

  Map<String, List<Task>> _groupTasksByDate(List<Task> tasks) {
    final grouped = <String, List<Task>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    for (final task in tasks) {
      final deadline = task.deadlineDate;
      if (deadline == null) {
        grouped.putIfAbsent('No Deadline', () => []).add(task);
      } else {
        final dateOnly = DateTime(deadline.year, deadline.month, deadline.day);
        String key;
        if (dateOnly == today) {
          key = 'Today';
        } else if (dateOnly == tomorrow) {
          key = 'Tomorrow';
        } else if (dateOnly.isBefore(today)) {
          key = 'Overdue';
        } else {
          final daysAway = dateOnly.difference(today).inDays;
          if (daysAway <= 7) {
            key = 'This Week';
          } else if (daysAway <= 30) {
            key = 'This Month';
          } else {
            key = 'Later';
          }
        }
        grouped.putIfAbsent(key, () => []).add(task);
      }
    }

    // Custom sort order for date groups
    final order = [
      'Overdue',
      'Today',
      'Tomorrow',
      'This Week',
      'This Month',
      'Later',
      'No Deadline',
    ];
    final sorted = <String, List<Task>>{};
    for (final key in order) {
      if (grouped.containsKey(key)) {
        sorted[key] = grouped[key]!;
      }
    }
    return sorted;
  }

  Map<String, List<Task>> _groupTasksByPriority(List<Task> tasks) {
    // Task model doesn't have priority field
    // Group all tasks under single key for now
    return {'All Tasks': tasks};
  }

  Map<String, List<Project>> _groupProjectsByLabel(List<Project> projects) {
    return {'No Labels': projects};
  }

  Map<String, List<Project>> _groupProjectsByValue(List<Project> projects) {
    final grouped = <String, List<Project>>{};
    for (final project in projects) {
      if (project.values.isEmpty) {
        grouped.putIfAbsent('No Values', () => []).add(project);
      } else {
        for (final value in project.values) {
          grouped.putIfAbsent(value.name, () => []).add(project);
        }
      }
    }
    return _sortMapByKey(grouped);
  }

  Map<String, List<Project>> _groupProjectsByPriority(
    List<Project> projects,
  ) {
    // Project model doesn't have priority field
    // Group all projects under single key for now
    return {'All Projects': projects};
  }

  Map<String, List<T>> _sortMapByKey<T>(Map<String, List<T>> map) {
    final sorted = <String, List<T>>{};
    final keys = map.keys.toList()..sort();
    for (final key in keys) {
      sorted[key] = map[key]!;
    }
    return sorted;
  }
}
