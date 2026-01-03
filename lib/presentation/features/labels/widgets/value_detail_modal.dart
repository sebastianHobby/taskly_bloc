import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/presentation/features/labels/widgets/enhanced_value_card.dart';

/// Modal showing detailed statistics for a value.
class ValueDetailModal extends StatelessWidget {
  const ValueDetailModal({
    required this.value,
    required this.stats,
    super.key,
  });

  final Label value;
  final ValueStats stats;

  static Future<void> show(
    BuildContext context, {
    required Label value,
    required ValueStats stats,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ValueDetailModal(value: value, stats: stats),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  if (value.color != null)
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(value.color!.replaceFirst('#', '0xFF')),
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    value.name,
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Large trend chart
              _LargeTrendChart(
                data: stats.weeklyTrend,
                weeks: stats.weeklyTrend.length,
              ),
              const SizedBox(height: 24),

              // Stats grid
              _StatsGrid(stats: stats),
              const SizedBox(height: 24),

              // Activity breakdown
              _ActivitySection(stats: stats, l10n: l10n),
            ],
          ),
        );
      },
    );
  }
}

class _LargeTrendChart extends StatelessWidget {
  const _LargeTrendChart({
    required this.data,
    required this.weeks,
  });

  final List<double> data;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.weekTrendTitle(weeks),
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: data.isEmpty || data.every((v) => v == 0)
                ? Center(
                    child: Text(
                      l10n.noTrendData,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : CustomPaint(
                    size: Size.infinite,
                    painter: SparklinePainter(
                      data: data,
                      color: colorScheme.primary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final ValueStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Expanded(
          child: _GridItem(
            label: l10n.targetLabel,
            value: '${stats.targetPercent.toStringAsFixed(0)}%',
          ),
        ),
        Expanded(
          child: _GridItem(
            label: l10n.actualLabel,
            value: '${stats.actualPercent.toStringAsFixed(0)}%',
          ),
        ),
        Expanded(
          child: _GridItem(
            label: l10n.gapLabel,
            value:
                '${stats.gap >= 0 ? '+' : ''}${stats.gap.toStringAsFixed(0)}%',
          ),
        ),
      ],
    );
  }
}

class _GridItem extends StatelessWidget {
  const _GridItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    required this.stats,
    required this.l10n,
  });

  final ValueStats stats;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.activitySectionTitle,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.task_alt),
          title: Text(l10n.activeTasksCount(stats.taskCount)),
          dense: true,
        ),
        ListTile(
          leading: const Icon(Icons.folder),
          title: Text(l10n.projectsCount(stats.projectCount)),
          dense: true,
        ),
      ],
    );
  }
}
