import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_bloc/presentation/shared/services/time/home_day_service.dart';

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
    required HomeDayService homeDayService,
  }) : _taskRepository = taskRepository,
       _homeDayService = homeDayService;

  final TaskRepositoryContract _taskRepository;
  final HomeDayService _homeDayService;

  /// Watch stream of incomplete task count for today.
  ///
  /// Returns a stream that emits the count of incomplete tasks for today
  /// whenever the underlying task data changes. The repository's watchCount
  /// uses SQL COUNT for efficient database-level counting.
  Stream<int> watchIncompleteCount() {
    final dayKeyUtc = _homeDayService.todayDayKeyUtc();
    return _taskRepository.watchAllCount(TaskQuery.today(now: dayKeyUtc));
  }
}
