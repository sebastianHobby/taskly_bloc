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
    required this.moodWeek,
    required this.moodStreakDays,
  });

  final List<TrackerDefinition> pinnedTrackers;
  final List<JournalEntry> entries;
  final Map<String, List<TrackerEvent>> eventsByEntryId;
  final Map<String, TrackerDefinition> definitionById;
  final String? moodTrackerId;
  final List<JournalMoodDay> moodWeek;
  final int moodStreakDays;
}

final class JournalTodayError extends JournalTodayState {
  const JournalTodayError(this.message);

  final String message;
}

class JournalTodayBloc extends Cubit<JournalTodayState> {
  JournalTodayBloc({
    required JournalRepositoryContract repository,
    required DateTime Function() nowUtc,
  }) : _repository = repository,
       _nowUtc = nowUtc,
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

    final weekStartUtc = startUtc.subtract(const Duration(days: 6));
    final weekEndUtc = endUtc;

    final defs$ = _repository.watchTrackerDefinitions();
    final prefs$ = _repository.watchTrackerPreferences();
    final entries$ = _repository.watchJournalEntriesByQuery(
      JournalQuery.forDate(nowUtc),
    );
    final events$ = _repository.watchTrackerEvents(
      range: DateRange(start: startUtc, end: endUtc),
      anchorType: 'entry',
    );
    final weekEvents$ = _repository.watchTrackerEvents(
      range: DateRange(start: weekStartUtc, end: weekEndUtc),
      anchorType: 'entry',
    );

    _sub =
        Rx.combineLatest5<
              List<TrackerDefinition>,
              List<TrackerPreference>,
              List<JournalEntry>,
              List<TrackerEvent>,
              List<TrackerEvent>,
              JournalTodayLoaded
            >(
              defs$,
              prefs$,
              entries$,
              events$,
              weekEvents$,
              (defs, prefs, entries, events, weekEvents) {
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

                final moodWeek = _buildMoodWeek(
                  weekEvents: weekEvents,
                  moodTrackerId: moodTrackerId,
                  weekStartUtc: weekStartUtc,
                );
                final moodStreakDays = _countMoodStreak(moodWeek);

                return JournalTodayLoaded(
                  pinnedTrackers: pinnedTrackers,
                  entries: entries,
                  eventsByEntryId: eventsByEntryId,
                  definitionById: definitionById,
                  moodTrackerId: moodTrackerId,
                  moodWeek: moodWeek,
                  moodStreakDays: moodStreakDays,
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

  List<JournalMoodDay> _buildMoodWeek({
    required List<TrackerEvent> weekEvents,
    required String? moodTrackerId,
    required DateTime weekStartUtc,
  }) {
    final moodEventByDay = <DateTime, TrackerEvent>{};
    if (moodTrackerId != null) {
      for (final event in weekEvents) {
        if (event.trackerId != moodTrackerId) continue;
        if (event.value is! int) continue;
        final dayKeyUtc = dateOnly(event.occurredAt.toUtc());
        final existing = moodEventByDay[dayKeyUtc];
        if (existing == null ||
            existing.occurredAt.isBefore(event.occurredAt)) {
          moodEventByDay[dayKeyUtc] = event;
        }
      }
    }

    return List<JournalMoodDay>.generate(7, (index) {
      final dayUtc = weekStartUtc.add(Duration(days: index));
      final event = moodEventByDay[dayUtc];
      final mood = event == null
          ? null
          : MoodRating.fromValue(event.value! as int);
      return JournalMoodDay(dayUtc: dayUtc, mood: mood);
    }, growable: false);
  }

  int _countMoodStreak(List<JournalMoodDay> week) {
    var streak = 0;
    for (var i = week.length - 1; i >= 0; i--) {
      if (week[i].mood == null) break;
      streak += 1;
    }
    return streak;
  }
}

class JournalMoodDay {
  const JournalMoodDay({required this.dayUtc, required this.mood});

  final DateTime dayUtc;
  final MoodRating? mood;
}
