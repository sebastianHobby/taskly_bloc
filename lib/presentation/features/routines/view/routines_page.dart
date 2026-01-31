import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/routines/bloc/routine_list_bloc.dart';
import 'package:taskly_bloc/presentation/features/routines/model/routine_sort_order.dart';
import 'package:taskly_bloc/presentation/features/routines/model/routine_list_item.dart';
import 'package:taskly_bloc/presentation/features/routines/selection/routine_selection_app_bar.dart';
import 'package:taskly_bloc/presentation/features/routines/selection/routine_selection_bloc.dart';
import 'package:taskly_bloc/presentation/features/routines/selection/routine_selection_models.dart';
import 'package:taskly_bloc/presentation/features/routines/widgets/routines_list.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_overflow_menu.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class RoutinesPage extends StatefulWidget {
  const RoutinesPage({super.key});

  @override
  State<RoutinesPage> createState() => _RoutinesPageState();
}

class _RoutinesPageState extends State<RoutinesPage> {
  RoutineSortOrder _sortOrder = RoutineSortOrder.scheduledFirst;
  bool _showInactive = false;

  void _createRoutine(BuildContext context) {
    Routing.toRoutineNew(context);
  }

  void _editRoutine(BuildContext context, String routineId) {
    Routing.toRoutineEdit(context, routineId);
  }

  void _toggleShowInactive() {
    setState(() => _showInactive = !_showInactive);
  }

  Future<void> _showFilterSheet({
    required List<Value> values,
    required List<RoutineListItem> routines,
  }) async {
    final sortedValues = values.toList(growable: false)..sort(_compareValues);
    final counts = _countRoutinesByValue(routines);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final tokens = TasklyTokens.of(sheetContext);
        final scheme = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceLg,
              tokens.spaceSm,
              tokens.spaceLg,
              tokens.spaceLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter & sort',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                SizedBox(height: tokens.spaceSm),
                Text(
                  'Sort',
                  style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                for (final order in RoutineSortOrder.values)
                  RadioListTile<RoutineSortOrder>(
                    value: order,
                    groupValue: _sortOrder,
                    title: Text(order.label),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _sortOrder = value);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                SizedBox(height: tokens.spaceSm),
                Text(
                  'Values',
                  style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: tokens.spaceSm),
                BlocSelector<RoutineListBloc, RoutineListState, String?>(
                  selector: (state) => switch (state) {
                    RoutineListLoaded(:final selectedValueId) =>
                      selectedValueId,
                    _ => null,
                  },
                  builder: (context, selectedValueId) {
                    return Wrap(
                      spacing: tokens.spaceSm,
                      runSpacing: tokens.spaceSm,
                      children: [
                        _RoutineValueFilterChip(
                          label: 'All values',
                          count: counts.total,
                          selected: selectedValueId == null,
                          icon: Icons.filter_list_rounded,
                          iconColor: scheme.onSurfaceVariant,
                          onTap: () {
                            if (selectedValueId == null) return;
                            context.read<RoutineListBloc>().add(
                              const RoutineListEvent.valueFilterChanged(),
                            );
                          },
                        ),
                        for (final value in sortedValues) ...[
                          Builder(
                            builder: (context) {
                              final chip = value.toChipData(sheetContext);
                              return _RoutineValueFilterChip(
                                label: chip.label,
                                count: counts.byValueId[value.id],
                                selected: value.id == selectedValueId,
                                icon: chip.icon,
                                iconColor: chip.color,
                                tintColor: chip.color,
                                onTap: () {
                                  if (value.id == selectedValueId) return;
                                  context.read<RoutineListBloc>().add(
                                    RoutineListEvent.valueFilterChanged(
                                      valueId: value.id,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ],
                    );
                  },
                ),
                SizedBox(height: tokens.spaceSm),
                SwitchListTile(
                  title: const Text('Show inactive'),
                  value: _showInactive,
                  onChanged: (_) {
                    _toggleShowInactive();
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RoutineListBloc>(
          create: (context) => RoutineListBloc(
            routineRepository: context.read<RoutineRepositoryContract>(),
            sessionDayKeyService: context.read<SessionDayKeyService>(),
            errorReporter: context.read<AppErrorReporter>(),
            sharedDataService: context.read<SessionSharedDataService>(),
            routineWriteService: context.read<RoutineWriteService>(),
            nowService: context.read<NowService>(),
          )..add(const RoutineListEvent.subscriptionRequested()),
        ),
        BlocProvider(create: (_) => RoutineSelectionBloc()),
      ],
      child: Builder(
        builder: (context) {
          return BlocBuilder<RoutineSelectionBloc, RoutineSelectionState>(
            builder: (context, selectionState) {
              return Scaffold(
                appBar: selectionState.isSelectionMode
                    ? RoutineSelectionAppBar(
                        baseTitle: context.l10n.routinesTitle,
                        onExit: () {},
                      )
                    : AppBar(
                        actions: TasklyAppBarActions.withAttentionBell(
                          context,
                          actions: [
                            IconButton(
                              tooltip: 'Filter & sort',
                              onPressed: () {
                                final state = context
                                    .read<RoutineListBloc>()
                                    .state;
                                if (state is! RoutineListLoaded) return;
                                _showFilterSheet(
                                  values: state.values,
                                  routines: state.routines,
                                );
                              },
                              icon: const Icon(Icons.tune_rounded),
                            ),
                            TasklyOverflowMenuButton<_RoutinesMenuAction>(
                              tooltip: 'More',
                              itemsBuilder: (context) => [
                                const PopupMenuItem(
                                  value: _RoutinesMenuAction.selectMultiple,
                                  child: Text('Select multiple'),
                                ),
                              ],
                              onSelected: (action) {
                                switch (action) {
                                  case _RoutinesMenuAction.selectMultiple:
                                    context
                                        .read<RoutineSelectionBloc>()
                                        .enterSelectionMode();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                floatingActionButton: EntityAddFab(
                  tooltip: context.l10n.routineCreateTooltip,
                  onPressed: () => _createRoutine(context),
                  heroTag: 'create_routine_fab',
                ),
                body: Column(
                  children: [
                    const _RoutinesTitleHeader(),
                    Expanded(
                      child: BlocBuilder<RoutineListBloc, RoutineListState>(
                        builder: (context, state) {
                          return switch (state) {
                            RoutineListInitial() ||
                            RoutineListLoading() => const TasklyFeedRenderer(
                              spec: TasklyFeedSpec.loading(),
                            ),
                            RoutineListError(:final error) => TasklyFeedRenderer(
                              spec: TasklyFeedSpec.error(
                                message: friendlyErrorMessageForUi(
                                  error,
                                  context.l10n,
                                ),
                                retryLabel: context.l10n.retryButton,
                                onRetry: () => context.read<RoutineListBloc>().add(
                                  const RoutineListEvent.subscriptionRequested(),
                                ),
                              ),
                            ),
                            RoutineListLoaded(:final routines)
                                when routines.isEmpty =>
                              TasklyFeedRenderer(
                                spec: TasklyFeedSpec.empty(
                                  empty: TasklyEmptyStateSpec(
                                    icon: Icons.auto_awesome,
                                    title: context.l10n.routineEmptyTitle,
                                    description:
                                        context.l10n.routineEmptyDescription,
                                    actionLabel: context.l10n.routineCreateCta,
                                    onAction: () => _createRoutine(context),
                                  ),
                                ),
                              ),
                            RoutineListLoaded(
                              :final routines,
                              :final selectedValueId,
                            ) =>
                              _RoutinesFilterLayout(
                                routines: routines,
                                selectedValueId: selectedValueId,
                                showInactive: _showInactive,
                                sortOrder: _sortOrder,
                                onEditRoutine: (id) =>
                                    _editRoutine(context, id),
                                onLogRoutine: (id) =>
                                    context.read<RoutineListBloc>().add(
                                      RoutineListEvent.logRequested(
                                        routineId: id,
                                      ),
                                    ),
                              ),
                          };
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

enum _RoutinesMenuAction { selectMultiple }

class _RoutinesFilterLayout extends StatelessWidget {
  const _RoutinesFilterLayout({
    required this.routines,
    required this.selectedValueId,
    required this.showInactive,
    required this.sortOrder,
    required this.onEditRoutine,
    required this.onLogRoutine,
  });

  final List<RoutineListItem> routines;
  final String? selectedValueId;
  final bool showInactive;
  final RoutineSortOrder sortOrder;
  final ValueChanged<String> onEditRoutine;
  final ValueChanged<String> onLogRoutine;

  @override
  Widget build(BuildContext context) {
    final filteredByValue = _filterRoutinesByValue(routines, selectedValueId);
    final filtered = showInactive
        ? filteredByValue
        : filteredByValue
              .where((item) => item.routine.isActive)
              .toList(growable: false);

    return RoutinesListView(
      items: filtered,
      sortOrder: sortOrder,
      onEditRoutine: onEditRoutine,
      onLogRoutine: onLogRoutine,
    );
  }
}

class _RoutineValueFilterChip extends StatelessWidget {
  const _RoutineValueFilterChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.tintColor,
    this.count,
  });

  final String label;
  final int? count;
  final bool selected;
  final IconData icon;
  final Color iconColor;
  final Color? tintColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;

    final baseBg = selected
        ? scheme.primaryContainer
        : scheme.surfaceContainerLow;
    final tintAlpha = selected ? 0.16 : 0.12;
    final bg = tintColor == null
        ? baseBg
        : Color.alphaBlend(tintColor!.withValues(alpha: tintAlpha), baseBg);
    final fg = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    final border = selected
        ? scheme.primary.withValues(alpha: 0.28)
        : scheme.outlineVariant.withValues(alpha: 0.7);

    final textStyle =
        Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 12);
    const visualHeight = 30.0;

    return InkWell(
      borderRadius: BorderRadius.circular(tokens.radiusPill),
      onTap: onTap,
      child: SizedBox(
        height: tokens.minTapTargetSize,
        child: Center(
          child: Container(
            height: visualHeight,
            padding: EdgeInsets.symmetric(horizontal: tokens.spaceSm),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(tokens.radiusPill),
              border: Border.all(color: border),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: tokens.filterPillIconSize - 2,
                  color: iconColor,
                ),
                SizedBox(width: tokens.spaceXxs2),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: label),
                      if (count != null && count! > 0)
                        TextSpan(
                          text: ' \u00b7 $count',
                          style: textStyle.copyWith(
                            color: fg.withValues(alpha: 0.7),
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                if (selected) ...[
                  SizedBox(width: tokens.spaceXxs2),
                  Icon(Icons.check_rounded, size: 12, color: fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

_RoutineValueCounts _countRoutinesByValue(List<RoutineListItem> routines) {
  final total = routines.length;
  final byValueId = <String, int>{};
  for (final item in routines) {
    final valueId = item.routine.valueId.trim();
    if (valueId.isEmpty) continue;
    byValueId[valueId] = (byValueId[valueId] ?? 0) + 1;
  }
  return _RoutineValueCounts(total: total, byValueId: byValueId);
}

List<RoutineListItem> _filterRoutinesByValue(
  List<RoutineListItem> routines,
  String? selectedValueId,
) {
  final id = selectedValueId?.trim();
  if (id == null || id.isEmpty) return routines;
  return routines
      .where((item) => item.routine.valueId == id)
      .toList(growable: false);
}

int _compareValues(Value a, Value b) {
  final ap = a.priority;
  final bp = b.priority;
  final byPriority = _priorityRank(ap).compareTo(_priorityRank(bp));
  if (byPriority != 0) return byPriority;

  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

int _priorityRank(ValuePriority priority) {
  return switch (priority) {
    ValuePriority.high => 0,
    ValuePriority.medium => 1,
    ValuePriority.low => 2,
  };
}

class _RoutineValueCounts {
  const _RoutineValueCounts({required this.total, required this.byValueId});

  final int total;
  final Map<String, int> byValueId;
}

class _RoutinesTitleHeader extends StatelessWidget {
  const _RoutinesTitleHeader();

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconSet = const NavigationIconResolver().resolve(
      screenId: 'routines',
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
            context.l10n.routinesTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
