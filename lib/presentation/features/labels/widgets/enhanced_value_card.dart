import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/models/label.dart';

/// Data class for value statistics.
class ValueStats {
  const ValueStats({
    required this.targetPercent,
    required this.actualPercent,
    required this.taskCount,
    required this.projectCount,
    required this.weeklyTrend,
    this.gapWarningThreshold = 15,
  });

  final double targetPercent;
  final double actualPercent;
  final int taskCount;
  final int projectCount;

  /// Weekly completion percentages for sparkline.
  /// Length determined by DisplaySettings.sparklineWeeks.
  final List<double> weeklyTrend;

  /// Gap warning threshold from DisplaySettings.gapWarningThresholdPercent.
  /// Range: 5-50%, Default: 15%
  final int gapWarningThreshold;

  double get gap => actualPercent - targetPercent;
  bool get isSignificantGap => gap.abs() >= gapWarningThreshold;
}

/// Enhanced card showing value with statistics.
class EnhancedValueCard extends StatelessWidget {
  const EnhancedValueCard({
    required this.value,
    required this.stats,
    required this.rank,
    required this.onTap,
    super.key,
  });

  final Label value;
  final ValueStats stats;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with drag handle and rank
              Row(
                children: [
                  ReorderableDragStartListener(
                    index: rank - 1,
                    child: Icon(
                      Icons.drag_handle,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$rank.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (value.color != null)
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(value.color!.replaceFirst('#', '0xFF')),
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      value.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Stats row
              _StatsRow(stats: stats, colorScheme: colorScheme),

              const SizedBox(height: 8),

              // Sparkline
              _Sparkline(data: stats.weeklyTrend, colorScheme: colorScheme),

              const SizedBox(height: 8),

              // Activity counts
              Text(
                l10n.valueActivityCounts(stats.taskCount, stats.projectCount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.stats,
    required this.colorScheme,
  });

  final ValueStats stats;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final gap = stats.gap;
    final gapColor = stats.isSignificantGap
        ? (gap > 0 ? colorScheme.error : colorScheme.tertiary)
        : colorScheme.onSurfaceVariant;

    return Row(
      children: [
        _StatChip(
          label: l10n.targetLabel,
          value: '${stats.targetPercent.toStringAsFixed(0)}%',
          colorScheme: colorScheme,
        ),
        const SizedBox(width: 8),
        _StatChip(
          label: l10n.actualLabel,
          value: '${stats.actualPercent.toStringAsFixed(0)}%',
          colorScheme: colorScheme,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: stats.isSignificantGap
                ? gapColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${gap >= 0 ? '+' : ''}${gap.toStringAsFixed(0)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: gapColor,
                  fontWeight: stats.isSignificantGap
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (stats.isSignificantGap) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: gapColor,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({
    required this.data,
    required this.colorScheme,
  });

  final List<double> data;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.every((v) => v == 0)) {
      return const SizedBox(height: 24);
    }

    return SizedBox(
      height: 24,
      child: CustomPaint(
        size: const Size(double.infinity, 24),
        painter: SparklinePainter(
          data: data,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}

/// Custom painter for sparkline chart.
class SparklinePainter extends CustomPainter {
  SparklinePainter({
    required this.data,
    required this.color,
  });

  final List<double> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal;

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = data.length > 1
          ? i * size.width / (data.length - 1)
          : size.width / 2;
      final normalizedY = range > 0 ? (data[i] - minVal) / range : 0.5;
      final y =
          size.height - (normalizedY * size.height * 0.8 + size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) {
    return data != oldDelegate.data || color != oldDelegate.color;
  }
}
