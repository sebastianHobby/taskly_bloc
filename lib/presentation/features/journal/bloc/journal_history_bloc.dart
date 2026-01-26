import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

sealed class JournalHistoryEvent {
  const JournalHistoryEvent();
}

final class JournalHistoryStarted extends JournalHistoryEvent {
  const JournalHistoryStarted();
}

sealed class JournalHistoryState {
  const JournalHistoryState();
}

final class JournalHistoryLoading extends JournalHistoryState {
  const JournalHistoryLoading();
}

final class JournalHistoryLoaded extends JournalHistoryState {
  const JournalHistoryLoaded(this.days);

  final List<JournalHistoryDaySummary> days;
}

final class JournalHistoryError extends JournalHistoryState {
  const JournalHistoryError(this.message);

  final String message;
}

class JournalHistoryBloc
    extends Bloc<JournalHistoryEvent, JournalHistoryState> {
  JournalHistoryBloc({
    required JournalRepositoryContract repository,
    required HomeDayKeyService dayKeyService,
  }) : _repository = repository,
       _dayKeyService = dayKeyService,
       super(const JournalHistoryLoading()) {
    on<JournalHistoryStarted>(_onStarted, transformer: restartable());
  }

  final JournalRepositoryContract _repository;
  final HomeDayKeyService _dayKeyService;

  Future<void> _onStarted(
    JournalHistoryStarted event,
    Emitter<JournalHistoryState> emit,
  ) async {
    final todayDayKeyUtc = _dayKeyService.todayDayKeyUtc();
    final startUtc = todayDayKeyUtc.subtract(const Duration(days: 29));
    final endUtc = todayDayKeyUtc
        .add(const Duration(days: 1))
        .subtract(const Duration(microseconds: 1));

    final defs$ = _repository.watchTrackerDefinitions();
    final entries$ = _repository.watchJournalEntriesByQuery(
      JournalQuery.recent(days: 30, todayDayKeyUtc: todayDayKeyUtc),
    );
    final dayState$ = _repository.watchTrackerStateDay(
      range: DateRange(start: startUtc, end: todayDayKeyUtc),
    );
    final events$ = _repository.watchTrackerEvents(
      range: DateRange(start: startUtc, end: endUtc),
      anchorType: 'entry',
    );

    await emit.onEach<JournalHistoryLoaded>(
      Rx.combineLatest4<
        List<TrackerDefinition>,
        List<JournalEntry>,
        List<TrackerStateDay>,
        List<TrackerEvent>,
        JournalHistoryLoaded
      >(
        defs$,
        entries$,
        dayState$,
        events$,
        (defs, entries, dayStates, events) {
          final days = _buildDaySummaries(
            defs: defs,
            entries: entries,
            dayStates: dayStates,
            events: events,
          );
          return JournalHistoryLoaded(days);
        },
      ),
      onData: emit.call,
      onError: (Object e, StackTrace _) {
        emit(JournalHistoryError('Failed to load history: $e'));
      },
    );
  }

  List<JournalHistoryDaySummary> _buildDaySummaries({
    required List<TrackerDefinition> defs,
    required List<JournalEntry> entries,
    required List<TrackerStateDay> dayStates,
    required List<TrackerEvent> events,
  }) {
    final definitionById = {for (final d in defs) d.id: d};
    final moodTrackerId = _findMoodTrackerId(defs);

    final entriesByDay = <DateTime, List<JournalEntry>>{};
    for (final entry in entries) {
      final day = dateOnly(entry.entryDate.toUtc());
      (entriesByDay[day] ??= <JournalEntry>[]).add(entry);
    }

    final eventsByEntryId = <String, List<TrackerEvent>>{};
    final moodValuesByDay = <DateTime, List<int>>{};
    for (final event in events) {
      final entryId = event.entryId;
      if (entryId != null) {
        (eventsByEntryId[entryId] ??= <TrackerEvent>[]).add(event);
      }

      if (moodTrackerId == null || event.trackerId != moodTrackerId) continue;
      if (event.value is! int) continue;
      final day = dateOnly(event.occurredAt.toUtc());
      (moodValuesByDay[day] ??= <int>[]).add(event.value! as int);
    }

    final dayStateByTrackerIdByDay = <DateTime, Map<String, TrackerStateDay>>{};
    for (final state in dayStates) {
      final day = dateOnly(state.anchorDate.toUtc());
      final map = dayStateByTrackerIdByDay[day] ??= <String, TrackerStateDay>{};
      map[state.trackerId] = state;
    }

    final dailyDefs =
        defs
            .where((d) => d.isActive && d.deletedAt == null)
            .where(_isDailyScope)
            .toList(growable: false)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final days = entriesByDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return [
      for (final day in days)
        JournalHistoryDaySummary(
          day: day,
          entries: entriesByDay[day] ?? const <JournalEntry>[],
          eventsByEntryId: eventsByEntryId,
          definitionById: definitionById,
          moodTrackerId: moodTrackerId,
          moodAverage: _average(moodValuesByDay[day]),
          dailySummaryItems: _buildDailySummaryItems(
            defs: dailyDefs,
            dayStates:
                dayStateByTrackerIdByDay[day] ??
                const <String, TrackerStateDay>{},
          ),
          dailySummaryTotalCount: dailyDefs.length,
        ),
    ];
  }

  String? _findMoodTrackerId(List<TrackerDefinition> defs) {
    for (final d in defs) {
      if (d.systemKey == 'mood') return d.id;
    }
    return null;
  }

  bool _isDailyScope(TrackerDefinition d) {
    final scope = d.scope.trim().toLowerCase();
    return scope == 'day' || scope == 'daily' || scope == 'sleep_night';
  }

  List<JournalDailySummaryItem> _buildDailySummaryItems({
    required List<TrackerDefinition> defs,
    required Map<String, TrackerStateDay> dayStates,
  }) {
    final items = <JournalDailySummaryItem>[];
    for (final d in defs) {
      final value = dayStates[d.id]?.value;
      if (value == null) continue;
      final formatted = _formatSummaryValue(value);
      if (formatted == null) continue;
      items.add(JournalDailySummaryItem(label: d.name, value: formatted));
      if (items.length == 3) break;
    }
    return items;
  }

  double? _average(List<int>? values) {
    if (values == null || values.isEmpty) return null;
    final sum = values.fold<int>(0, (a, b) => a + b);
    return sum / values.length;
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
}

final class JournalHistoryDaySummary {
  const JournalHistoryDaySummary({
    required this.day,
    required this.entries,
    required this.eventsByEntryId,
    required this.definitionById,
    required this.moodTrackerId,
    required this.moodAverage,
    required this.dailySummaryItems,
    required this.dailySummaryTotalCount,
  });

  final DateTime day;
  final List<JournalEntry> entries;
  final Map<String, List<TrackerEvent>> eventsByEntryId;
  final Map<String, TrackerDefinition> definitionById;
  final String? moodTrackerId;
  final double? moodAverage;
  final List<JournalDailySummaryItem> dailySummaryItems;
  final int dailySummaryTotalCount;
}

final class JournalDailySummaryItem {
  const JournalDailySummaryItem({required this.label, required this.value});

  final String label;
  final String value;
}
