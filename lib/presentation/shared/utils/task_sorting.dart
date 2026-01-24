import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/time.dart';

List<Task> sortTasksByDeadline(
  List<Task> tasks, {
  required DateTime today,
}) {
  final effectiveToday = dateOnly(today);
  final entries = <_SortEntry>[];
  for (var i = 0; i < tasks.length; i += 1) {
    final task = tasks[i];
    final deadline = dateOnlyOrNull(
      task.occurrence?.deadline ?? task.deadlineDate,
    );
    final bucket = _deadlineBucket(deadline, effectiveToday);
    entries.add(_SortEntry(task, i, deadline, bucket));
  }

  entries.sort((a, b) {
    if (a.bucket != b.bucket) return a.bucket.compareTo(b.bucket);
    final dateCompare = _compareDates(a.date, b.date);
    if (dateCompare != 0) return dateCompare;
    return a.index.compareTo(b.index);
  });

  return entries.map((entry) => entry.task).toList(growable: false);
}

List<Task> sortTasksByStartDate(List<Task> tasks) {
  final entries = <_SortEntry>[];
  for (var i = 0; i < tasks.length; i += 1) {
    final task = tasks[i];
    final start = dateOnlyOrNull(task.occurrence?.date ?? task.startDate);
    final bucket = start == null ? 1 : 0;
    entries.add(_SortEntry(task, i, start, bucket));
  }

  entries.sort((a, b) {
    if (a.bucket != b.bucket) return a.bucket.compareTo(b.bucket);
    final dateCompare = _compareDates(a.date, b.date);
    if (dateCompare != 0) return dateCompare;
    return a.index.compareTo(b.index);
  });

  return entries.map((entry) => entry.task).toList(growable: false);
}

List<Task> sortTasksByDeadlineThenStartThenName(
  List<Task> tasks, {
  required DateTime today,
}) {
  final effectiveToday = dateOnly(today);
  final entries = <_PinnedSortEntry>[];
  for (var i = 0; i < tasks.length; i += 1) {
    final task = tasks[i];
    final deadline = dateOnlyOrNull(
      task.occurrence?.deadline ?? task.deadlineDate,
    );
    final start = dateOnlyOrNull(task.occurrence?.date ?? task.startDate);
    final bucket = _deadlineBucket(deadline, effectiveToday);
    entries.add(
      _PinnedSortEntry(task, i, deadline, start, bucket),
    );
  }

  entries.sort((a, b) {
    if (a.deadlineBucket != b.deadlineBucket) {
      return a.deadlineBucket.compareTo(b.deadlineBucket);
    }
    final deadlineCompare = _compareDates(a.deadline, b.deadline);
    if (deadlineCompare != 0) return deadlineCompare;
    final startCompare = _compareDates(a.start, b.start);
    if (startCompare != 0) return startCompare;
    final nameCompare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (nameCompare != 0) return nameCompare;
    return a.index.compareTo(b.index);
  });

  return entries.map((entry) => entry.task).toList(growable: false);
}

List<Task> sortTasksByDeadlineThenStartThenPriorityThenName(
  List<Task> tasks, {
  required DateTime today,
}) {
  final effectiveToday = dateOnly(today);
  final entries = <_PrioritySortEntry>[];
  for (var i = 0; i < tasks.length; i += 1) {
    final task = tasks[i];
    final deadline = dateOnlyOrNull(
      task.occurrence?.deadline ?? task.deadlineDate,
    );
    final start = dateOnlyOrNull(task.occurrence?.date ?? task.startDate);
    final bucket = _deadlineBucket(deadline, effectiveToday);
    entries.add(
      _PrioritySortEntry(task, i, deadline, start, bucket),
    );
  }

  entries.sort((a, b) {
    if (a.deadlineBucket != b.deadlineBucket) {
      return a.deadlineBucket.compareTo(b.deadlineBucket);
    }
    final deadlineCompare = _compareDates(a.deadline, b.deadline);
    if (deadlineCompare != 0) return deadlineCompare;
    final startCompare = _compareDates(a.start, b.start);
    if (startCompare != 0) return startCompare;
    final priorityCompare = _priorityRank(
      a.priority,
    ).compareTo(_priorityRank(b.priority));
    if (priorityCompare != 0) return priorityCompare;
    final nameCompare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (nameCompare != 0) return nameCompare;
    return a.index.compareTo(b.index);
  });

  return entries.map((entry) => entry.task).toList(growable: false);
}

int _compareDates(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

int _priorityRank(int? priority) {
  if (priority == null) return 99;
  return priority.clamp(1, 99);
}

int _deadlineBucket(DateTime? deadline, DateTime today) {
  if (deadline == null) return 3;
  if (deadline.isBefore(today)) return 0;
  if (deadline.isAtSameMomentAs(today)) return 1;
  return 2;
}

class _SortEntry {
  _SortEntry(this.task, this.index, this.date, this.bucket);

  final Task task;
  final int index;
  final DateTime? date;
  final int bucket;
}

class _PinnedSortEntry {
  _PinnedSortEntry(
    this.task,
    this.index,
    this.deadline,
    this.start,
    this.deadlineBucket,
  );

  final Task task;
  final int index;
  final DateTime? deadline;
  final DateTime? start;
  final int deadlineBucket;

  String get name => task.name;
}

class _PrioritySortEntry {
  _PrioritySortEntry(
    this.task,
    this.index,
    this.deadline,
    this.start,
    this.deadlineBucket,
  );

  final Task task;
  final int index;
  final DateTime? deadline;
  final DateTime? start;
  final int deadlineBucket;

  int? get priority => task.priority;
  String get name => task.name;
}
