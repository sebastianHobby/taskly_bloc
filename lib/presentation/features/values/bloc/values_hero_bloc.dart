import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_bloc/presentation/shared/utils/sort_utils.dart';
import 'package:taskly_core/logging.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/time.dart';

const int kDefaultValuesRangeDays = 90;

sealed class ValuesHeroEvent {
  const ValuesHeroEvent();
}

final class ValuesHeroSubscriptionRequested extends ValuesHeroEvent {
  const ValuesHeroSubscriptionRequested();
}

final class ValuesHeroRangeChanged extends ValuesHeroEvent {
  const ValuesHeroRangeChanged(this.rangeDays);

  final int rangeDays;
}

sealed class ValuesHeroState {
  const ValuesHeroState({
    required this.rangeDays,
    required this.range,
  });

  final int rangeDays;
  final DateRange range;
}

final class ValuesHeroLoading extends ValuesHeroState {
  const ValuesHeroLoading({required super.rangeDays, required super.range});
}

final class ValuesHeroLoaded extends ValuesHeroState {
  const ValuesHeroLoaded({
    required super.rangeDays,
    required super.range,
    required this.items,
  });

  final List<ValueHeroStatsItem> items;
}

final class ValuesHeroError extends ValuesHeroState {
  const ValuesHeroError({
    required super.rangeDays,
    required super.range,
    required this.error,
    this.stackTrace,
  });

  final Object error;
  final StackTrace? stackTrace;
}

class ValueHeroStatsItem {
  const ValueHeroStatsItem({
    required this.value,
    required this.completionCount,
    required this.completionSharePercent,
    required this.activeTaskCount,
    required this.activeProjectCount,
  });

  final Value value;
  final int completionCount;
  final double completionSharePercent;
  final int activeTaskCount;
  final int activeProjectCount;
}

class ValuesHeroBloc extends Bloc<ValuesHeroEvent, ValuesHeroState> {
  ValuesHeroBloc({
    required AnalyticsService analyticsService,
    required ValueRepositoryContract valueRepository,
    required SessionSharedDataService sharedDataService,
    required NowService nowService,
    int defaultRangeDays = kDefaultValuesRangeDays,
  }) : _analyticsService = analyticsService,
       _valueRepository = valueRepository,
       _sharedDataService = sharedDataService,
       _nowService = nowService,
       _rangeDays = defaultRangeDays,
       super(
         ValuesHeroLoading(
           rangeDays: defaultRangeDays,
           range: _buildRange(nowService, defaultRangeDays),
         ),
       ) {
    on<ValuesHeroSubscriptionRequested>(
      _onSubscriptionRequested,
      transformer: restartable(),
    );
    on<ValuesHeroRangeChanged>(_onRangeChanged, transformer: restartable());
  }

  final AnalyticsService _analyticsService;
  final ValueRepositoryContract _valueRepository;
  final SessionSharedDataService _sharedDataService;
  final NowService _nowService;

  int _rangeDays;

  static DateRange _buildRange(NowService nowService, int rangeDays) {
    final safeDays = rangeDays.clamp(7, 365);
    final endDay = dateOnly(nowService.nowLocal());
    final startDay = endDay.subtract(Duration(days: safeDays - 1));
    return DateRange(start: startDay, end: endDay);
  }

  Future<void> _onSubscriptionRequested(
    ValuesHeroSubscriptionRequested event,
    Emitter<ValuesHeroState> emit,
  ) async {
    await _subscribe(emit);
  }

  Future<void> _onRangeChanged(
    ValuesHeroRangeChanged event,
    Emitter<ValuesHeroState> emit,
  ) async {
    _rangeDays = event.rangeDays;
    await _subscribe(emit);
  }

  Future<void> _subscribe(Emitter<ValuesHeroState> emit) async {
    final range = _buildRange(_nowService, _rangeDays);

    emit(ValuesHeroLoading(rangeDays: _rangeDays, range: range));

    try {
      final initialValues = await _valueRepository.getAll();
      if (emit.isDone) return;
      final items = await _buildItems(initialValues, _rangeDays);
      if (emit.isDone) return;
      emit(ValuesHeroLoaded(rangeDays: _rangeDays, range: range, items: items));
    } catch (error, stackTrace) {
      if (emit.isDone) return;
      emit(
        ValuesHeroError(
          rangeDays: _rangeDays,
          range: range,
          error: error,
          stackTrace: stackTrace,
        ),
      );
      return;
    }

    final stream = _sharedDataService.watchValues().switchMap(
      (values) => Stream<ValuesHeroState>.fromFuture(
        () async {
          try {
            final items = await _buildItems(values, _rangeDays);
            return ValuesHeroLoaded(
              rangeDays: _rangeDays,
              range: _buildRange(_nowService, _rangeDays),
              items: items,
            );
          } catch (error, stackTrace) {
            AppLog.warnThrottledStructured(
              'values.hero.load.failed',
              const Duration(seconds: 2),
              'values.hero',
              'analytics build failed',
              fields: <String, Object?>{
                'error': error.toString(),
              },
            );
            return ValuesHeroError(
              rangeDays: _rangeDays,
              range: _buildRange(_nowService, _rangeDays),
              error: error,
              stackTrace: stackTrace,
            );
          }
        }(),
      ),
    );

    await emit.forEach<ValuesHeroState>(
      stream,
      onData: (state) => state,
      onError: (error, stackTrace) => ValuesHeroError(
        rangeDays: _rangeDays,
        range: _buildRange(_nowService, _rangeDays),
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }

  Future<List<ValueHeroStatsItem>> _buildItems(
    List<Value> values,
    int rangeDays,
  ) async {
    final completionsFuture = _analyticsService.getRecentCompletionsByValue(
      days: rangeDays,
    );
    final activityFuture = _analyticsService.getValueActivityStats();

    final completionsByValue = await completionsFuture;
    final activityByValue = await activityFuture;

    final totalCompletions = completionsByValue.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );

    final sorted = [...values];
    sorted.sort((a, b) {
      final byPriority = b.priority.weight.compareTo(a.priority.weight);
      if (byPriority != 0) return byPriority;
      return compareAsciiLowerCase(a.name, b.name);
    });

    return sorted
        .map((value) {
          final completionCount = completionsByValue[value.id] ?? 0;
          final completionSharePercent = totalCompletions == 0
              ? 0.0
              : completionCount / totalCompletions * 100.0;
          final activity = activityByValue[value.id];

          return ValueHeroStatsItem(
            value: value,
            completionCount: completionCount,
            completionSharePercent: completionSharePercent,
            activeTaskCount: activity?.taskCount ?? 0,
            activeProjectCount: activity?.projectCount ?? 0,
          );
        })
        .toList(growable: false);
  }
}
