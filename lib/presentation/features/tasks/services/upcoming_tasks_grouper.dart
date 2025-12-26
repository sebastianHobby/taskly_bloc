import 'package:taskly_bloc/domain/models/task.dart';

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

/// Indicates whether a task is associated with a date via its start or deadline.
enum TaskDateType {
  start,
  deadline,
}

/// Groups tasks by date for the upcoming view.
///
/// Tasks with both start date and deadline on different days will appear twice.
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

  static DateTime _dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
}
