import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
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
    on<MyDayMvpStarted>(_onStarted, transformer: restartable());
    add(const MyDayMvpStarted());
  }

  final MyDayRankedTasksV1ModuleInterpreter _interpreter;

  Future<void> _onStarted(
    MyDayMvpStarted event,
    Emitter<MyDayMvpState> emit,
  ) async {
    await emit.forEach<SectionDataResult>(
      _interpreter.watch(),
      onData: (result) {
        if (result is! HierarchyValueProjectTaskV2SectionResult) {
          return MyDayMvpError(
            'Unexpected My Day result type: ${result.runtimeType}',
          );
        }

        final tasks = result.allTasks;
        final totalCount = tasks.length;
        final doneCount = tasks.where((t) => t.completed).length;

        return MyDayMvpLoaded(
          hero: MyDayHeroV1SectionResult(
            doneCount: doneCount,
            totalCount: totalCount,
          ),
          rankedTasks: result,
        );
      },
      onError: (error, stackTrace) => MyDayMvpError(
        'Failed to load My Day data: $error',
      ),
    );
  }
}
