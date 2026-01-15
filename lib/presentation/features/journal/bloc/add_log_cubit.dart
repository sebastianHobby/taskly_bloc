import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/domain/interfaces/journal_repository_contract.dart';
import 'package:taskly_bloc/domain/journal/model/journal_entry.dart';
import 'package:taskly_bloc/domain/journal/model/mood_rating.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_event.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_preference.dart';
import 'package:taskly_bloc/domain/time/date_only.dart';

sealed class AddLogStatus {
  const AddLogStatus();
}

final class AddLogIdle extends AddLogStatus {
  const AddLogIdle();
}

final class AddLogSaving extends AddLogStatus {
  const AddLogSaving();
}

final class AddLogSaved extends AddLogStatus {
  const AddLogSaved();
}

final class AddLogError extends AddLogStatus {
  const AddLogError(this.message);

  final String message;
}

final class AddLogState {
  const AddLogState({
    required this.mood,
    required this.note,
    required this.selectedTrackerIds,
    required this.quickAddTrackers,
    required this.status,
  });

  factory AddLogState.initial(Set<String> preselectedTrackerIds) {
    return AddLogState(
      mood: null,
      note: '',
      selectedTrackerIds: {...preselectedTrackerIds},
      quickAddTrackers: const <TrackerDefinition>[],
      status: const AddLogIdle(),
    );
  }

  final MoodRating? mood;
  final String note;
  final Set<String> selectedTrackerIds;
  final List<TrackerDefinition> quickAddTrackers;
  final AddLogStatus status;

  AddLogState copyWith({
    MoodRating? mood,
    String? note,
    Set<String>? selectedTrackerIds,
    List<TrackerDefinition>? quickAddTrackers,
    AddLogStatus? status,
  }) {
    return AddLogState(
      mood: mood ?? this.mood,
      note: note ?? this.note,
      selectedTrackerIds: selectedTrackerIds ?? this.selectedTrackerIds,
      quickAddTrackers: quickAddTrackers ?? this.quickAddTrackers,
      status: status ?? this.status,
    );
  }
}

class AddLogCubit extends Cubit<AddLogState> {
  AddLogCubit({
    required JournalRepositoryContract repository,
    required Set<String> preselectedTrackerIds,
    DateTime Function()? nowUtc,
  }) : _repository = repository,
       _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
       super(AddLogState.initial(preselectedTrackerIds)) {
    _subscribeQuickAdd();
  }

  final JournalRepositoryContract _repository;
  final DateTime Function() _nowUtc;

  StreamSubscription<
    ({List<TrackerDefinition> defs, List<TrackerPreference> prefs})
  >?
  _quickAddSub;

  List<TrackerDefinition> _latestDefs = const <TrackerDefinition>[];
  Map<String, TrackerPreference> _latestPrefByTrackerId =
      const <String, TrackerPreference>{};

  @override
  Future<void> close() async {
    await _quickAddSub?.cancel();
    _quickAddSub = null;
    return super.close();
  }

  void moodChanged(MoodRating? mood) {
    emit(state.copyWith(mood: mood, status: const AddLogIdle()));
  }

  void noteChanged(String note) {
    emit(state.copyWith(note: note, status: const AddLogIdle()));
  }

  void toggleTracker(String trackerId) {
    final next = {...state.selectedTrackerIds};
    if (next.contains(trackerId)) {
      next.remove(trackerId);
    } else {
      next.add(trackerId);
    }

    emit(state.copyWith(selectedTrackerIds: next, status: const AddLogIdle()));
  }

  Future<void> save() async {
    final mood = state.mood;
    if (mood == null) {
      emit(state.copyWith(status: const AddLogError('Please choose a mood.')));
      return;
    }

    emit(state.copyWith(status: const AddLogSaving()));

    try {
      final nowUtc = _nowUtc();
      final dayUtc = dateOnly(nowUtc);

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

      final entryId = await _repository.upsertJournalEntry(entry);

      String? moodTrackerId;
      for (final t in _latestDefs) {
        if (t.systemKey == 'mood') {
          moodTrackerId = t.id;
          break;
        }
      }

      if (moodTrackerId == null) {
        throw StateError('Missing system mood tracker');
      }

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

      // Selected quick-add trackers (best-effort boolean set=true)
      for (final trackerId in state.selectedTrackerIds) {
        if (trackerId == moodTrackerId) continue;
        await _repository.appendTrackerEvent(
          TrackerEvent(
            id: '',
            trackerId: trackerId,
            anchorType: 'entry',
            entryId: entryId,
            op: 'set',
            value: true,
            occurredAt: nowUtc,
            recordedAt: nowUtc,
          ),
        );
      }

      emit(state.copyWith(status: const AddLogSaved()));
    } catch (e) {
      emit(state.copyWith(status: AddLogError('Failed to save log: $e')));
    }
  }

  void _subscribeQuickAdd() {
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
          ({
            List<TrackerDefinition> defs,
            List<TrackerPreference> prefs,
          })
        >(
          defs$,
          prefs$,
          (defs, prefs) => (defs: defs, prefs: prefs),
        );

    _quickAddSub?.cancel();

    // Keep a single subscription to the combined result and update local caches.
    _quickAddSub = combined$.listen(
      (data) {
        _latestDefs = data.defs;
        _latestPrefByTrackerId = {
          for (final p in data.prefs) p.trackerId: p,
        };

        final quickAdd =
            data.defs
                .where((d) => d.isActive && d.deletedAt == null)
                .where(
                  (d) =>
                      (_latestPrefByTrackerId[d.id]?.showInQuickAdd ?? false) ||
                      (_latestPrefByTrackerId[d.id]?.pinned ?? false),
                )
                .toList(growable: false)
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        emit(state.copyWith(quickAddTrackers: quickAdd));
      },
      onError: (Object e) {
        // Non-fatal; keep sheet usable for mood+note.
        emit(
          state.copyWith(status: AddLogError('Failed to load trackers: $e')),
        );
      },
    );
  }
}
