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
import 'package:taskly_ui/taskly_ui_tokens.dart';

Future<void> showWeeklyReviewModal(
  BuildContext context, {
  required GlobalSettings settings,
}) {
  final config = WeeklyReviewConfig.fromSettings(settings);
  final parentContext = context;

  return Navigator.of(context).push<void>(
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
            valueRatingsWriteService: context.read<ValueRatingsWriteService>(),
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
  bool _useRatingWheel = true;

  int get _pageCount {
    var count = 0;
    final showValuesOverview = widget.config.valuesSummaryEnabled;
    if (showValuesOverview) {
      count += 1;
    }
    if (_ratingsEnabled) {
      count += 1;
    }
    if (widget.config.maintenanceEnabled) {
      count += 1;
    }
    return count + 1;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
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
          return Scaffold(
            body: SafeArea(child: _ReviewLoading()),
          );
        }
        if (state.status == WeeklyReviewStatus.failure) {
          return Scaffold(
            body: SafeArea(
              child: _ReviewError(
                message: state.errorMessage ?? 'Failed to load review.',
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
        _ratingsEnabled = ratingsEnabled;

        final initialCheckInValueId = ratingsSummary == null
            ? null
            : _initialValueId(ratingsSummary);

        final showValuesOverview = widget.config.valuesSummaryEnabled;

        final pages = <Widget>[
          if (showValuesOverview)
            _ValuesSnapshotPage(
              config: widget.config,
              summary: state.valuesSummary,
              wins: state.valueWins,
            ),
          if (ratingsEnabled && ratingsSummary != null)
            WeeklyValueCheckInContent(
              initialValueId: initialCheckInValueId,
              windowWeeks: widget.config.valuesWindowWeeks,
              useRatingWheel: _useRatingWheel,
              onChartToggle: (value) => setState(() {
                _useRatingWheel = value;
              }),
              onExit: () {
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
              sections: state.maintenanceSections,
            ),
          const _CompletionPage(),
        ];

        final isCheckInPage =
            ratingsEnabled && _pageIndex == (showValuesOverview ? 1 : 0);
        final buttonLabel = _pageIndex == _pageCount - 1
            ? 'Done'
            : (isCheckInPage && !ratingsComplete
                  ? 'Skip check-in'
                  : 'Continue');

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                if (!isCheckInPage)
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
                if (!isCheckInPage)
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
                          onPressed: _goNext,
                          child: Text(buttonLabel),
                        ),
                      ],
                    ),
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
