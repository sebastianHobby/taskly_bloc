import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:intl/intl.dart';
import 'package:taskly_domain/taskly_domain.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/feeds/rows/row_key.dart';
import 'package:taskly_bloc/presentation/shared/services/time/home_day_service.dart';

sealed class ScheduledFeedEvent {
  const ScheduledFeedEvent();
}

final class ScheduledFeedStarted extends ScheduledFeedEvent {
  const ScheduledFeedStarted();
}

final class ScheduledFeedRetryRequested extends ScheduledFeedEvent {
  const ScheduledFeedRetryRequested();
}

final class ScheduledBucketCollapseToggled extends ScheduledFeedEvent {
  const ScheduledBucketCollapseToggled({required this.bucketKey});

  final String bucketKey;
}

final class ScheduledJumpToTodayRequested extends ScheduledFeedEvent {
  const ScheduledJumpToTodayRequested();
}

sealed class ScheduledFeedState {
  const ScheduledFeedState();
}

final class ScheduledFeedLoading extends ScheduledFeedState {
  const ScheduledFeedLoading();
}

final class ScheduledFeedLoaded extends ScheduledFeedState {
  const ScheduledFeedLoaded({
    required this.rows,
    required this.scrollToTodaySignal,
  });

  final List<ListRowUiModel> rows;

  /// Monotonically increasing signal used by the UI to trigger a one-off
  /// "scroll to today" effect after the state has been rebuilt.
  final int scrollToTodaySignal;
}

final class ScheduledFeedError extends ScheduledFeedState {
  const ScheduledFeedError({required this.message});

  final String message;
}

class ScheduledFeedBloc extends Bloc<ScheduledFeedEvent, ScheduledFeedState> {
  ScheduledFeedBloc({
    required ScheduledOccurrencesService scheduledOccurrencesService,
    required HomeDayService homeDayService,
    ScheduledScope scope = const GlobalScheduledScope(),
  }) : _scheduledOccurrencesService = scheduledOccurrencesService,
       _homeDayService = homeDayService,
       _scope = scope,
       super(const ScheduledFeedLoading()) {
    on<ScheduledFeedStarted>(_onStarted, transformer: restartable());
    on<ScheduledFeedRetryRequested>(
      _onRetryRequested,
      transformer: restartable(),
    );

    on<ScheduledBucketCollapseToggled>(_onBucketCollapseToggled);
    on<ScheduledJumpToTodayRequested>(_onJumpToTodayRequested);

    add(const ScheduledFeedStarted());
  }

  final ScheduledOccurrencesService _scheduledOccurrencesService;
  final HomeDayService _homeDayService;
  final ScheduledScope _scope;

  ScheduledOccurrencesResult? _latestResult;
  final Map<String, bool> _collapsedBuckets = <String, bool>{};
  int _scrollToTodaySignal = 0;

  Future<void> _onStarted(
    ScheduledFeedStarted event,
    Emitter<ScheduledFeedState> emit,
  ) async {
    await _bind(emit);
  }

  Future<void> _onRetryRequested(
    ScheduledFeedRetryRequested event,
    Emitter<ScheduledFeedState> emit,
  ) async {
    emit(const ScheduledFeedLoading());
    await _bind(emit);
  }

  Future<void> _bind(Emitter<ScheduledFeedState> emit) async {
    final todayDayKeyUtc = _homeDayService.todayDayKeyUtc();
    final rangeStart = todayDayKeyUtc;
    final rangeEnd = todayDayKeyUtc.add(const Duration(days: 30));

    await emit.forEach<ScheduledOccurrencesResult>(
      _scheduledOccurrencesService.watchScheduledOccurrences(
        rangeStartDay: rangeStart,
        rangeEndDay: rangeEnd,
        scope: _scope,
      ),
      onData: (result) {
        try {
          _latestResult = result;
          return ScheduledFeedLoaded(
            rows: _mapToRows(result),
            scrollToTodaySignal: _scrollToTodaySignal,
          );
        } catch (e) {
          return ScheduledFeedError(message: e.toString());
        }
      },
      onError: (error, stackTrace) => ScheduledFeedError(
        message: error.toString(),
      ),
    );
  }

  Future<void> _onBucketCollapseToggled(
    ScheduledBucketCollapseToggled event,
    Emitter<ScheduledFeedState> emit,
  ) async {
    final current = _collapsedBuckets[event.bucketKey] ?? false;
    _collapsedBuckets[event.bucketKey] = !current;

    final latestResult = _latestResult;
    if (latestResult == null) return;

    emit(
      ScheduledFeedLoaded(
        rows: _mapToRows(latestResult),
        scrollToTodaySignal: _scrollToTodaySignal,
      ),
    );
  }

  Future<void> _onJumpToTodayRequested(
    ScheduledJumpToTodayRequested event,
    Emitter<ScheduledFeedState> emit,
  ) async {
    final latestResult = _latestResult;
    if (latestResult == null) return;

    // Ensure the section containing today's header is visible.
    _collapsedBuckets['overdue'] = false;

    _scrollToTodaySignal++;
    emit(
      ScheduledFeedLoaded(
        rows: _mapToRows(latestResult),
        scrollToTodaySignal: _scrollToTodaySignal,
      ),
    );
  }

  static const int _nearTermDays = 7;

  List<ListRowUiModel> _mapToRows(ScheduledOccurrencesResult result) {
    final rows = <ListRowUiModel>[];

    const overdueBucketKey = 'overdue';

    if (result.overdue.isNotEmpty) {
      final isCollapsed = _collapsedBuckets[overdueBucketKey] ?? false;
      rows.add(
        BucketHeaderRowUiModel(
          rowKey: RowKey.v1(
            screen: 'scheduled',
            rowType: 'bucket',
            params: const <String, String>{'bucket': overdueBucketKey},
          ),
          depth: 0,
          bucketKey: overdueBucketKey,
          title: 'Overdue',
          isCollapsed: isCollapsed,
        ),
      );

      if (!isCollapsed) {
        final overdueSorted = [...result.overdue]..sort(_compareOccurrences);

        for (final item in overdueSorted) {
          rows.add(_itemRow(item, bucketKey: overdueBucketKey, date: null));
        }
      }
    }

    // Date-first layout: each date's items are ordered by schedule tag
    // (due → ongoing → starts). The UI intentionally does not render tag
    // header rows; tags only influence within-day ordering.
    // SCHED-23: omit empty days entirely.
    final normalizedToday = _normalizeDate(result.rangeStartDay);
    final rangeStart = normalizedToday;
    final rangeEnd = _normalizeDate(result.rangeEndDay);

    final itemsByDateAndTag =
        <DateTime, Map<ScheduledDateTag, List<ScheduledOccurrence>>>{};

    for (final occurrence in result.occurrences) {
      final day = _normalizeDate(occurrence.ref.localDay);
      if (day.isBefore(rangeStart) || day.isAfter(rangeEnd)) continue;

      final tag = occurrence.ref.tag;
      final byTag = itemsByDateAndTag[day] ??=
          <ScheduledDateTag, List<ScheduledOccurrence>>{
            ScheduledDateTag.due: <ScheduledOccurrence>[],
            ScheduledDateTag.ongoing: <ScheduledOccurrence>[],
            ScheduledDateTag.starts: <ScheduledOccurrence>[],
          };
      (byTag[tag] ??= <ScheduledOccurrence>[]).add(occurrence);
    }

    // Near-term dates first (today..today+_nearTermDays) where there are items,
    // then remaining future dates.
    final datesWithItems = itemsByDateAndTag.keys.toList()..sort();
    final nearTermMax = normalizedToday.add(
      const Duration(days: _nearTermDays),
    );
    final nearTermDates = datesWithItems
        .where((d) => !d.isAfter(nearTermMax))
        .toList(growable: false);
    final laterDates = datesWithItems
        .where((d) => d.isAfter(nearTermMax))
        .toList(growable: false);
    final orderedDates = <DateTime>[...nearTermDates, ...laterDates];

    for (final date in orderedDates) {
      final byTag = itemsByDateAndTag[date];
      if (byTag == null) continue;

      rows.add(
        DateHeaderRowUiModel(
          rowKey: RowKey.v1(
            screen: 'scheduled',
            rowType: 'date_header',
            params: <String, String>{'date': _dateKey(date)},
          ),
          depth: 0,
          date: date,
          title: _formatHeader(date),
        ),
      );

      final allItems = <ScheduledOccurrence>[
        ...(byTag[ScheduledDateTag.due] ?? const <ScheduledOccurrence>[]),
        ...(byTag[ScheduledDateTag.ongoing] ?? const <ScheduledOccurrence>[]),
        ...(byTag[ScheduledDateTag.starts] ?? const <ScheduledOccurrence>[]),
      ];
      allItems.sort(_compareOccurrences);

      for (final item in allItems) {
        rows.add(_itemRow(item, bucketKey: null, date: date));
      }
    }

    return rows;
  }

  ScheduledEntityRowUiModel _itemRow(
    ScheduledOccurrence item, {
    required String? bucketKey,
    required DateTime? date,
  }) {
    final entityId = item.ref.entityId;
    final tag = item.ref.tag;
    final rowType = item.ref.entityType == EntityType.task ? 'task' : 'project';

    return ScheduledEntityRowUiModel(
      rowKey: RowKey.v1(
        screen: 'scheduled',
        rowType: rowType,
        params: <String, String>{
          'id': entityId,
          if (date != null) 'date': _dateKey(date),
          'tag': tag.name,
          ...?(bucketKey == null
              ? null
              : <String, String>{
                  'bucket': bucketKey,
                }),
        },
      ),
      depth: date == null ? 1 : 2,
      occurrence: item,
    );
  }

  int _compareOccurrences(ScheduledOccurrence a, ScheduledOccurrence b) {
    final aPinned = a.ref.entityType == EntityType.task
        ? (a.task?.isPinned ?? false)
        : (a.project?.isPinned ?? false);
    final bPinned = b.ref.entityType == EntityType.task
        ? (b.task?.isPinned ?? false)
        : (b.project?.isPinned ?? false);
    if (aPinned != bPinned) return aPinned ? -1 : 1;

    final aTagRank = _tagRank(a.ref.tag);
    final bTagRank = _tagRank(b.ref.tag);
    if (aTagRank != bTagRank) return aTagRank.compareTo(bTagRank);

    final aName = a.name.toLowerCase();
    final bName = b.name.toLowerCase();
    final nameCmp = aName.compareTo(bName);
    if (nameCmp != 0) return nameCmp;

    return a.ref.entityId.compareTo(b.ref.entityId);
  }

  int _tagRank(ScheduledDateTag tag) {
    return switch (tag) {
      ScheduledDateTag.due => 0,
      ScheduledDateTag.ongoing => 1,
      ScheduledDateTag.starts => 2,
    };
  }

  String _formatHeader(DateTime date) {
    return DateFormat('E, MMM d').format(date);
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
