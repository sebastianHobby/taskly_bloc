import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/domain/models/analytics/date_range.dart';
import 'package:taskly_bloc/presentation/features/analytics/widgets/correlation_card.dart';
import 'package:taskly_bloc/presentation/features/analytics/widgets/trend_chart.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/wellbeing_dashboard/wellbeing_dashboard_bloc.dart';
import 'package:taskly_bloc/presentation/widgets/content_constraint.dart';

class WellbeingDashboardScreen extends StatelessWidget {
  const WellbeingDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wellbeing Dashboard'),
      ),
      body: BlocBuilder<WellbeingDashboardBloc, WellbeingDashboardState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.error!),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<WellbeingDashboardBloc>().add(
                WellbeingDashboardEvent.load(
                  dateRange: DateRange.last30Days(),
                ),
              );
            },
            child: ResponsiveBody(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                Routing.toScreenKey(context, 'journal'),
                            child: const Text('Journal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Routing.toScreenKey(context, 'trackers'),
                            child: const Text('Manage Trackers'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (state.moodTrend != null) ...[
                      Text(
                        'Mood Trend',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TrendChart(data: state.moodTrend!),
                      const SizedBox(height: 32),
                    ],
                    if (state.topCorrelations != null &&
                        state.topCorrelations!.isNotEmpty) ...[
                      Text(
                        'Top Mood Correlations',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ...state.topCorrelations!.map(
                        (correlation) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CorrelationCard(correlation: correlation),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
