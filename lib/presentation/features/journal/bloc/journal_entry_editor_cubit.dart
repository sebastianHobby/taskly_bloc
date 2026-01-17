import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/domain/interfaces/journal_repository_contract.dart';
import 'package:taskly_domain/domain/journal/model/journal_entry.dart';
import 'package:taskly_domain/domain/journal/model/mood_rating.dart';
import 'package:taskly_domain/domain/journal/model/tracker_definition.dart';
import 'package:taskly_domain/domain/journal/model/tracker_event.dart';
import 'package:taskly_domain/domain/journal/model/tracker_preference.dart';
import 'package:taskly_domain/domain/time/date_only.dart';

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
    required this.mood,
    required this.note,
    required this.availableTrackers,
    required this.selectedTrackerIds,
    required this.moodTrackerId,
    required this.isDirty,
  });

  factory JournalEntryEditorState.initial({required String? entryId}) {
    return JournalEntryEditorState(
      status: const JournalEntryEditorLoading(),
      entryId: entryId,
      mood: null,
      note: '',
      availableTrackers: const <TrackerDefinition>[],
      selectedTrackerIds: const <String>{},
      moodTrackerId: null,
      isDirty: false,
    );
  }

  final JournalEntryEditorStatus status;
  final String? entryId;
  final MoodRating? mood;
  final String note;
  final List<TrackerDefinition> availableTrackers;
  final Set<String> selectedTrackerIds;
  final String? moodTrackerId;
  final bool isDirty;

  bool get isEditingExisting => entryId != null && entryId!.trim().isNotEmpty;

  JournalEntryEditorState copyWith({
    JournalEntryEditorStatus? status,
    String? entryId,
    MoodRating? mood,
    String? note,
    List<TrackerDefinition>? availableTrackers,
    Set<String>? selectedTrackerIds,
    String? moodTrackerId,
    bool? isDirty,
  }) {
    return JournalEntryEditorState(
      status: status ?? this.status,
      entryId: entryId ?? this.entryId,
      mood: mood ?? this.mood,
      note: note ?? this.note,
      availableTrackers: availableTrackers ?? this.availableTrackers,
      selectedTrackerIds: selectedTrackerIds ?? this.selectedTrackerIds,
      moodTrackerId: moodTrackerId ?? this.moodTrackerId,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

class JournalEntryEditorCubit extends Cubit<JournalEntryEditorState> {
  JournalEntryEditorCubit({
    required JournalRepositoryContract repository,
    required String? entryId,
    required Set<String> preselectedTrackerIds,
    DateTime Function()? nowUtc,
  }) : _repository = repository,
       _preselectedTrackerIds = preselectedTrackerIds,
       _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
       super(JournalEntryEditorState.initial(entryId: entryId)) {
    _init();
  }

  final JournalRepositoryContract _repository;
  final Set<String> _preselectedTrackerIds;
  final DateTime Function() _nowUtc;

  StreamSubscription<
    ({List<TrackerDefinition> defs, List<TrackerPreference> prefs})
  >?
  _defsSub;

  List<TrackerDefinition> _latestDefs = const <TrackerDefinition>[];

  Set<String> _initialSelected = const <String>{};
  JournalEntry? _initialEntry;
  MoodRating? _initialMood;
  String _initialNote = '';

  @override
  Future<void> close() async {
    await _defsSub?.cancel();
    _defsSub = null;
    return super.close();
  }

  void moodChanged(MoodRating? mood) {
    emit(_withIdleAndDirty(state.copyWith(mood: mood)));
  }

  void noteChanged(String note) {
    emit(_withIdleAndDirty(state.copyWith(note: note)));
  }

  void toggleTracker(String trackerId) {
    final next = {...state.selectedTrackerIds};
    if (next.contains(trackerId)) {
      next.remove(trackerId);
    } else {
      next.add(trackerId);
    }

    emit(_withIdleAndDirty(state.copyWith(selectedTrackerIds: next)));
  }

  Future<void> save() async {
    final mood = state.mood;
    if (mood == null) {
      emit(
        state.copyWith(
          status: const JournalEntryEditorError('Please choose a mood.'),
        ),
      );
      return;
    }

    final moodTrackerId = _findMoodTrackerId();
    if (moodTrackerId == null) {
      emit(
        state.copyWith(
          status: const JournalEntryEditorError('Missing system mood tracker.'),
        ),
      );
      return;
    }

    emit(state.copyWith(status: const JournalEntryEditorSaving()));

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

      final entryId = await _repository.upsertJournalEntry(entryToSave);

      // Mood (required)
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
      );

      // Boolean tracker changes (best-effort set true/false).
      final currentSelected = state.selectedTrackerIds;
      final union = <String>{..._initialSelected, ...currentSelected};
      union.remove(moodTrackerId);

      for (final trackerId in union) {
        final shouldBeSelected = currentSelected.contains(trackerId);
        await _repository.appendTrackerEvent(
          TrackerEvent(
            id: '',
            trackerId: trackerId,
            anchorType: 'entry',
            entryId: entryId,
            op: 'set',
            value: shouldBeSelected,
            occurredAt: nowUtc,
            recordedAt: nowUtc,
          ),
        );
      }

      emit(
        state.copyWith(
          entryId: entryId,
          status: const JournalEntryEditorSaved(),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: JournalEntryEditorError('Failed to save log: $e'),
        ),
      );
    }
  }

  Future<void> _init() async {
    _subscribeDefinitions();

    try {
      if (state.entryId != null && state.entryId!.trim().isNotEmpty) {
        await _loadExistingEntry(state.entryId!);
      } else {
        _initialMood = null;
        _initialNote = '';
        _initialSelected = {..._preselectedTrackerIds};
        emit(
          state.copyWith(
            selectedTrackerIds: {..._preselectedTrackerIds},
            status: const JournalEntryEditorIdle(),
            isDirty: false,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: JournalEntryEditorError('Failed to load log: $e'),
        ),
      );
    }
  }

  void _subscribeDefinitions() {
    final defs$ = _repository.watchTrackerDefinitions().startWith(
      const <TrackerDefinition>[],
    );
    final prefs$ = _repository.watchTrackerPreferences().startWith(
      const <TrackerPreference>[],
    );

    final combined$ =
        Rx.combineLatest2<
          List<TrackerDefinition>,
          List<TrackerPreference>,
          ({List<TrackerDefinition> defs, List<TrackerPreference> prefs})
        >(defs$, prefs$, (defs, prefs) => (defs: defs, prefs: prefs));

    _defsSub?.cancel();
    _defsSub = combined$.listen(
      (data) {
        _latestDefs = data.defs;

        final preferenceByTrackerId = {
          for (final p in data.prefs) p.trackerId: p,
        };

        String? moodTrackerId;
        for (final d in data.defs) {
          if (d.systemKey == 'mood') {
            moodTrackerId = d.id;
            break;
          }
        }

        final available =
            data.defs
                .where((d) => d.isActive && d.deletedAt == null)
                .where((d) => d.systemKey != 'mood')
                .where((d) {
                  final pref = preferenceByTrackerId[d.id];
                  return (pref?.pinned ?? false) ||
                      (pref?.showInQuickAdd ?? false);
                })
                .toList(growable: false)
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        emit(
          state.copyWith(
            availableTrackers: available,
            moodTrackerId: moodTrackerId,
          ),
        );
      },
      onError: (Object e) {
        // Non-fatal; editor should still allow mood + note.
        emit(
          state.copyWith(
            status: JournalEntryEditorError('Failed to load trackers: $e'),
          ),
        );
      },
    );
  }

  Future<void> _loadExistingEntry(String entryId) async {
    final entry = await _repository.getJournalEntryById(entryId);
    if (entry == null) {
      throw StateError('Log not found');
    }

    _initialEntry = entry;

    // Load events once for prefill.
    final events = await _repository
        .watchTrackerEvents(anchorType: 'entry', entryId: entryId)
        .first;

    final moodTrackerId = _findMoodTrackerId();

    MoodRating? mood;
    final selected = <String>{};

    for (final e in events) {
      if (moodTrackerId != null && e.trackerId == moodTrackerId) {
        if (e.value is int) {
          mood = MoodRating.fromValue(e.value! as int);
        }
        continue;
      }

      if (e.value is bool && (e.value! as bool)) {
        selected.add(e.trackerId);
      }
    }

    if (selected.isEmpty) {
      selected.addAll(_preselectedTrackerIds);
    }

    _initialSelected = {...selected};
    _initialMood = mood;
    _initialNote = entry.journalText ?? '';

    emit(
      state.copyWith(
        mood: mood,
        note: entry.journalText ?? '',
        selectedTrackerIds: selected,
        status: const JournalEntryEditorIdle(),
        isDirty: false,
      ),
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

    final selectedChanged = !_sameSet(
      next.selectedTrackerIds,
      _initialSelected,
    );
    return moodChanged || noteChanged || selectedChanged;
  }

  bool _sameSet(Set<String> a, Set<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }

  String? _findMoodTrackerId() {
    for (final t in _latestDefs) {
      if (t.systemKey == 'mood') return t.id;
    }
    return null;
  }
}
