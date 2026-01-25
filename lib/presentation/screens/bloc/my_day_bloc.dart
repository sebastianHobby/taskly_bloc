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
    required this.pinnedTasks,
    required this.acceptedDue,
    required this.acceptedStarts,
    required this.acceptedFocus,
    required this.completedPicks,
    required this.selectedTotalCount,
    required this.todaySelectedTaskIds,
  });

  final MyDaySummary summary;
  final MyDayMixVm mix;
  final List<Task> tasks;
  final List<Task> pinnedTasks;

  /// Tasks accepted from the plan "Overdue & due" section.
  final List<Task> acceptedDue;

  /// Tasks accepted from the plan "Starts today" section.
  final List<Task> acceptedStarts;

  /// Tasks accepted from the plan "Suggestions" section.
  final List<Task> acceptedFocus;

  /// Tasks selected for today that are already completed.
  final List<Task> completedPicks;

  final int selectedTotalCount;

  /// Full set of task ids selected for today (from plan persistence).
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
        pinnedTasks: vm.pinnedTasks,
        acceptedDue: vm.acceptedDue,
        acceptedStarts: vm.acceptedStarts,
        acceptedFocus: vm.acceptedFocus,
        completedPicks: vm.completedPicks,
        selectedTotalCount: vm.selectedTotalCount,
        todaySelectedTaskIds: vm.todaySelectedTaskIds,
      ),
    );
  }
}
