import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

/// Service that provides today's incomplete task count for navigation badges.
///
/// This replaces the heavier TodayTasksBloc for badge display, providing a
/// simple stream of counts instead of full task lists. The actual Today page
/// uses the standard TaskListBloc for its UI.
///
/// Architecture:
/// - Single responsibility: badge count only
/// - Uses repository's watchAllCount with TaskQuery.today() for efficient SQL counts
/// - Lightweight: delegates counting to the database layer
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
  /// whenever the underlying task data changes. The repository's watchCount
  /// uses SQL COUNT for efficient database-level counting.
  Stream<int> watchIncompleteCount() {
    final now = _nowFactory();
    return _taskRepository.watchAllCount(TaskQuery.today(now: now));
  }
}
