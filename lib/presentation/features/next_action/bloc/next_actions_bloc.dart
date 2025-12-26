import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/utils/app_logger.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart'
    show SettingsRepositoryContract;
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/presentation/features/next_action/services/next_actions_view_builder.dart';

enum NextActionsStatus {
  initial,
  loading,
  success,
  failure,
}

class NextActionProjectTasks {
  const NextActionProjectTasks({
    required this.project,
    required this.tasks,
  });

  final Project project;
  final List<Task> tasks;
}

class NextActionPriorityGroup {
  const NextActionPriorityGroup({
    required this.priority,
    required this.label,
    required this.projects,
  });

  final int priority;
  final String label;
  final List<NextActionProjectTasks> projects;
}

class NextActionsState {
  const NextActionsState({
    this.status = NextActionsStatus.initial,
    this.groups = const <NextActionPriorityGroup>[],
    this.totalCount = 0,
    this.error,
  });

  final NextActionsStatus status;
  final List<NextActionPriorityGroup> groups;
  final int totalCount;
  final Object? error;

  NextActionsState copyWith({
    NextActionsStatus? status,
    List<NextActionPriorityGroup>? groups,
    int? totalCount,
    Object? error,
  }) {
    return NextActionsState(
      status: status ?? this.status,
      groups: groups ?? this.groups,
      totalCount: totalCount ?? this.totalCount,
      error: error,
    );
  }
}

abstract class NextActionsEvent {
  const NextActionsEvent();
}

class NextActionsSubscriptionRequested extends NextActionsEvent {
  const NextActionsSubscriptionRequested();
}

class NextActionsTaskToggled extends NextActionsEvent {
  const NextActionsTaskToggled(this.task);

  final Task task;
}

class _NextActionsDataReceived extends NextActionsEvent {
  const _NextActionsDataReceived({
    required this.tasks,
    required this.settings,
  });

  final List<Task> tasks;
  final NextActionsSettings settings;
}

class _NextActionsStreamError extends NextActionsEvent {
  const _NextActionsStreamError(this.error);

  final Object error;
}

/// A BLoC that manages the Next Actions view.
///
/// This bloc combines task data from [TaskRepositoryContract] and settings
/// from [SettingsRepositoryContract] into a unified stream. This design:
///
/// 1. **Avoids bloc-to-bloc dependencies** - Uses repository directly
/// 2. **Eliminates race conditions** - Single combined stream ensures
///    atomic updates when either tasks or settings change
/// 3. **Maintains consistency** - View always reflects the latest
///    combination of tasks and settings
class NextActionsBloc extends Bloc<NextActionsEvent, NextActionsState> {
  NextActionsBloc({
    required TaskRepositoryContract taskRepository,
    required SettingsRepositoryContract settingsRepository,
    NextActionsViewBuilder? viewBuilder,
  }) : _taskRepository = taskRepository,
       _settingsRepository = settingsRepository,
       _viewBuilder = viewBuilder ?? NextActionsViewBuilder(),
       super(const NextActionsState()) {
    on<NextActionsSubscriptionRequested>(_onSubscriptionRequested);
    on<_NextActionsDataReceived>(_onDataReceived);
    on<_NextActionsStreamError>(_onStreamError);
    on<NextActionsTaskToggled>(_onTaskToggled);
  }

  final TaskRepositoryContract _taskRepository;
  final SettingsRepositoryContract _settingsRepository;
  final _logger = AppLogger.forBloc('NextActions');
  final NextActionsViewBuilder _viewBuilder;

  StreamSubscription<_CombinedData>? _dataSubscription;

  @override
  Future<void> close() async {
    await _dataSubscription?.cancel();
    return super.close();
  }

  Future<void> _onSubscriptionRequested(
    NextActionsSubscriptionRequested event,
    Emitter<NextActionsState> emit,
  ) async {
    emit(state.copyWith(status: NextActionsStatus.loading));

    await _dataSubscription?.cancel();

    // Watch settings to get the current configuration
    final settingsStream = _settingsRepository.watchNextActionsSettings();

    // Create a stream that switches to a new filtered task stream
    // whenever settings change
    final combinedStream = settingsStream.switchMap((settings) {
      // Build TaskQuery based on current settings
      final rules = <TaskRule>[
        const BooleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isFalse,
        ),
      ];

      // Add project filter based on includeInboxTasks setting
      if (!settings.includeInboxTasks) {
        rules.add(
          const ProjectRule(
            operator: ProjectRuleOperator.isNotNull,
          ),
        );
      }

      final query = TaskQuery(rules: rules);

      // Combine tasks with settings
      return _taskRepository
          .watchAll(query)
          .map(
            (tasks) => _CombinedData(tasks: tasks, settings: settings),
          );
    });

    _dataSubscription = combinedStream.listen(
      (data) => add(
        _NextActionsDataReceived(
          tasks: data.tasks,
          settings: data.settings,
        ),
      ),
      onError: (Object error) => add(_NextActionsStreamError(error)),
    );
  }

  void _onDataReceived(
    _NextActionsDataReceived event,
    Emitter<NextActionsState> emit,
  ) {
    // Tasks are already filtered by the repository with finalized rules
    final view = _buildView(event.tasks, event.settings);
    emit(
      state.copyWith(
        status: NextActionsStatus.success,
        groups: view.groups,
        totalCount: view.totalCount,
      ),
    );
  }

  Future<void> _onTaskToggled(
    NextActionsTaskToggled event,
    Emitter<NextActionsState> emit,
  ) async {
    final task = event.task;
    try {
      await _taskRepository.update(
        id: task.id,
        name: task.name,
        description: task.description,
        completed: !task.completed,
        startDate: task.startDate,
        deadlineDate: task.deadlineDate,
        projectId: task.projectId,
        repeatIcalRrule: task.repeatIcalRrule,
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to toggle task completion in next actions',
        error,
        stackTrace,
      );
      emit(
        state.copyWith(
          status: NextActionsStatus.failure,
          error: error,
        ),
      );
    }
  }

  void _onStreamError(
    _NextActionsStreamError event,
    Emitter<NextActionsState> emit,
  ) {
    emit(
      state.copyWith(
        status: NextActionsStatus.failure,
        error: event.error,
      ),
    );
  }

  ({List<NextActionPriorityGroup> groups, int totalCount}) _buildView(
    List<Task> tasks,
    NextActionsSettings settings,
  ) {
    final selection = _viewBuilder.build(
      tasks: tasks,
      settings: settings,
      now: DateTime.now(),
    );

    final groups = selection.sortedPriorities
        .map((priority) {
          final projects = selection.priorityBuckets[priority] ?? const {};
          final projectGroups =
              projects.entries
                  .map((entry) {
                    final project = selection.projectsById[entry.key];
                    if (project == null) return null;
                    final tasksForProject = List<Task>.unmodifiable(
                      entry.value,
                    );
                    return NextActionProjectTasks(
                      project: project,
                      tasks: tasksForProject,
                    );
                  })
                  .whereType<NextActionProjectTasks>()
                  .toList()
                ..sort((a, b) => a.project.name.compareTo(b.project.name));

          final ruleName = selection.bucketRuleByPriority[priority]?.name
              .trim();
          final label = priority == 9999
              ? 'Unmatched priority'
              : ruleName != null && ruleName.isNotEmpty
              ? 'Priority $priority - $ruleName'
              : 'Priority $priority';

          // Always return the group, even if it has no projects
          return NextActionPriorityGroup(
            priority: priority,
            label: label,
            projects: projectGroups,
          );
        })
        .toList(growable: false);

    return (groups: groups, totalCount: selection.totalCount);
  }
}

/// Internal data class for combining tasks and settings.
class _CombinedData {
  const _CombinedData({
    required this.tasks,
    required this.settings,
  });

  final List<Task> tasks;
  final NextActionsSettings settings;
}
