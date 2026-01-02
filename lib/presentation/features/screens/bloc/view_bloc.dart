import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/view_definition.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_acknowledgment.dart';
import 'package:taskly_bloc/domain/services/screens/view_service.dart';
import 'package:taskly_bloc/domain/services/workflow/problem_detector_service.dart';

part 'view_bloc.freezed.dart';

// =============================================================================
// Events
// =============================================================================

@freezed
sealed class ViewEvent with _$ViewEvent {
  /// Start watching view data based on ViewDefinition
  const factory ViewEvent.started({
    required ViewDefinition view,
    String? parentEntityId,
  }) = ViewStarted;

  /// Refresh view data
  const factory ViewEvent.refreshed() = ViewRefreshed;

  /// Toggle task completion
  const factory ViewEvent.taskCompletionToggled({
    required Task task,
  }) = ViewTaskCompletionToggled;

  /// Dismiss a detected problem
  const factory ViewEvent.problemDismissed({
    required DetectedProblem problem,
  }) = ViewProblemDismissed;
}

// =============================================================================
// States
// =============================================================================

@freezed
sealed class ViewState with _$ViewState {
  const factory ViewState.initial() = ViewInitial;
  const factory ViewState.loading() = ViewLoading;

  /// Collection view loaded state
  const factory ViewState.collectionLoaded({
    required List<dynamic> items,
    required DisplayConfig display,
    @Default([]) List<DetectedProblem> problems,
  }) = ViewCollectionLoaded;

  /// Agenda view loaded state (tasks grouped by date)
  const factory ViewState.agendaLoaded({
    required List<Task> tasks,
    required DisplayConfig display,
    required AgendaConfig agendaConfig,
    @Default([]) List<DetectedProblem> problems,
  }) = ViewAgendaLoaded;

  /// Detail view loaded state
  const factory ViewState.detailLoaded({
    required dynamic entity,
    required DetailParentType parentType,
    ViewDefinition? childView,
  }) = ViewDetailLoaded;

  /// Allocated view loaded state (Next Actions style)
  const factory ViewState.allocatedLoaded({
    required List<Task> tasks,
    required DisplayConfig display,
    @Default([]) List<DetectedProblem> problems,
  }) = ViewAllocatedLoaded;

  const factory ViewState.empty({
    required String message,
  }) = ViewEmpty;

  const factory ViewState.error({
    required Object error,
    required StackTrace stackTrace,
  }) = ViewError;
}

// =============================================================================
// BLoC
// =============================================================================

/// Generic BLoC for handling all view types via ViewDefinition.
///
/// Uses ViewService to fetch entities and ProblemDetectorService to detect
/// problems based on the view's opt-in configuration.
///
/// This replaces individual view-specific BLoCs with a unified approach.
class ViewBloc extends Bloc<ViewEvent, ViewState> {
  ViewBloc({
    required ViewService viewService,
    required ProblemDetectorService problemDetectorService,
  }) : _viewService = viewService,
       _problemDetectorService = problemDetectorService,
       super(const ViewState.initial()) {
    on<ViewStarted>(_onStarted);
    on<ViewRefreshed>(_onRefreshed);
    on<ViewTaskCompletionToggled>(_onTaskCompletionToggled);
    on<ViewProblemDismissed>(_onProblemDismissed);
  }

  final ViewService _viewService;
  final ProblemDetectorService _problemDetectorService;

  ViewDefinition? _currentView;
  String? _parentEntityId;
  StreamSubscription<dynamic>? _dataSubscription;

  // Session-only dismissed problems (not persisted)
  final Set<String> _dismissedProblemIds = {};

  Future<void> _onStarted(
    ViewStarted event,
    Emitter<ViewState> emit,
  ) async {
    _currentView = event.view;
    _parentEntityId = event.parentEntityId;
    _dismissedProblemIds.clear();

    await _startWatching(emit);
  }

  Future<void> _onRefreshed(
    ViewRefreshed event,
    Emitter<ViewState> emit,
  ) async {
    if (_currentView == null) return;
    await _startWatching(emit);
  }

  Future<void> _onTaskCompletionToggled(
    ViewTaskCompletionToggled event,
    Emitter<ViewState> emit,
  ) async {
    // Task completion is handled by TaskRepository directly
    // The view will update via the stream subscription
    talker.blocLog(
      'ViewBloc',
      'Task completion toggled for ${event.task.id} - will update via stream',
    );
  }

  Future<void> _onProblemDismissed(
    ViewProblemDismissed event,
    Emitter<ViewState> emit,
  ) async {
    // Session-only dismiss - just track the problem ID
    _dismissedProblemIds.add(event.problem.entityId);

    // Re-emit current state with filtered problems
    final currentState = state;
    switch (currentState) {
      case ViewCollectionLoaded(
        items: final items,
        display: final display,
        problems: final problems,
      ):
        emit(
          ViewState.collectionLoaded(
            items: items,
            display: display,
            problems: _filterDismissedProblems(problems),
          ),
        );

      case ViewAgendaLoaded(
        tasks: final tasks,
        display: final display,
        agendaConfig: final config,
        problems: final problems,
      ):
        emit(
          ViewState.agendaLoaded(
            tasks: tasks,
            display: display,
            agendaConfig: config,
            problems: _filterDismissedProblems(problems),
          ),
        );

      case ViewAllocatedLoaded(
        tasks: final tasks,
        display: final display,
        problems: final problems,
      ):
        emit(
          ViewState.allocatedLoaded(
            tasks: tasks,
            display: display,
            problems: _filterDismissedProblems(problems),
          ),
        );

      case ViewInitial():
      case ViewLoading():
      case ViewDetailLoaded():
      case ViewEmpty():
      case ViewError():
        // No problems to dismiss
        break;
    }
  }

  Future<void> _startWatching(Emitter<ViewState> emit) async {
    emit(const ViewState.loading());
    await _dataSubscription?.cancel();

    final view = _currentView;
    if (view == null) {
      emit(
        const ViewState.error(
          error: 'No view definition provided',
          stackTrace: StackTrace.empty,
        ),
      );
      return;
    }

    try {
      switch (view) {
        case CollectionView(
          selector: final selector,
          display: final display,
        ):
          await emit.forEach<List<dynamic>>(
            _viewService.watchCollectionView(
              selector: selector,
              display: display,
            ),
            onData: (items) => _handleCollectionData(items, display),
          );

        case AgendaView(
          selector: final selector,
          display: final display,
          agendaConfig: final agendaConfig,
        ):
          await emit.forEach<List<Task>>(
            _viewService.watchAgendaView(
              selector: selector,
              display: display,
              agendaConfig: agendaConfig,
            ),
            onData: (tasks) => _handleAgendaData(tasks, display, agendaConfig),
          );

        case DetailView(
          parentType: final parentType,
          childView: final childView,
        ):
          final entityId = _parentEntityId;
          if (entityId == null) {
            emit(
              const ViewState.error(
                error: 'Detail view requires parentEntityId',
                stackTrace: StackTrace.empty,
              ),
            );
            return;
          }
          await emit.forEach<dynamic>(
            _viewService.watchDetailEntity(
              parentType: parentType,
              entityId: entityId,
            ),
            onData: (entity) =>
                _handleDetailData(entity, parentType, childView),
          );

        case AllocatedView(
          selector: final selector,
          display: final display,
        ):
          await emit.forEach<List<Task>>(
            _viewService.watchAllocatedView(
              selector: selector,
              display: display,
            ),
            onData: (tasks) => _handleAllocatedData(tasks, display),
          );
      }
    } catch (e, st) {
      talker.handle(e, st, '[ViewBloc] Error watching view');
      emit(ViewState.error(error: e, stackTrace: st));
    }
  }

  ViewState _handleCollectionData(List<dynamic> items, DisplayConfig display) {
    if (items.isEmpty) {
      return const ViewState.empty(message: 'No items found');
    }

    // Detect problems for tasks
    final List<DetectedProblem> problems = [];
    if (items.isNotEmpty && items.first is Task) {
      _detectProblemsAsync(items.cast<Task>(), display);
    }

    return ViewState.collectionLoaded(
      items: items,
      display: display,
      problems: _filterDismissedProblems(problems),
    );
  }

  ViewState _handleAgendaData(
    List<Task> tasks,
    DisplayConfig display,
    AgendaConfig agendaConfig,
  ) {
    _detectProblemsAsync(tasks, display);

    return ViewState.agendaLoaded(
      tasks: tasks,
      display: display,
      agendaConfig: agendaConfig,
      problems: [],
    );
  }

  ViewState _handleDetailData(
    dynamic entity,
    DetailParentType parentType,
    ViewDefinition? childView,
  ) {
    if (entity == null) {
      return const ViewState.empty(message: 'Entity not found');
    }

    return ViewState.detailLoaded(
      entity: entity,
      parentType: parentType,
      childView: childView,
    );
  }

  ViewState _handleAllocatedData(List<Task> tasks, DisplayConfig display) {
    _detectProblemsAsync(tasks, display);

    return ViewState.allocatedLoaded(
      tasks: tasks,
      display: display,
      problems: [],
    );
  }

  /// Detect problems asynchronously and update state
  void _detectProblemsAsync(List<Task> tasks, DisplayConfig display) {
    _problemDetectorService
        .detectTaskProblems(
          tasks: tasks,
          displayConfig: display,
        )
        .then((problems) {
          // Only emit if we have problems and bloc is still active
          if (problems.isNotEmpty && !isClosed) {
            final filtered = _filterDismissedProblems(problems);
            if (filtered.isNotEmpty) {
              _emitWithProblems(filtered);
            }
          }
        });
  }

  void _emitWithProblems(List<DetectedProblem> problems) {
    final currentState = state;
    switch (currentState) {
      case ViewCollectionLoaded(items: final items, display: final display):
        // ignore: invalid_use_of_visible_for_testing_member, emit is valid for bloc internals
        emit(
          ViewState.collectionLoaded(
            items: items,
            display: display,
            problems: problems,
          ),
        );

      case ViewAgendaLoaded(
        tasks: final tasks,
        display: final display,
        agendaConfig: final config,
      ):
        // ignore: invalid_use_of_visible_for_testing_member, emit is valid for bloc internals
        emit(
          ViewState.agendaLoaded(
            tasks: tasks,
            display: display,
            agendaConfig: config,
            problems: problems,
          ),
        );

      case ViewAllocatedLoaded(tasks: final tasks, display: final display):
        // ignore: invalid_use_of_visible_for_testing_member, emit is valid for bloc internals
        emit(
          ViewState.allocatedLoaded(
            tasks: tasks,
            display: display,
            problems: problems,
          ),
        );

      case ViewInitial():
      case ViewLoading():
      case ViewDetailLoaded():
      case ViewEmpty():
      case ViewError():
        // No problems to update
        break;
    }
  }

  List<DetectedProblem> _filterDismissedProblems(
    List<DetectedProblem> problems,
  ) {
    return problems
        .where((p) => !_dismissedProblemIds.contains(p.entityId))
        .toList();
  }

  @override
  Future<void> close() {
    _dataSubscription?.cancel();
    return super.close();
  }
}
