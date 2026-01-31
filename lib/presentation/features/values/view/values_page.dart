import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/values/bloc/values_hero_bloc.dart';
import 'package:taskly_bloc/presentation/features/values/model/value_sort_order.dart';
import 'package:taskly_bloc/presentation/features/values/widgets/values_list.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_overflow_menu.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_bloc.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class ValuesPage extends StatefulWidget {
  const ValuesPage({super.key});

  @override
  State<ValuesPage> createState() => _ValuesPageState();
}

class _ValuesPageState extends State<ValuesPage> {
  ValueSortOrder _sortOrder = ValueSortOrder.priority;

  void _createValue(BuildContext context) {
    Routing.toValueNew(context);
  }

  void _updateSort(ValueSortOrder order) {
    if (_sortOrder == order) return;
    setState(() => _sortOrder = order);
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
          return BlocBuilder<SelectionBloc, SelectionState>(
            builder: (context, selectionState) {
              return Scaffold(
                appBar: selectionState.isSelectionMode
                    ? SelectionAppBar(baseTitle: 'Values', onExit: () {})
                    : AppBar(
                        actions: TasklyAppBarActions.withAttentionBell(
                          context,
                          actions: [
                            TasklyOverflowMenuButton<_ValuesMenuAction>(
                              tooltip: 'More',
                              itemsBuilder: (context) => [
                                const PopupMenuItem(
                                  value: _ValuesMenuAction.sortBy,
                                  child: Text('Sort by'),
                                ),
                                const PopupMenuItem(
                                  value: _ValuesMenuAction.selectMultiple,
                                  child: Text('Select multiple'),
                                ),
                              ],
                              onSelected: (action) {
                                switch (action) {
                                  case _ValuesMenuAction.sortBy:
                                    _showSortSheet();
                                  case _ValuesMenuAction.selectMultiple:
                                    context
                                        .read<SelectionBloc>()
                                        .enterSelectionMode();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                floatingActionButton: FloatingActionButton(
                  tooltip: context.l10n.createValueTooltip,
                  onPressed: () => _createValue(context),
                  heroTag: 'create_value_fab_values',
                  child: const Icon(Icons.add),
                ),
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
                          onRetry: () => context.read<ValuesHeroBloc>().add(
                            const ValuesHeroSubscriptionRequested(),
                          ),
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
                        items: _sortItems(items, _sortOrder),
                      ),
                    };

                    final tokens = TasklyTokens.of(context);

                    return Column(
                      children: [
                        const _ValuesTitleHeader(),
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

  Future<void> _showSortSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text(
                  'Sort by',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              for (final option in ValueSortOrder.values)
                RadioListTile<ValueSortOrder>(
                  value: option,
                  groupValue: _sortOrder,
                  title: Text(option.label),
                  onChanged: (value) {
                    if (value == null) return;
                    _updateSort(value);
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

enum _ValuesMenuAction {
  sortBy,
  selectMultiple,
}

class _ValuesTitleHeader extends StatelessWidget {
  const _ValuesTitleHeader();

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconSet = const NavigationIconResolver().resolve(
      screenId: 'values',
      iconName: null,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.sectionPaddingH,
        tokens.spaceMd,
        tokens.sectionPaddingH,
        tokens.spaceSm,
      ),
      child: Row(
        children: [
          Icon(
            iconSet.selectedIcon,
            color: scheme.primary,
            size: tokens.spaceLg3,
          ),
          SizedBox(width: tokens.spaceSm),
          Text(
            context.l10n.valuesTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

List<ValueHeroStatsItem> _sortItems(
  List<ValueHeroStatsItem> items,
  ValueSortOrder order,
) {
  final sorted = items.toList(growable: false);
  int byName(ValueHeroStatsItem a, ValueHeroStatsItem b) {
    return a.value.name.compareTo(b.value.name);
  }

  int byPriority(ValueHeroStatsItem a, ValueHeroStatsItem b) {
    final byPriority = b.value.priority.weight.compareTo(
      a.value.priority.weight,
    );
    if (byPriority != 0) return byPriority;
    return byName(a, b);
  }

  int byMostActive(ValueHeroStatsItem a, ValueHeroStatsItem b) {
    final byActivity = b.completionCount.compareTo(a.completionCount);
    if (byActivity != 0) return byActivity;
    return byName(a, b);
  }

  sorted.sort(
    switch (order) {
      ValueSortOrder.priority => byPriority,
      ValueSortOrder.alphabetical => byName,
      ValueSortOrder.mostActive => byMostActive,
    },
  );

  return sorted;
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
