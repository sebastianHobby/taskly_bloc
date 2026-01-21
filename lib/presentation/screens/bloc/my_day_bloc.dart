import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import 'package:taskly_domain/core.dart';

import 'package:taskly_bloc/presentation/screens/models/my_day_models.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_session_query_service.dart';

sealed class MyDayEvent {
  const MyDayEvent();
}

final class MyDayStarted extends MyDayEvent {
  const MyDayStarted();
}

sealed class MyDayState {
  const MyDayState();
}

final class MyDayLoading extends MyDayState {
  const MyDayLoading();
}

final class MyDayLoaded extends MyDayState {
  const MyDayLoaded({
    required this.summary,
    required this.mix,
    required this.tasks,
    required this.acceptedDue,
    required this.acceptedStarts,
    required this.acceptedFocus,
    required this.dueAcceptedTotalCount,
    required this.startsAcceptedTotalCount,
    required this.focusAcceptedTotalCount,
    required this.selectedTotalCount,
    required this.missingDueCount,
    required this.missingStartsCount,
    required this.missingDueTasks,
    required this.missingStartsTasks,
    required this.todaySelectedTaskIds,
  });

  final MyDaySummary summary;
  final MyDayMixVm mix;
  final List<Task> tasks;

  /// Tasks accepted from the ritual "Overdue & due" section.
  final List<Task> acceptedDue;

  /// Tasks accepted from the ritual "Starts today" section.
  final List<Task> acceptedStarts;

  /// Tasks accepted from the ritual "Suggestions" section.
  final List<Task> acceptedFocus;

  /// Total counts as persisted by the ritual (includes already-completed
  /// accepted tasks).
  final int dueAcceptedTotalCount;
  final int startsAcceptedTotalCount;
  final int focusAcceptedTotalCount;
  final int selectedTotalCount;

  /// Count of bucket candidates that were not selected during the ritual.
  final int missingDueCount;
  final int missingStartsCount;

  /// Tasks (from frozen ritual candidates) that were not selected.
  final List<Task> missingDueTasks;
  final List<Task> missingStartsTasks;

  /// Full set of task ids selected for today (from ritual persistence).
  final Set<String> todaySelectedTaskIds;
}

final class MyDayError extends MyDayState {
  const MyDayError(this.message);

  final String message;
}

final class MyDayBloc extends Bloc<MyDayEvent, MyDayState> {
  MyDayBloc({
    required MyDaySessionQueryService queryService,
  }) : _queryService = queryService,
       super(const MyDayLoading()) {
    on<MyDayStarted>(_onStarted, transformer: restartable());
    add(const MyDayStarted());
  }

  final MyDaySessionQueryService _queryService;

  Future<void> _onStarted(MyDayStarted event, Emitter<MyDayState> emit) async {
    await emit.forEach<MyDayState>(
      _watchState(),
      onData: (state) => state,
      onError: (error, stackTrace) => MyDayError(
        'Failed to load My Day: $error',
      ),
    );
  }

  Stream<MyDayState> _watchState() {
    return _queryService.viewModel.map(
      (vm) => MyDayLoaded(
        summary: vm.summary,
        mix: vm.mix,
        tasks: vm.tasks,
        acceptedDue: vm.acceptedDue,
        acceptedStarts: vm.acceptedStarts,
        acceptedFocus: vm.acceptedFocus,
        dueAcceptedTotalCount: vm.dueAcceptedTotalCount,
        startsAcceptedTotalCount: vm.startsAcceptedTotalCount,
        focusAcceptedTotalCount: vm.focusAcceptedTotalCount,
        selectedTotalCount: vm.selectedTotalCount,
        missingDueCount: vm.missingDueCount,
        missingStartsCount: vm.missingStartsCount,
        missingDueTasks: vm.missingDueTasks,
        missingStartsTasks: vm.missingStartsTasks,
        todaySelectedTaskIds: vm.todaySelectedTaskIds,
      ),
    );
  }
}
