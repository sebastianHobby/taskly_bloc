import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:taskly_bloc/domain/screens/language/models/agenda_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/agenda_scope.dart';
import 'package:taskly_bloc/domain/screens/runtime/agenda_section_data_service.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/feeds/rows/row_key.dart';
import 'package:taskly_bloc/presentation/features/scheduled/model/scheduled_scope.dart';
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
    required AgendaSectionDataService agendaDataService,
    required HomeDayService homeDayService,
    ScheduledScope scope = const GlobalScheduledScope(),
  }) : _agendaDataService = agendaDataService,
       _homeDayService = homeDayService,
       _scope = scope,
       super(const ScheduledFeedLoading()) {
    on<ScheduledFeedStarted>(_onStarted);
    on<ScheduledFeedRetryRequested>(_onRetryRequested);

    add(const ScheduledFeedStarted());
  }

  final AgendaSectionDataService _agendaDataService;
  final HomeDayService _homeDayService;
  final ScheduledScope _scope;

  StreamSubscription<AgendaData>? _sub;

  Future<void> _onStarted(
    ScheduledFeedStarted event,
    Emitter<ScheduledFeedState> emit,
  ) async {
    await _subscribe(emit);
  }

  Future<void> _onRetryRequested(
    ScheduledFeedRetryRequested event,
    Emitter<ScheduledFeedState> emit,
  ) async {
    emit(const ScheduledFeedLoading());
    await _subscribe(emit);
  }

  Future<void> _subscribe(Emitter<ScheduledFeedState> emit) async {
    await _sub?.cancel();

    final todayDayKeyUtc = _homeDayService.todayDayKeyUtc();
    final rangeStart = todayDayKeyUtc;
    final rangeEnd = todayDayKeyUtc.add(const Duration(days: 30));

    _sub = _agendaDataService
        .watchAgendaData(
          referenceDate: todayDayKeyUtc,
          focusDate: todayDayKeyUtc,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          scope: _toAgendaScope(_scope),
        )
        .listen(
          (agenda) {
            try {
              emit(ScheduledFeedLoaded(rows: _mapToRows(agenda)));
            } catch (e) {
              emit(ScheduledFeedError(message: e.toString()));
            }
          },
          onError: (Object e, StackTrace s) {
            emit(ScheduledFeedError(message: e.toString()));
          },
        );
  }

  AgendaScope? _toAgendaScope(ScheduledScope scope) {
    return switch (scope) {
      GlobalScheduledScope() => null,
      ProjectScheduledScope(:final projectId) => AgendaScope.project(
        projectId: projectId,
      ),
      ValueScheduledScope(:final valueId) => AgendaScope.value(
        valueId: valueId,
      ),
    };
  }

  List<ListRowUiModel> _mapToRows(AgendaData data) {
    final rows = <ListRowUiModel>[];

    if (data.overdueItems.isNotEmpty) {
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

      final overdueSorted = [...data.overdueItems]..sort(_compareAgendaItems);

      for (final item in overdueSorted) {
        rows.add(_itemRow(item, bucket: 'Overdue', date: null));
      }
    }

    String? lastBucket;
    for (final group in data.groups) {
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

      final itemsSorted = [...group.items]..sort(_compareAgendaItems);
      for (final item in itemsSorted) {
        rows.add(_itemRow(item, bucket: bucket, date: group.date));
      }
    }

    return rows;
  }

  AgendaEntityRowUiModel _itemRow(
    AgendaItem item, {
    required String bucket,
    required DateTime? date,
  }) {
    final entityId = item.entityId;
    final tag = item.tag;

    return AgendaEntityRowUiModel(
      rowKey: RowKey.v1(
        screen: 'scheduled',
        rowType: item.isTask ? 'task' : 'project',
        params: <String, String>{
          'id': entityId,
          if (date != null) 'date': _dateKey(date),
          'tag': tag.name,
          'bucket': bucket,
        },
      ),
      depth: 0,
      item: item,
    );
  }

  int _compareAgendaItems(AgendaItem a, AgendaItem b) {
    final aPinned = a.isTask
        ? (a.task?.isPinned ?? false)
        : (a.project?.isPinned ?? false);
    final bPinned = b.isTask
        ? (b.task?.isPinned ?? false)
        : (b.project?.isPinned ?? false);
    if (aPinned != bPinned) return aPinned ? -1 : 1;

    // Tasks before projects.
    if (a.isTask != b.isTask) {
      return a.isTask ? -1 : 1;
    }

    final aTagRank = _tagRank(a.tag);
    final bTagRank = _tagRank(b.tag);
    if (aTagRank != bTagRank) return aTagRank.compareTo(bTagRank);

    final aName = a.name.toLowerCase();
    final bName = b.name.toLowerCase();
    final nameCmp = aName.compareTo(bName);
    if (nameCmp != 0) return nameCmp;

    return a.entityId.compareTo(b.entityId);
  }

  int _tagRank(AgendaDateTag tag) {
    return switch (tag) {
      AgendaDateTag.due => 0,
      AgendaDateTag.starts => 1,
      AgendaDateTag.inProgress => 2,
    };
  }

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
