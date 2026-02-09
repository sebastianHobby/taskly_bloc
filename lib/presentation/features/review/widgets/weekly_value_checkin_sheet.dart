import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/review/bloc/weekly_review_cubit.dart';
import 'package:taskly_bloc/presentation/features/review/widgets/weekly_rating_evidence_sheet.dart';
import 'package:taskly_bloc/presentation/features/review/widgets/weekly_rating_details_sheet.dart';
import 'package:taskly_bloc/presentation/features/review/widgets/weekly_rating_wheel.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

Future<void> showWeeklyValueCheckInSheet(
  BuildContext context, {
  required String? initialValueId,
  required int windowWeeks,
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
        ),
      ),
    ),
  );
}

class WeeklyValueCheckInSheet extends StatelessWidget {
  const WeeklyValueCheckInSheet({
    required this.initialValueId,
    required this.windowWeeks,
    super.key,
  });

  final String? initialValueId;
  final int windowWeeks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: WeeklyValueCheckInContent(
        initialValueId: initialValueId,
        windowWeeks: windowWeeks,
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
    required this.onExit,
    required this.onComplete,
    super.key,
    this.wizardStep,
    this.wizardTotal,
    this.onWizardBack,
  });

  final String? initialValueId;
  final int windowWeeks;
  final VoidCallback onExit;
  final VoidCallback onComplete;
  final int? wizardStep;
  final int? wizardTotal;
  final VoidCallback? onWizardBack;

  @override
  State<WeeklyValueCheckInContent> createState() =>
      _WeeklyValueCheckInContentState();
}

class _WeeklyValueCheckInContentState extends State<WeeklyValueCheckInContent>
    with AutomaticKeepAliveClientMixin {
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
    super.build(context);
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: BlocBuilder<WeeklyReviewBloc, WeeklyReviewState>(
        builder: (context, state) {
          final l10n = context.l10n;
          final summary = state.ratingsSummary;
          if (summary == null || summary.entries.isEmpty) {
            return Padding(
              padding: EdgeInsets.all(tokens.spaceLg),
              child: Center(
                child: Text(
                  l10n.weeklyReviewNoValuesForCheckIn,
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
          final rating = _draftRatings[selected.value.id] ?? selected.rating;
          final maxRating = summary.maxRating;

          final accent = ColorUtils.valueColorForTheme(
            context,
            selected.value.color,
          );
          final iconData =
              getIconDataFromName(selected.value.iconName) ?? Icons.star;
          final wizardStep = widget.wizardStep;
          final wizardTotal = widget.wizardTotal;
          final wizardLabel = wizardStep == null || wizardTotal == null
              ? null
              : l10n.weeklyReviewWizardStepLabel(
                  wizardStep,
                  wizardTotal,
                );

          return Column(
            children: [
              _CheckInTopBar(
                title: l10n.weeklyReviewCheckInTitle,
                wizardLabel: wizardLabel,
                onBack: () {
                  final onWizardBack = widget.onWizardBack;
                  if (onWizardBack != null) {
                    onWizardBack();
                    return;
                  }
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
              Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.spaceLg,
                  tokens.spaceSm,
                  tokens.spaceLg,
                  tokens.spaceXs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.weeklyReviewCheckInPromptTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: tokens.spaceXs),
                    Text(
                      l10n.weeklyReviewCheckInPromptSubtitle(
                        selected.value.name,
                        maxRating,
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wheelSize = math.min(
                      constraints.maxWidth,
                      constraints.maxHeight * 0.42,
                    );

                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        tokens.spaceLg,
                        0,
                        tokens.spaceLg,
                        tokens.spaceSm,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: wheelSize,
                            height: wheelSize,
                            child: WeeklyRatingWheel(
                              entries: entries,
                              maxRating: maxRating,
                              selectedValueId: selected.value.id,
                              enableTap: true,
                              onValueSelected: (valueId) => context
                                  .read<WeeklyReviewBloc>()
                                  .add(WeeklyReviewValueSelected(valueId)),
                              onRatingChanged: (valueId, rating) =>
                                  context.read<WeeklyReviewBloc>().add(
                                        WeeklyReviewValueRatingChanged(
                                          valueId: valueId,
                                          rating: rating,
                                        ),
                                      ),
                            ),
                          ),
                          SizedBox(height: tokens.spaceSm),
                          _ValueSummaryCard(
                            valueName: selected.value.name,
                            iconData: iconData,
                            accent: accent,
                            rating: rating,
                            maxRating: maxRating,
                            onRatingChanged: (value) => setState(() {
                              _draftRatings[selected.value.id] = value;
                            }),
                            onRatingCommit: (value) {
                              context.read<WeeklyReviewBloc>().add(
                                    WeeklyReviewValueRatingChanged(
                                      valueId: selected.value.id,
                                      rating: value,
                                    ),
                                  );
                            },
                          ),
                          SizedBox(height: tokens.spaceSm),
                          _ActivityMixPanel(
                            entries: entries,
                            entry: selected,
                            accent: accent,
                            onViewAll: () => showWeeklyRatingEvidenceSheet(
                              context,
                              entry: selected,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _RatingActionsBar(
                isLast: isLast,
                onNext: rating <= 0
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
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _CheckInTopBar extends StatelessWidget {
  const _CheckInTopBar({
    required this.title,
    required this.onBack,
    required this.onHistory,
    this.wizardLabel,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onHistory;
  final String? wizardLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceSm,
        tokens.spaceLg,
        tokens.spaceSm,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: onBack,
            child: Text(context.l10n.backLabel),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (wizardLabel != null)
                  Text(
                    wizardLabel!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: tokens.iconButtonMinSize,
            height: tokens.iconButtonMinSize,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: context.l10n.historyLabel,
              onPressed: onHistory,
              icon: const Icon(Icons.info_outline, size: 18),
            ),
          ),
        ],
      ),
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
    required this.onRatingChanged,
    required this.onRatingCommit,
  });

  final String valueName;
  final IconData iconData;
  final Color accent;
  final int rating;
  final int maxRating;
  final ValueChanged<int> onRatingChanged;
  final ValueChanged<int> onRatingCommit;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final ratingLabel = rating > 0
        ? rating.toString()
        : context.l10n.notAvailableShortLabel;

    return Container(
      padding: EdgeInsets.all(tokens.spaceMd2),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusXxl),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: tokens.spaceLg,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
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
                      context.l10n.weeklyReviewSelectedValueLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
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
          SizedBox(height: tokens.spaceSm),
          _RatingSlider(
            rating: rating,
            maxRating: maxRating,
            accent: accent,
            onChanged: onRatingChanged,
            onCommit: onRatingCommit,
          ),
        ],
      ),
    );
  }
}

class _ActivityMixPanel extends StatelessWidget {
  const _ActivityMixPanel({
    required this.entries,
    required this.entry,
    required this.accent,
    required this.onViewAll,
  });

  final List<WeeklyReviewRatingEntry> entries;
  final WeeklyReviewRatingEntry entry;
  final Color accent;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final selectedTasks = entry.taskCompletions;
    final selectedRoutines = entry.routineCompletions;
    final selectedTotal = selectedTasks + selectedRoutines;

    var otherTasks = 0;
    var otherRoutines = 0;
    var otherCount = 0;
    for (final other in entries) {
      if (other.value.id == entry.value.id) continue;
      otherTasks += other.taskCompletions;
      otherRoutines += other.routineCompletions;
      otherCount += 1;
    }
    final avgTasks = otherCount == 0 ? 0.0 : otherTasks / otherCount.toDouble();
    final avgRoutines = otherCount == 0
        ? 0.0
        : otherRoutines / otherCount.toDouble();
    final avgTotal = avgTasks + avgRoutines;

    final insight = selectedTotal == 0 && avgTotal == 0
        ? l10n.weeklyReviewActivityMixInsightSame(entry.value.name)
        : selectedTotal > avgTotal
        ? l10n.weeklyReviewActivityMixInsightMore(entry.value.name)
        : selectedTotal < avgTotal
        ? l10n.weeklyReviewActivityMixInsightLess(entry.value.name)
        : l10n.weeklyReviewActivityMixInsightSame(entry.value.name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.weeklyReviewActivityMixTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onViewAll,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text(l10n.weeklyReviewActivityMixViewDetails),
              style: TextButton.styleFrom(
                foregroundColor: accent,
                padding: EdgeInsets.symmetric(horizontal: tokens.spaceSm),
                textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceSm,
                vertical: tokens.spaceXxs,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(tokens.radiusPill),
              ),
              child: Text(
                l10n.weeklyReviewActivityMixWeeklyLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        _ActivityMixBar(
          label: l10n.weeklyReviewActivityMixValueThisWeekLabel(
            entry.value.name,
          ),
          totalLabel: l10n.weeklyReviewActivityMixTotalLabel(
            selectedTotal.toString(),
          ),
          taskCount: selectedTasks.toDouble(),
          routineCount: selectedRoutines.toDouble(),
          accent: accent,
          background: scheme.surfaceContainerHighest,
          isMuted: false,
        ),
        SizedBox(height: tokens.spaceSm),
        _ActivityMixBar(
          label: l10n.weeklyReviewActivityMixAvgOtherValuesLabel,
          totalLabel: l10n.weeklyReviewActivityMixTotalLabel(
            _formatCount(avgTotal),
          ),
          taskCount: avgTasks,
          routineCount: avgRoutines,
          accent: scheme.onSurfaceVariant,
          background: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          isMuted: true,
        ),
        SizedBox(height: tokens.spaceSm),
        Text(
          insight,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatCount(double value) {
    if (value == 0) return '0';
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class _ActivityMixBar extends StatelessWidget {
  const _ActivityMixBar({
    required this.label,
    required this.totalLabel,
    required this.taskCount,
    required this.routineCount,
    required this.accent,
    required this.background,
    required this.isMuted,
  });

  final String label;
  final String totalLabel;
  final double taskCount;
  final double routineCount;
  final Color accent;
  final Color background;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final total = taskCount + routineCount;
    final taskFlex = _segmentFlex(taskCount, total);
    final routineFlex = _segmentFlex(routineCount, total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isMuted ? scheme.onSurfaceVariant : accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              totalLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceXxs),
        Container(
          height: 28,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(tokens.radiusLg),
          ),
          clipBehavior: Clip.hardEdge,
          child: total <= 0
              ? const SizedBox.shrink()
              : Row(
                  children: [
                    if (taskFlex > 0)
                      Expanded(
                        flex: taskFlex,
                        child: _ActivityMixSegment(
                          icon: Icons.check_circle,
                          value: taskCount,
                          color: isMuted
                              ? scheme.onSurfaceVariant.withValues(alpha: 0.5)
                              : accent,
                          foreground: scheme.surface,
                        ),
                      ),
                    if (routineFlex > 0)
                      Expanded(
                        flex: routineFlex,
                        child: _ActivityMixSegment(
                          icon: Icons.update,
                          value: routineCount,
                          color: isMuted
                              ? scheme.onSurfaceVariant.withValues(alpha: 0.3)
                              : accent.withValues(alpha: 0.35),
                          foreground: isMuted
                              ? scheme.onSurfaceVariant
                              : accent.withValues(alpha: 0.9),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  int _segmentFlex(double value, double total) {
    if (total <= 0 || value <= 0) return 0;
    return math.max(1, (value / total * 100).round());
  }
}

class _ActivityMixSegment extends StatelessWidget {
  const _ActivityMixSegment({
    required this.icon,
    required this.value,
    required this.color,
    required this.foreground,
  });

  final IconData icon;
  final double value;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final label = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);

    return ColoredBox(
      color: color,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: tokens.spaceSm, color: foreground),
              SizedBox(width: tokens.spaceXxs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
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

    final midLabel = (maxRating / 2).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.weeklyReviewRateAlignmentLabel,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              midLabel.toString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              maxRating.toString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accent,
            thumbColor: accent,
            overlayColor: accent.withValues(alpha: 0.15),
            inactiveTrackColor: scheme.surfaceContainerHighest,
            trackHeight: 6,
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
      ],
    );
  }
}

class _RatingActionsBar extends StatelessWidget {
  const _RatingActionsBar({
    required this.isLast,
    required this.onNext,
  });

  final bool isLast;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceSm,
        tokens.spaceLg,
        tokens.spaceLg,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton(
            onPressed: onNext,
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
                      ? l10n.weeklyReviewCompleteCheckInAction
                      : l10n.weeklyReviewNextValueAction,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
