  import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/taskly_domain.dart'
    show AppFailure, OperationContext;

sealed class JournalAddEntryStatus {
  const JournalAddEntryStatus();
}

final class JournalAddEntryLoading extends JournalAddEntryStatus {
  const JournalAddEntryLoading();
}

final class JournalAddEntryIdle extends JournalAddEntryStatus {
  const JournalAddEntryIdle();
}

final class JournalAddEntrySaving extends JournalAddEntryStatus {
  const JournalAddEntrySaving();
}

final class JournalAddEntrySaved extends JournalAddEntryStatus {
  const JournalAddEntrySaved();
}

final class JournalAddEntryError extends JournalAddEntryStatus {
  const JournalAddEntryError(this.message);

  final String message;
}

final class JournalAddEntryState {
  const JournalAddEntryState({
    required this.status,
    required this.selectedDayLocal,
    required this.groups,
    required this.trackers,
    required this.dayStateByTrackerId,
    required this.moodTrackerId,
    required this.mood,
    required this.note,
    required this.entryValues,
    required this.dailyValues,
  });

  factory JournalAddEntryState.initial({required DateTime selectedDayLocal}) {
    return JournalAddEntryState(
      status: const JournalAddEntryLoading(),
      selectedDayLocal: selectedDayLocal,
      groups: const <TrackerGroup>[],
      trackers: const <TrackerDefinition>[],
      dayStateByTrackerId: const <String, TrackerStateDay>{},
      moodTrackerId: null,
      mood: null,
      note: '',
      entryValues: const <String, Object?>{},
      dailyValues: const <String, Object?>{},
    );
  }

  final JournalAddEntryStatus status;
  final DateTime selectedDayLocal;

  final List<TrackerGroup> groups;
  final List<TrackerDefinition> trackers;

  /// Latest persisted day-level state (from projections), keyed by trackerId.
  final Map<String, TrackerStateDay> dayStateByTrackerId;

  final String? moodTrackerId;
  final MoodRating? mood;
  final String note;

  /// Draft values for trackers anchored to this entry.
  final Map<String, Object?> entryValues;

  /// Draft values for trackers anchored to the selected day.
  final Map<String, Object?> dailyValues;

  JournalAddEntryState copyWith({
    JournalAddEntryStatus? status,
    DateTime? selectedDayLocal,
    List<TrackerGroup>? groups,
    List<TrackerDefinition>? trackers,
    Map<String, TrackerStateDay>? dayStateByTrackerId,
    String? moodTrackerId,
    MoodRating? mood,
    String? note,
    Map<String, Object?>? entryValues,
    Map<String, Object?>? dailyValues,
  }) {
    return JournalAddEntryState(
      status: status ?? this.status,
      selectedDayLocal: selectedDayLocal ?? this.selectedDayLocal,
      groups: groups ?? this.groups,
      trackers: trackers ?? this.trackers,
      dayStateByTrackerId: dayStateByTrackerId ?? this.dayStateByTrackerId,
      moodTrackerId: moodTrackerId ?? this.moodTrackerId,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      entryValues: entryValues ?? this.entryValues,
      dailyValues: dailyValues ?? this.dailyValues,
    );
  }
}

class JournalAddEntryCubit extends Cubit<JournalAddEntryState> {
  JournalAddEntryCubit({
    required JournalRepositoryContract repository,
    required AppErrorReporter errorReporter,
    required DateTime selectedDayLocal,
    required DateTime Function() nowUtc,
    Set<String> preselectedTrackerIds = const <String>{},
  }) : _repository = repository,
       _errorReporter = errorReporter,
       _nowUtc = nowUtc,
       _preselectedTrackerIds = preselectedTrackerIds,
       super(JournalAddEntryState.initial(selectedDayLocal: selectedDayLocal)) {
    _subscribe();

    if (_preselectedTrackerIds.isNotEmpty) {
      final next = <String, Object?>{};
      for (final id in _preselectedTrackerIds) {
        next[id] = true;
      }
      emit(state.copyWith(entryValues: next));
    }
  }

  final JournalRepositoryContract _repository;
  final AppErrorReporter _errorReporter;
  final DateTime Function() _nowUtc;
  final Set<String> _preselectedTrackerIds;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  StreamSubscription<
    ({
      List<TrackerGroup> groups,
      List<TrackerDefinition> defs,
      List<TrackerStateDay> dayStates,
    })
  >?
  _sub;

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    return super.close();
  }

  OperationContext _newContext({
    required String intent,
    required String operation,
    Map<String, Object?> extraFields = const <String, Object?>{},
  }) {
    return _contextFactory.create(
      feature: 'journal',
      screen: 'add_entry_sheet',
      intent: intent,
      operation: operation,
      entityType: 'journal_entry',
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

  DateTime _dayUtcFromLocal(DateTime selectedDayLocal) {
    return DateTime.utc(
      selectedDayLocal.year,
      selectedDayLocal.month,
      selectedDayLocal.day,
    );
  }

  void moodChanged(MoodRating? mood) {
    emit(state.copyWith(mood: mood, status: const JournalAddEntryIdle()));
  }

  void noteChanged(String note) {
    emit(state.copyWith(note: note, status: const JournalAddEntryIdle()));
  }

  void setEntryValue(String trackerId, Object? value) {
    final trimmed = trackerId.trim();
    if (trimmed.isEmpty) return;

    final next = {...state.entryValues};
    next[trimmed] = value;
    emit(
      state.copyWith(entryValues: next, status: const JournalAddEntryIdle()),
    );
  }

  void setDailyValue(String trackerId, Object? value) {
    final trimmed = trackerId.trim();
    if (trimmed.isEmpty) return;

    final next = {...state.dailyValues};
    next[trimmed] = value;
    emit(
      state.copyWith(dailyValues: next, status: const JournalAddEntryIdle()),
    );
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

  Future<void> save() async {
    final hasEntryContent =
        state.mood != null ||
        state.note.trim().isNotEmpty ||
        state.entryValues.values.any((v) => v != null);

    final hasDailyContent = state.dailyValues.values.any((v) => v != null);

    if (!hasEntryContent && !hasDailyContent) {
      emit(
        state.copyWith(
          status: const JournalAddEntryError('Nothing to save.'),
        ),
      );
      return;
    }

    if (hasEntryContent && state.mood == null) {
      emit(
        state.copyWith(
          status: const JournalAddEntryError('Please choose a mood.'),
        ),
      );
      return;
    }

    emit(state.copyWith(status: const JournalAddEntrySaving()));

    final context = _newContext(
      intent: 'save',
      operation: 'journal.add_entry.save',
      extraFields: <String, Object?>{
        'hasEntryContent': hasEntryContent,
        'hasDailyContent': hasDailyContent,
        'entryValueCount': state.entryValues.length,
        'dailyValueCount': state.dailyValues.length,
      },
    );

    try {
      final nowUtc = _nowUtc();
      final dayUtc = _dayUtcFromLocal(state.selectedDayLocal);

      String? entryId;

      if (hasEntryContent) {
        final entry = JournalEntry(
          id: '',
          entryDate: dayUtc,
          entryTime: nowUtc,
          occurredAt: nowUtc,
          localDate: dayUtc,
          createdAt: nowUtc,
          updatedAt: nowUtc,
          journalText: state.note.trim().isEmpty ? null : state.note.trim(),
          deletedAt: null,
        );

        entryId = await _repository.upsertJournalEntry(entry, context: context);

        final moodTrackerId = state.moodTrackerId;
        if (moodTrackerId == null || moodTrackerId.trim().isEmpty) {
          throw StateError('Missing system mood tracker');
        }

        await _repository.appendTrackerEvent(
          TrackerEvent(
            id: '',
            trackerId: moodTrackerId,
            anchorType: 'entry',
            entryId: entryId,
            op: 'set',
            value: state.mood!.value,
            occurredAt: nowUtc,
            recordedAt: nowUtc,
          ),
          context: context,
        );

        for (final entry in state.entryValues.entries) {
          final trackerId = entry.key;
          if (trackerId == moodTrackerId) continue;
          final value = entry.value;
          if (value == null) continue;

          await _repository.appendTrackerEvent(
            TrackerEvent(
              id: '',
              trackerId: trackerId,
              anchorType: 'entry',
              entryId: entryId,
              op: 'set',
              value: value,
              occurredAt: nowUtc,
              recordedAt: nowUtc,
            ),
            context: context,
          );
        }
      }

      if (hasDailyContent) {
        for (final entry in state.dailyValues.entries) {
          final trackerId = entry.key;
          final value = entry.value;
          if (value == null) continue;

          await _repository.appendTrackerEvent(
            TrackerEvent(
              id: '',
              trackerId: trackerId,
              anchorType: 'day',
              anchorDate: dayUtc,
              entryId: entryId,
              op: 'set',
              value: value,
              occurredAt: nowUtc,
              recordedAt: nowUtc,
            ),
            context: context,
          );
        }
      }

      emit(state.copyWith(status: const JournalAddEntrySaved()));
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalAddEntryCubit] save failed',
      );

      emit(
        state.copyWith(
          status: JournalAddEntryError(
            _uiMessageFor(
              error,
              fallback: 'Failed to save. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  void _subscribe() {
    final defs$ = _repository.watchTrackerDefinitions().startWith(
      const <TrackerDefinition>[],
    );

    final groups$ = _repository.watchTrackerGroups().startWith(
      const <TrackerGroup>[],
    );

    final dayUtc = _dayUtcFromLocal(state.selectedDayLocal);
    final dayRange = DateRange(start: dayUtc, end: dayUtc);

    final dayState$ = _repository
        .watchTrackerStateDay(range: dayRange)
        .startWith(
          const <TrackerStateDay>[],
        );

    final combined$ =
        Rx.combineLatest3<
          List<TrackerGroup>,
          List<TrackerDefinition>,
          List<TrackerStateDay>,
          ({
            List<TrackerGroup> groups,
            List<TrackerDefinition> defs,
            List<TrackerStateDay> dayStates,
          })
        >(groups$, defs$, dayState$, (groups, defs, dayStates) {
          return (groups: groups, defs: defs, dayStates: dayStates);
        });

    _sub?.cancel();
    _sub = combined$.listen(
      (data) {
        final groups =
            data.groups.where((g) => g.isActive).toList(growable: false)
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final trackers =
            data.defs
                .where((d) => d.isActive && d.deletedAt == null)
                .toList(growable: false)
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final dayStateByTrackerId = <String, TrackerStateDay>{
          for (final s in data.dayStates) s.trackerId: s,
        };

        String? moodTrackerId;
        for (final d in data.defs) {
          if (d.systemKey == 'mood') {
            moodTrackerId = d.id;
            break;
          }
        }

        emit(
          state.copyWith(
            status: const JournalAddEntryIdle(),
            groups: groups,
            trackers: trackers,
            dayStateByTrackerId: dayStateByTrackerId,
            moodTrackerId: moodTrackerId,
          ),
        );
      },
      onError: (Object e, StackTrace st) {
        final context = _newContext(
          intent: 'stream_error',
          operation: 'journal.watchTrackerDefinitions+groups+stateDay',
        );

        _reportIfUnexpectedOrUnmapped(
          e,
          st,
          context: context,
          message: '[JournalAddEntryCubit] stream error',
        );

        emit(
          state.copyWith(
            status: JournalAddEntryError(
              _uiMessageFor(
                e,
                fallback: 'Failed to load trackers. Please try again.',
              ),
            ),
          ),
        );
      },
    );
  }
}
