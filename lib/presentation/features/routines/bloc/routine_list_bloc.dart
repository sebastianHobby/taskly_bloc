import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';

import 'package:taskly_bloc/presentation/features/routines/model/routine_list_item.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';

part 'routine_list_bloc.freezed.dart';

@freezed
sealed class RoutineListEvent with _$RoutineListEvent {
  const factory RoutineListEvent.subscriptionRequested() =
      RoutineListSubscriptionRequested;
}

@freezed
sealed class RoutineListState with _$RoutineListState {
  const factory RoutineListState.initial() = RoutineListInitial;
  const factory RoutineListState.loading() = RoutineListLoading;
  const factory RoutineListState.loaded({
    required List<RoutineListItem> routines,
  }) = RoutineListLoaded;
  const factory RoutineListState.error({
    required Object error,
    StackTrace? stackTrace,
  }) = RoutineListError;
}

class RoutineListBloc extends Bloc<RoutineListEvent, RoutineListState> {
  RoutineListBloc({
    required RoutineRepositoryContract routineRepository,
    required SessionDayKeyService sessionDayKeyService,
    required AppErrorReporter errorReporter,
    RoutineScheduleService scheduleService = const RoutineScheduleService(),
  }) : _routineRepository = routineRepository,
       _sessionDayKeyService = sessionDayKeyService,
       _errorReporter = errorReporter,
       _scheduleService = scheduleService,
       super(const RoutineListInitial()) {
    on<RoutineListSubscriptionRequested>(
      _onSubscriptionRequested,
      transformer: restartable(),
    );
  }

  final RoutineRepositoryContract _routineRepository;
  final SessionDayKeyService _sessionDayKeyService;
  final AppErrorReporter _errorReporter;
  final RoutineScheduleService _scheduleService;

  Future<void> _onSubscriptionRequested(
    RoutineListSubscriptionRequested event,
    Emitter<RoutineListState> emit,
  ) async {
    emit(const RoutineListLoading());

    try {
      final initial = await _routineRepository.getAll(includeInactive: true);
      final completions = await _routineRepository.getCompletions();
      final skips = await _routineRepository.getSkips();
      final today =
          _sessionDayKeyService.todayDayKeyUtc.valueOrNull ??
          await _sessionDayKeyService.todayDayKeyUtc.first;

      emit(
        RoutineListLoaded(
          routines: _buildItems(
            routines: initial,
            dayKeyUtc: today,
            completions: completions,
            skips: skips,
          ),
        ),
      );
    } catch (error, stackTrace) {
      _errorReporter.reportUnexpected(
        error,
        stackTrace,
        message: '[RoutineListBloc] initial load failed',
      );
      emit(RoutineListError(error: error, stackTrace: stackTrace));
      return;
    }

    final routines$ = _routineRepository.watchAll(includeInactive: true);
    final completions$ = _routineRepository.watchCompletions();
    final skips$ = _routineRepository.watchSkips();
    final dayKey$ = _sessionDayKeyService.todayDayKeyUtc;

    final combined$ = Rx.combineLatest4<
      DateTime,
      List<Routine>,
      List<RoutineCompletion>,
      List<RoutineSkip>,
      RoutineListState
    >(
      dayKey$,
      routines$,
      completions$,
      skips$,
      (dayKey, routines, completions, skips) {
        return RoutineListLoaded(
          routines: _buildItems(
            routines: routines,
            dayKeyUtc: dayKey,
            completions: completions,
            skips: skips,
          ),
        );
      },
    );

    await emit.forEach<RoutineListState>(
      combined$,
      onData: (state) => state,
      onError: (error, stackTrace) {
        _errorReporter.reportUnexpected(
          error,
          stackTrace,
          message: '[RoutineListBloc] watch failed',
        );
        return RoutineListError(error: error, stackTrace: stackTrace);
      },
    );
  }

  List<RoutineListItem> _buildItems({
    required List<Routine> routines,
    required DateTime dayKeyUtc,
    required List<RoutineCompletion> completions,
    required List<RoutineSkip> skips,
  }) {
    final items = <RoutineListItem>[];
    for (final routine in routines) {
      final snapshot = _scheduleService.buildSnapshot(
        routine: routine,
        dayKeyUtc: dayKeyUtc,
        completions: completions,
        skips: skips,
      );
      items.add(RoutineListItem(routine: routine, snapshot: snapshot));
    }

    items.sort((a, b) => a.routine.name.compareTo(b.routine.name));
    return items;
  }
}
