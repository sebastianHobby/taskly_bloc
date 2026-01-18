import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';

/// Service for computing badge counts for navigation screens.
///
/// Post-USM, badges are computed explicitly by screen key.
class NavigationBadgeService {
  NavigationBadgeService({
    required TaskRepositoryContract taskRepository,
    required NowService nowService,
  }) : _taskRepository = taskRepository,
       _nowService = nowService;

  final TaskRepositoryContract _taskRepository;
  final NowService _nowService;

  final Map<String, Stream<int>?> _badgeStreamCache = {};

  /// Returns a stream of badge counts for a given system [screenKey].
  Stream<int>? badgeStreamForScreenKey(String screenKey) {
    final normalized = screenKey.replaceAll('-', '_');
    if (_badgeStreamCache.containsKey(screenKey)) {
      return _badgeStreamCache[screenKey];
    }

    // Keep this intentionally small and explicit.
    // Add more mappings as we introduce navigation badges outside USM.
    final stream = switch (normalized) {
      'scheduled' => _taskRepository.watchAllCount(_scheduledQuery()),
      _ => null,
    };

    _badgeStreamCache[screenKey] = stream;
    return stream;
  }

  TaskQuery _scheduledQuery() {
    return TaskQuery(
      filter: QueryFilter<TaskPredicate>(
        shared: const [
          TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
        ],
        orGroups: const [
          [
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.isNotNull,
            ),
          ],
          [
            TaskDatePredicate(
              field: TaskDateField.startDate,
              operator: DateOperator.isNotNull,
            ),
          ],
        ],
      ),
    );
  }
}
