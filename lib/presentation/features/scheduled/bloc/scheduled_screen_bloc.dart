import 'package:bloc/bloc.dart';

sealed class ScheduledScreenEffect {
  const ScheduledScreenEffect();
}

final class ScheduledOpenTaskNew extends ScheduledScreenEffect {
  const ScheduledOpenTaskNew({required this.defaultDeadlineDay});

  /// Date-only day (local day semantics) to prefill as a deadline.
  final DateTime defaultDeadlineDay;
}

final class ScheduledOpenProjectNew extends ScheduledScreenEffect {
  const ScheduledOpenProjectNew();
}

sealed class ScheduledScreenEvent {
  const ScheduledScreenEvent();
}

final class ScheduledCreateTaskForDayRequested extends ScheduledScreenEvent {
  const ScheduledCreateTaskForDayRequested({required this.day});

  /// Day key to create the task for (date-only semantics).
  final DateTime day;
}

final class ScheduledCreateProjectRequested extends ScheduledScreenEvent {
  const ScheduledCreateProjectRequested();
}

final class ScheduledEffectHandled extends ScheduledScreenEvent {
  const ScheduledEffectHandled();
}

sealed class ScheduledScreenState {
  const ScheduledScreenState({this.effect});

  final ScheduledScreenEffect? effect;
}

final class ScheduledScreenReady extends ScheduledScreenState {
  const ScheduledScreenReady({super.effect});
}

class ScheduledScreenBloc
    extends Bloc<ScheduledScreenEvent, ScheduledScreenState> {
  ScheduledScreenBloc() : super(const ScheduledScreenReady()) {
    on<ScheduledCreateTaskForDayRequested>((event, emit) {
      emit(
        ScheduledScreenReady(
          effect: ScheduledOpenTaskNew(
            defaultDeadlineDay: DateTime(
              event.day.year,
              event.day.month,
              event.day.day,
            ),
          ),
        ),
      );
    });

    on<ScheduledCreateProjectRequested>((event, emit) {
      emit(const ScheduledScreenReady(effect: ScheduledOpenProjectNew()));
    });

    on<ScheduledEffectHandled>((event, emit) {
      if (state.effect == null) return;
      emit(const ScheduledScreenReady());
    });
  }
}
