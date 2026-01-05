import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/models/value.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/emoji_utils.dart';

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
///
/// Supports two display modes:
/// - Full mode (default): Shows stats row, sparkline, and activity counts
/// - Compact mode: Shows inline stats and activity counts, no sparkline
class EnhancedValueCard extends StatelessWidget {
  const EnhancedValueCard({
    required this.value,
    required this.rank,
    this.stats,
    this.onTap,
    this.compact = false,
    this.notRankedMessage,
    this.showDragHandle = false,
    super.key,
  });

  /// Creates a compact version for settings/ranking contexts.
  const EnhancedValueCard.compact({
    required this.value,
    required this.rank,
    this.stats,
    this.onTap,
    this.notRankedMessage,
    this.showDragHandle = false,
    super.key,
  }) : compact = true;

  final Value value;

  /// Statistics for the value. Optional in compact mode to show "not ranked".
  final ValueStats? stats;
  final int rank;

  /// Tap callback. If null, card is not tappable.
  final VoidCallback? onTap;

  /// Whether to use compact layout (no sparkline, inline stats).
  final bool compact;

  /// Message to show when stats is null (e.g., "Not ranked - drag to rank").
  final String? notRankedMessage;

  /// Whether to show a drag handle for reordering.
  /// Only set to true when inside a ReorderableListView.
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompact(context) : _buildFull(context);
  }

  Widget _buildFull(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final valueStats = stats;
    final valueColor = ColorUtils.fromHexWithThemeFallback(
      context,
      value.color,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: valueColor.withOpacity(0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with drag handle and rank
              _buildHeader(theme, colorScheme),
              const SizedBox(height: 12),

              // Stats row
              if (valueStats != null) ...[
                _StatsRow(stats: valueStats, colorScheme: colorScheme),
                const SizedBox(height: 8),

                // Sparkline (only shows when data exists)
                _SparklineWithSpacing(
                  data: valueStats.weeklyTrend,
                  colorScheme: colorScheme,
                ),

                // Activity counts
                Text(
                  l10n.valueActivityCounts(
                    valueStats.taskCount,
                    valueStats.projectCount,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ] else if (notRankedMessage != null)
                Text(
                  notRankedMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final valueStats = stats;
    final valueColor = ColorUtils.fromHexWithThemeFallback(
      context,
      value.color,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      color: valueColor.withOpacity(0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row with inline stats
              Row(
                children: [
                  if (showDragHandle)
                    ReorderableDragStartListener(
                      index: rank - 1,
                      child: Icon(
                        Icons.drag_handle,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    )
                  else
                    Icon(
                      Icons.star_outline,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    '$rank.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    (value.iconName?.isNotEmpty ?? false)
                        ? value.iconName!
                        : '⭐',
                    style: EmojiUtils.emojiTextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      value.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Inline stats on the right
                  if (valueStats != null) ...[
                    _CompactStatChip(
                      label: l10n.targetLabel,
                      value: '${valueStats.targetPercent.toStringAsFixed(0)}%',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 8),
                    _CompactStatChip(
                      label: l10n.actualLabel,
                      value: '${valueStats.actualPercent.toStringAsFixed(0)}%',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 8),
                    _CompactGapIndicator(
                      stats: valueStats,
                      colorScheme: colorScheme,
                    ),
                  ],
                ],
              ),
              // Second row: activity counts or not-ranked message
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 2),
                child: valueStats != null
                    ? Text(
                        l10n.valueActivityCounts(
                          valueStats.taskCount,
                          valueStats.projectCount,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Text(
                        notRankedMessage ?? l10n.notRankedDragToRank,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        if (showDragHandle)
          ReorderableDragStartListener(
            index: rank - 1,
            child: Icon(
              Icons.drag_handle,
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else
          Icon(
            Icons.star_outline,
            color: colorScheme.onSurfaceVariant,
          ),
        const SizedBox(width: 8),
        Text(
          '$rank.',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          (value.iconName?.isNotEmpty ?? false) ? value.iconName! : '⭐',
          style: EmojiUtils.emojiTextStyle(fontSize: 22),
        ),
        const SizedBox(width: 8),
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
    );
  }
}

/// Compact stat chip for inline display.
class _CompactStatChip extends StatelessWidget {
  const _CompactStatChip({
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Compact gap indicator for inline display.
class _CompactGapIndicator extends StatelessWidget {
  const _CompactGapIndicator({
    required this.stats,
    required this.colorScheme,
  });

  final ValueStats stats;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final gap = stats.gap;
    final gapColor = stats.isSignificantGap
        ? (gap > 0 ? colorScheme.error : colorScheme.tertiary)
        : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            style: TextStyle(
              fontSize: 12,
              color: gapColor,
              fontWeight: stats.isSignificantGap
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          if (stats.isSignificantGap) ...[
            const SizedBox(width: 2),
            Icon(Icons.warning_amber, size: 12, color: gapColor),
          ],
        ],
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

/// Sparkline with conditional spacing - hides entirely when no data.
class _SparklineWithSpacing extends StatelessWidget {
  const _SparklineWithSpacing({
    required this.data,
    required this.colorScheme,
  });

  final List<double> data;
  final ColorScheme colorScheme;

  /// Returns true if the data has meaningful values to display.
  bool get hasData => data.isNotEmpty && data.any((v) => v > 0);

  @override
  Widget build(BuildContext context) {
    // Hide sparkline and spacing entirely when there's no data
    if (!hasData) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Sparkline(data: data, colorScheme: colorScheme),
        const SizedBox(height: 8),
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

  /// Returns true if the data has meaningful values to display.
  bool get hasData => data.isNotEmpty && data.any((v) => v > 0);

  @override
  Widget build(BuildContext context) {
    // Hide sparkline entirely when there's no data
    if (!hasData) {
      return const SizedBox.shrink();
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
