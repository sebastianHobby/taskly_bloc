import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/review/bloc/weekly_review_cubit.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/settings.dart';

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
          create: (_) => WeeklyReviewCubit(
            analyticsService: getIt<AnalyticsService>(),
            attentionEngine: getIt<AttentionEngineContract>(),
            valueRepository: getIt<ValueRepositoryContract>(),
            taskRepository: getIt<TaskRepositoryContract>(),
            nowService: getIt<NowService>(),
          )..load(config),
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
    final nowUtc = getIt<NowService>().nowUtc();
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

    return BlocBuilder<WeeklyReviewCubit, WeeklyReviewState>(
      builder: (context, state) {
        if (state.status == WeeklyReviewStatus.loading) {
          return _ReviewLoading();
        }
        if (state.status == WeeklyReviewStatus.failure) {
          return _ReviewError(
            message: state.errorMessage ?? 'Failed to load review.',
            onRetry: () => context.read<WeeklyReviewCubit>().load(
              widget.config,
            ),
          );
        }

        final pages = <Widget>[
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

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(
          'Values Snapshot',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'How your completed work aligned with what matters.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (summary?.hasData ?? false) ...[
          Text(
            'Last ${config.valuesWindowWeeks} weeks',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _RingsRow(rings: summary?.rings ?? const []),
          const SizedBox(height: 12),
        ],
        Text(
          insight,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        Text(
          'Value Wins',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Small moments that added up.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
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
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, size: 18),
                  const SizedBox(width: 8),
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
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: rings
            .map(
              (ring) => Padding(
                padding: const EdgeInsets.only(right: 12),
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
    final accent = ColorUtils.fromHexWithThemeFallback(
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
        const SizedBox(height: 6),
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(
          'Maintenance Check',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'A short list to keep things from building up.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        for (final section in sections) ...[
          Text(
            section.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (section.items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
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
                padding: const EdgeInsets.only(bottom: 12),
                child: _MaintenanceItem(item: item),
              ),
            ),
          const SizedBox(height: 4),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 4),
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 48, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              "You're done.",
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Clear, calm, and ready to go.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
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
