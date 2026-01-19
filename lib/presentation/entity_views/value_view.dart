import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_bloc/presentation/shared/ui/sparkline_painter.dart';

enum ValueViewVariant {
  standard,

  /// Screenshot-style card variant used on the system “My Values” screen.
  myValuesCardV1,
}

/// The canonical, entity-level value UI entrypoint.
///
/// Per-screen customization should happen by selecting an entity-level
/// variant (added later) rather than by re-implementing field rendering.
class ValueView extends StatelessWidget {
  const ValueView({
    required this.value,
    this.rank,
    this.stats,
    this.onTap,
    this.compact = false,
    this.notRankedMessage,
    this.showDragHandle = false,
    this.titlePrefix,
    this.variant = ValueViewVariant.standard,
    super.key,
  });

  /// Creates a compact version for settings/ranking contexts.
  const ValueView.compact({
    required this.value,
    this.rank,
    this.stats,
    this.onTap,
    this.notRankedMessage,
    this.showDragHandle = false,
    this.titlePrefix,
    super.key,
  }) : compact = true,
       variant = ValueViewVariant.standard;

  final Value value;

  /// Statistics for the value. Optional in compact mode to show "not ranked".
  final ValueStats? stats;

  /// Rank of this value (optional since ranking feature was removed).
  final int? rank;

  /// Tap callback. If null, card is not tappable.
  final VoidCallback? onTap;

  /// Whether to use compact layout (no sparkline, inline stats).
  final bool compact;

  /// Message to show when stats is null (e.g., "Not ranked - drag to rank").
  final String? notRankedMessage;

  /// Whether to show a drag handle for reordering.
  /// Only set to true when inside a ReorderableListView.
  final bool showDragHandle;

  /// Optional widget shown inline before the title.
  ///
  /// Used for per-screen chrome (e.g. small tags/badges) without forking the
  /// core entity view.
  final Widget? titlePrefix;

  /// Which full-card layout to render.
  ///
  /// This is ignored when [compact] is true.
  final ValueViewVariant variant;

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact(context);

    return switch (variant) {
      ValueViewVariant.standard => _buildFull(context),
      ValueViewVariant.myValuesCardV1 => _buildMyValuesCardV1(context),
    };
  }

  Widget _buildMyValuesCardV1(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    final valueColor = ColorUtils.fromHexWithThemeFallback(
      context,
      value.color,
    );

    final iconName = value.iconName;
    final iconData = getIconDataFromName(iconName) ?? Icons.star;

    final stats = this.stats;
    final primaryLabel = stats == null
        ? null
        : l10n.valueActivityCounts(
            stats.primaryTaskCount,
            stats.primaryProjectCount,
          );
    final secondaryLabel = stats == null
        ? null
        : l10n.valueActivityCounts(
            stats.secondaryTaskCount,
            stats.secondaryProjectCount,
          );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.6),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ValueIconAvatar(
                icon: iconData,
                color: valueColor,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (titlePrefix != null) ...[
                          titlePrefix!,
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            value.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (stats == null)
                      Text(
                        l10n.loadingTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    else ...[
                      _MyValuesCountRow(
                        label: 'Primary',
                        value: primaryLabel ?? '',
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 6),
                      _MyValuesCountRow(
                        label: 'Secondary',
                        value: secondaryLabel ?? '',
                        colorScheme: colorScheme,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
              _buildHeader(context, theme, colorScheme),
              const SizedBox(height: 12),
              if (valueStats != null) ...[
                _StatsRow(stats: valueStats, colorScheme: colorScheme),
                const SizedBox(height: 8),
                _SparklineWithSpacing(
                  data: valueStats.weeklyTrend,
                  colorScheme: colorScheme,
                ),
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

    final indicatorColor = valueColor.withOpacity(0.9);

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
              Row(
                children: [
                  if (showDragHandle && rank != null)
                    ReorderableDragStartListener(
                      index: rank! - 1,
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
                  if (titlePrefix != null) ...[
                    titlePrefix!,
                    const SizedBox(width: 6),
                  ],
                  if (rank != null) ...[
                    Text(
                      '$rank.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: indicatorColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final valueColor = ColorUtils.fromHexWithThemeFallback(
      context,
      value.color,
    );
    final iconData = getIconDataFromName(value.iconName) ?? Icons.star;

    return Row(
      children: [
        if (showDragHandle && rank != null)
          ReorderableDragStartListener(
            index: rank! - 1,
            child: Icon(
              Icons.drag_handle,
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else
          _ValueIconAvatar(
            icon: iconData,
            color: valueColor,
            size: 32,
          ),
        const SizedBox(width: 8),
        if (rank != null) ...[
          Text(
            '$rank.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (showDragHandle && rank != null) ...[
          _ValueIconAvatar(
            icon: iconData,
            color: valueColor,
            size: 32,
          ),
          const SizedBox(width: 10),
        ] else
          const SizedBox(width: 2),
        if (titlePrefix != null) ...[
          titlePrefix!,
          const SizedBox(width: 6),
        ],
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

class _ValueIconAvatar extends StatelessWidget {
  const _ValueIconAvatar({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.52,
      ),
    );
  }
}

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

class _MyValuesCountRow extends StatelessWidget {
  const _MyValuesCountRow({
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
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

class _SparklineWithSpacing extends StatelessWidget {
  const _SparklineWithSpacing({
    required this.data,
    required this.colorScheme,
  });

  final List<double> data;
  final ColorScheme colorScheme;

  bool get hasData => data.isNotEmpty && data.any((v) => v > 0);

  @override
  Widget build(BuildContext context) {
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

  bool get hasData => data.isNotEmpty && data.any((v) => v > 0);

  @override
  Widget build(BuildContext context) {
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
