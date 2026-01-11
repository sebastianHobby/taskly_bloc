import 'package:taskly_bloc/domain/core/model/project.dart';
import 'package:taskly_bloc/domain/core/model/task.dart';

/// Represents a task with its associated date and the type of that date.
class TaskDateEntry {
  const TaskDateEntry({
    required this.task,
    required this.date,
    required this.dateType,
  });

  final Task task;
  final DateTime date;
  final TaskDateType dateType;
}

/// Represents a project with its associated date and the type of that date.
class ProjectDateEntry {
  const ProjectDateEntry({
    required this.project,
    required this.date,
    required this.dateType,
  });

  final Project project;
  final DateTime date;
  final TaskDateType dateType;
}

/// Combined entry for items that can appear on a date (task or project).
sealed class UpcomingDateEntry {
  DateTime get date;
  TaskDateType get dateType;
}

class UpcomingTaskEntry extends UpcomingDateEntry {
  UpcomingTaskEntry({
    required this.task,
    required this.date,
    required this.dateType,
  });

  final Task task;
  @override
  final DateTime date;
  @override
  final TaskDateType dateType;
}

class UpcomingProjectEntry extends UpcomingDateEntry {
  UpcomingProjectEntry({
    required this.project,
    required this.date,
    required this.dateType,
  });

  final Project project;
  @override
  final DateTime date;
  @override
  final TaskDateType dateType;
}

/// Indicates whether an item is associated with a date via its start or deadline.
enum TaskDateType {
  start,
  deadline,
}

/// Groups tasks and projects by date for the upcoming view.
///
/// Items with both start date and deadline on different days will appear twice.
class UpcomingTasksGrouper {
  /// Groups tasks by date for the next [daysAhead] days (default 7).
  ///
  /// Returns a map where keys are date-only DateTime objects and values
  /// are lists of [TaskDateEntry] objects for that date.
  static Map<DateTime, List<TaskDateEntry>> groupByDate({
    required List<Task> tasks,
    required DateTime now,
    int daysAhead = 7,
  }) {
    final today = _dateOnly(now);
    final endDate = today.add(Duration(days: daysAhead));

    // Initialize map with all dates in range
    final grouped = <DateTime, List<TaskDateEntry>>{};
    for (var i = 0; i < daysAhead; i++) {
      final date = today.add(Duration(days: i + 1));
      grouped[date] = [];
    }

    // Add tasks to appropriate dates
    for (final task in tasks) {
      // Add task for its start date if within range
      if (task.startDate != null) {
        final startDateOnly = _dateOnly(task.startDate!);
        if (!startDateOnly.isBefore(today.add(const Duration(days: 1))) &&
            startDateOnly.isBefore(endDate)) {
          grouped[startDateOnly]?.add(
            TaskDateEntry(
              task: task,
              date: startDateOnly,
              dateType: TaskDateType.start,
            ),
          );
        }
      }

      // Add task for its deadline date if within range
      if (task.deadlineDate != null) {
        final deadlineDateOnly = _dateOnly(task.deadlineDate!);
        if (!deadlineDateOnly.isBefore(today.add(const Duration(days: 1))) &&
            deadlineDateOnly.isBefore(endDate)) {
          // Only add if it's a different date than start date
          final startDateOnly = task.startDate != null
              ? _dateOnly(task.startDate!)
              : null;
          if (startDateOnly == null || startDateOnly != deadlineDateOnly) {
            grouped[deadlineDateOnly]?.add(
              TaskDateEntry(
                task: task,
                date: deadlineDateOnly,
                dateType: TaskDateType.deadline,
              ),
            );
          }
        }
      }
    }

    return grouped;
  }

  /// Groups tasks and projects together by date.
  ///
  /// Returns a map where keys are date-only DateTime objects and values
  /// are lists of [UpcomingDateEntry] (either tasks or projects) for that date.
  static Map<DateTime, List<UpcomingDateEntry>> groupAllByDate({
    required List<Task> tasks,
    required List<Project> projects,
    required DateTime now,
    int daysAhead = 7,
  }) {
    final today = _dateOnly(now);
    final endDate = today.add(Duration(days: daysAhead));

    // Initialize map with all dates in range
    final grouped = <DateTime, List<UpcomingDateEntry>>{};
    for (var i = 0; i < daysAhead; i++) {
      final date = today.add(Duration(days: i + 1));
      grouped[date] = [];
    }

    // Add tasks to appropriate dates
    for (final task in tasks) {
      _addItemToDateMap(
        grouped: grouped,
        startDate: task.startDate,
        deadlineDate: task.deadlineDate,
        today: today,
        endDate: endDate,
        createEntry: (date, dateType) => UpcomingTaskEntry(
          task: task,
          date: date,
          dateType: dateType,
        ),
      );
    }

    // Add projects to appropriate dates
    for (final project in projects) {
      // Skip completed projects
      if (project.completed) continue;

      _addItemToDateMap(
        grouped: grouped,
        startDate: project.startDate,
        deadlineDate: project.deadlineDate,
        today: today,
        endDate: endDate,
        createEntry: (date, dateType) => UpcomingProjectEntry(
          project: project,
          date: date,
          dateType: dateType,
        ),
      );
    }

    return grouped;
  }

  static void _addItemToDateMap<T extends UpcomingDateEntry>({
    required Map<DateTime, List<UpcomingDateEntry>> grouped,
    required DateTime? startDate,
    required DateTime? deadlineDate,
    required DateTime today,
    required DateTime endDate,
    required T Function(DateTime date, TaskDateType dateType) createEntry,
  }) {
    DateTime? startDateOnly;
    DateTime? deadlineDateOnly;

    // Add for start date if within range
    if (startDate != null) {
      startDateOnly = _dateOnly(startDate);
      if (!startDateOnly.isBefore(today.add(const Duration(days: 1))) &&
          startDateOnly.isBefore(endDate)) {
        grouped[startDateOnly]?.add(
          createEntry(startDateOnly, TaskDateType.start),
        );
      }
    }

    // Add for deadline date if within range and different from start
    if (deadlineDate != null) {
      deadlineDateOnly = _dateOnly(deadlineDate);
      if (!deadlineDateOnly.isBefore(today.add(const Duration(days: 1))) &&
          deadlineDateOnly.isBefore(endDate)) {
        // Only add if it's a different date than start date
        if (startDateOnly == null || startDateOnly != deadlineDateOnly) {
          grouped[deadlineDateOnly]?.add(
            createEntry(deadlineDateOnly, TaskDateType.deadline),
          );
        }
      }
    }
  }

  static DateTime _dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
}
