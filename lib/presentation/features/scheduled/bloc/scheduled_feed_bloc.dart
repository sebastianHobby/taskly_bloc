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

sealed class ScheduledFeedState {
  const ScheduledFeedState();
}

final class ScheduledFeedLoading extends ScheduledFeedState {
  const ScheduledFeedLoading();
}

final class ScheduledFeedLoaded extends ScheduledFeedState {
  const ScheduledFeedLoaded({required this.rows});

  final List<ListRowUiModel> rows;
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

    add(const ScheduledFeedStarted());
  }

  final ScheduledOccurrencesService _scheduledOccurrencesService;
  final HomeDayService _homeDayService;
  final ScheduledScope _scope;

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
          return ScheduledFeedLoaded(rows: _mapToRows(result));
        } catch (e) {
          return ScheduledFeedError(message: e.toString());
        }
      },
      onError: (error, stackTrace) => ScheduledFeedError(
        message: error.toString(),
      ),
    );
  }

  static const int _nearTermDays = 7;

  List<ListRowUiModel> _mapToRows(ScheduledOccurrencesResult result) {
    final rows = <ListRowUiModel>[];

    if (result.overdue.isNotEmpty) {
      rows.add(
        BucketHeaderRowUiModel(
          rowKey: RowKey.v1(
            screen: 'scheduled',
            rowType: 'bucket',
            params: const <String, String>{'label': 'Overdue'},
          ),
          depth: 0,
          title: 'Overdue',
        ),
      );

      final overdueSorted = [...result.overdue]..sort(_compareOccurrences);

      for (final item in overdueSorted) {
        rows.add(_itemRow(item, bucket: 'Overdue', date: null));
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

    String? lastBucket;
    for (final group in groups) {
      final bucket = group.semanticLabel;
      if (bucket != lastBucket) {
        rows.add(
          BucketHeaderRowUiModel(
            rowKey: RowKey.v1(
              screen: 'scheduled',
              rowType: 'bucket',
              params: <String, String>{
                'label': bucket,
                'start': _dateKey(group.date),
              },
            ),
            depth: 0,
            title: bucket,
          ),
        );
        lastBucket = bucket;
      }

      rows.add(
        DateHeaderRowUiModel(
          rowKey: RowKey.v1(
            screen: 'scheduled',
            rowType: 'date_header',
            params: <String, String>{'date': _dateKey(group.date)},
          ),
          depth: 0,
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
              params: <String, String>{'date': _dateKey(group.date)},
            ),
            depth: 0,
            date: group.date,
          ),
        );
        continue;
      }

      final itemsSorted = [...group.items]..sort(_compareOccurrences);
      for (final item in itemsSorted) {
        rows.add(_itemRow(item, bucket: bucket, date: group.date));
      }
    }

    return rows;
  }

  ScheduledEntityRowUiModel _itemRow(
    ScheduledOccurrence item, {
    required String bucket,
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
          'bucket': bucket,
        },
      ),
      depth: 0,
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

    for (var i = 0; i <= nearTermDays; i++) {
      final date = today.add(Duration(days: i));
      final items = itemsByDate[_normalizeDate(date)] ?? const [];
      groups.add(
        _ScheduledDateGroup(
          date: date,
          semanticLabel: _getSemanticLabel(date, today),
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
          semanticLabel: _getSemanticLabel(date, today),
          formattedHeader: _formatHeader(date),
          items: itemsByDate[date] ?? const [],
          isEmpty: false,
        ),
      );
    }

    return groups;
  }

  String _getSemanticLabel(DateTime date, DateTime today) {
    final diff = _normalizeDate(date).difference(_normalizeDate(today)).inDays;

    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';

    final daysUntilEndOfWeek = 6 - today.weekday; // Saturday = 6
    if (diff <= daysUntilEndOfWeek && daysUntilEndOfWeek >= 0) {
      return 'This Week';
    }

    final daysUntilEndOfNextWeek = daysUntilEndOfWeek + 7;
    if (diff <= daysUntilEndOfNextWeek) return 'Next Week';

    return 'Later';
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
    required this.semanticLabel,
    required this.formattedHeader,
    required this.items,
    required this.isEmpty,
  });

  final DateTime date;
  final String semanticLabel;
  final String formattedHeader;
  final List<ScheduledOccurrence> items;
  final bool isEmpty;
}
