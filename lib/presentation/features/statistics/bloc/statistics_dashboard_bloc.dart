import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/time.dart';

const int kDefaultStatisticsRangeDays = 90;
const int kGapWarningThresholdPercent = 15;

sealed class StatisticsDashboardEvent {
  const StatisticsDashboardEvent();
}

final class StatisticsDashboardRequested extends StatisticsDashboardEvent {
  const StatisticsDashboardRequested();
}

final class StatisticsDashboardRangeChanged extends StatisticsDashboardEvent {
  const StatisticsDashboardRangeChanged(this.rangeDays);

  final int rangeDays;
}

enum StatisticsSectionStatus { idle, loading, ready, failure }

class StatisticsSection<T> {
  const StatisticsSection({
    required this.status,
    this.data,
    this.error,
  });

  const StatisticsSection.idle() : this(status: StatisticsSectionStatus.idle);
  const StatisticsSection.loading()
    : this(status: StatisticsSectionStatus.loading);

  const StatisticsSection.ready(T data)
    : this(status: StatisticsSectionStatus.ready, data: data);

  const StatisticsSection.failure(Object error)
    : this(status: StatisticsSectionStatus.failure, error: error);

  final StatisticsSectionStatus status;
  final T? data;
  final Object? error;
}

class StatisticsDashboardState {
  const StatisticsDashboardState({
    required this.rangeDays,
    required this.range,
    required this.valuesFocus,
    required this.valueTrends,
    required this.moodStats,
    required this.correlations,
  });

  factory StatisticsDashboardState.initial({
    required int rangeDays,
    required DateRange range,
  }) {
    return StatisticsDashboardState(
      rangeDays: rangeDays,
      range: range,
      valuesFocus: const StatisticsSection.idle(),
      valueTrends: const StatisticsSection.idle(),
      moodStats: const StatisticsSection.idle(),
      correlations: const StatisticsSection.idle(),
    );
  }

  final int rangeDays;
  final DateRange range;
  final StatisticsSection<ValuesFocusData> valuesFocus;
  final StatisticsSection<ValueTrendsData> valueTrends;
  final StatisticsSection<MoodStatsData> moodStats;
  final StatisticsSection<CorrelationData> correlations;

  StatisticsDashboardState copyWith({
    int? rangeDays,
    DateRange? range,
    StatisticsSection<ValuesFocusData>? valuesFocus,
    StatisticsSection<ValueTrendsData>? valueTrends,
    StatisticsSection<MoodStatsData>? moodStats,
    StatisticsSection<CorrelationData>? correlations,
  }) {
    return StatisticsDashboardState(
      rangeDays: rangeDays ?? this.rangeDays,
      range: range ?? this.range,
      valuesFocus: valuesFocus ?? this.valuesFocus,
      valueTrends: valueTrends ?? this.valueTrends,
      moodStats: moodStats ?? this.moodStats,
      correlations: correlations ?? this.correlations,
    );
  }
}

class StatisticsDashboardBloc
    extends Bloc<StatisticsDashboardEvent, StatisticsDashboardState> {
  StatisticsDashboardBloc({
    required AnalyticsService analyticsService,
    required ValueRepositoryContract valueRepository,
    required NowService nowService,
    int defaultRangeDays = kDefaultStatisticsRangeDays,
  }) : _analyticsService = analyticsService,
       _valueRepository = valueRepository,
       _nowService = nowService,
       _defaultRangeDays = defaultRangeDays,
       super(
         StatisticsDashboardState.initial(
           rangeDays: defaultRangeDays,
           range: _buildRange(nowService, defaultRangeDays),
         ),
       ) {
    on<StatisticsDashboardRequested>(_onRequested, transformer: restartable());
    on<StatisticsDashboardRangeChanged>(
      _onRangeChanged,
      transformer: restartable(),
    );
  }

  final AnalyticsService _analyticsService;
  final ValueRepositoryContract _valueRepository;
  final NowService _nowService;
  final int _defaultRangeDays;

  static DateRange _buildRange(NowService nowService, int rangeDays) {
    final safeDays = rangeDays.clamp(7, 365);
    final endDay = dateOnly(nowService.nowLocal());
    final startDay = endDay.subtract(Duration(days: safeDays - 1));
    return DateRange(start: startDay, end: endDay);
  }

  Future<void> _onRequested(
    StatisticsDashboardRequested event,
    Emitter<StatisticsDashboardState> emit,
  ) async {
    await _load(emit, rangeDays: _defaultRangeDays);
  }

  Future<void> _onRangeChanged(
    StatisticsDashboardRangeChanged event,
    Emitter<StatisticsDashboardState> emit,
  ) async {
    await _load(emit, rangeDays: event.rangeDays);
  }

  Future<void> _load(
    Emitter<StatisticsDashboardState> emit, {
    required int rangeDays,
  }) async {
    final range = _buildRange(_nowService, rangeDays);

    emit(
      state.copyWith(
        rangeDays: rangeDays,
        range: range,
        valuesFocus: const StatisticsSection.loading(),
        valueTrends: const StatisticsSection.loading(),
        moodStats: const StatisticsSection.loading(),
        correlations: const StatisticsSection.loading(),
      ),
    );

    final values = await _valueRepository.getAll();

    try {
      final valuesFocus = await _buildValuesFocus(values, rangeDays);
      emit(state.copyWith(valuesFocus: StatisticsSection.ready(valuesFocus)));
    } catch (error) {
      emit(state.copyWith(valuesFocus: StatisticsSection.failure(error)));
    }

    try {
      final trends = await _buildValueTrends(values, rangeDays);
      emit(state.copyWith(valueTrends: StatisticsSection.ready(trends)));
    } catch (error) {
      emit(state.copyWith(valueTrends: StatisticsSection.failure(error)));
    }

    try {
      final moodStats = await _buildMoodStats(range);
      emit(state.copyWith(moodStats: StatisticsSection.ready(moodStats)));
    } catch (error) {
      emit(state.copyWith(moodStats: StatisticsSection.failure(error)));
    }

    try {
      final correlations = await _buildCorrelations(range);
      emit(state.copyWith(correlations: StatisticsSection.ready(correlations)));
    } catch (error) {
      emit(state.copyWith(correlations: StatisticsSection.failure(error)));
    }
  }

  Future<ValuesFocusData> _buildValuesFocus(
    List<Value> values,
    int rangeDays,
  ) async {
    final completionsByValue = await _analyticsService
        .getRecentCompletionsByValue(days: rangeDays);
    final primarySecondary = await _analyticsService
        .getValuePrimarySecondaryStats();

    final totalCompletions = completionsByValue.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );

    final totalWeight = values.fold<int>(
      0,
      (sum, value) => sum + value.priority.weight,
    );

    final items =
        values.map((value) {
          final completionCount = completionsByValue[value.id] ?? 0;
          final actualPercent = totalCompletions == 0
              ? 0.0
              : completionCount / totalCompletions * 100;
          final targetPercent = totalWeight == 0
              ? 0.0
              : value.priority.weight / totalWeight * 100;
          final needsAttention =
              totalCompletions > 0 &&
              (targetPercent - actualPercent) >= kGapWarningThresholdPercent;

          return ValueAlignmentItem(
            value: value,
            completionCount: completionCount,
            completionPercent: actualPercent,
            targetPercent: targetPercent,
            needsAttention: needsAttention,
            primarySecondaryStats: primarySecondary[value.id],
          );
        }).toList()..sort(
          (a, b) => b.completionPercent.compareTo(a.completionPercent),
        );

    final needsAttention = items
        .where((item) => item.needsAttention)
        .toList(growable: false);

    return ValuesFocusData(
      totalCompletions: totalCompletions,
      items: items,
      needsAttention: needsAttention,
      gapWarningThresholdPercent: kGapWarningThresholdPercent,
    );
  }

  Future<ValueTrendsData> _buildValueTrends(
    List<Value> values,
    int rangeDays,
  ) async {
    final weeks = (rangeDays / 7).ceil().clamp(1, 52);
    final trends = await _analyticsService.getValueWeeklyTrends(weeks: weeks);

    final byId = {for (final value in values) value.id: value};

    final items = trends.entries
        .map((entry) {
          final value = byId[entry.key];
          if (value == null) return null;
          return ValueTrendItem(value: value, weeklyPercentages: entry.value);
        })
        .whereType<ValueTrendItem>()
        .toList();

    return ValueTrendsData(weeks: weeks, items: items);
  }

  Future<MoodStatsData> _buildMoodStats(DateRange range) async {
    final trend = await _analyticsService.getMoodTrend(
      range: range,
      granularity: TrendGranularity.weekly,
    );
    final distribution = await _analyticsService.getMoodDistribution(
      range: range,
    );
    final summary = await _analyticsService.getMoodSummary(range: range);

    return MoodStatsData(
      trend: trend,
      distribution: distribution,
      summary: summary,
    );
  }

  Future<CorrelationData> _buildCorrelations(DateRange range) async {
    final correlations = await _analyticsService.getTopMoodCorrelations(
      range: range,
    );
    return CorrelationData(correlations: correlations);
  }
}

class ValueAlignmentItem {
  const ValueAlignmentItem({
    required this.value,
    required this.completionCount,
    required this.completionPercent,
    required this.targetPercent,
    required this.needsAttention,
    this.primarySecondaryStats,
  });

  final Value value;
  final int completionCount;
  final double completionPercent;
  final double targetPercent;
  final bool needsAttention;
  final ValuePrimarySecondaryStats? primarySecondaryStats;
}

class ValuesFocusData {
  const ValuesFocusData({
    required this.totalCompletions,
    required this.items,
    required this.needsAttention,
    required this.gapWarningThresholdPercent,
  });

  final int totalCompletions;
  final List<ValueAlignmentItem> items;
  final List<ValueAlignmentItem> needsAttention;
  final int gapWarningThresholdPercent;
}

class ValueTrendItem {
  const ValueTrendItem({
    required this.value,
    required this.weeklyPercentages,
  });

  final Value value;
  final List<double> weeklyPercentages;
}

class ValueTrendsData {
  const ValueTrendsData({
    required this.weeks,
    required this.items,
  });

  final int weeks;
  final List<ValueTrendItem> items;
}

class MoodStatsData {
  const MoodStatsData({
    required this.trend,
    required this.distribution,
    required this.summary,
  });

  final TrendData trend;
  final Map<int, int> distribution;
  final MoodSummary summary;
}

class CorrelationData {
  const CorrelationData({required this.correlations});

  final List<CorrelationResult> correlations;
}
