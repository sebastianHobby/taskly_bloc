import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/next_action/services/next_actions_view_builder.dart';
import 'package:taskly_bloc/features/settings/settings.dart';
import 'package:taskly_bloc/features/tasks/utils/task_selector.dart';

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

class NextActionsSettingsUpdated extends NextActionsEvent {
  const NextActionsSettingsUpdated(this.settings);

  final NextActionsSettings settings;
}

class NextActionsTaskToggled extends NextActionsEvent {
  const NextActionsTaskToggled(this.task);

  final Task task;
}

class NextActionsTasksReceived extends NextActionsEvent {
  const NextActionsTasksReceived(this.tasks);

  final List<Task> tasks;
}

class NextActionsStreamError extends NextActionsEvent {
  const NextActionsStreamError(this.error);

  final Object error;
}

class NextActionsBloc extends Bloc<NextActionsEvent, NextActionsState> {
  NextActionsBloc({
    required TaskRepositoryContract taskRepository,
    required SettingsBloc settingsBloc,
    NextActionsViewBuilder? viewBuilder,
    TaskSelector? taskSelector,
  }) : _taskRepository = taskRepository,
       _viewBuilder = viewBuilder ?? NextActionsViewBuilder(),
       _taskSelector = taskSelector ?? TaskSelector(),
       _settingsBloc = settingsBloc,
       super(const NextActionsState()) {
    on<NextActionsSubscriptionRequested>(_onSubscriptionRequested);
    on<NextActionsSettingsUpdated>(_onSettingsUpdated);
    on<NextActionsTasksReceived>(_onTasksReceived);
    on<NextActionsStreamError>(_onStreamError);
    on<NextActionsTaskToggled>(_onTaskToggled);

    _settings =
        _settingsBloc.state.settings?.nextActions ??
        const NextActionsSettings();
    _settingsSubscription = _settingsBloc.stream
        .map(
          (state) => state.settings?.nextActions ?? const NextActionsSettings(),
        )
        .distinct()
        .listen((settings) {
          add(NextActionsSettingsUpdated(settings));
        });
  }

  final TaskRepositoryContract _taskRepository;
  final NextActionsViewBuilder _viewBuilder;
  final TaskSelector _taskSelector;
  final SettingsBloc _settingsBloc;

  late NextActionsSettings _settings;
  List<Task> _latestTasks = const [];
  StreamSubscription<List<Task>>? _tasksSubscription;
  StreamSubscription<NextActionsSettings>? _settingsSubscription;

  @override
  Future<void> close() async {
    await _tasksSubscription?.cancel();
    await _settingsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onSubscriptionRequested(
    NextActionsSubscriptionRequested event,
    Emitter<NextActionsState> emit,
  ) async {
    emit(state.copyWith(status: NextActionsStatus.loading));

    await _tasksSubscription?.cancel();
    _tasksSubscription = _taskRepository
        .watchAll(withRelated: true)
        .listen(
          (tasks) => add(NextActionsTasksReceived(tasks)),
          onError: (Object error, StackTrace _) =>
              add(NextActionsStreamError(error)),
        );
  }

  void _onSettingsUpdated(
    NextActionsSettingsUpdated event,
    Emitter<NextActionsState> emit,
  ) {
    if (event.settings == _settings) return;
    _settings = event.settings;
    if (_latestTasks.isEmpty) return;

    final filtered = _filterTasks(_latestTasks);
    final view = _buildView(filtered);
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
    } catch (error, _) {
      emit(
        state.copyWith(
          status: NextActionsStatus.failure,
          error: error,
        ),
      );
    }
  }

  void _onTasksReceived(
    NextActionsTasksReceived event,
    Emitter<NextActionsState> emit,
  ) {
    _latestTasks = event.tasks;
    final filtered = _filterTasks(event.tasks);
    final view = _buildView(filtered);
    emit(
      state.copyWith(
        status: NextActionsStatus.success,
        groups: view.groups,
        totalCount: view.totalCount,
      ),
    );
  }

  void _onStreamError(
    NextActionsStreamError event,
    Emitter<NextActionsState> emit,
  ) {
    emit(
      state.copyWith(
        status: NextActionsStatus.failure,
        error: event.error,
      ),
    );
  }

  List<Task> _filterTasks(List<Task> tasks) {
    final config = TaskSelector.nextActions(
      includeInbox: _settings.includeInboxTasks,
    );
    return _taskSelector.filter(
      tasks: tasks,
      ruleSets: config.ruleSets,
      sortCriteria: config.sortCriteria,
      now: DateTime.now(),
    );
  }

  ({List<NextActionPriorityGroup> groups, int totalCount}) _buildView(
    List<Task> tasks,
  ) {
    final selection = _viewBuilder.build(
      tasks: tasks,
      settings: _settings,
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
                    // Tasks are already ordered in the selector; avoid re-sorting here.
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
              : [
                  'P$priority',
                  if (ruleName != null && ruleName.isNotEmpty) ruleName,
                ].join(' ');

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
