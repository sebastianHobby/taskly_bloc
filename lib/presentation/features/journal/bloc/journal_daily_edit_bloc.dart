import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/taskly_domain.dart'
    show AppFailure, OperationContext;

sealed class JournalDailyEditEvent {
  const JournalDailyEditEvent();
}

final class JournalDailyEditStarted extends JournalDailyEditEvent {
  const JournalDailyEditStarted({required this.selectedDayLocal});

  final DateTime selectedDayLocal;
}

final class JournalDailyEditValueChanged extends JournalDailyEditEvent {
  const JournalDailyEditValueChanged({
    required this.trackerId,
    required this.value,
  });

  final String trackerId;
  final Object? value;
}

final class JournalDailyEditDeltaAdded extends JournalDailyEditEvent {
  const JournalDailyEditDeltaAdded({
    required this.trackerId,
    required this.delta,
  });

  final String trackerId;
  final int delta;
}

sealed class JournalDailyEditStatus {
  const JournalDailyEditStatus();
}

final class JournalDailyEditLoading extends JournalDailyEditStatus {
  const JournalDailyEditLoading();
}

final class JournalDailyEditIdle extends JournalDailyEditStatus {
  const JournalDailyEditIdle();
}

final class JournalDailyEditSaving extends JournalDailyEditStatus {
  const JournalDailyEditSaving();
}

final class JournalDailyEditError extends JournalDailyEditStatus {
  const JournalDailyEditError(this.message);

  final String message;
}

final class JournalDailyEditState {
  const JournalDailyEditState({
    required this.status,
    required this.selectedDayLocal,
    required this.groups,
    required this.dailyTrackers,
    required this.definitionById,
    required this.dayStateByTrackerId,
    required this.draftValues,
  });

  factory JournalDailyEditState.initial() {
    return JournalDailyEditState(
      status: const JournalDailyEditLoading(),
      selectedDayLocal: DateTime(2000),
      groups: const <TrackerGroup>[],
      dailyTrackers: const <TrackerDefinition>[],
      definitionById: const <String, TrackerDefinition>{},
      dayStateByTrackerId: const <String, TrackerStateDay>{},
      draftValues: const <String, Object?>{},
    );
  }

  final JournalDailyEditStatus status;
  final DateTime selectedDayLocal;
  final List<TrackerGroup> groups;
  final List<TrackerDefinition> dailyTrackers;
  final Map<String, TrackerDefinition> definitionById;
  final Map<String, TrackerStateDay> dayStateByTrackerId;
  final Map<String, Object?> draftValues;

  JournalDailyEditState copyWith({
    JournalDailyEditStatus? status,
    DateTime? selectedDayLocal,
    List<TrackerGroup>? groups,
    List<TrackerDefinition>? dailyTrackers,
    Map<String, TrackerDefinition>? definitionById,
    Map<String, TrackerStateDay>? dayStateByTrackerId,
    Map<String, Object?>? draftValues,
  }) {
    return JournalDailyEditState(
      status: status ?? this.status,
      selectedDayLocal: selectedDayLocal ?? this.selectedDayLocal,
      groups: groups ?? this.groups,
      dailyTrackers: dailyTrackers ?? this.dailyTrackers,
      definitionById: definitionById ?? this.definitionById,
      dayStateByTrackerId: dayStateByTrackerId ?? this.dayStateByTrackerId,
      draftValues: draftValues ?? this.draftValues,
    );
  }
}

class JournalDailyEditBloc
    extends Bloc<JournalDailyEditEvent, JournalDailyEditState> {
  JournalDailyEditBloc({
    required JournalRepositoryContract repository,
    required AppErrorReporter errorReporter,
    required DateTime Function() nowUtc,
  }) : _repository = repository,
       _errorReporter = errorReporter,
       _nowUtc = nowUtc,
       super(JournalDailyEditState.initial()) {
    on<JournalDailyEditStarted>(
      _onStarted,
      transformer: restartable(),
    );
    on<JournalDailyEditValueChanged>(
      _onValueChanged,
      transformer: sequential(),
    );
    on<JournalDailyEditDeltaAdded>(_onDeltaAdded, transformer: sequential());
  }

  final JournalRepositoryContract _repository;
  final AppErrorReporter _errorReporter;
  final DateTime Function() _nowUtc;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  OperationContext _newContext({
    required String intent,
    required String operation,
    String? trackerId,
    Map<String, Object?> extraFields = const <String, Object?>{},
  }) {
    return _contextFactory.create(
      feature: 'journal',
      screen: 'journal_daily_edit',
      intent: intent,
      operation: operation,
      entityType: 'tracker_event',
      entityId: trackerId,
      extraFields: extraFields,
    );
  }

  void _reportIfUnexpectedOrUnmapped(
    Object error,
    StackTrace stackTrace, {
    required OperationContext context,
    required String message,
  }) {
    if (error is AppFailure && error.reportAsUnexpected) {
      _errorReporter.reportUnexpected(
        error,
        stackTrace,
        context: context,
        message: '$message (unexpected failure)',
      );
      return;
    }

    if (error is! AppFailure) {
      _errorReporter.reportUnexpected(
        error,
        stackTrace,
        context: context,
        message: '$message (unmapped exception)',
      );
    }
  }

  String _uiMessageFor(Object error, {required String fallback}) {
    if (error is AppFailure) return error.uiMessage();
    return fallback;
  }

  bool _isDailyScope(TrackerDefinition d) {
    final scope = d.scope.trim().toLowerCase();
    return scope == 'day' || scope == 'daily' || scope == 'sleep_night';
  }

  DateTime _dayUtcFromLocal(DateTime selectedDayLocal) {
    return DateTime.utc(
      selectedDayLocal.year,
      selectedDayLocal.month,
      selectedDayLocal.day,
    );
  }

  Future<void> _onStarted(
    JournalDailyEditStarted event,
    Emitter<JournalDailyEditState> emit,
  ) async {
    emit(state.copyWith(selectedDayLocal: event.selectedDayLocal));

    final defs$ = _repository.watchTrackerDefinitions().startWith(
      const <TrackerDefinition>[],
    );
    final groups$ = _repository.watchTrackerGroups().startWith(
      const <TrackerGroup>[],
    );

    final dayUtc = _dayUtcFromLocal(event.selectedDayLocal);
    final dayRange = DateRange(start: dayUtc, end: dayUtc);
    final dayState$ = _repository
        .watchTrackerStateDay(range: dayRange)
        .startWith(
          const <TrackerStateDay>[],
        );

    final combined$ =
        Rx.combineLatest3<
          List<TrackerDefinition>,
          List<TrackerGroup>,
          List<TrackerStateDay>,
          ({
            List<TrackerDefinition> defs,
            List<TrackerGroup> groups,
            List<TrackerStateDay> dayStates,
          })
        >(defs$, groups$, dayState$, (defs, groups, dayStates) {
          return (defs: defs, groups: groups, dayStates: dayStates);
        });

    await emit.forEach(
      combined$,
      onData: (data) {
        final groups =
            data.groups.where((g) => g.isActive).toList(growable: false)
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final dailyTrackers =
            data.defs
                .where((d) => d.isActive && d.deletedAt == null)
                .where(_isDailyScope)
                .toList(growable: false)
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final definitionById = {
          for (final d in data.defs) d.id: d,
        };

        final dayStateByTrackerId = <String, TrackerStateDay>{
          for (final s in data.dayStates) s.trackerId: s,
        };

        return state.copyWith(
          status: const JournalDailyEditIdle(),
          groups: groups,
          dailyTrackers: dailyTrackers,
          definitionById: definitionById,
          dayStateByTrackerId: dayStateByTrackerId,
        );
      },
      onError: (e, st) {
        final context = _newContext(
          intent: 'stream_error',
          operation: 'journal.watchTrackerDefinitions+groups+stateDay',
        );

        _reportIfUnexpectedOrUnmapped(
          e,
          st,
          context: context,
          message: '[JournalDailyEditBloc] stream error',
        );

        return state.copyWith(
          status: JournalDailyEditError(
            _uiMessageFor(
              e,
              fallback: 'Failed to load daily trackers. Please try again.',
            ),
          ),
        );
      },
    );
  }

  Future<void> _onValueChanged(
    JournalDailyEditValueChanged event,
    Emitter<JournalDailyEditState> emit,
  ) async {
    final trackerId = event.trackerId.trim();
    if (trackerId.isEmpty) return;

    final definition = state.definitionById[trackerId];
    if (definition == null) return;

    final nextDraft = {...state.draftValues};
    nextDraft[trackerId] = event.value;

    emit(
      state.copyWith(
        status: const JournalDailyEditSaving(),
        draftValues: nextDraft,
      ),
    );

    final context = _newContext(
      intent: 'set_daily_value',
      operation: 'journal.daily_edit.set',
      trackerId: trackerId,
      extraFields: <String, Object?>{
        'valueType': definition.valueType,
        'scope': definition.scope,
      },
    );

    try {
      final nowUtc = _nowUtc();
      final dayUtc = _dayUtcFromLocal(state.selectedDayLocal);
      final op = definition.opKind.trim();

      await _repository.appendTrackerEvent(
        TrackerEvent(
          id: '',
          trackerId: trackerId,
          anchorType: 'day',
          anchorDate: dayUtc,
          op: op.isEmpty ? 'set' : op,
          value: event.value,
          occurredAt: nowUtc,
          recordedAt: nowUtc,
        ),
        context: context,
      );

      emit(state.copyWith(status: const JournalDailyEditIdle()));
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalDailyEditBloc] set value failed',
      );

      emit(
        state.copyWith(
          status: JournalDailyEditError(
            _uiMessageFor(
              error,
              fallback: 'Failed to update daily tracker. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _onDeltaAdded(
    JournalDailyEditDeltaAdded event,
    Emitter<JournalDailyEditState> emit,
  ) async {
    final trackerId = event.trackerId.trim();
    if (trackerId.isEmpty) return;

    final definition = state.definitionById[trackerId];
    if (definition == null) return;

    final current = _effectiveValue(trackerId);
    final currentNum = switch (current) {
      final int v => v.toDouble(),
      final double v => v,
      _ => 0.0,
    };
    final nextDraft = {...state.draftValues};
    nextDraft[trackerId] = currentNum + event.delta;

    emit(
      state.copyWith(
        status: const JournalDailyEditSaving(),
        draftValues: nextDraft,
      ),
    );

    final context = _newContext(
      intent: 'add_daily_delta',
      operation: 'journal.daily_edit.add',
      trackerId: trackerId,
      extraFields: <String, Object?>{
        'delta': event.delta,
        'valueType': definition.valueType,
        'scope': definition.scope,
      },
    );

    try {
      final nowUtc = _nowUtc();
      final dayUtc = _dayUtcFromLocal(state.selectedDayLocal);

      await _repository.appendTrackerEvent(
        TrackerEvent(
          id: '',
          trackerId: trackerId,
          anchorType: 'day',
          anchorDate: dayUtc,
          op: 'add',
          value: event.delta,
          occurredAt: nowUtc,
          recordedAt: nowUtc,
        ),
        context: context,
      );

      emit(state.copyWith(status: const JournalDailyEditIdle()));
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalDailyEditBloc] add delta failed',
      );

      emit(
        state.copyWith(
          status: JournalDailyEditError(
            _uiMessageFor(
              error,
              fallback: 'Failed to update daily tracker. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  Future<List<TrackerDefinitionChoice>> getChoices(String trackerId) async {
    final trimmed = trackerId.trim();
    if (trimmed.isEmpty) return const <TrackerDefinitionChoice>[];

    try {
      final all = await _repository
          .watchTrackerDefinitionChoices(trackerId: trimmed)
          .first;
      return all.where((c) => c.isActive).toList(growable: false)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    } catch (_) {
      return const <TrackerDefinitionChoice>[];
    }
  }

  Object? _effectiveValue(String trackerId) {
    if (state.draftValues.containsKey(trackerId)) {
      return state.draftValues[trackerId];
    }
    return state.dayStateByTrackerId[trackerId]?.value;
  }
}
