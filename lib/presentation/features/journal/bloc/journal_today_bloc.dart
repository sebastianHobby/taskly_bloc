import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/time.dart';

sealed class JournalTodayEvent {
  const JournalTodayEvent();
}

final class JournalTodayStarted extends JournalTodayEvent {
  const JournalTodayStarted({required this.selectedDay});

  final DateTime selectedDay;
}

sealed class JournalTodayState {
  const JournalTodayState();
}

final class JournalTodayLoading extends JournalTodayState {
  const JournalTodayLoading();
}

final class JournalTodayLoaded extends JournalTodayState {
  const JournalTodayLoaded({
    required this.entries,
    required this.eventsByEntryId,
    required this.definitionById,
    required this.moodTrackerId,
    required this.moodWeek,
    required this.moodStreakDays,
    required this.moodAverage,
    required this.dailySummaryItems,
    required this.dailySummaryTotalCount,
  });

  final List<JournalEntry> entries;
  final Map<String, List<TrackerEvent>> eventsByEntryId;
  final Map<String, TrackerDefinition> definitionById;
  final String? moodTrackerId;
  final List<JournalMoodDay> moodWeek;
  final int moodStreakDays;
  final double? moodAverage;
  final List<JournalDailySummaryItem> dailySummaryItems;
  final int dailySummaryTotalCount;
}

final class JournalTodayError extends JournalTodayState {
  const JournalTodayError(this.message);

  final String message;
}

class JournalTodayBloc extends Bloc<JournalTodayEvent, JournalTodayState> {
  JournalTodayBloc({
    required JournalRepositoryContract repository,
    DateTime? selectedDay,
  }) : _repository = repository,
       _selectedDay = selectedDay,
       super(const JournalTodayLoading()) {
    on<JournalTodayStarted>(_onStarted, transformer: restartable());
  }

  final JournalRepositoryContract _repository;
  final DateTime? _selectedDay;

  Future<void> _onStarted(
    JournalTodayStarted event,
    Emitter<JournalTodayState> emit,
  ) async {
    final day = _selectedDay ?? event.selectedDay;
    final startUtc = dateOnly(day);
    final endUtc = startUtc
        .add(const Duration(days: 1))
        .subtract(const Duration(microseconds: 1));

    final weekStartUtc = startUtc.subtract(const Duration(days: 6));
    final weekEndUtc = endUtc;

    final defs$ = _repository.watchTrackerDefinitions();
    final entries$ = _repository.watchJournalEntriesByQuery(
      JournalQuery.forDate(day),
    );
    final events$ = _repository.watchTrackerEvents(
      range: DateRange(start: startUtc, end: endUtc),
      anchorType: 'entry',
    );
    final weekEvents$ = _repository.watchTrackerEvents(
      range: DateRange(start: weekStartUtc, end: weekEndUtc),
      anchorType: 'entry',
    );
    final dayState$ = _repository.watchTrackerStateDay(
      range: DateRange(start: startUtc, end: startUtc),
    );

    await emit.onEach<JournalTodayLoaded>(
      Rx.combineLatest5<
        List<TrackerDefinition>,
        List<JournalEntry>,
        List<TrackerEvent>,
        List<TrackerEvent>,
        List<TrackerStateDay>,
        JournalTodayLoaded
      >(
        defs$,
        entries$,
        events$,
        weekEvents$,
        dayState$,
        (defs, entries, events, weekEvents, dayStates) {
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
          final moodAverage = _computeMoodAverage(
            entries: entries,
            eventsByEntryId: eventsByEntryId,
            moodTrackerId: moodTrackerId,
          );

          final summary = _buildDailySummary(
            defs: defs,
            dayStates: dayStates,
          );

          return JournalTodayLoaded(
            entries: entries,
            eventsByEntryId: eventsByEntryId,
            definitionById: definitionById,
            moodTrackerId: moodTrackerId,
            moodWeek: moodWeek,
            moodStreakDays: moodStreakDays,
            moodAverage: moodAverage,
            dailySummaryItems: summary.items,
            dailySummaryTotalCount: summary.totalCount,
          );
        },
      ),
      onData: emit.call,
      onError: (Object e, StackTrace _) {
        emit(JournalTodayError('Failed to load Journal data: $e'));
      },
    );
  }

  double? _computeMoodAverage({
    required List<JournalEntry> entries,
    required Map<String, List<TrackerEvent>> eventsByEntryId,
    required String? moodTrackerId,
  }) {
    if (moodTrackerId == null) return null;

    final moodValues = <int>[];
    for (final entry in entries) {
      final events = eventsByEntryId[entry.id] ?? const <TrackerEvent>[];
      for (final e in events) {
        if (e.trackerId == moodTrackerId && e.value is int) {
          moodValues.add(e.value! as int);
          break;
        }
      }
    }

    if (moodValues.isEmpty) return null;
    final sum = moodValues.reduce((a, b) => a + b);
    return sum / moodValues.length;
  }

  _DailySummary _buildDailySummary({
    required List<TrackerDefinition> defs,
    required List<TrackerStateDay> dayStates,
  }) {
    final dayStateByTrackerId = {
      for (final s in dayStates) s.trackerId: s,
    };

    bool isDailyScope(TrackerDefinition d) {
      final scope = d.scope.trim().toLowerCase();
      return scope == 'day' || scope == 'daily' || scope == 'sleep_night';
    }

    final dailyDefs =
        defs
            .where((d) => d.isActive && d.deletedAt == null)
            .where(isDailyScope)
            .toList(growable: false)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final items = <JournalDailySummaryItem>[];
    for (final d in dailyDefs) {
      final value = dayStateByTrackerId[d.id]?.value;
      if (value == null) continue;
      final label = d.name;
      final valueText = _formatSummaryValue(value);
      if (valueText == null) continue;
      items.add(JournalDailySummaryItem(label: label, value: valueText));
      if (items.length == 3) break;
    }

    return _DailySummary(items: items, totalCount: dailyDefs.length);
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

final class JournalMoodDay {
  const JournalMoodDay({required this.dayUtc, required this.mood});

  final DateTime dayUtc;
  final MoodRating? mood;
}

final class JournalDailySummaryItem {
  const JournalDailySummaryItem({required this.label, required this.value});

  final String label;
  final String value;
}

final class _DailySummary {
  const _DailySummary({required this.items, required this.totalCount});

  final List<JournalDailySummaryItem> items;
  final int totalCount;
}
