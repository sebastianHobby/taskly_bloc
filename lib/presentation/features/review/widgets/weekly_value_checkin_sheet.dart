import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/features/review/bloc/weekly_review_cubit.dart';
import 'package:taskly_bloc/presentation/features/review/widgets/weekly_rating_details_sheet.dart';
import 'package:taskly_bloc/presentation/features/review/widgets/weekly_rating_radar.dart';
import 'package:taskly_bloc/presentation/features/review/widgets/weekly_rating_wheel.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

Future<void> showWeeklyValueCheckInSheet(
  BuildContext context, {
  required String? initialValueId,
  required int windowWeeks,
  required bool useRatingWheel,
}) {
  final reviewBloc = context.read<WeeklyReviewBloc>();
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => BlocProvider.value(
        value: reviewBloc,
        child: WeeklyValueCheckInSheet(
          initialValueId: initialValueId,
          windowWeeks: windowWeeks,
          useRatingWheel: useRatingWheel,
        ),
      ),
    ),
  );
}

class WeeklyValueCheckInSheet extends StatelessWidget {
  const WeeklyValueCheckInSheet({
    required this.initialValueId,
    required this.windowWeeks,
    required this.useRatingWheel,
    super.key,
    this.onChartToggle,
  });

  final String? initialValueId;
  final int windowWeeks;
  final bool useRatingWheel;
  final ValueChanged<bool>? onChartToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: WeeklyValueCheckInContent(
        initialValueId: initialValueId,
        windowWeeks: windowWeeks,
        useRatingWheel: useRatingWheel,
        onChartToggle: onChartToggle,
        onExit: () => Navigator.of(context).maybePop(),
        onComplete: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

class WeeklyValueCheckInContent extends StatefulWidget {
  const WeeklyValueCheckInContent({
    required this.initialValueId,
    required this.windowWeeks,
    required this.useRatingWheel,
    required this.onExit,
    required this.onComplete,
    super.key,
    this.onChartToggle,
  });

  final String? initialValueId;
  final int windowWeeks;
  final bool useRatingWheel;
  final ValueChanged<bool>? onChartToggle;
  final VoidCallback onExit;
  final VoidCallback onComplete;

  @override
  State<WeeklyValueCheckInContent> createState() =>
      _WeeklyValueCheckInContentState();
}

class _WeeklyValueCheckInContentState extends State<WeeklyValueCheckInContent> {
  final Map<String, int> _draftRatings = <String, int>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialId = widget.initialValueId;
      if (initialId == null) return;
      context.read<WeeklyReviewBloc>().add(
        WeeklyReviewValueSelected(initialId),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: BlocBuilder<WeeklyReviewBloc, WeeklyReviewState>(
        builder: (context, state) {
          final summary = state.ratingsSummary;
          if (summary == null || summary.entries.isEmpty) {
            return Padding(
              padding: EdgeInsets.all(tokens.spaceLg),
              child: Center(
                child: Text(
                  'No values available for check-in.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            );
          }

          final entries = summary.entries;
          final selected = summary.selectedEntry ?? entries.first;
          final selectedIndex = entries.indexWhere(
            (entry) => entry.value.id == selected.value.id,
          );
          final stepIndex = selectedIndex < 0 ? 0 : selectedIndex;
          final isFirst = stepIndex == 0;
          final isLast = stepIndex == entries.length - 1;
          final rating =
              _draftRatings[selected.value.id] ?? selected.rating;
          final maxRating = summary.maxRating;
          final trend = _ratingTrendPercent(
            selected,
            summary.weekStartUtc,
          );

          final accent = ColorUtils.valueColorForTheme(
            context,
            selected.value.color,
          );
          final iconData =
              getIconDataFromName(selected.value.iconName) ?? Icons.star;

          return LayoutBuilder(
            builder: (context, constraints) {
              final useRatingWheel = widget.useRatingWheel;
              final availableHeight =
                  constraints.maxHeight - tokens.spaceLg * 2;
              final baseSize = math.min(
                constraints.maxWidth,
                availableHeight * 0.45,
              );
              final extraHeight = useRatingWheel ? tokens.spaceLg2 * 2 : 0.0;
              final chartBoxHeight = baseSize + extraHeight;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  tokens.spaceLg,
                  tokens.spaceSm,
                  tokens.spaceLg,
                  tokens.spaceLg,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - tokens.spaceLg * 2,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TopControlsRow(
                          onBack: () {
                            if (isFirst) {
                              widget.onExit();
                              return;
                            }
                            final previous = entries[stepIndex - 1];
                            context.read<WeeklyReviewBloc>().add(
                              WeeklyReviewValueSelected(previous.value.id),
                            );
                          },
                          onHistory: () => showWeeklyRatingDetailsSheet(
                            context,
                            entry: selected,
                            windowWeeks: widget.windowWeeks,
                          ),
                        ),
                        SizedBox(height: tokens.spaceSm),
                        Text(
                          'Step ${stepIndex + 1} of ${entries.length}: '
                          '${selected.value.name}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: tokens.spaceXs),
                        Text(
                          'Use the slider to rate your alignment with each '
                          'value from 1 to 10.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        if (widget.onChartToggle != null) ...[
                          SizedBox(height: tokens.spaceSm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                useRatingWheel ? 'Wheel' : 'Radar',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              SizedBox(width: tokens.spaceXs),
                              Switch(
                                value: useRatingWheel,
                                onChanged: widget.onChartToggle,
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: tokens.spaceLg),
                        SizedBox(
                          height: chartBoxHeight,
                          child: Center(
                            child: SizedBox(
                              width: baseSize,
                              height: baseSize,
                              child: useRatingWheel
                                  ? WeeklyRatingWheel(
                                      entries: entries,
                                      maxRating: maxRating,
                                      selectedValueId: selected.value.id,
                                      onValueSelected: (valueId) => context
                                          .read<WeeklyReviewBloc>()
                                          .add(
                                            WeeklyReviewValueSelected(
                                              valueId,
                                            ),
                                          ),
                                      onRatingChanged: (valueId, rating) =>
                                          context.read<WeeklyReviewBloc>().add(
                                            WeeklyReviewValueRatingChanged(
                                              valueId: valueId,
                                              rating: rating,
                                            ),
                                          ),
                                    )
                                  : WeeklyRatingRadar(
                                      entries: entries,
                                      maxRating: maxRating,
                                      selectedValueId: selected.value.id,
                                      showIcons: true,
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(height: tokens.spaceLg),
                        _ValueSummaryCard(
                          valueName: selected.value.name,
                          iconData: iconData,
                          accent: accent,
                          rating: rating,
                          maxRating: maxRating,
                        ),
                        SizedBox(height: tokens.spaceSm),
                        _StatsRow(
                          taskCount: selected.taskCompletions,
                          routineCount: selected.routineCompletions,
                          trendPercent: trend,
                        ),
                        SizedBox(height: tokens.spaceSm),
                        _RatingSlider(
                          rating: rating,
                          maxRating: maxRating,
                          accent: accent,
                          onChanged: (value) => setState(() {
                            _draftRatings[selected.value.id] = value;
                          }),
                          onCommit: (value) {
                            context.read<WeeklyReviewBloc>().add(
                              WeeklyReviewValueRatingChanged(
                                valueId: selected.value.id,
                                rating: value,
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        SizedBox(height: tokens.spaceLg),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: rating <= 0
                                ? null
                                : () {
                                    if (rating != selected.rating) {
                                      context.read<WeeklyReviewBloc>().add(
                                        WeeklyReviewValueRatingChanged(
                                          valueId: selected.value.id,
                                          rating: rating,
                                        ),
                                      );
                                    }
                                    if (isLast) {
                                      widget.onComplete();
                                      return;
                                    }
                                    final next = entries[stepIndex + 1];
                                    context.read<WeeklyReviewBloc>().add(
                                      WeeklyReviewValueSelected(next.value.id),
                                    );
                                  },
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: tokens.spaceMd2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  tokens.radiusXxl,
                                ),
                              ),
                              backgroundColor: scheme.onSurface,
                              foregroundColor: scheme.surface,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isLast)
                                  const Icon(Icons.check_circle)
                                else
                                  const Icon(Icons.arrow_forward),
                                SizedBox(width: tokens.spaceSm),
                                Text(
                                  isLast
                                      ? 'Complete Check-in'
                                      : 'Next Value',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TopControlsRow extends StatelessWidget {
  const _TopControlsRow({
    required this.onBack,
    required this.onHistory,
  });

  final VoidCallback onBack;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        TextButton(
          onPressed: onBack,
          child: const Text('Back'),
        ),
        const Spacer(),
        Container(
          width: tokens.iconButtonMinSize,
          height: tokens.iconButtonMinSize,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            tooltip: 'History',
            onPressed: onHistory,
            icon: const Icon(Icons.info_outline, size: 18),
          ),
        ),
      ],
    );
  }
}

class _ValueSummaryCard extends StatelessWidget {
  const _ValueSummaryCard({
    required this.valueName,
    required this.iconData,
    required this.accent,
    required this.rating,
    required this.maxRating,
  });

  final String valueName;
  final IconData iconData;
  final Color accent;
  final int rating;
  final int maxRating;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ratingLabel = rating > 0 ? rating.toString() : '--';

    return Container(
      padding: EdgeInsets.all(tokens.spaceMd2),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusXxl),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: tokens.spaceLg,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(tokens.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.3),
                  blurRadius: tokens.spaceSm,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(iconData, color: scheme.surface),
          ),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Value',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: tokens.spaceXxs),
                Text(
                  valueName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          RichText(
            text: TextSpan(
              text: ratingLabel,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
              children: [
                TextSpan(
                  text: '/$maxRating',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.taskCount,
    required this.routineCount,
    required this.trendPercent,
  });

  final int taskCount;
  final int routineCount;
  final double? trendPercent;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    Color trendColor;
    IconData trendIcon;
    if (trendPercent == null) {
      trendColor = scheme.onSurfaceVariant;
      trendIcon = Icons.trending_flat;
    } else if (trendPercent! >= 0) {
      trendColor = scheme.tertiary;
      trendIcon = Icons.trending_up;
    } else {
      trendColor = scheme.error;
      trendIcon = Icons.trending_down;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMd,
        vertical: tokens.spaceSm,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatColumn(
            label: 'Tasks',
            value: taskCount.toString(),
          ),
          _DividerLine(),
          _StatColumn(
            label: 'Routines',
            value: routineCount.toString(),
          ),
          _DividerLine(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Trend',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: tokens.spaceXxs),
              Row(
                children: [
                  Icon(trendIcon, size: tokens.spaceSm2, color: trendColor),
                  SizedBox(width: tokens.spaceXxs),
                  Text(
                    trendPercent == null
                        ? '--'
                        : '${trendPercent!.abs().round()}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: trendColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 1,
      height: 32,
      color: scheme.outlineVariant.withValues(alpha: 0.6),
    );
  }
}

class _RatingSlider extends StatelessWidget {
  const _RatingSlider({
    required this.rating,
    required this.maxRating,
    required this.accent,
    required this.onChanged,
    required this.onCommit,
  });

  final int rating;
  final int maxRating;
  final Color accent;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onCommit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);
    final clamped = rating <= 0 ? 1 : rating;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Rate your alignment',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            thumbColor: accent,
            overlayColor: accent.withValues(alpha: 0.15),
            inactiveTrackColor: scheme.surfaceContainerHighest,
            trackHeight: 4,
          ),
          child: Slider(
            value: clamped.toDouble(),
            min: 1,
            max: maxRating.toDouble(),
            divisions: maxRating - 1,
            onChanged: (value) => onChanged(value.round()),
            onChangeEnd: (value) => onCommit(value.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Low',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'High',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

int? _previousRating(
  WeeklyReviewRatingEntry entry,
  DateTime weekStartUtc,
) {
  for (final rating in entry.history) {
    if (!dateOnly(
      rating.weekStartUtc,
    ).isAtSameMomentAs(dateOnly(weekStartUtc))) {
      return rating.rating;
    }
  }
  return null;
}

double? _ratingTrendPercent(
  WeeklyReviewRatingEntry entry,
  DateTime weekStartUtc,
) {
  if (entry.rating <= 0) return null;
  final previous = _previousRating(entry, weekStartUtc);
  if (previous == null || previous <= 0) return null;
  return (entry.rating - previous) / previous * 100;
}
