import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

import 'package:taskly_bloc/presentation/features/routines/model/routine_list_item.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';

part 'routine_list_bloc.freezed.dart';

@freezed
sealed class RoutineListEvent with _$RoutineListEvent {
  const factory RoutineListEvent.subscriptionRequested() =
      RoutineListSubscriptionRequested;
  const factory RoutineListEvent.valueFilterChanged({String? valueId}) =
      RoutineListValueFilterChanged;
  const factory RoutineListEvent.logRequested({required String routineId}) =
      RoutineListLogRequested;
}

@freezed
sealed class RoutineListState with _$RoutineListState {
  const factory RoutineListState.initial() = RoutineListInitial;
  const factory RoutineListState.loading() = RoutineListLoading;
  const factory RoutineListState.loaded({
    required List<RoutineListItem> routines,
    required List<Value> values,
    String? selectedValueId,
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
    required SessionSharedDataService sharedDataService,
    required RoutineWriteService routineWriteService,
    required NowService nowService,
    RoutineScheduleService scheduleService = const RoutineScheduleService(),
  }) : _routineRepository = routineRepository,
       _sessionDayKeyService = sessionDayKeyService,
       _errorReporter = errorReporter,
       _sharedDataService = sharedDataService,
       _routineWriteService = routineWriteService,
       _nowService = nowService,
       _scheduleService = scheduleService,
       super(const RoutineListInitial()) {
    on<RoutineListSubscriptionRequested>(
      _onSubscriptionRequested,
      transformer: restartable(),
    );
    on<RoutineListValueFilterChanged>(_onValueFilterChanged);
    on<RoutineListLogRequested>(_onLogRequested, transformer: droppable());
  }

  final RoutineRepositoryContract _routineRepository;
  final SessionDayKeyService _sessionDayKeyService;
  final AppErrorReporter _errorReporter;
  final SessionSharedDataService _sharedDataService;
  final RoutineWriteService _routineWriteService;
  final NowService _nowService;
  final RoutineScheduleService _scheduleService;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  List<RoutineListItem> _latestItems = const <RoutineListItem>[];
  List<Value> _latestValues = const <Value>[];
  String? _selectedValueId;

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

      final values = await _sharedDataService.watchValues().first;
      emit(
        _buildLoadedState(
          routines: initial,
          values: values,
          dayKeyUtc: today,
          completions: completions,
          skips: skips,
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
    final values$ = _sharedDataService.watchValues();

    final combined$ =
        Rx.combineLatest5<
          DateTime,
          List<Routine>,
          List<RoutineCompletion>,
          List<RoutineSkip>,
          List<Value>,
          RoutineListState
        >(
          dayKey$,
          routines$,
          completions$,
          skips$,
          values$,
          (dayKey, routines, completions, skips, values) {
            return _buildLoadedState(
              routines: routines,
              values: values,
              dayKeyUtc: dayKey,
              completions: completions,
              skips: skips,
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

  void _onValueFilterChanged(
    RoutineListValueFilterChanged event,
    Emitter<RoutineListState> emit,
  ) {
    _selectedValueId = event.valueId?.trim().isEmpty ?? true
        ? null
        : event.valueId;
    if (_latestItems.isEmpty && _latestValues.isEmpty) return;
    emit(
      RoutineListLoaded(
        routines: _latestItems,
        values: _latestValues,
        selectedValueId: _selectedValueId,
      ),
    );
  }

  Future<void> _onLogRequested(
    RoutineListLogRequested event,
    Emitter<RoutineListState> emit,
  ) async {
    final completedToday = _isCompletedToday(event.routineId);
    final dayKeyUtc =
        _dayKeyForRoutine(event.routineId) ?? dateOnly(_nowService.nowUtc());
    if (completedToday) {
      final context = _contextFactory.create(
        feature: 'routines',
        screen: 'routines_list',
        intent: 'routine_unlog',
        operation: 'routines.unlog',
        entityType: 'routine',
        entityId: event.routineId,
      );

      await _routineWriteService.removeLatestCompletionForDay(
        routineId: event.routineId,
        dayKeyUtc: dayKeyUtc,
        context: context,
      );
      return;
    }

    final context = _contextFactory.create(
      feature: 'routines',
      screen: 'routines_list',
      intent: 'routine_complete',
      operation: 'routines.complete',
      entityType: 'routine',
      entityId: event.routineId,
    );

    await _routineWriteService.recordCompletion(
      routineId: event.routineId,
      completedAtUtc: _nowService.nowUtc(),
      context: context,
    );
  }

  Future<void> logRoutines(List<String> routineIds) async {
    if (routineIds.isEmpty) return;
    for (final routineId in routineIds) {
      if (_isCompletedToday(routineId)) continue;
      final context = _contextFactory.create(
        feature: 'routines',
        screen: 'routines_list',
        intent: 'routine_bulk_log',
        operation: 'routines.complete',
        entityType: 'routine',
        entityId: routineId,
      );
      try {
        await _routineWriteService.recordCompletion(
          routineId: routineId,
          completedAtUtc: _nowService.nowUtc(),
          context: context,
        );
      } catch (error, stackTrace) {
        _errorReporter.reportUnexpected(
          error,
          stackTrace,
          context: context,
          message: '[RoutineListBloc] bulk log failed',
        );
      }
    }
  }

  Future<void> unlogRoutines(List<String> routineIds) async {
    if (routineIds.isEmpty) return;
    for (final routineId in routineIds) {
      final dayKeyUtc =
          _dayKeyForRoutine(routineId) ?? dateOnly(_nowService.nowUtc());
      final context = _contextFactory.create(
        feature: 'routines',
        screen: 'routines_list',
        intent: 'routine_bulk_unlog',
        operation: 'routines.unlog',
        entityType: 'routine',
        entityId: routineId,
      );
      try {
        await _routineWriteService.removeLatestCompletionForDay(
          routineId: routineId,
          dayKeyUtc: dayKeyUtc,
          context: context,
        );
      } catch (error, stackTrace) {
        _errorReporter.reportUnexpected(
          error,
          stackTrace,
          context: context,
          message: '[RoutineListBloc] bulk unlog failed',
        );
      }
    }
  }

  Future<void> deactivateRoutines(List<String> routineIds) async {
    if (routineIds.isEmpty) return;
    for (final routineId in routineIds) {
      final routine = _routineById(routineId);
      if (routine == null || !routine.isActive) continue;

      final context = _contextFactory.create(
        feature: 'routines',
        screen: 'routines_list',
        intent: 'routine_bulk_deactivate',
        operation: 'routines.deactivate',
        entityType: 'routine',
        entityId: routineId,
      );

      try {
        await _routineWriteService.update(
          UpdateRoutineCommand(
            id: routine.id,
            name: routine.name,
            valueId: routine.valueId,
            routineType: routine.routineType,
            targetCount: routine.targetCount,
            scheduleDays: routine.scheduleDays,
            minSpacingDays: routine.minSpacingDays,
            restDayBuffer: routine.restDayBuffer,
            preferredWeeks: routine.preferredWeeks,
            fixedDayOfMonth: routine.fixedDayOfMonth,
            fixedWeekday: routine.fixedWeekday,
            fixedWeekOfMonth: routine.fixedWeekOfMonth,
            isActive: false,
            pausedUntilUtc: routine.pausedUntil,
          ),
          context: context,
        );
      } catch (error, stackTrace) {
        _errorReporter.reportUnexpected(
          error,
          stackTrace,
          context: context,
          message: '[RoutineListBloc] bulk deactivate failed',
        );
      }
    }
  }

  Future<void> activateRoutines(List<String> routineIds) async {
    if (routineIds.isEmpty) return;
    for (final routineId in routineIds) {
      final routine = _routineById(routineId);
      if (routine == null || routine.isActive) continue;

      final context = _contextFactory.create(
        feature: 'routines',
        screen: 'routines_list',
        intent: 'routine_bulk_activate',
        operation: 'routines.activate',
        entityType: 'routine',
        entityId: routineId,
      );

      try {
        await _routineWriteService.update(
          UpdateRoutineCommand(
            id: routine.id,
            name: routine.name,
            valueId: routine.valueId,
            routineType: routine.routineType,
            targetCount: routine.targetCount,
            scheduleDays: routine.scheduleDays,
            minSpacingDays: routine.minSpacingDays,
            restDayBuffer: routine.restDayBuffer,
            preferredWeeks: routine.preferredWeeks,
            fixedDayOfMonth: routine.fixedDayOfMonth,
            fixedWeekday: routine.fixedWeekday,
            fixedWeekOfMonth: routine.fixedWeekOfMonth,
            isActive: true,
            pausedUntilUtc: routine.pausedUntil,
          ),
          context: context,
        );
      } catch (error, stackTrace) {
        _errorReporter.reportUnexpected(
          error,
          stackTrace,
          context: context,
          message: '[RoutineListBloc] bulk activate failed',
        );
      }
    }
  }

  Future<void> deleteRoutines(List<String> routineIds) async {
    if (routineIds.isEmpty) return;
    for (final routineId in routineIds) {
      final context = _contextFactory.create(
        feature: 'routines',
        screen: 'routines_list',
        intent: 'routine_bulk_delete',
        operation: 'routines.delete',
        entityType: 'routine',
        entityId: routineId,
      );

      try {
        await _routineWriteService.delete(routineId, context: context);
      } catch (error, stackTrace) {
        _errorReporter.reportUnexpected(
          error,
          stackTrace,
          context: context,
          message: '[RoutineListBloc] bulk delete failed',
        );
      }
    }
  }

  RoutineListLoaded _buildLoadedState({
    required List<Routine> routines,
    required List<Value> values,
    required DateTime dayKeyUtc,
    required List<RoutineCompletion> completions,
    required List<RoutineSkip> skips,
  }) {
    final items = _buildItems(
      routines: routines,
      dayKeyUtc: dayKeyUtc,
      completions: completions,
      skips: skips,
    );
    _latestItems = items;
    _latestValues = values;
    return RoutineListLoaded(
      routines: items,
      values: values,
      selectedValueId: _selectedValueId,
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
      items.add(
        RoutineListItem(
          routine: routine,
          snapshot: snapshot,
          dayKeyUtc: dayKeyUtc,
          completionsInPeriod: _completionsForPeriod(
            routine: routine,
            snapshot: snapshot,
            completions: completions,
          ),
        ),
      );
    }

    items.sort((a, b) => a.routine.name.compareTo(b.routine.name));
    return items;
  }

  List<RoutineCompletion> _completionsForPeriod({
    required Routine routine,
    required RoutineCadenceSnapshot snapshot,
    required List<RoutineCompletion> completions,
  }) {
    final periodStart = dateOnly(snapshot.periodStartUtc);
    final periodEnd = dateOnly(snapshot.periodEndUtc);
    final filtered = <RoutineCompletion>[];

    for (final completion in completions) {
      if (completion.routineId != routine.id) continue;
      final day = dateOnly(completion.completedAtUtc);
      if (day.isBefore(periodStart) || day.isAfter(periodEnd)) continue;
      filtered.add(completion);
    }

    return filtered;
  }

  bool _isCompletedToday(String routineId) {
    for (final item in _latestItems) {
      if (item.routine.id != routineId) continue;
      final today = dateOnly(item.dayKeyUtc);
      return item.completionsInPeriod.any(
        (completion) =>
            completion.routineId == routineId &&
            dateOnly(completion.completedAtUtc).isAtSameMomentAs(today),
      );
    }
    return false;
  }

  Routine? _routineById(String routineId) {
    for (final item in _latestItems) {
      if (item.routine.id == routineId) return item.routine;
    }
    return null;
  }

  DateTime? _dayKeyForRoutine(String routineId) {
    for (final item in _latestItems) {
      if (item.routine.id == routineId) return item.dayKeyUtc;
    }
    return null;
  }
}
