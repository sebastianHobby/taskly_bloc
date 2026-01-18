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

    final today = _normalizeDate(latestResult.rangeStartDay);
    final todayBucketKey = _bucketKeyForDate(today, today: today);
    _collapsedBuckets[todayBucketKey] = false;

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

    final itemsByDate = <DateTime, List<ScheduledOccurrence>>{};
    for (final occurrence in result.occurrences) {
      final day = _normalizeDate(occurrence.ref.localDay);
      (itemsByDate[day] ??= <ScheduledOccurrence>[]).add(occurrence);
    }

    final groups = _generateDateGroups(
      itemsByDate: itemsByDate,
      today: result.rangeStartDay,
      nearTermDays: _nearTermDays,
    );

    final distinctBucketKeys = groups
        .map((g) => g.bucketKey)
        .toSet()
        .toList(growable: false);
    final useBuckets = distinctBucketKeys.length >= 2;

    String? lastBucketKey;
    var isCurrentBucketCollapsed = false;
    for (final group in groups) {
      final bucketKey = group.bucketKey;
      if (useBuckets && bucketKey != lastBucketKey) {
        isCurrentBucketCollapsed = _collapsedBuckets[bucketKey] ?? false;
        rows.add(
          BucketHeaderRowUiModel(
            rowKey: RowKey.v1(
              screen: 'scheduled',
              rowType: 'bucket',
              params: <String, String>{'bucket': bucketKey},
            ),
            depth: 0,
            bucketKey: bucketKey,
            title: _bucketTitle(bucketKey),
            isCollapsed: isCurrentBucketCollapsed,
          ),
        );
        lastBucketKey = bucketKey;
      }

      if (useBuckets && isCurrentBucketCollapsed) continue;

      rows.add(
        DateHeaderRowUiModel(
          rowKey: RowKey.v1(
            screen: 'scheduled',
            rowType: 'date_header',
            params: <String, String>{
              'date': _dateKey(group.date),
              if (useBuckets) 'bucket': bucketKey,
            },
          ),
          depth: 1,
          date: group.date,
          title: group.formattedHeader,
        ),
      );

      if (group.isEmpty) {
        rows.add(
          EmptyDayRowUiModel(
            rowKey: RowKey.v1(
              screen: 'scheduled',
              rowType: 'empty_day',
              params: <String, String>{
                'date': _dateKey(group.date),
                if (useBuckets) 'bucket': bucketKey,
              },
            ),
            depth: 2,
            date: group.date,
          ),
        );
        continue;
      }

      final itemsSorted = [...group.items]..sort(_compareOccurrences);
      for (final item in itemsSorted) {
        rows.add(
          _itemRow(
            item,
            bucketKey: useBuckets ? bucketKey : null,
            date: group.date,
          ),
        );
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
          'bucket': ?bucketKey,
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

    // Tasks before projects.
    if (a.ref.entityType != b.ref.entityType) {
      return a.ref.entityType == EntityType.task ? -1 : 1;
    }

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
      ScheduledDateTag.starts => 1,
      ScheduledDateTag.ongoing => 2,
    };
  }

  List<_ScheduledDateGroup> _generateDateGroups({
    required Map<DateTime, List<ScheduledOccurrence>> itemsByDate,
    required DateTime today,
    required int nearTermDays,
  }) {
    final groups = <_ScheduledDateGroup>[];

    final normalizedToday = _normalizeDate(today);

    for (var i = 0; i <= nearTermDays; i++) {
      final date = normalizedToday.add(Duration(days: i));
      final items = itemsByDate[_normalizeDate(date)] ?? const [];
      groups.add(
        _ScheduledDateGroup(
          date: date,
          bucketKey: _bucketKeyForDate(date, today: normalizedToday),
          formattedHeader: _formatHeader(date),
          items: items,
          isEmpty: items.isEmpty,
        ),
      );
    }

    final futureDates =
        itemsByDate.keys
            .where((d) => d.isAfter(today.add(Duration(days: nearTermDays))))
            .toList()
          ..sort();

    for (final date in futureDates) {
      groups.add(
        _ScheduledDateGroup(
          date: date,
          bucketKey: _bucketKeyForDate(date, today: normalizedToday),
          formattedHeader: _formatHeader(date),
          items: itemsByDate[date] ?? const [],
          isEmpty: false,
        ),
      );
    }

    return groups;
  }

  String _bucketKeyForDate(DateTime date, {required DateTime today}) {
    // Sunday-start week boundaries (Sunday..Saturday).
    final startOfThisWeek = today.subtract(Duration(days: today.weekday % 7));
    final endOfThisWeek = startOfThisWeek.add(const Duration(days: 6));
    final endOfNextWeek = endOfThisWeek.add(const Duration(days: 7));

    final normalizedDate = _normalizeDate(date);
    if (!normalizedDate.isAfter(endOfThisWeek)) return 'this_week';
    if (!normalizedDate.isAfter(endOfNextWeek)) return 'next_week';
    return 'later';
  }

  String _bucketTitle(String bucketKey) {
    return switch (bucketKey) {
      'this_week' => 'This Week',
      'next_week' => 'Next Week',
      'later' => 'Later',
      'overdue' => 'Overdue',
      _ => bucketKey,
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

class _ScheduledDateGroup {
  const _ScheduledDateGroup({
    required this.date,
    required this.bucketKey,
    required this.formattedHeader,
    required this.items,
    required this.isEmpty,
  });

  final DateTime date;
  final String bucketKey;
  final String formattedHeader;
  final List<ScheduledOccurrence> items;
  final bool isEmpty;
}
