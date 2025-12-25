import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

/// Service that provides today's incomplete task count for navigation badges.
///
/// This replaces the heavier TodayTasksBloc for badge display, providing a
/// simple stream of counts instead of full task lists. The actual Today page
/// uses the standard TaskListBloc for its UI.
///
/// Architecture:
/// - Single responsibility: badge count only
/// - Uses repository's watchAll with TaskQuery.today() for filtering
/// - Lightweight: maps to count, doesn't hold full task list in memory
class TodayBadgeService {
  TodayBadgeService({
    required TaskRepositoryContract taskRepository,
    DateTime Function()? nowFactory,
  }) : _taskRepository = taskRepository,
       _nowFactory = nowFactory ?? DateTime.now;

  final TaskRepositoryContract _taskRepository;
  final DateTime Function() _nowFactory;

  /// Watch stream of incomplete task count for today.
  ///
  /// Returns a stream that emits the count of incomplete tasks for today
  /// whenever the underlying task data changes. Uses distinct() to prevent
  /// unnecessary rebuilds when count hasn't changed.
  Stream<int> watchIncompleteCount() {
    final now = _nowFactory();
    return _taskRepository
        .watchAll(TaskQuery.today(now: now))
        .map((tasks) => tasks.where((t) => !t.completed).length)
        .distinct();
  }
}
