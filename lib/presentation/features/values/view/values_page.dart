import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/values_hero_bloc.dart';
import 'package:taskly_bloc/presentation/features/values/widgets/values_list.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_bloc.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class ValuesPage extends StatelessWidget {
  const ValuesPage({super.key});

  void _createValue(BuildContext context) {
    Routing.toValueNew(context);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ValuesHeroBloc>(
          create: (context) => ValuesHeroBloc(
            analyticsService: context.read<AnalyticsService>(),
            valueRepository: context.read<ValueRepositoryContract>(),
            sharedDataService: context.read<SessionSharedDataService>(),
            nowService: context.read<NowService>(),
          )..add(const ValuesHeroSubscriptionRequested()),
        ),
        BlocProvider(create: (_) => SelectionBloc()),
      ],
      child: Builder(
        builder: (context) {
          final isCompact = WindowSizeClass.of(context).isCompact;

          return BlocBuilder<SelectionBloc, SelectionState>(
            builder: (context, selectionState) {
              return Scaffold(
                appBar: selectionState.isSelectionMode
                    ? SelectionAppBar(baseTitle: 'Values', onExit: () {})
                    : AppBar(
                        title: const Text('Values'),
                        actions: TasklyAppBarActions.withAttentionBell(
                          context,
                          actions: [
                            if (!isCompact)
                              IconButton(
                                tooltip: context.l10n.createValueTooltip,
                                onPressed: () => _createValue(context),
                                icon: const Icon(Icons.add),
                              ),
                          ],
                        ),
                      ),
                floatingActionButton: isCompact
                    ? FloatingActionButton(
                        tooltip: context.l10n.createValueTooltip,
                        onPressed: () => _createValue(context),
                        heroTag: 'create_value_fab_values',
                        child: const Icon(Icons.add),
                      )
                    : null,
                body: BlocBuilder<ValuesHeroBloc, ValuesHeroState>(
                  builder: (context, state) {
                    final body = switch (state) {
                      ValuesHeroLoading() => const TasklyFeedRenderer(
                        spec: TasklyFeedSpec.loading(),
                      ),
                      ValuesHeroError(:final error) => TasklyFeedRenderer(
                        spec: TasklyFeedSpec.error(
                          message: friendlyErrorMessageForUi(
                            error,
                            context.l10n,
                          ),
                          retryLabel: context.l10n.retryButton,
                          onRetry: () => context
                              .read<ValuesHeroBloc>()
                              .add(const ValuesHeroSubscriptionRequested()),
                        ),
                      ),
                      ValuesHeroLoaded(:final items) when items.isEmpty =>
                        TasklyFeedRenderer(
                          spec: TasklyFeedSpec.empty(
                            empty: TasklyEmptyStateSpec(
                              icon: Icons.favorite_border,
                              title: 'No values yet',
                              description:
                                  'Create a value to clarify what matters most.',
                              actionLabel: context.l10n.createValueOption,
                              onAction: () => _createValue(context),
                            ),
                          ),
                        ),
                      ValuesHeroLoaded(:final items) => ValuesListView(
                        items: items,
                      ),
                    };

                    final tokens = TasklyTokens.of(context);

                    return Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            tokens.sectionPaddingH,
                            tokens.spaceMd,
                            tokens.sectionPaddingH,
                            tokens.spaceSm,
                          ),
                          child: _ValuesRangeSelector(
                            selectedDays: state.rangeDays,
                            onChanged: (days) => context
                                .read<ValuesHeroBloc>()
                                .add(ValuesHeroRangeChanged(days)),
                          ),
                        ),
                        Expanded(child: body),
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ValuesRangeSelector extends StatelessWidget {
  const _ValuesRangeSelector({
    required this.selectedDays,
    required this.onChanged,
  });

  final int selectedDays;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Range',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: tokens.spaceSm),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 30, label: Text('30d')),
            ButtonSegment(value: 90, label: Text('90d')),
            ButtonSegment(value: 180, label: Text('180d')),
            ButtonSegment(value: 365, label: Text('365d')),
          ],
          selected: {selectedDays},
          onSelectionChanged: (selection) {
            if (selection.isEmpty) return;
            onChanged(selection.first);
          },
        ),
      ],
    );
  }
}
