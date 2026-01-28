import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/shared/telemetry/operation_context_factory.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/taskly_domain.dart'
    show AppFailure, OperationContext;
import 'package:taskly_domain/time.dart';

sealed class JournalEntryEditorEvent {
  const JournalEntryEditorEvent();
}

final class JournalEntryEditorStarted extends JournalEntryEditorEvent {
  const JournalEntryEditorStarted();
}

final class JournalEntryEditorMoodChanged extends JournalEntryEditorEvent {
  const JournalEntryEditorMoodChanged(this.mood);

  final MoodRating? mood;
}

final class JournalEntryEditorNoteChanged extends JournalEntryEditorEvent {
  const JournalEntryEditorNoteChanged(this.note);

  final String note;
}

final class JournalEntryEditorEntryValueChanged
    extends JournalEntryEditorEvent {
  const JournalEntryEditorEntryValueChanged({
    required this.trackerId,
    required this.value,
  });

  final String trackerId;
  final Object? value;
}

final class JournalEntryEditorSaveRequested extends JournalEntryEditorEvent {
  const JournalEntryEditorSaveRequested();
}

sealed class JournalEntryEditorStatus {
  const JournalEntryEditorStatus();
}

final class JournalEntryEditorLoading extends JournalEntryEditorStatus {
  const JournalEntryEditorLoading();
}

final class JournalEntryEditorIdle extends JournalEntryEditorStatus {
  const JournalEntryEditorIdle();
}

final class JournalEntryEditorSaving extends JournalEntryEditorStatus {
  const JournalEntryEditorSaving();
}

final class JournalEntryEditorSaved extends JournalEntryEditorStatus {
  const JournalEntryEditorSaved();
}

final class JournalEntryEditorError extends JournalEntryEditorStatus {
  const JournalEntryEditorError(this.message);

  final String message;
}

final class JournalEntryEditorState {
  const JournalEntryEditorState({
    required this.status,
    required this.entryId,
    required this.selectedDayLocal,
    required this.groups,
    required this.trackers,
    required this.definitionById,
    required this.moodTrackerId,
    required this.mood,
    required this.note,
    required this.entryValues,
    required this.dailySummaryItems,
    required this.isDirty,
  });

  factory JournalEntryEditorState.initial({required String? entryId}) {
    return JournalEntryEditorState(
      status: const JournalEntryEditorLoading(),
      entryId: entryId,
      selectedDayLocal: DateTime(2000),
      groups: const <TrackerGroup>[],
      trackers: const <TrackerDefinition>[],
      definitionById: const <String, TrackerDefinition>{},
      moodTrackerId: null,
      mood: null,
      note: '',
      entryValues: const <String, Object?>{},
      dailySummaryItems: const <JournalDailySummaryItem>[],
      isDirty: false,
    );
  }

  final JournalEntryEditorStatus status;
  final String? entryId;
  final DateTime selectedDayLocal;
  final List<TrackerGroup> groups;
  final List<TrackerDefinition> trackers;
  final Map<String, TrackerDefinition> definitionById;
  final String? moodTrackerId;
  final MoodRating? mood;
  final String note;
  final Map<String, Object?> entryValues;
  final List<JournalDailySummaryItem> dailySummaryItems;
  final bool isDirty;

  bool get isEditingExisting => entryId != null && entryId!.trim().isNotEmpty;

  JournalEntryEditorState copyWith({
    JournalEntryEditorStatus? status,
    String? entryId,
    DateTime? selectedDayLocal,
    List<TrackerGroup>? groups,
    List<TrackerDefinition>? trackers,
    Map<String, TrackerDefinition>? definitionById,
    String? moodTrackerId,
    MoodRating? mood,
    String? note,
    Map<String, Object?>? entryValues,
    List<JournalDailySummaryItem>? dailySummaryItems,
    bool? isDirty,
  }) {
    return JournalEntryEditorState(
      status: status ?? this.status,
      entryId: entryId ?? this.entryId,
      selectedDayLocal: selectedDayLocal ?? this.selectedDayLocal,
      groups: groups ?? this.groups,
      trackers: trackers ?? this.trackers,
      definitionById: definitionById ?? this.definitionById,
      moodTrackerId: moodTrackerId ?? this.moodTrackerId,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      entryValues: entryValues ?? this.entryValues,
      dailySummaryItems: dailySummaryItems ?? this.dailySummaryItems,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

class JournalEntryEditorBloc
    extends Bloc<JournalEntryEditorEvent, JournalEntryEditorState> {
  JournalEntryEditorBloc({
    required JournalRepositoryContract repository,
    required AppErrorReporter errorReporter,
    required String? entryId,
    required Set<String> preselectedTrackerIds,
    required DateTime Function() nowUtc,
  }) : _repository = repository,
       _errorReporter = errorReporter,
       _entryId = entryId,
       _preselectedTrackerIds = preselectedTrackerIds,
       _nowUtc = nowUtc,
       super(JournalEntryEditorState.initial(entryId: entryId)) {
    on<JournalEntryEditorStarted>(_onStarted, transformer: restartable());
    on<JournalEntryEditorMoodChanged>(_onMoodChanged);
    on<JournalEntryEditorNoteChanged>(_onNoteChanged);
    on<JournalEntryEditorEntryValueChanged>(_onEntryValueChanged);
    on<JournalEntryEditorSaveRequested>(
      _onSaveRequested,
      transformer: sequential(),
    );
  }

  final JournalRepositoryContract _repository;
  final AppErrorReporter _errorReporter;
  final String? _entryId;
  final Set<String> _preselectedTrackerIds;
  final DateTime Function() _nowUtc;
  final OperationContextFactory _contextFactory =
      const OperationContextFactory();

  OperationContext _newContext({
    required String intent,
    required String operation,
    String? entryId,
    Map<String, Object?> extraFields = const <String, Object?>{},
  }) {
    return _contextFactory.create(
      feature: 'journal',
      screen: 'journal_entry_editor',
      intent: intent,
      operation: operation,
      entityType: 'journal_entry',
      entityId: entryId,
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

  List<JournalDailySummaryItem> _buildDailySummaryItems({
    required List<TrackerDefinition> defs,
    required List<TrackerStateDay> dayStates,
  }) {
    final dailyDefs =
        defs
            .where((d) => d.isActive && d.deletedAt == null)
            .where(_isDailyScope)
            .toList(growable: false)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final dayStateByTrackerId = {
      for (final s in dayStates) s.trackerId: s,
    };

    final items = <JournalDailySummaryItem>[];
    for (final d in dailyDefs) {
      final value = dayStateByTrackerId[d.id]?.value;
      if (value == null) continue;
      final formatted = _formatSummaryValue(value);
      if (formatted == null) continue;
      items.add(JournalDailySummaryItem(label: d.name, value: formatted));
      if (items.length == 2) break;
    }

    return items;
  }

  String? _formatSummaryValue(Object value) {
    return switch (value) {
      final bool v => v ? 'Yes' : null,
      final int v => v.toString(),
      final double v => v.toStringAsFixed(1),
      final String v => v,
      _ => value.toString(),
    };
  }

  JournalEntry? _initialEntry;
  MoodRating? _initialMood;
  String _initialNote = '';
  Map<String, Object?> _initialEntryValues = const <String, Object?>{};
  DateTime _selectedDayLocal = DateTime(2000);

  Future<void> _onStarted(
    JournalEntryEditorStarted event,
    Emitter<JournalEntryEditorState> emit,
  ) async {
    final nowLocal = _nowUtc().toLocal();
    _selectedDayLocal = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
    );
    emit(state.copyWith(selectedDayLocal: _selectedDayLocal));

    try {
      final entryId = _entryId;
      if (entryId != null && entryId.trim().isNotEmpty) {
        final loaded = await _loadExistingEntry(entryId);
        emit(loaded);
      } else {
        _initialMood = null;
        _initialNote = '';
        _initialEntryValues = _seedPreselectedValues();
        emit(
          state.copyWith(
            entryValues: _initialEntryValues,
            status: const JournalEntryEditorIdle(),
            isDirty: false,
          ),
        );
      }
    } catch (error, stackTrace) {
      final context = _newContext(
        intent: 'init',
        operation: 'journal.entry_editor.init',
        entryId: state.entryId,
      );

      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalEntryEditorBloc] init failed',
      );

      emit(
        state.copyWith(
          status: JournalEntryEditorError(
            _uiMessageFor(
              error,
              fallback: 'Failed to load log. Please try again.',
            ),
          ),
        ),
      );
    }

    final defs$ = _repository.watchTrackerDefinitions().startWith(
      const <TrackerDefinition>[],
    );
    final groups$ = _repository.watchTrackerGroups().startWith(
      const <TrackerGroup>[],
    );
    final dayUtc = dateOnly(_selectedDayLocal);
    final dayState$ = _repository
        .watchTrackerStateDay(
          range: DateRange(start: dayUtc, end: dayUtc),
        )
        .startWith(const <TrackerStateDay>[]);

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

    unawaited(
      emit.forEach(
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

          final dailySummaryItems = _buildDailySummaryItems(
            defs: data.defs,
            dayStates: data.dayStates,
          );

          return state.copyWith(
            status: const JournalEntryEditorIdle(),
            groups: groups,
            trackers: trackers,
            definitionById: definitionById,
            moodTrackerId: moodTrackerId,
            dailySummaryItems: dailySummaryItems,
          );
        },
        onError: (Object e, StackTrace st) {
          final context = _newContext(
            intent: 'trackers_stream_error',
            operation: 'journal.watchTrackerDefinitions+groups+stateDay',
            entryId: state.entryId,
          );

          _reportIfUnexpectedOrUnmapped(
            e,
            st,
            context: context,
            message: '[JournalEntryEditorBloc] trackers stream error',
          );

          return state.copyWith(
            status: JournalEntryEditorError(
              _uiMessageFor(
                e,
                fallback: 'Failed to load trackers. Please try again.',
              ),
            ),
          );
        },
      ),
    );
  }

  void _onMoodChanged(
    JournalEntryEditorMoodChanged event,
    Emitter<JournalEntryEditorState> emit,
  ) {
    emit(_withIdleAndDirty(state.copyWith(mood: event.mood)));
  }

  void _onNoteChanged(
    JournalEntryEditorNoteChanged event,
    Emitter<JournalEntryEditorState> emit,
  ) {
    emit(_withIdleAndDirty(state.copyWith(note: event.note)));
  }

  void _onEntryValueChanged(
    JournalEntryEditorEntryValueChanged event,
    Emitter<JournalEntryEditorState> emit,
  ) {
    final trimmed = event.trackerId.trim();
    if (trimmed.isEmpty) return;

    final next = {...state.entryValues};
    next[trimmed] = event.value;
    emit(_withIdleAndDirty(state.copyWith(entryValues: next)));
  }

  Future<void> _onSaveRequested(
    JournalEntryEditorSaveRequested event,
    Emitter<JournalEntryEditorState> emit,
  ) async {
    final mood = state.mood;
    if (mood == null) {
      emit(
        state.copyWith(
          status: const JournalEntryEditorError('Please choose a mood.'),
        ),
      );
      return;
    }

    final moodTrackerId = state.moodTrackerId;
    if (moodTrackerId == null || moodTrackerId.trim().isEmpty) {
      emit(
        state.copyWith(
          status: const JournalEntryEditorError('Missing system mood tracker.'),
        ),
      );
      return;
    }

    emit(state.copyWith(status: const JournalEntryEditorSaving()));

    final context = _newContext(
      intent: 'save',
      operation: 'journal.entry_editor.save',
      entryId: state.entryId,
      extraFields: <String, Object?>{
        'isEditingExisting': state.isEditingExisting,
      },
    );

    try {
      final nowUtc = _nowUtc();
      final dayUtc = dateOnly(nowUtc);

      final existing = _initialEntry;

      final entryToSave = existing == null
          ? JournalEntry(
              id: '',
              entryDate: dayUtc,
              entryTime: nowUtc,
              occurredAt: nowUtc,
              localDate: dayUtc,
              createdAt: nowUtc,
              updatedAt: nowUtc,
              journalText: state.note.trim().isEmpty ? null : state.note.trim(),
              deletedAt: null,
            )
          : existing.copyWith(
              journalText: state.note.trim().isEmpty ? null : state.note.trim(),
              updatedAt: nowUtc,
            );

      final entryId = await _repository.upsertJournalEntry(
        entryToSave,
        context: context,
      );

      await _repository.appendTrackerEvent(
        TrackerEvent(
          id: '',
          trackerId: moodTrackerId,
          anchorType: 'entry',
          entryId: entryId,
          op: 'set',
          value: mood.value,
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

      emit(
        state.copyWith(
          entryId: entryId,
          status: const JournalEntryEditorSaved(),
          isDirty: false,
        ),
      );
    } catch (error, stackTrace) {
      _reportIfUnexpectedOrUnmapped(
        error,
        stackTrace,
        context: context,
        message: '[JournalEntryEditorBloc] save failed',
      );

      emit(
        state.copyWith(
          status: JournalEntryEditorError(
            _uiMessageFor(
              error,
              fallback: 'Failed to save log. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  Map<String, Object?> _seedPreselectedValues() {
    final next = <String, Object?>{};
    for (final id in _preselectedTrackerIds) {
      next[id] = true;
    }
    return next;
  }

  Future<JournalEntryEditorState> _loadExistingEntry(String entryId) async {
    final entry = await _repository.getJournalEntryById(entryId);
    if (entry == null) {
      throw StateError('Log not found');
    }

    _initialEntry = entry;
    _selectedDayLocal = DateTime(
      entry.localDate.year,
      entry.localDate.month,
      entry.localDate.day,
    );

    final defs = await _repository.watchTrackerDefinitions().first;
    String? moodTrackerId;
    for (final d in defs) {
      if (d.systemKey == 'mood') {
        moodTrackerId = d.id;
        break;
      }
    }

    final events = await _repository
        .watchTrackerEvents(anchorType: 'entry', entryId: entryId)
        .first;

    MoodRating? mood;
    final values = <String, Object?>{};

    for (final e in events) {
      if (moodTrackerId != null && e.trackerId == moodTrackerId) {
        if (e.value is int) {
          mood = MoodRating.fromValue(e.value! as int);
        }
        continue;
      }

      if (!values.containsKey(e.trackerId)) {
        values[e.trackerId] = e.value;
      }
    }

    if (values.isEmpty) {
      values.addAll(_seedPreselectedValues());
    }

    _initialEntryValues = {...values};
    _initialMood = mood;
    _initialNote = entry.journalText ?? '';

    return state.copyWith(
      mood: mood,
      note: entry.journalText ?? '',
      entryValues: values,
      selectedDayLocal: _selectedDayLocal,
      status: const JournalEntryEditorIdle(),
      isDirty: false,
    );
  }

  JournalEntryEditorState _withIdleAndDirty(JournalEntryEditorState next) {
    final isDirty = _computeIsDirty(next);
    return next.copyWith(
      status: const JournalEntryEditorIdle(),
      isDirty: isDirty,
    );
  }

  bool _computeIsDirty(JournalEntryEditorState next) {
    final moodChanged = next.mood != _initialMood;

    final nextNote = next.note.trim();
    final initialNote = _initialNote.trim();
    final noteChanged = nextNote != initialNote;

    final entriesChanged = !_sameMap(next.entryValues, _initialEntryValues);
    return moodChanged || noteChanged || entriesChanged;
  }

  bool _sameMap(Map<String, Object?> a, Map<String, Object?> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (b[entry.key] != entry.value) return false;
    }
    return true;
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

final class JournalDailySummaryItem {
  const JournalDailySummaryItem({required this.label, required this.value});

  final String label;
  final String value;
}
