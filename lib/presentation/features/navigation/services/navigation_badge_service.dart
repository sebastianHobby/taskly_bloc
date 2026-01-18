import 'package:taskly_domain/contracts.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/params/list_section_params_v2.dart';
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
      'scheduled' => _taskRepository.watchAllCount(
        _buildTaskQueryFromAgendaParams(
          AgendaSectionParamsV2(
            dateField: AgendaDateFieldV2.deadlineDate,
            layout: AgendaLayoutV2.dayCardsFeed,
          ),
          now: _nowService.nowLocal(),
        ),
      ),
      _ => null,
    };

    _badgeStreamCache[screenKey] = stream;
    return stream;
  }

  TaskQuery _buildTaskQueryFromAgendaParams(
    AgendaSectionParamsV2 params, {
    required DateTime now,
  }) {
    final baseFilter =
        params.additionalFilter?.filter ?? const QueryFilter.matchAll();

    final alreadyHasCompletionPredicate = baseFilter.shared.any(
      (p) =>
          p is TaskBoolPredicate &&
          p.field == TaskBoolField.completed &&
          p.operator == BoolOperator.isFalse,
    );

    final withCompletion = alreadyHasCompletionPredicate
        ? baseFilter
        : baseFilter.copyWith(
            shared: [
              const TaskBoolPredicate(
                field: TaskBoolField.completed,
                operator: BoolOperator.isFalse,
              ),
              ...baseFilter.shared,
            ],
          );

    final dateField = switch (params.dateField) {
      AgendaDateFieldV2.deadlineDate => TaskDateField.deadlineDate,
      AgendaDateFieldV2.startDate => TaskDateField.startDate,
      AgendaDateFieldV2.scheduledFor => TaskDateField.deadlineDate,
    };

    // Only include tasks that have the date field set.
    final withDateFilter = withCompletion.copyWith(
      shared: [
        ...withCompletion.shared,
        TaskDatePredicate(
          field: dateField,
          operator: DateOperator.onOrAfter,
          date: DateTime(now.year - 1, now.month, now.day),
        ),
      ],
    );

    return TaskQuery(filter: withDateFilter);
  }
}
