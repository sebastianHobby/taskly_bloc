import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/review/bloc/weekly_review_cubit.dart';
import 'package:taskly_bloc/presentation/shared/ui/sparkline_painter.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

Future<void> showWeeklyRatingDetailsSheet(
  BuildContext context, {
  required WeeklyReviewRatingEntry entry,
  required int windowWeeks,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return WeeklyRatingDetailsSheet(
        entry: entry,
        windowWeeks: windowWeeks,
      );
    },
  );
}

class WeeklyRatingDetailsSheet extends StatelessWidget {
  const WeeklyRatingDetailsSheet({
    required this.entry,
    required this.windowWeeks,
    super.key,
  });

  final WeeklyReviewRatingEntry entry;
  final int windowWeeks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);
    final localization = MaterialLocalizations.of(context);
    final accent = ColorUtils.valueColorForTheme(
      context,
      entry.value.color,
    );

    final history = entry.history;
    final iconData = getIconDataFromName(entry.value.iconName) ?? Icons.star;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceSm,
        tokens.spaceLg,
        tokens.spaceXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, color: accent),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: Text(
                  entry.value.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceSm),
          Text(
            entry.lastRating == null
                ? 'No ratings yet'
                : 'Last rating ${entry.lastRating} '
                      '(${entry.weeksSinceLastRating ?? 0} '
                      'week${(entry.weeksSinceLastRating ?? 0) == 1 ? '' : 's'} ago)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.spaceMd),
          Text(
            'Last $windowWeeks weeks',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.spaceXs2),
          Row(
            children: [
              _StatPill(
                label: 'Tasks',
                value: entry.taskCompletions.toString(),
              ),
              SizedBox(width: tokens.spaceSm),
              _StatPill(
                label: 'Routines',
                value: entry.routineCompletions.toString(),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceMd),
          Text(
            '$windowWeeks-week trend',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.spaceXs2),
          SizedBox(
            height: 40,
            child: history.isEmpty || entry.trend.isEmpty
                ? Text(
                    'No trend data yet',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                : CustomPaint(
                    painter: SparklinePainter(
                      data: entry.trend,
                      color: accent,
                    ),
                    child: const SizedBox.expand(),
                  ),
          ),
          SizedBox(height: tokens.spaceMd),
          Text(
            'Recent ratings',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.spaceXs2),
          if (history.isEmpty)
            Text(
              'No rating history yet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            for (final rating in history)
              Padding(
                padding: EdgeInsets.only(bottom: tokens.spaceXs2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        localization.formatShortDate(
                          rating.weekStartUtc.toLocal(),
                        ),
                      ),
                    ),
                    Text(
                      rating.rating.toString(),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMd,
        vertical: tokens.spaceXs2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.radiusPill),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: tokens.spaceXs2),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
