import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/taskly_domain.dart'
    show AppFailure, OperationContext;

sealed class JournalAddEntryEvent {
  const JournalAddEntryEvent();
}

final class JournalAddEntryStarted extends JournalAddEntryEvent {
  const JournalAddEntryStarted({required this.selectedDayLocal});

  final DateTime selectedDayLocal;
}

final class JournalAddEntryMoodChanged extends JournalAddEntryEvent {
  const JournalAddEntryMoodChanged(this.mood);

  final MoodRating? mood;
}

final class JournalAddEntryNoteChanged extends JournalAddEntryEvent {
  const JournalAddEntryNoteChanged(this.note);

  final String note;
}

final class JournalAddEntryEntryValueChanged extends JournalAddEntryEvent {
  const JournalAddEntryEntryValueChanged({
    required this.trackerId,
    required this.value,
  });

  final String trackerId;
  final Object? value;
}

final class JournalAddEntrySaveRequested extends JournalAddEntryEvent {
  const JournalAddEntrySaveRequested();
}

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
    required this.definitionById,
    required this.moodTrackerId,
    required this.mood,
    required this.note,
    required this.entryValues,
  });

  factory JournalAddEntryState.initial() {
    return JournalAddEntryState(
      status: const JournalAddEntryLoading(),
      selectedDayLocal: DateTime(2000),
      groups: const <TrackerGroup>[],
      trackers: const <TrackerDefinition>[],
      definitionById: const <String, TrackerDefinition>{},
      moodTrackerId: null,
      mood: null,
      note: '',
      entryValues: const <String, Object?>{},
    );
  }

  final JournalAddEntryStatus status;
  final DateTime selectedDayLocal;

  final List<TrackerGroup> groups;
  final List<TrackerDefinition> trackers;
  final Map<String, TrackerDefinition> definitionById;

  final String? moodTrackerId;
  final MoodRating? mood;
  final String note;

  /// Draft values for trackers anchored to this entry.
  final Map<String, Object?> entryValues;

  JournalAddEntryState copyWith({
    JournalAddEntryStatus? status,
    DateTime? selectedDayLocal,
    List<TrackerGroup>? groups,
    List<TrackerDefinition>? trackers,
    Map<String, TrackerDefinition>? definitionById,
    String? moodTrackerId,
    MoodRating? mood,
    String? note,
    Map<String, Object?>? entryValues,
  }) {
    return JournalAddEntryState(
      status: status ?? this.status,
      selectedDayLocal: selectedDayLocal ?? this.selectedDayLocal,
      groups: groups ?? this.groups,
      trackers: trackers ?? this.trackers,
      definitionById: definitionById ?? this.definitionById,
      moodTrackerId: moodTrackerId ?? this.moodTrackerId,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      entryValues: entryValues ?? this.entryValues,
    );
  }
}

class JournalAddEntryBloc
    extends Bloc<JournalAddEntryEvent, JournalAddEntryState> {
  JournalAddEntryBloc({
    required JournalRepositoryContract repository,
    required AppErrorReporter errorReporter,
    required DateTime Function() nowUtc,
    Set<String> preselectedTrackerIds = const <String>{},
  }) : _repository = repository,
       _errorReporter = errorReporter,
       _nowUtc = nowUtc,
       _preselectedTrackerIds = preselectedTrackerIds,
       super(JournalAddEntryState.initial()) {
    on<JournalAddEntryStarted>(_onStarted, transformer: restartable());
    on<JournalAddEntryMoodChanged>(_onMoodChanged);
    on<JournalAddEntryNoteChanged>(_onNoteChanged);
    on<JournalAddEntryEntryValueChanged>(_onEntryValueChanged);
    on<JournalAddEntrySaveRequested>(
      _onSaveRequested,
      transformer: sequential(),
    );
  }

  final JournalRepositoryContract _repository;
  final AppErrorReporter _errorReporter;
  final DateTime Function() _nowUtc;
  final Set<String> _preselectedTrackerIds;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

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
    JournalAddEntryStarted event,
    Emitter<JournalAddEntryState> emit,
  ) async {
    final preselectedValues = <String, Object?>{};
    if (_preselectedTrackerIds.isNotEmpty && state.entryValues.isEmpty) {
      for (final id in _preselectedTrackerIds) {
        preselectedValues[id] = true;
      }
    }

    emit(
      state.copyWith(
        selectedDayLocal: event.selectedDayLocal,
        entryValues: preselectedValues.isEmpty
            ? state.entryValues
            : preselectedValues,
      ),
    );

    final defs$ = _repository.watchTrackerDefinitions().startWith(
      const <TrackerDefinition>[],
    );

    final groups$ = _repository.watchTrackerGroups().startWith(
      const <TrackerGroup>[],
    );

    final combined$ =
        Rx.combineLatest2<
          List<TrackerDefinition>,
          List<TrackerGroup>,
          ({List<TrackerDefinition> defs, List<TrackerGroup> groups})
        >(defs$, groups$, (defs, groups) => (defs: defs, groups: groups));

    await emit.forEach(
      combined$,
      onData: (data) {
        final groups =
            data.groups.where((g) => g.isActive).toList(growable: false)
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        final trackers =
            data.defs
                .where((d) => d.isActive && d.deletedAt == null)
                .where((d) => !_isDailyScope(d))
                .where((d) => d.systemKey != 'mood')
                .toList(growable: false)
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        String? moodTrackerId;
        for (final d in data.defs) {
          if (d.systemKey == 'mood') {
            moodTrackerId = d.id;
            break;
          }
        }

        final definitionById = {
          for (final d in data.defs) d.id: d,
        };

        return state.copyWith(
          status: const JournalAddEntryIdle(),
          groups: groups,
          trackers: trackers,
          definitionById: definitionById,
          moodTrackerId: moodTrackerId,
        );
      },
      onError: (e, st) {
        final context = _newContext(
          intent: 'stream_error',
          operation: 'journal.watchTrackerDefinitions+groups',
        );

        _reportIfUnexpectedOrUnmapped(
          e,
          st,
          context: context,
          message: '[JournalAddEntryBloc] stream error',
        );

        return state.copyWith(
          status: JournalAddEntryError(
            _uiMessageFor(
              e,
              fallback: 'Failed to load trackers. Please try again.',
            ),
          ),
        );
      },
    );
  }

  void _onMoodChanged(
    JournalAddEntryMoodChanged event,
    Emitter<JournalAddEntryState> emit,
  ) {
    emit(state.copyWith(mood: event.mood, status: const JournalAddEntryIdle()));
  }

  void _onNoteChanged(
    JournalAddEntryNoteChanged event,
    Emitter<JournalAddEntryState> emit,
  ) {
    emit(state.copyWith(note: event.note, status: const JournalAddEntryIdle()));
  }

  void _onEntryValueChanged(
    JournalAddEntryEntryValueChanged event,
    Emitter<JournalAddEntryState> emit,
  ) {
    final trimmed = event.trackerId.trim();
    if (trimmed.isEmpty) return;

    final next = {...state.entryValues};
    next[trimmed] = event.value;
    emit(
      state.copyWith(entryValues: next, status: const JournalAddEntryIdle()),
    );
  }

  Future<void> _onSaveRequested(
    JournalAddEntrySaveRequested event,
    Emitter<JournalAddEntryState> emit,
  ) async {
    final hasEntryContent =
        state.mood != null ||
        state.note.trim().isNotEmpty ||
        state.entryValues.values.any((v) => v != null);

    if (!hasEntryContent) {
      emit(
        state.copyWith(
          status: const JournalAddEntryError('Nothing to save.'),
        ),
      );
      return;
    }

    if (state.mood == null) {
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
        'entryValueCount': state.entryValues.length,
      },
    );

    try {
      final nowUtc = _nowUtc();
      final dayUtc = _dayUtcFromLocal(state.selectedDayLocal);

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

      final entryId = await _repository.upsertJournalEntry(
        entry,
        context: context,
      );

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

      for (final entryValue in state.entryValues.entries) {
        final trackerId = entryValue.key;
        if (trackerId == moodTrackerId) continue;
        final value = entryValue.value;
        if (value == null) continue;

        final op = state.definitionById[trackerId]?.opKind ?? 'set';

        await _repository.appendTrackerEvent(
          TrackerEvent(
            id: '',
            trackerId: trackerId,
            anchorType: 'entry',
            entryId: entryId,
            op: op.isEmpty ? 'set' : op,
            value: value,
            occurredAt: nowUtc,
            recordedAt: nowUtc,
          ),
          context: context,
        );
      }

      emit(state.copyWith(status: const JournalAddEntrySaved()));
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalAddEntryBloc] save failed',
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
}
