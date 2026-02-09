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
  bool _useRatingWheel = true;
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
              useRatingWheel: _useRatingWheel,
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
              onChartToggle: (value) => setState(() {
                _useRatingWheel = value;
              }),
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
                  ),
                Expanded(
                  child: PageView(
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
                            child: Text(context.l10n.backLabel),
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

    final hasSummary = summary?.hasData ?? false;
    final insight = hasSummary
        ? l10n.weeklyReviewValuesInsightLabel(
            summary?.topValueName ?? l10n.valueLabel,
            summary?.bottomValueName ?? l10n.valueLabel,
          )
        : l10n.weeklyReviewValuesInsightEmptyLabel;

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
        if (summary?.hasData ?? false) ...[
          Text(
            l10n.weeklyReviewLastWeeksLabel(config.valuesWindowWeeks),
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
    final l10n = context.l10n;
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
                l10n.analyticsPercentValue(percentLabel),
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
