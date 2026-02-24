import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/statistics/bloc/debug_stats_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/my_day.dart';

class DebugStatsPage extends StatelessWidget {
  const DebugStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DebugStatsBloc(
        repository: context.read<MyDayDecisionEventRepositoryContract>(),
        nowService: context.read<NowService>(),
      )..add(const DebugStatsStarted()),
      child: const _DebugStatsView(),
    );
  }
}

class _DebugStatsView extends StatelessWidget {
  const _DebugStatsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settingsStatsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<DebugStatsBloc>().add(
              DebugStatsRangeChanged(
                context.read<DebugStatsBloc>().state.range,
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<DebugStatsBloc, DebugStatsState>(
        builder: (context, state) {
          if (state.loading &&
              state.keepRates.isEmpty &&
              state.deferRates.isEmpty &&
              state.topDeferredTasks.isEmpty &&
              state.topDeferredRoutines.isEmpty &&
              state.routineWeekdays.isEmpty &&
              state.lagMetrics.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RangeChips(selected: state.range),
              const SizedBox(height: 16),
              _SectionCard(
                title: context.l10n.statsKeepRateByShelfTitle,
                child: _ShelfRatesView(rates: state.keepRates),
              ),
              _SectionCard(
                title: context.l10n.statsDeferRateByShelfTitle,
                child: _ShelfRatesView(rates: state.deferRates),
              ),
              _SectionCard(
                title: context.l10n.statsTopDeferredTasksTitle,
                child: _EntityCountsView(rows: state.topDeferredTasks),
              ),
              _SectionCard(
                title: context.l10n.statsTopDeferredRoutinesTitle,
                child: _EntityCountsView(rows: state.topDeferredRoutines),
              ),
              _SectionCard(
                title: context.l10n.statsRoutineTopWeekdaysTitle,
                child: _RoutineWeekdayView(rows: state.routineWeekdays),
              ),
              _SectionCard(
                title: context.l10n.statsDeferredToCompletedLagTitle,
                child: _LagMetricsView(rows: state.lagMetrics),
              ),
              if (state.error != null)
                Text(
                  '${context.l10n.statsErrorLabel}: ${state.error}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RangeChips extends StatelessWidget {
  const _RangeChips({required this.selected});

  final DebugStatsRange selected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _chip(context, DebugStatsRange.days7, '7d'),
        _chip(context, DebugStatsRange.days28, '28d'),
        _chip(context, DebugStatsRange.days90, '90d'),
      ],
    );
  }

  Widget _chip(BuildContext context, DebugStatsRange value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (_) => context.read<DebugStatsBloc>().add(
        DebugStatsRangeChanged(value),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _ShelfRatesView extends StatelessWidget {
  const _ShelfRatesView({required this.rates});

  final List<MyDayShelfRate> rates;

  @override
  Widget build(BuildContext context) {
    if (rates.isEmpty) return Text(context.l10n.statsNoDataLabel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rate in rates)
          Text(
            '${_shelfName(rate.shelf)}: ${(rate.rate * 100).toStringAsFixed(1)}% '
            '(${rate.numerator}/${rate.denominator})',
          ),
      ],
    );
  }

  String _shelfName(MyDayDecisionShelf shelf) {
    return switch (shelf) {
      MyDayDecisionShelf.due => 'Due',
      MyDayDecisionShelf.planned => 'Planned',
      MyDayDecisionShelf.routineScheduled => 'Routine scheduled',
      MyDayDecisionShelf.routineFlexible => 'Routine flexible',
      MyDayDecisionShelf.suggestion => 'Suggestion',
    };
  }
}

class _EntityCountsView extends StatelessWidget {
  const _EntityCountsView({required this.rows});

  final List<MyDayEntityDeferCount> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return Text(context.l10n.statsNoDataLabel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows)
          Text(
            '${row.entityId}: defer=${row.deferCount}, snooze=${row.snoozeCount}',
          ),
      ],
    );
  }
}

class _RoutineWeekdayView extends StatelessWidget {
  const _RoutineWeekdayView({required this.rows});

  final List<RoutineWeekdayStat> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return Text(context.l10n.statsNoDataLabel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows)
          Text(
            '${row.routineId}: ${_weekday(row.weekdayLocal)} (${row.count})',
          ),
      ],
    );
  }

  String _weekday(int day) {
    return switch (day) {
      1 => 'Mon',
      2 => 'Tue',
      3 => 'Wed',
      4 => 'Thu',
      5 => 'Fri',
      6 => 'Sat',
      _ => 'Sun',
    };
  }
}

class _LagMetricsView extends StatelessWidget {
  const _LagMetricsView({required this.rows});

  final List<DeferredThenCompletedLagMetric> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return Text(context.l10n.statsNoDataLabel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows)
          Text(
            '${row.entityId}: median=${row.medianLagHours.toStringAsFixed(1)}h, '
            'p75=${row.p75LagHours.toStringAsFixed(1)}h, '
            'within7d=${(row.completedWithin7DaysRate * 100).toStringAsFixed(1)}%, '
            'n=${row.sampleSize}',
          ),
      ],
    );
  }
}
