import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/review/bloc/weekly_review_cubit.dart';
import 'package:taskly_bloc/presentation/features/review/widgets/weekly_value_checkin_sheet.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
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
    Routing.pushSettingsWeeklyReview(widget.parentContext);
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
        final hasCheckIn = ratingsEnabled && ratingsSummary != null;
        final pageCount =
            (hasCheckIn ? 1 : 0) +
            (widget.config.maintenanceEnabled ? 1 : 0) +
            1;
        final pages = <Widget>[
          if (hasCheckIn)
            WeeklyValueCheckInContent(
              key: const ValueKey('weekly_review_check_in'),
              initialValueId: initialCheckInValueId,
              windowWeeks: widget.config.checkInWindowWeeks,
              wizardStep: 1,
              wizardTotal: pageCount,
              onExit: () {
                AppLog.warnStructured(
                  'weekly_review',
                  'exit_checkin',
                  fields: <String, Object?>{
                    'maintenanceEnabled': widget.config.maintenanceEnabled,
                  },
                );
                Navigator.of(context).maybePop();
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
            'ratingsEnabled': ratingsEnabled,
            'ratingsSummary': ratingsSummary != null,
            'maintenanceEnabled': widget.config.maintenanceEnabled,
            'pageCount': pages.length,
          },
        );

        _pageCount = pageCount;
        _logPageCountChange(
          pageCount: pageCount,
          ratingsEnabled: ratingsEnabled,
          ratingsSummary: ratingsSummary != null,
          maintenanceEnabled: widget.config.maintenanceEnabled,
        );
        _ensurePageInRange(pageCount);

        const checkInIndex = 0;
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
              if (_pageIndex > 0) ...[
                TextButton(
                  onPressed: () => _controller.previousPage(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  ),
                  child: Text(context.l10n.backLabel),
                ),
              ],
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
    final tokens = TasklyTokens.of(context);
    final hasAnyItems = sections.any((section) => section.items.isNotEmpty);

    return ListView(
      key: const PageStorageKey<String>(
        'weekly_review_maintenance_list',
      ),
      padding: EdgeInsets.fromLTRB(
        tokens.spaceLg,
        tokens.spaceXs,
        tokens.spaceLg,
        tokens.spaceXl,
      ),
      children: [
        Text(
          l10n.weeklyReviewMaintenanceTitle,
          style: theme.textTheme.titleLarge,
        ),
        SizedBox(height: tokens.spaceSm),
        Text(
          l10n.weeklyReviewMaintenanceCheckSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        if (!hasAnyItems)
          _MaintenanceAllClearCard(
            title: l10n.weeklyReviewMaintenanceAllClearTitle,
            subtitle: l10n.weeklyReviewMaintenanceAllClearSubtitle,
          )
        else
          ...sections
              .where((section) => section.items.isNotEmpty)
              .map(
                (section) => Padding(
                  padding: EdgeInsets.only(bottom: tokens.spaceSm),
                  child: _MaintenanceSectionCard(
                    title: _sectionTitle(l10n, section.type),
                    icon: _sectionIcon(section.type),
                    accent: _sectionAccent(context, section.type),
                    itemCount: section.items.length,
                    children: section.items
                        .map(
                          (item) => Padding(
                            padding: EdgeInsets.only(bottom: tokens.spaceSm),
                            child: _MaintenanceItem(
                              title: _itemTitle(l10n, item),
                              description: _itemDescription(l10n, item),
                              accent: _sectionAccent(context, section.type),
                              badgeLabel: _itemBadgeLabel(l10n, item),
                              onTap: _onItemTap(context, item),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
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

  IconData _sectionIcon(WeeklyReviewMaintenanceSectionType type) {
    return switch (type) {
      WeeklyReviewMaintenanceSectionType.deadlineRisk =>
        Icons.warning_amber_rounded,
      WeeklyReviewMaintenanceSectionType.staleItems =>
        Icons.hourglass_bottom_rounded,
      WeeklyReviewMaintenanceSectionType.frequentlySnoozed =>
        Icons.snooze_rounded,
    };
  }

  Color _sectionAccent(
    BuildContext context,
    WeeklyReviewMaintenanceSectionType type,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return switch (type) {
      WeeklyReviewMaintenanceSectionType.deadlineRisk => scheme.error,
      WeeklyReviewMaintenanceSectionType.staleItems => scheme.tertiary,
      WeeklyReviewMaintenanceSectionType.frequentlySnoozed => scheme.secondary,
    };
  }

  String? _itemBadgeLabel(
    AppLocalizations l10n,
    WeeklyReviewMaintenanceItem item,
  ) {
    return switch (item) {
      WeeklyReviewDeadlineRiskItem(:final dueInDays) => _dueLabel(
        l10n,
        dueInDays,
      ),
      WeeklyReviewStaleItem(:final thresholdDays) => l10n.daysCountLabel(
        thresholdDays,
      ),
      WeeklyReviewFrequentSnoozedItem(:final snoozeCount) => '${snoozeCount}x',
    };
  }

  VoidCallback? _onItemTap(
    BuildContext context,
    WeeklyReviewMaintenanceItem item,
  ) {
    final entityId = item.entityId;
    final attentionType = item.entityType;
    final routeType = _routeEntityType(attentionType);
    if (entityId == null || routeType == null) return null;
    return () => Routing.toEntity(context, routeType, entityId);
  }

  EntityType? _routeEntityType(AttentionEntityType? attentionType) {
    return switch (attentionType) {
      AttentionEntityType.task => EntityType.task,
      AttentionEntityType.project => EntityType.project,
      AttentionEntityType.value => EntityType.value,
      _ => null,
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
    required this.accent,
    this.badgeLabel,
    this.onTap,
  });

  final String title;
  final String description;
  final Color accent;
  final String? badgeLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    final cardColor = scheme.surfaceContainerLowest;
    final borderColor = scheme.outlineVariant.withValues(alpha: 0.6);
    final isInteractive = onTap != null;

    return Material(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (badgeLabel != null)
                    _MaintenanceBadge(
                      label: badgeLabel!,
                      accent: accent,
                    ),
                  if (isInteractive)
                    Padding(
                      padding: EdgeInsets.only(left: tokens.spaceXs),
                      child: Icon(
                        Icons.chevron_right,
                        size: tokens.spaceMd,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              SizedBox(height: tokens.spaceSm),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaintenanceSectionCard extends StatelessWidget {
  const _MaintenanceSectionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.itemCount,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final int itemCount;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final countLabel = context.l10n.itemsCountLabel(itemCount);

    return Container(
      padding: EdgeInsets.all(tokens.spaceLg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusXxl),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.06),
            blurRadius: tokens.spaceLg,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(tokens.radiusLg),
                ),
                child: Icon(icon, color: accent),
              ),
              SizedBox(width: tokens.spaceSm),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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
                  countLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.spaceSm),
          ...children,
        ],
      ),
    );
  }
}

class _MaintenanceBadge extends StatelessWidget {
  const _MaintenanceBadge({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSm,
        vertical: tokens.spaceXxs,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(tokens.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MaintenanceAllClearCard extends StatelessWidget {
  const _MaintenanceAllClearCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(tokens.spaceLg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusXxl),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(tokens.radiusLg),
            ),
            child: Icon(
              Icons.check_circle,
              color: scheme.primary,
            ),
          ),
          SizedBox(width: tokens.spaceSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: tokens.spaceXxs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
