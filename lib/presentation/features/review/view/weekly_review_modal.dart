import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/review/bloc/weekly_review_cubit.dart';
import 'package:taskly_bloc/presentation/features/review/widgets/weekly_rating_wheel.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/ui/sparkline_painter.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/widgets/icon_picker/icon_catalog.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

Future<void> showWeeklyReviewModal(
  BuildContext context, {
  required GlobalSettings settings,
}) {
  final config = WeeklyReviewConfig.fromSettings(settings);
  final parentContext = context;
  final height = MediaQuery.sizeOf(context).height * 0.92;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) {
      return SizedBox(
        height: height,
        child: BlocProvider(
          create: (context) => WeeklyReviewBloc(
            analyticsService: context.read<AnalyticsService>(),
            attentionEngine: context.read<AttentionEngineContract>(),
            valueRepository: context.read<ValueRepositoryContract>(),
            valueRatingsRepository: context
                .read<ValueRatingsRepositoryContract>(),
            valueRatingsWriteService: context.read<ValueRatingsWriteService>(),
            routineRepository: context.read<RoutineRepositoryContract>(),
            settingsRepository: context.read<SettingsRepositoryContract>(),
            taskRepository: context.read<TaskRepositoryContract>(),
            nowService: context.read<NowService>(),
          )..add(WeeklyReviewRequested(config)),
          child: _WeeklyReviewModal(
            config: config,
            parentContext: parentContext,
          ),
        ),
      );
    },
  );
}

class _WeeklyReviewModal extends StatefulWidget {
  const _WeeklyReviewModal({
    required this.config,
    required this.parentContext,
  });

  final WeeklyReviewConfig config;
  final BuildContext parentContext;

  @override
  State<_WeeklyReviewModal> createState() => _WeeklyReviewModalState();
}

class _WeeklyReviewModalState extends State<_WeeklyReviewModal> {
  late final PageController _controller = PageController();
  int _pageIndex = 0;
  bool _ratingsEnabled = false;
  bool _ratingsComplete = true;

  int get _pageCount {
    final base = widget.config.maintenanceEnabled ? 2 : 1;
    return base + 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_ratingsEnabled && !_ratingsComplete && _pageIndex == 0) {
      return;
    }
    if (_pageIndex >= _pageCount - 1) {
      _finishReview();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _finishReview() {
    final nowUtc = context.read<NowService>().nowUtc();
    context.read<GlobalSettingsBloc>().add(
      GlobalSettingsEvent.weeklyReviewCompleted(nowUtc),
    );
    Navigator.of(context).maybePop();
  }

  void _openSettings() {
    Navigator.of(context).maybePop();
    if (!widget.parentContext.mounted) return;
    Routing.toScreenKey(widget.parentContext, 'settings');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<WeeklyReviewBloc, WeeklyReviewState>(
      builder: (context, state) {
        if (state.status == WeeklyReviewStatus.loading) {
          return _ReviewLoading();
        }
        if (state.status == WeeklyReviewStatus.failure) {
          return _ReviewError(
            message: state.errorMessage ?? 'Failed to load review.',
            onRetry: () => context.read<WeeklyReviewBloc>().add(
              WeeklyReviewRequested(widget.config),
            ),
          );
        }

        final ratingsSummary = state.ratingsSummary;
        final ratingsEnabled = ratingsSummary?.ratingsEnabled ?? false;
        final ratingsComplete = ratingsSummary?.isComplete ?? true;

        _ratingsEnabled = ratingsEnabled;
        _ratingsComplete = ratingsComplete;

        final pages = <Widget>[
          if (ratingsEnabled && ratingsSummary != null)
            _RatingsPage(
              config: widget.config,
              summary: ratingsSummary,
            )
          else
            _ValuesSnapshotPage(
              config: widget.config,
              summary: state.valuesSummary,
              wins: state.valueWins,
            ),
          if (widget.config.maintenanceEnabled)
            _MaintenancePage(
              sections: state.maintenanceSections,
            ),
          const _CompletionPage(),
        ];

        final buttonLabel = _pageIndex == _pageCount - 1 ? 'Done' : 'Continue';
        final canContinue =
            !_ratingsEnabled || _ratingsComplete || _pageIndex != 0;

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                TasklyTokens.of(context).spaceLg,
                TasklyTokens.of(context).spaceXs2,
                TasklyTokens.of(context).spaceLg,
                TasklyTokens.of(context).spaceXs2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Weekly Review',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: _openSettings,
                    child: Text(context.l10n.settingsTitle),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                children: pages,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                TasklyTokens.of(context).spaceLg,
                TasklyTokens.of(context).spaceSm,
                TasklyTokens.of(context).spaceLg,
                TasklyTokens.of(context).spaceLg,
              ),
              child: Row(
                children: [
                  if (_pageIndex > 0)
                    TextButton(
                      onPressed: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      ),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: canContinue ? _goNext : null,
                    child: Text(buttonLabel),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ValuesSnapshotPage extends StatelessWidget {
  const _ValuesSnapshotPage({
    required this.config,
    required this.summary,
    required this.wins,
  });

  final WeeklyReviewConfig config;
  final WeeklyReviewValuesSummary? summary;
  final List<WeeklyReviewValueWin> wins;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final hasSummary = summary?.hasData ?? false;
    final insight = hasSummary
        ? 'Most aligned with ${summary?.topValueName}. '
              'Least aligned with ${summary?.bottomValueName}.'
        : 'No completed tasks yet.';

    return ListView(
      padding: EdgeInsets.fromLTRB(
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceXs,
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceXl,
      ),
      children: [
        Text(
          'Values Snapshot',
          style: theme.textTheme.titleLarge,
        ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        Text(
          'How your completed work aligned with what matters.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        if (summary?.hasData ?? false) ...[
          Text(
            'Last ${config.valuesWindowWeeks} weeks',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          _RingsRow(rings: summary?.rings ?? const []),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
        ],
        Text(
          insight,
          style: theme.textTheme.bodyMedium,
        ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        Text(
          'Value Wins',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        Text(
          'Small moments that added up.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        if (wins.isEmpty)
          Text(
            'No value wins yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          ...wins.map(
            (win) => Padding(
              padding: EdgeInsets.only(
                bottom: TasklyTokens.of(context).spaceSm,
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, size: 18),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  Expanded(
                    child: Text(
                      '${win.valueName} - ${win.completionCount} completions',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

enum _CompletionSnapshotMode { tasks, routines }

class _RatingsPage extends StatefulWidget {
  const _RatingsPage({
    required this.config,
    required this.summary,
  });

  final WeeklyReviewConfig config;
  final WeeklyReviewRatingsSummary summary;

  @override
  State<_RatingsPage> createState() => _RatingsPageState();
}

class _RatingsPageState extends State<_RatingsPage> {
  _CompletionSnapshotMode _mode = _CompletionSnapshotMode.tasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    final summary = widget.summary;
    final entries = summary.entries;
    final selected = summary.selectedEntry;
    final ratedCount = summary.ratedCount;
    final totalCount = summary.totalCount;
    final progress = totalCount == 0 ? 0.0 : ratedCount / totalCount;

    final maxWeeksSince = entries
        .map((entry) => entry.weeksSinceLastRating ?? summary.graceWeeks + 1)
        .fold<int>(0, (max, value) => value > max ? value : max);

    final distributionEntries = _buildDistributionEntries(
      context,
      entries,
      _mode == _CompletionSnapshotMode.tasks
          ? (entry) => entry.taskCompletions
          : (entry) => entry.routineCompletions,
    );
    final totalCompletions = distributionEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.count,
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceXs,
        tokens.spaceLg,
        tokens.spaceXl,
      ),
      children: [
        Text(
          'Rate this past week.',
          style: theme.textTheme.titleLarge,
        ),
        SizedBox(height: tokens.spaceSm),
        Text(
          'We blend weekly check-ins over time to keep suggestions steady.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        if (summary.ratingsOverdue)
          _RatingsBanner(
            tone: _RatingsBannerTone.critical,
            title: 'Ratings overdue',
            message: 'Suggestions are paused until you check in.',
          )
        else if (summary.ratingsInGrace && maxWeeksSince > 0)
          _RatingsBanner(
            tone: _RatingsBannerTone.info,
            title: 'Using last ratings',
            message:
                'We are still using ratings from $maxWeeksSince week'
                '${maxWeeksSince == 1 ? '' : 's'} ago.',
          ),
        SizedBox(height: tokens.spaceSm),
        Center(
          child: SizedBox(
            width: 320,
            height: 320,
            child: Stack(
              alignment: Alignment.center,
              children: [
                WeeklyRatingWheel(
                  entries: entries,
                  maxRating: summary.maxRating,
                  selectedValueId: summary.selectedValueId,
                  onValueSelected: (valueId) {
                    context.read<WeeklyReviewBloc>().add(
                      WeeklyReviewValueSelected(valueId),
                    );
                  },
                  onRatingChanged: (valueId, rating) {
                    context.read<WeeklyReviewBloc>().add(
                      WeeklyReviewValueRatingChanged(
                        valueId: valueId,
                        rating: rating,
                      ),
                    );
                  },
                ),
                if (selected != null)
                  _WheelCenterLabel(
                    name: selected.value.name,
                    rating: selected.rating,
                    maxRating: summary.maxRating,
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        Wrap(
          spacing: tokens.spaceXs2,
          runSpacing: tokens.spaceXs2,
          children: [
            for (final entry in entries)
              ChoiceChip(
                label: Text(entry.value.name),
                selected: entry.value.id == summary.selectedValueId,
                selectedColor: ColorUtils.valueColorForTheme(
                  context,
                  entry.value.color,
                ).withOpacity(0.2),
                onSelected: (_) {
                  context.read<WeeklyReviewBloc>().add(
                    WeeklyReviewValueSelected(entry.value.id),
                  );
                },
              ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        Row(
          children: [
            Expanded(
              child: Text(
                '$ratedCount/$totalCount values rated',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: selected == null
                  ? null
                  : () => _openValueDetails(
                      context,
                      entry: selected,
                      windowWeeks: widget.config.valuesWindowWeeks,
                    ),
              child: const Text('Details'),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceXs2),
        LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          color: scheme.primary,
          backgroundColor: scheme.surfaceContainerHighest,
        ),
        SizedBox(height: tokens.spaceSm),
        if (selected != null)
          _RatingLadder(
            rating: selected.rating,
            maxRating: summary.maxRating,
            onSelected: (value) {
              context.read<WeeklyReviewBloc>().add(
                WeeklyReviewValueRatingChanged(
                  valueId: selected.value.id,
                  rating: value,
                ),
              );
            },
          ),
        SizedBox(height: tokens.spaceSm),
        Text(
          '1 Neglected • 4 Low • 7 Steady • 8 Thriving',
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: tokens.spaceLg),
        Text(
          'Completion share (last ${widget.config.valuesWindowWeeks} weeks)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        SegmentedButton<_CompletionSnapshotMode>(
          segments: const [
            ButtonSegment(
              value: _CompletionSnapshotMode.tasks,
              label: Text('Tasks'),
            ),
            ButtonSegment(
              value: _CompletionSnapshotMode.routines,
              label: Text('Routines'),
            ),
          ],
          selected: <_CompletionSnapshotMode>{_mode},
          onSelectionChanged: (value) {
            if (value.isEmpty) return;
            setState(() => _mode = value.first);
          },
        ),
        SizedBox(height: tokens.spaceSm),
        if (distributionEntries.isEmpty || totalCompletions == 0)
          Text(
            'No completions yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          TasklyFeedRenderer.buildSection(
            TasklySectionSpec.valueDistribution(
              id: 'weekly-review-distribution',
              title: _mode == _CompletionSnapshotMode.tasks
                  ? 'Task completions'
                  : 'Routine completions',
              totalLabel: '$totalCompletions total',
              entries: distributionEntries,
            ),
          ),
      ],
    );
  }

  List<TasklyValueDistributionEntry> _buildDistributionEntries(
    BuildContext context,
    List<WeeklyReviewRatingEntry> entries,
    int Function(WeeklyReviewRatingEntry entry) countFor,
  ) {
    return entries
        .map(
          (entry) => TasklyValueDistributionEntry(
            value: entry.value.toChipData(context),
            count: countFor(entry),
          ),
        )
        .toList(growable: false);
  }

  void _openValueDetails(
    BuildContext context, {
    required WeeklyReviewRatingEntry entry,
    required int windowWeeks,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return _RatingDetailsSheet(
          entry: entry,
          windowWeeks: windowWeeks,
        );
      },
    );
  }
}

enum _RatingsBannerTone { info, critical }

class _RatingsBanner extends StatelessWidget {
  const _RatingsBanner({
    required this.tone,
    required this.title,
    required this.message,
  });

  final _RatingsBannerTone tone;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);
    final background = switch (tone) {
      _RatingsBannerTone.info => scheme.tertiaryContainer,
      _RatingsBannerTone.critical => scheme.errorContainer,
    };
    final foreground = switch (tone) {
      _RatingsBannerTone.info => scheme.onTertiaryContainer,
      _RatingsBannerTone.critical => scheme.onErrorContainer,
    };

    return Container(
      margin: EdgeInsets.only(bottom: tokens.spaceSm),
      padding: EdgeInsets.all(tokens.spaceMd),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
          SizedBox(height: tokens.spaceXs2),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelCenterLabel extends StatelessWidget {
  const _WheelCenterLabel({
    required this.name,
    required this.rating,
    required this.maxRating,
  });

  final String name;
  final int rating;
  final int maxRating;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMd,
        vertical: tokens.spaceSm,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.spaceXs2),
          Text(
            rating > 0 ? '$rating / $maxRating' : 'Tap to rate',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingLadder extends StatelessWidget {
  const _RatingLadder({
    required this.rating,
    required this.maxRating,
    required this.onSelected,
  });

  final int rating;
  final int maxRating;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Wrap(
      spacing: tokens.spaceXs2,
      runSpacing: tokens.spaceXs2,
      children: [
        for (var i = 1; i <= maxRating; i++)
          ChoiceChip(
            label: Text(i.toString()),
            selected: rating == i,
            onSelected: (_) => onSelected(i),
          ),
      ],
    );
  }
}

class _RatingDetailsSheet extends StatelessWidget {
  const _RatingDetailsSheet({
    required this.entry,
    required this.windowWeeks,
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

class _RingsRow extends StatelessWidget {
  const _RingsRow({required this.rings});

  final List<WeeklyReviewValueRing> rings;

  @override
  Widget build(BuildContext context) {
    if (rings.isEmpty) {
      return SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: rings
            .map(
              (ring) => Padding(
                padding: EdgeInsets.only(
                  bottom: TasklyTokens.of(context).spaceSm,
                ),
                child: _ValueRing(ring: ring),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _ValueRing extends StatelessWidget {
  const _ValueRing({required this.ring});

  final WeeklyReviewValueRing ring;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = ColorUtils.valueColorForTheme(
      context,
      ring.value.color,
    );
    final percentLabel = ring.percent.round();

    return Column(
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: ring.percent / 100,
                strokeWidth: 6,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
              Text(
                '$percentLabel%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        SizedBox(
          width: 72,
          child: Text(
            ring.value.name,
            style: Theme.of(context).textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _MaintenancePage extends StatelessWidget {
  const _MaintenancePage({required this.sections});

  final List<WeeklyReviewMaintenanceSection> sections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceXs,
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceXl,
      ),
      children: [
        Text(
          'Maintenance Check',
          style: theme.textTheme.titleLarge,
        ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        Text(
          'A short list to keep things from building up.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        for (final section in sections) ...[
          Text(
            section.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          if (section.items.isEmpty)
            Padding(
              padding: EdgeInsets.only(
                bottom: TasklyTokens.of(context).spaceSm,
              ),
              child: Text(
                section.emptyMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            )
          else
            ...section.items.map(
              (item) => Padding(
                padding: EdgeInsets.only(
                  bottom: TasklyTokens.of(context).spaceSm,
                ),
                child: _MaintenanceItem(item: item),
              ),
            ),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
        ],
      ],
    );
  }
}

class _MaintenanceItem extends StatelessWidget {
  const _MaintenanceItem({required this.item});

  final WeeklyReviewMaintenanceItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(TasklyTokens.of(context).radiusMd),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          Text(
            item.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionPage extends StatelessWidget {
  const _CompletionPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: TasklyTokens.of(context).spaceLg,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: scheme.primary),
            SizedBox(height: TasklyTokens.of(context).spaceSm),
            Text(
              "You're done.",
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: TasklyTokens.of(context).spaceSm),
            Text(
              'Clear, calm, and ready to go.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: TasklyTokens.of(context).spaceSm),
            Text(
              'Run again anytime.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _ReviewError extends StatelessWidget {
  const _ReviewError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            SizedBox(height: TasklyTokens.of(context).spaceSm),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
