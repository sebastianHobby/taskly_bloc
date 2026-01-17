import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/my_day_ranked_tasks_v1_module_interpreter.dart';

sealed class MyDayMvpEvent {
  const MyDayMvpEvent();
}

final class MyDayMvpStarted extends MyDayMvpEvent {
  const MyDayMvpStarted();
}

sealed class MyDayMvpState {
  const MyDayMvpState();
}

final class MyDayMvpLoading extends MyDayMvpState {
  const MyDayMvpLoading();
}

final class MyDayMvpLoaded extends MyDayMvpState {
  const MyDayMvpLoaded({required this.hero, required this.rankedTasks});

  final MyDayHeroV1SectionResult hero;
  final HierarchyValueProjectTaskV2SectionResult rankedTasks;
}

final class MyDayMvpError extends MyDayMvpState {
  const MyDayMvpError(this.message);

  final String message;
}

final class MyDayMvpBloc extends Bloc<MyDayMvpEvent, MyDayMvpState> {
  MyDayMvpBloc({required MyDayRankedTasksV1ModuleInterpreter interpreter})
    : _interpreter = interpreter,
      super(const MyDayMvpLoading()) {
    on<MyDayMvpStarted>((event, emit) => _subscribe(emit));
    add(const MyDayMvpStarted());
  }

  final MyDayRankedTasksV1ModuleInterpreter _interpreter;

  StreamSubscription<SectionDataResult>? _sub;

  bool _isSubscribed = false;

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    return super.close();
  }

  void _subscribe(Emitter<MyDayMvpState> emit) {
    if (_isSubscribed) return;
    _isSubscribed = true;

    _sub = _interpreter.watch().listen(
      (result) {
        if (result is! HierarchyValueProjectTaskV2SectionResult) {
          emit(
            MyDayMvpError(
              'Unexpected My Day result type: ${result.runtimeType}',
            ),
          );
          return;
        }

        final tasks = result.allTasks;
        final totalCount = tasks.length;
        final doneCount = tasks.where((t) => t.completed).length;

        emit(
          MyDayMvpLoaded(
            hero: MyDayHeroV1SectionResult(
              doneCount: doneCount,
              totalCount: totalCount,
            ),
            rankedTasks: result,
          ),
        );
      },
      onError: (Object e) {
        emit(MyDayMvpError('Failed to load My Day data: $e'));
      },
    );
  }
}
