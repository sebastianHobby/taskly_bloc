import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/checklists.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/routines.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

part 'checklist_execution_bloc.freezed.dart';

enum ChecklistParentKind { task, routine }

@freezed
sealed class ChecklistExecutionEvent with _$ChecklistExecutionEvent {
  const factory ChecklistExecutionEvent.started() = _ChecklistExecutionStarted;
  const factory ChecklistExecutionEvent.toggleChanged({
    required String itemId,
    required bool checked,
  }) = _ChecklistExecutionToggleChanged;
  const factory ChecklistExecutionEvent.addItem({required String title}) =
      _ChecklistExecutionAddItem;
  const factory ChecklistExecutionEvent.updateItemTitle({
    required int index,
    required String title,
  }) = _ChecklistExecutionUpdateItemTitle;
  const factory ChecklistExecutionEvent.deleteItem({required int index}) =
      _ChecklistExecutionDeleteItem;
  const factory ChecklistExecutionEvent.reorderItems({
    required int oldIndex,
    required int newIndex,
  }) = _ChecklistExecutionReorderItems;
  const factory ChecklistExecutionEvent.completeParentNow() =
      _ChecklistExecutionCompleteParentNow;
  const factory ChecklistExecutionEvent.checkAllAndComplete() =
      _ChecklistExecutionCheckAllAndComplete;
  const factory ChecklistExecutionEvent.effectHandled() =
      _ChecklistExecutionEffectHandled;
}

@freezed
sealed class ChecklistExecutionEffect with _$ChecklistExecutionEffect {
  const factory ChecklistExecutionEffect.promptComplete() =
      ChecklistExecutionPromptComplete;
  const factory ChecklistExecutionEffect.close() = ChecklistExecutionClose;
  const factory ChecklistExecutionEffect.error({required String message}) =
      ChecklistExecutionError;
}

@freezed
abstract class ChecklistExecutionState with _$ChecklistExecutionState {
  const factory ChecklistExecutionState({
    @Default(true) bool loading,
    @Default(false) bool saving,
    @Default(<ChecklistItem>[]) List<ChecklistItem> items,
    @Default(<String>{}) Set<String> checkedItemIds,
    ChecklistExecutionEffect? effect,
  }) = _ChecklistExecutionState;
}

class ChecklistExecutionBloc
    extends Bloc<ChecklistExecutionEvent, ChecklistExecutionState> {
  ChecklistExecutionBloc.task({
    required String taskId,
    required this.taskTitle,
    required DateTime? occurrenceDate,
    required DateTime? originalOccurrenceDate,
    required TaskChecklistRepositoryContract taskChecklistRepository,
    required TaskWriteService taskWriteService,
    required NowService nowService,
  }) : _kind = ChecklistParentKind.task,
       _taskId = taskId,
       _occurrenceDate = dateOnlyOrNull(occurrenceDate),
       _originalOccurrenceDate = dateOnlyOrNull(
         originalOccurrenceDate ?? occurrenceDate,
       ),
       _taskChecklistRepository = taskChecklistRepository,
       _taskWriteService = taskWriteService,
       _routineId = null,
       _routine = null,
       _routineChecklistRepository = null,
       _routineWriteService = null,
       _routineDayKeyUtc = null,
       _nowService = nowService,
       super(const ChecklistExecutionState()) {
    on<_ChecklistExecutionStarted>(_onStarted);
    on<_ChecklistExecutionToggleChanged>(_onToggleChanged);
    on<_ChecklistExecutionAddItem>(_onAddItem);
    on<_ChecklistExecutionUpdateItemTitle>(_onUpdateItemTitle);
    on<_ChecklistExecutionDeleteItem>(_onDeleteItem);
    on<_ChecklistExecutionReorderItems>(_onReorderItems);
    on<_ChecklistExecutionCompleteParentNow>(_onCompleteParentNow);
    on<_ChecklistExecutionCheckAllAndComplete>(_onCheckAllAndComplete);
    on<_ChecklistExecutionEffectHandled>(_onEffectHandled);
  }

  ChecklistExecutionBloc.routine({
    required Routine routine,
    required DateTime dayKeyUtc,
    required this.taskTitle,
    required RoutineChecklistRepositoryContract routineChecklistRepository,
    required RoutineWriteService routineWriteService,
    required NowService nowService,
  }) : _kind = ChecklistParentKind.routine,
       _taskId = null,
       _occurrenceDate = null,
       _originalOccurrenceDate = null,
       _taskChecklistRepository = null,
       _taskWriteService = null,
       _routineId = routine.id,
       _routine = routine,
       _routineChecklistRepository = routineChecklistRepository,
       _routineWriteService = routineWriteService,
       _routineDayKeyUtc = dateOnly(dayKeyUtc),
       _nowService = nowService,
       super(const ChecklistExecutionState()) {
    on<_ChecklistExecutionStarted>(_onStarted);
    on<_ChecklistExecutionToggleChanged>(_onToggleChanged);
    on<_ChecklistExecutionAddItem>(_onAddItem);
    on<_ChecklistExecutionUpdateItemTitle>(_onUpdateItemTitle);
    on<_ChecklistExecutionDeleteItem>(_onDeleteItem);
    on<_ChecklistExecutionReorderItems>(_onReorderItems);
    on<_ChecklistExecutionCompleteParentNow>(_onCompleteParentNow);
    on<_ChecklistExecutionCheckAllAndComplete>(_onCheckAllAndComplete);
    on<_ChecklistExecutionEffectHandled>(_onEffectHandled);
  }

  final ChecklistParentKind _kind;
  final String? _taskId;
  final DateTime? _occurrenceDate;
  final DateTime? _originalOccurrenceDate;
  final TaskChecklistRepositoryContract? _taskChecklistRepository;
  final TaskWriteService? _taskWriteService;

  final String? _routineId;
  final Routine? _routine;
  final RoutineChecklistRepositoryContract? _routineChecklistRepository;
  final RoutineWriteService? _routineWriteService;
  final DateTime? _routineDayKeyUtc;
  final NowService _nowService;
  final String taskTitle;
  ChecklistParentKind get parentKind => _kind;

  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  Future<void> _onStarted(
    _ChecklistExecutionStarted event,
    Emitter<ChecklistExecutionState> emit,
  ) async {
    emit(state.copyWith(loading: true, effect: null));
    await _reload(emit);
  }

  Future<void> _onToggleChanged(
    _ChecklistExecutionToggleChanged event,
    Emitter<ChecklistExecutionState> emit,
  ) async {
    if (_kind == ChecklistParentKind.task) {
      await _taskChecklistRepository!.setChecked(
        taskId: _taskId!,
        itemId: event.itemId,
        isChecked: event.checked,
        occurrenceDate: _occurrenceDate,
        context: _newContext('checklist_toggle', 'task_checklist.set_checked'),
      );
    } else {
      final scope = _routineScope();
      await _routineChecklistRepository!.setChecked(
        routineId: _routineId!,
        itemId: event.itemId,
        isChecked: event.checked,
        periodType: scope.periodType,
        windowKey: scope.windowKey,
        context: _newContext(
          'checklist_toggle',
          'routine_checklist.set_checked',
        ),
      );
    }
    await _reload(emit);

    if (_allChecked(state)) {
      emit(
        state.copyWith(effect: const ChecklistExecutionEffect.promptComplete()),
      );
    }
  }

  Future<void> _onAddItem(
    _ChecklistExecutionAddItem event,
    Emitter<ChecklistExecutionState> emit,
  ) async {
    final next = [..._titles(state), event.title];
    await _replaceItems(next);
    await _reload(emit);
  }

  Future<void> _onUpdateItemTitle(
    _ChecklistExecutionUpdateItemTitle event,
    Emitter<ChecklistExecutionState> emit,
  ) async {
    final next = _titles(state);
    if (event.index < 0 || event.index >= next.length) return;
    next[event.index] = event.title;
    await _replaceItems(next);
    await _reload(emit);
  }

  Future<void> _onDeleteItem(
    _ChecklistExecutionDeleteItem event,
    Emitter<ChecklistExecutionState> emit,
  ) async {
    final next = _titles(state);
    if (event.index < 0 || event.index >= next.length) return;
    next.removeAt(event.index);
    await _replaceItems(next);
    await _reload(emit);
  }

  Future<void> _onReorderItems(
    _ChecklistExecutionReorderItems event,
    Emitter<ChecklistExecutionState> emit,
  ) async {
    final next = _titles(state);
    if (event.oldIndex < 0 || event.oldIndex >= next.length) return;
    var adjustedNewIndex = event.newIndex;
    if (adjustedNewIndex > event.oldIndex) adjustedNewIndex -= 1;
    if (adjustedNewIndex < 0 || adjustedNewIndex > next.length) return;
    final item = next.removeAt(event.oldIndex);
    next.insert(adjustedNewIndex, item);
    await _replaceItems(next);
    await _reload(emit);
  }

  Future<void> _onCompleteParentNow(
    _ChecklistExecutionCompleteParentNow event,
    Emitter<ChecklistExecutionState> emit,
  ) async {
    emit(state.copyWith(saving: true, effect: null));
    try {
      if (_kind == ChecklistParentKind.task) {
        await _taskWriteService!.complete(
          _taskId!,
          occurrenceDate: _occurrenceDate,
          originalOccurrenceDate: _originalOccurrenceDate,
          context: _newContext('task_complete', 'tasks.complete'),
        );
      } else {
        final nowLocal = _nowService.nowLocal();
        await _routineWriteService!.recordCompletion(
          routineId: _routineId!,
          completedAtUtc: _nowService.nowUtc(),
          completedDayLocal: _routineDayKeyUtc,
          completedTimeLocalMinutes: nowLocal.hour * 60 + nowLocal.minute,
          context: _newContext('routine_log', 'routines.complete'),
        );
      }
      emit(
        state.copyWith(
          saving: false,
          effect: const ChecklistExecutionEffect.close(),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          saving: false,
          effect: const ChecklistExecutionEffect.error(
            message: 'Failed to complete',
          ),
        ),
      );
    }
  }

  Future<void> _onCheckAllAndComplete(
    _ChecklistExecutionCheckAllAndComplete event,
    Emitter<ChecklistExecutionState> emit,
  ) async {
    emit(state.copyWith(saving: true, effect: null));
    try {
      if (_kind == ChecklistParentKind.task) {
        for (final item in state.items) {
          if (state.checkedItemIds.contains(item.id)) continue;
          await _taskChecklistRepository!.setChecked(
            taskId: _taskId!,
            itemId: item.id,
            isChecked: true,
            occurrenceDate: _occurrenceDate,
            context: _newContext(
              'checklist_check_all',
              'task_checklist.bulk_check',
            ),
          );
        }
      } else {
        final scope = _routineScope();
        for (final item in state.items) {
          if (state.checkedItemIds.contains(item.id)) continue;
          await _routineChecklistRepository!.setChecked(
            routineId: _routineId!,
            itemId: item.id,
            isChecked: true,
            periodType: scope.periodType,
            windowKey: scope.windowKey,
            context: _newContext(
              'checklist_check_all',
              'routine_checklist.bulk_check',
            ),
          );
        }
      }
      add(const ChecklistExecutionEvent.completeParentNow());
    } catch (_) {
      emit(
        state.copyWith(
          saving: false,
          effect: const ChecklistExecutionEffect.error(
            message: 'Failed to check all',
          ),
        ),
      );
    }
  }

  void _onEffectHandled(
    _ChecklistExecutionEffectHandled event,
    Emitter<ChecklistExecutionState> emit,
  ) {
    if (state.effect == null) return;
    emit(state.copyWith(effect: null));
  }

  Future<void> _reload(Emitter<ChecklistExecutionState> emit) async {
    if (_kind == ChecklistParentKind.task) {
      final repository = _taskChecklistRepository;
      final taskId = _taskId;
      if (repository == null || taskId == null) return;
      final items = await repository.getItems(taskId);
      final itemStates = await repository.getState(
        taskId: taskId,
        occurrenceDate: _occurrenceDate,
      );
      final checked = itemStates
          .where((s) => s.isChecked)
          .map((s) => s.itemId)
          .toSet();
      emit(
        state.copyWith(
          loading: false,
          saving: false,
          items: items,
          checkedItemIds: checked,
        ),
      );
      return;
    }

    final scope = _routineScope();
    final repository = _routineChecklistRepository;
    final routineId = _routineId;
    if (repository == null || routineId == null) return;
    final items = await repository.getItems(routineId);
    final itemStates = await repository.getState(
      routineId: routineId,
      periodType: scope.periodType,
      windowKey: scope.windowKey,
    );
    final checked = itemStates
        .where((s) => s.isChecked)
        .map((s) => s.itemId)
        .toSet();
    emit(
      state.copyWith(
        loading: false,
        saving: false,
        items: items,
        checkedItemIds: checked,
      ),
    );
  }

  Future<void> _replaceItems(List<String> titles) async {
    if (_kind == ChecklistParentKind.task) {
      await _taskChecklistRepository!.replaceItems(
        taskId: _taskId!,
        titlesInOrder: titles,
        context: _newContext('checklist_update', 'task_checklist.replace'),
      );
      return;
    }

    await _routineChecklistRepository!.replaceItems(
      routineId: _routineId!,
      titlesInOrder: titles,
      context: _newContext('checklist_update', 'routine_checklist.replace'),
    );
  }

  List<String> _titles(ChecklistExecutionState state) =>
      state.items.map((item) => item.title).toList(growable: true);

  bool _allChecked(ChecklistExecutionState state) {
    if (state.items.isEmpty) return false;
    return state.items.every((item) => state.checkedItemIds.contains(item.id));
  }

  ({RoutinePeriodType periodType, DateTime windowKey}) _routineScope() {
    final routine = _routine!;
    final day = _routineDayKeyUtc!;
    switch (routine.periodType) {
      case RoutinePeriodType.day:
        return (periodType: RoutinePeriodType.day, windowKey: day);
      case RoutinePeriodType.week:
        final delta = day.weekday - DateTime.monday;
        return (
          periodType: RoutinePeriodType.week,
          windowKey: day.subtract(Duration(days: delta)),
        );
      case RoutinePeriodType.fortnight:
        final weekDelta = day.weekday - DateTime.monday;
        final weekStart = day.subtract(Duration(days: weekDelta));
        final anchor = DateTime.utc(1970, 1, 5);
        final deltaDays = weekStart.difference(anchor).inDays;
        final periodIndex = _floorDiv(deltaDays, 14);
        return (
          periodType: RoutinePeriodType.fortnight,
          windowKey: anchor.add(Duration(days: periodIndex * 14)),
        );
      case RoutinePeriodType.month:
        return (
          periodType: RoutinePeriodType.month,
          windowKey: DateTime.utc(day.year, day.month, 1),
        );
    }
  }

  int _floorDiv(int value, int divisor) {
    if (value >= 0) return value ~/ divisor;
    return -(((-value) + divisor - 1) ~/ divisor);
  }

  OperationContext _newContext(String intent, String operation) {
    final entityType = _kind == ChecklistParentKind.task ? 'task' : 'routine';
    final entityId = _kind == ChecklistParentKind.task ? _taskId : _routineId;
    return _contextFactory.create(
      feature: 'checklists',
      screen: 'checklist_sheet',
      intent: intent,
      operation: operation,
      entityType: entityType,
      entityId: entityId,
    );
  }
}
