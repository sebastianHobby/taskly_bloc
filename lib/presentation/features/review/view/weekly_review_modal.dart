import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/review/bloc/weekly_review_cubit.dart';
import 'package:taskly_bloc/presentation/features/review/widgets/weekly_value_checkin_sheet.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/settings.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

Future<void> showWeeklyReviewModal(
  BuildContext context, {
  required GlobalSettings settings,
}) {
  final config = WeeklyReviewConfig.fromSettings(settings);
  final parentContext = context;

  AppLog.warnStructured(
    'weekly_review',
    'open_modal',
    fields: <String, Object?>{
      'valuesSummaryEnabled': config.valuesSummaryEnabled,
      'maintenanceEnabled': config.maintenanceEnabled,
    },
  );

  return Navigator.of(context)
      .push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) {
            return BlocProvider(
              create: (context) => WeeklyReviewBloc(
                analyticsService: context.read<AnalyticsService>(),
                attentionEngine: context.read<AttentionEngineContract>(),
                valueRepository: context.read<ValueRepositoryContract>(),
                valueRatingsRepository: context
                    .read<ValueRatingsRepositoryContract>(),
                valueRatingsWriteService: context
                    .read<ValueRatingsWriteService>(),
                routineRepository: context.read<RoutineRepositoryContract>(),
                taskRepository: context.read<TaskRepositoryContract>(),
                nowService: context.read<NowService>(),
              )..add(WeeklyReviewRequested(config)),
              child: _WeeklyReviewModal(
                config: config,
                parentContext: parentContext,
              ),
            );
          },
        ),
      )
      .whenComplete(
        () => AppLog.warn('weekly_review', 'close_modal'),
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
  int _pageCount = 1;
  int _lastLoggedPageCount = -1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    AppLog.warnStructured(
      'weekly_review',
      'next',
      fields: <String, Object?>{
        'pageIndex': _pageIndex,
        'pageCount': _pageCount,
      },
    );
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
    AppLog.warn('weekly_review', 'complete_review');
    final nowUtc = context.read<NowService>().nowUtc();
    context.read<GlobalSettingsBloc>().add(
      GlobalSettingsEvent.weeklyReviewCompleted(nowUtc),
    );
    Navigator.of(context).maybePop();
  }

  void _openSettings() {
    AppLog.warn('weekly_review', 'open_settings');
    Navigator.of(context).maybePop();
    if (!widget.parentContext.mounted) return;
    Routing.toScreenKey(widget.parentContext, 'settings');
  }

  void _ensurePageInRange(int pageCount) {
    if (_pageIndex < pageCount) return;
    final target = pageCount - 1;
    AppLog.warnStructured(
      'weekly_review',
      'page_index_clamped',
      fields: <String, Object?>{
        'pageIndex': _pageIndex,
        'pageCount': pageCount,
        'targetIndex': target,
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _pageIndex = target);
      _controller.jumpToPage(target);
    });
  }

  void _logPageCountChange({
    required int pageCount,
    required bool showValuesOverview,
    required bool ratingsEnabled,
    required bool ratingsSummary,
    required bool maintenanceEnabled,
  }) {
    if (pageCount == _lastLoggedPageCount) return;
    AppLog.warnStructured(
      'weekly_review',
      'page_count_changed',
      fields: <String, Object?>{
        'pageIndex': _pageIndex,
        'previousPageCount': _lastLoggedPageCount,
        'pageCount': pageCount,
        'valuesOverview': showValuesOverview,
        'ratingsEnabled': ratingsEnabled,
        'ratingsSummary': ratingsSummary,
        'maintenanceEnabled': maintenanceEnabled,
      },
    );
    _lastLoggedPageCount = pageCount;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<WeeklyReviewBloc, WeeklyReviewState>(
      builder: (context, state) {
        final l10n = context.l10n;
        if (state.status == WeeklyReviewStatus.loading) {
          return Scaffold(
            body: SafeArea(child: _ReviewLoading()),
          );
        }
        if (state.status == WeeklyReviewStatus.failure) {
          return Scaffold(
            body: SafeArea(
              child: _ReviewError(
                message: l10n.weeklyReviewLoadFailureMessage,
                onRetry: () => context.read<WeeklyReviewBloc>().add(
                  WeeklyReviewRequested(widget.config),
                ),
              ),
            ),
          );
        }

        final ratingsSummary = state.ratingsSummary;
        final ratingsEnabled = ratingsSummary?.ratingsEnabled ?? false;
        final ratingsComplete = ratingsSummary?.isComplete ?? true;
        final initialCheckInValueId = ratingsSummary == null
            ? null
            : _initialValueId(ratingsSummary);

        final showValuesOverview = widget.config.valuesSummaryEnabled;
        final hasCheckIn = ratingsEnabled && ratingsSummary != null;
        final pageCount =
            (showValuesOverview ? 1 : 0) +
            (hasCheckIn ? 1 : 0) +
            (widget.config.maintenanceEnabled ? 1 : 0) +
            1;
        final checkInStep = showValuesOverview ? 2 : 1;
        final pages = <Widget>[
          if (showValuesOverview)
            _ValuesSnapshotPage(
              key: const ValueKey('weekly_review_values_snapshot'),
              config: widget.config,
              summary: state.valuesSummary,
              wins: state.valueWins,
            ),
          if (hasCheckIn)
            WeeklyValueCheckInContent(
              key: const ValueKey('weekly_review_check_in'),
              initialValueId: initialCheckInValueId,
              windowWeeks: widget.config.valuesWindowWeeks,
              wizardStep: checkInStep,
              wizardTotal: pageCount,
              onWizardBack: () {
                if (showValuesOverview) {
                  _controller.previousPage(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                } else {
                  Navigator.of(context).maybePop();
                }
              },
              onExit: () {
                AppLog.warnStructured(
                  'weekly_review',
                  'exit_checkin',
                  fields: <String, Object?>{
                    'hasValuesOverview': showValuesOverview,
                  },
                );
                if (showValuesOverview) {
                  _controller.previousPage(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                } else {
                  Navigator.of(context).maybePop();
                }
              },
              onComplete: _goNext,
            ),
          if (widget.config.maintenanceEnabled)
            _MaintenancePage(
              key: const ValueKey('weekly_review_maintenance'),
              sections: state.maintenanceSections,
            ),
          const _CompletionPage(
            key: ValueKey('weekly_review_completion'),
          ),
        ];

        AppLog.warnStructured(
          'weekly_review',
          'build_pages',
          fields: <String, Object?>{
            'valuesOverview': showValuesOverview,
            'ratingsEnabled': ratingsEnabled,
            'ratingsSummary': ratingsSummary != null,
            'maintenanceEnabled': widget.config.maintenanceEnabled,
            'pageCount': pages.length,
          },
        );

        _pageCount = pageCount;
        _logPageCountChange(
          pageCount: pageCount,
          showValuesOverview: showValuesOverview,
          ratingsEnabled: ratingsEnabled,
          ratingsSummary: ratingsSummary != null,
          maintenanceEnabled: widget.config.maintenanceEnabled,
        );
        _ensurePageInRange(pageCount);

        final checkInIndex = showValuesOverview ? 1 : 0;
        final isCheckInPage =
            ratingsEnabled &&
            ratingsSummary != null &&
            _pageIndex == checkInIndex;
        final buttonLabel = _pageIndex == _pageCount - 1
            ? l10n.doneLabel
            : (isCheckInPage && !ratingsComplete
                  ? l10n.weeklyReviewSkipCheckInAction
                  : l10n.continueLabel);

        final header = Padding(
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
                  l10n.weeklyReviewTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: _openSettings,
                child: Text(context.l10n.settingsTitle),
              ),
              IconButton(
                tooltip: context.l10n.closeLabel,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        );

        final footer = Padding(
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
                  child: Text(context.l10n.backLabel),
                ),
              const Spacer(),
              FilledButton(
                onPressed: _goNext,
                child: Text(buttonLabel),
              ),
            ],
          ),
        );

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Offstage(
                  offstage: isCheckInPage,
                  child: header,
                ),
                Expanded(
                  child: PageView(
                    key: const PageStorageKey<String>(
                      'weekly_review_page_view',
                    ),
                    controller: _controller,
                    onPageChanged: (index) {
                      AppLog.warnStructured(
                        'weekly_review',
                        'page_changed',
                        fields: <String, Object?>{
                          'pageIndex': index,
                          'pageCount': _pageCount,
                        },
                      );
                      setState(() => _pageIndex = index);
                    },
                    children: pages,
                  ),
                ),
                Offstage(
                  offstage: isCheckInPage,
                  child: footer,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _initialValueId(WeeklyReviewRatingsSummary summary) {
    return summary.entries.isEmpty ? null : summary.entries.first.value.id;
  }
}

class _ValuesSnapshotPage extends StatelessWidget {
  const _ValuesSnapshotPage({
    required this.config,
    required this.summary,
    required this.wins,
    super.key,
  });

  final WeeklyReviewConfig config;
  final WeeklyReviewValuesSummary? summary;
  final List<WeeklyReviewValueWin> wins;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shares = summary?.shares ?? const <WeeklyReviewValueShare>[];
    final hasValues = summary?.hasValues ?? false;
    final hasCompletions = summary?.hasCompletions ?? false;
    final completionSummary = summary == null
        ? null
        : l10n.weeklyReviewValuesCompletionSummary(
            summary!.taskCompletions,
            summary!.routineCompletions,
          );

    return ListView(
      key: const PageStorageKey<String>(
        'weekly_review_values_snapshot_list',
      ),
      padding: EdgeInsets.fromLTRB(
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceXs,
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceXl,
      ),
      children: [
        Text(
          l10n.weeklyReviewValuesTitle,
          style: theme.textTheme.titleLarge,
        ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        Text(
          l10n.weeklyReviewValuesSnapshotSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        Text(
          l10n.weeklyReviewLastWeeksLabel(config.valuesWindowWeeks),
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        if (completionSummary != null)
          Text(
            completionSummary,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        if (hasValues)
          _ValuesDonutChart(
            shares: shares,
            totalCompletions: summary?.alignedCompletions ?? 0,
          )
        else
          Text(
            l10n.weeklyReviewValuesNoValuesLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        if (hasValues) ...[
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          _ValuesLegend(shares: shares),
          if (!hasCompletions) ...[
            SizedBox(height: TasklyTokens.of(context).spaceSm),
            Text(
              l10n.weeklyReviewValuesInsightEmptyLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          SizedBox(height: TasklyTokens.of(context).spaceLg),
          _PriorityTargetsSection(shares: shares),
          SizedBox(height: TasklyTokens.of(context).spaceLg),
        ],
        Text(
          l10n.weeklyReviewValuesWinsLabel,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        Text(
          l10n.weeklyReviewValueWinsSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        if (wins.isEmpty)
          Text(
            l10n.weeklyReviewValueWinsEmpty,
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
                      l10n.weeklyReviewValueWinsRow(
                        win.valueName ?? l10n.valueLabel,
                        win.completionCount,
                      ),
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

class _ValuesDonutChart extends StatelessWidget {
  const _ValuesDonutChart({
    required this.shares,
    required this.totalCompletions,
  });

  final List<WeeklyReviewValueShare> shares;
  final int totalCompletions;

  static const double _maxSize = 240;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    final colors = shares
        .map(
          (share) => ColorUtils.valueColorForTheme(
            context,
            share.value.color,
          ),
        )
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, _maxSize);
        final strokeWidth = size * 0.16;

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(size),
                  painter: _ValuesDonutPainter(
                    shares: shares,
                    colors: colors,
                    totalCompletions: totalCompletions,
                    strokeWidth: strokeWidth,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      totalCompletions.toString(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: tokens.spaceXs),
                    Text(
                      context.l10n.weeklyReviewValuesCompletionsLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ValuesDonutPainter extends CustomPainter {
  _ValuesDonutPainter({
    required this.shares,
    required this.colors,
    required this.totalCompletions,
    required this.strokeWidth,
    required this.backgroundColor,
  });

  final List<WeeklyReviewValueShare> shares;
  final List<Color> colors;
  final int totalCompletions;
  final double strokeWidth;
  final Color backgroundColor;

  static const double _gapRadians = 0.05;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, backgroundPaint);

    if (totalCompletions <= 0 || shares.isEmpty) return;

    var startAngle = -math.pi / 2;

    for (var i = 0; i < shares.length; i++) {
      final share = shares[i];
      if (share.actualPercent <= 0) continue;

      final sweep = math.pi * 2 * (share.actualPercent / 100);
      final gap = math.min(_gapRadians, sweep * 0.35);
      if (sweep <= gap) {
        startAngle += sweep;
        continue;
      }

      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        startAngle + gap / 2,
        sweep - gap,
        false,
        paint,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _ValuesDonutPainter oldDelegate) {
    return oldDelegate.shares != shares ||
        oldDelegate.colors != colors ||
        oldDelegate.totalCompletions != totalCompletions;
  }
}

class _ValuesLegend extends StatelessWidget {
  const _ValuesLegend({required this.shares});

  final List<WeeklyReviewValueShare> shares;

  @override
  Widget build(BuildContext context) {
    if (shares.isEmpty) return const SizedBox.shrink();

    final tokens = TasklyTokens.of(context);

    return Wrap(
      spacing: tokens.spaceSm,
      runSpacing: tokens.spaceSm,
      children: shares
          .map(
            (share) => _ValueLegendChip(share: share),
          )
          .toList(growable: false),
    );
  }
}

class _ValueLegendChip extends StatelessWidget {
  const _ValueLegendChip({required this.share});

  final WeeklyReviewValueShare share;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = ColorUtils.valueColorForTheme(
      context,
      share.value.color,
    );
    final percentLabel = share.actualPercent.round();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSm,
        vertical: tokens.spaceXs,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: tokens.spaceXs,
            height: tokens.spaceXs,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: tokens.spaceXs),
          Text(
            share.value.name,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          SizedBox(width: tokens.spaceXs),
          Text(
            context.l10n.analyticsPercentValue(percentLabel),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: tokens.spaceXs),
          Text(
            '(${share.completionCount})',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityTargetsSection extends StatelessWidget {
  const _PriorityTargetsSection({required this.shares});

  final List<WeeklyReviewValueShare> shares;

  @override
  Widget build(BuildContext context) {
    if (shares.isEmpty) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.weeklyReviewValuesPriorityTargetsTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        Text(
          l10n.weeklyReviewValuesPriorityTargetsSubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        ...shares.map(
          (share) => Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceSm),
            child: _PriorityTargetRow(share: share),
          ),
        ),
      ],
    );
  }
}

class _PriorityTargetRow extends StatelessWidget {
  const _PriorityTargetRow({required this.share});

  final WeeklyReviewValueShare share;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    final accent = ColorUtils.valueColorForTheme(
      context,
      share.value.color,
    );
    final expectedPercent = share.expectedPercent.round();
    final actualPercent = share.actualPercent.round();
    final delta = share.deltaPercent.round();

    return Container(
      padding: EdgeInsets.all(tokens.spaceMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: tokens.spaceSm,
            height: tokens.spaceSm,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  share.value.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: tokens.spaceXs),
                Wrap(
                  spacing: tokens.spaceSm,
                  runSpacing: tokens.spaceXs,
                  children: [
                    _TargetMetric(
                      label: l10n.weeklyReviewValuesTargetShareLabel,
                      percent: expectedPercent,
                    ),
                    _TargetMetric(
                      label: l10n.weeklyReviewValuesActualShareLabel,
                      percent: actualPercent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: tokens.spaceSm),
          Text(
            _deltaText(l10n, delta),
            style: theme.textTheme.labelSmall?.copyWith(
              color: _deltaColor(scheme, delta),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _deltaText(AppLocalizations l10n, int delta) {
    final absLabel = l10n.analyticsPercentValue(delta.abs());
    final sign = delta > 0 ? '+' : (delta < 0 ? '-' : '');
    return '$sign$absLabel ${l10n.weeklyReviewValuesDeltaLabel}';
  }

  Color _deltaColor(ColorScheme scheme, int delta) {
    if (delta > 0) return scheme.primary;
    if (delta < 0) return scheme.error;
    return scheme.onSurfaceVariant;
  }
}

class _TargetMetric extends StatelessWidget {
  const _TargetMetric({
    required this.label,
    required this.percent,
  });

  final String label;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = '$label ${context.l10n.analyticsPercentValue(percent)}';

    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

class _MaintenancePage extends StatelessWidget {
  const _MaintenancePage({
    required this.sections,
    super.key,
  });

  final List<WeeklyReviewMaintenanceSection> sections;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      key: const PageStorageKey<String>(
        'weekly_review_maintenance_list',
      ),
      padding: EdgeInsets.fromLTRB(
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceXs,
        TasklyTokens.of(context).spaceLg,
        TasklyTokens.of(context).spaceXl,
      ),
      children: [
        Text(
          l10n.weeklyReviewMaintenanceTitle,
          style: theme.textTheme.titleLarge,
        ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        Text(
          l10n.weeklyReviewMaintenanceCheckSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: TasklyTokens.of(context).spaceSm),
        for (final section in sections) ...[
          Text(
            _sectionTitle(l10n, section.type),
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
                _sectionEmptyMessage(l10n, section.type),
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
                child: _MaintenanceItem(
                  title: _itemTitle(l10n, item),
                  description: _itemDescription(l10n, item),
                ),
              ),
            ),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
        ],
      ],
    );
  }

  String _sectionTitle(
    AppLocalizations l10n,
    WeeklyReviewMaintenanceSectionType type,
  ) {
    return switch (type) {
      WeeklyReviewMaintenanceSectionType.deadlineRisk =>
        l10n.weeklyReviewDeadlineRiskTitle,
      WeeklyReviewMaintenanceSectionType.staleItems =>
        l10n.weeklyReviewStaleTitle,
      WeeklyReviewMaintenanceSectionType.frequentlySnoozed =>
        l10n.weeklyReviewFrequentSnoozedTitle,
    };
  }

  String _sectionEmptyMessage(
    AppLocalizations l10n,
    WeeklyReviewMaintenanceSectionType type,
  ) {
    return switch (type) {
      WeeklyReviewMaintenanceSectionType.deadlineRisk =>
        l10n.weeklyReviewDeadlineRiskEmptyMessage,
      WeeklyReviewMaintenanceSectionType.staleItems =>
        l10n.weeklyReviewStaleItemsEmptyMessage,
      WeeklyReviewMaintenanceSectionType.frequentlySnoozed =>
        l10n.weeklyReviewFrequentSnoozedEmptyMessage,
    };
  }

  String _itemTitle(AppLocalizations l10n, WeeklyReviewMaintenanceItem item) {
    final name = item.name;
    if (name != null && name.trim().isNotEmpty) return name;
    return switch (item) {
      WeeklyReviewDeadlineRiskItem() => l10n.projectLabel,
      WeeklyReviewStaleItem() => l10n.itemLabel,
      WeeklyReviewFrequentSnoozedItem() => l10n.taskLabel,
    };
  }

  String _itemDescription(
    AppLocalizations l10n,
    WeeklyReviewMaintenanceItem item,
  ) {
    return switch (item) {
      WeeklyReviewDeadlineRiskItem(
        :final dueInDays,
        :final unscheduledCount,
      ) =>
        l10n.weeklyReviewDeadlineRiskItemDescription(
          _dueLabel(l10n, dueInDays),
          unscheduledCount,
        ),
      WeeklyReviewStaleItem(:final thresholdDays) =>
        l10n.weeklyReviewStaleItemDescription(thresholdDays),
      WeeklyReviewFrequentSnoozedItem(
        :final snoozeCount,
        :final totalSnoozeDays,
      ) =>
        l10n.weeklyReviewFrequentSnoozeItemDescription(
          snoozeCount,
          totalSnoozeDays,
        ),
    };
  }

  String _dueLabel(AppLocalizations l10n, int? dueInDays) {
    return switch (dueInDays) {
      null => l10n.weeklyReviewDueSoonLabel,
      0 => l10n.weeklyReviewDueTodayLabel,
      1 => l10n.weeklyReviewDueTomorrowLabel,
      < 0 => l10n.weeklyReviewOverdueByDaysLabel(dueInDays.abs()),
      _ => l10n.weeklyReviewDueInDaysLabel(dueInDays),
    };
  }
}

class _MaintenanceItem extends StatelessWidget {
  const _MaintenanceItem({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

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
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: TasklyTokens.of(context).spaceSm),
          Text(
            description,
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
  const _CompletionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
              l10n.weeklyReviewCompletionTitle,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: TasklyTokens.of(context).spaceSm),
            Text(
              l10n.weeklyReviewCompletionSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: TasklyTokens.of(context).spaceSm),
            Text(
              l10n.weeklyReviewCompletionFooter,
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
              child: Text(context.l10n.retryButton),
            ),
          ],
        ),
      ),
    );
  }
}
