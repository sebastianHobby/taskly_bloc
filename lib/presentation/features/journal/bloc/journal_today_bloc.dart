import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/time.dart';

sealed class JournalTodayState {
  const JournalTodayState();
}

final class JournalTodayLoading extends JournalTodayState {
  const JournalTodayLoading();
}

final class JournalTodayLoaded extends JournalTodayState {
  const JournalTodayLoaded({
    required this.pinnedTrackers,
    required this.entries,
    required this.eventsByEntryId,
    required this.definitionById,
    required this.moodTrackerId,
  });

  final List<TrackerDefinition> pinnedTrackers;
  final List<JournalEntry> entries;
  final Map<String, List<TrackerEvent>> eventsByEntryId;
  final Map<String, TrackerDefinition> definitionById;
  final String? moodTrackerId;
}

final class JournalTodayError extends JournalTodayState {
  const JournalTodayError(this.message);

  final String message;
}

class JournalTodayBloc extends Cubit<JournalTodayState> {
  JournalTodayBloc({
    required JournalRepositoryContract repository,
    DateTime Function()? nowUtc,
  }) : _repository = repository,
       _nowUtc = nowUtc ?? (() => DateTime.now().toUtc()),
       super(const JournalTodayLoading()) {
    _subscribe();
  }

  final JournalRepositoryContract _repository;
  final DateTime Function() _nowUtc;

  StreamSubscription<JournalTodayLoaded>? _sub;

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    return super.close();
  }

  void _subscribe() {
    final nowUtc = _nowUtc();
    final startUtc = dateOnly(nowUtc);
    final endUtc = startUtc
        .add(const Duration(days: 1))
        .subtract(const Duration(microseconds: 1));

    final defs$ = _repository.watchTrackerDefinitions();
    final prefs$ = _repository.watchTrackerPreferences();
    final entries$ = _repository.watchJournalEntriesByQuery(
      JournalQuery.forDate(nowUtc),
    );
    final events$ = _repository.watchTrackerEvents(
      range: DateRange(start: startUtc, end: endUtc),
      anchorType: 'entry',
    );

    _sub =
        Rx.combineLatest4<
              List<TrackerDefinition>,
              List<TrackerPreference>,
              List<JournalEntry>,
              List<TrackerEvent>,
              JournalTodayLoaded
            >(
              defs$,
              prefs$,
              entries$,
              events$,
              (defs, prefs, entries, events) {
                final definitionById = {
                  for (final d in defs) d.id: d,
                };

                String? moodTrackerId;
                for (final d in defs) {
                  if (d.systemKey == 'mood') {
                    moodTrackerId = d.id;
                    break;
                  }
                }

                final prefByTrackerId = {
                  for (final p in prefs) p.trackerId: p,
                };

                final pinnedTrackers =
                    defs
                        .where((d) => d.isActive && d.deletedAt == null)
                        .where((d) => d.systemKey != 'mood')
                        .where((d) {
                          final pref = prefByTrackerId[d.id];
                          return (pref?.pinned ?? false) ||
                              (pref?.showInQuickAdd ?? false);
                        })
                        .toList(growable: false)
                      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

                final eventsByEntryId = <String, List<TrackerEvent>>{};
                for (final e in events) {
                  final entryId = e.entryId;
                  if (entryId == null) continue;
                  (eventsByEntryId[entryId] ??= <TrackerEvent>[]).add(e);
                }

                return JournalTodayLoaded(
                  pinnedTrackers: pinnedTrackers,
                  entries: entries,
                  eventsByEntryId: eventsByEntryId,
                  definitionById: definitionById,
                  moodTrackerId: moodTrackerId,
                );
              },
            )
            .listen(
              emit,
              onError: (Object e) {
                emit(JournalTodayError('Failed to load Journal data: $e'));
              },
            );
  }
}
