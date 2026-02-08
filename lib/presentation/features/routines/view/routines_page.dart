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
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_overflow_menu.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_bloc/presentation/shared/widgets/display_density_toggle.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_bloc/presentation/shared/widgets/filter_sort_sheet.dart';
import 'package:taskly_bloc/presentation/shared/bloc/display_density_bloc.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/preferences.dart';
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

  Future<void> _showFilterSheet(
    BuildContext sheetContext, {
    required List<Value> values,
    required List<RoutineListItem> routines,
    required DisplayDensity density,
  }) async {
    final routineListBloc = sheetContext.read<RoutineListBloc>();
    final sortedValues = values.toList(growable: false)..sort(_compareValues);
    final counts = _countRoutinesByValue(routines);
    await showFilterSortSheet(
      context: sheetContext,
      sortGroups: [
        FilterSortRadioGroup(
          title: 'Sort',
          options: [
            for (final order in RoutineSortOrder.values)
              FilterSortRadioOption(value: order, label: order.label),
          ],
          selectedValue: _sortOrder,
          onSelected: (value) {
            if (value is! RoutineSortOrder) return;
            setState(() => _sortOrder = value);
          },
        ),
      ],
      sections: [
        FilterSortSection(
          title: 'View',
          child: Builder(
            builder: (sectionContext) {
              return DisplayDensityToggle(
                density: density,
                onChanged: (next) {
                  if (next == density) return;
                  sheetContext.read<DisplayDensityBloc>().add(
                    DisplayDensitySet(next),
                  );
                  Navigator.of(sectionContext).pop();
                },
              );
            },
          ),
        ),
        FilterSortSection(
          title: 'Values',
          child: BlocProvider.value(
            value: routineListBloc,
            child: BlocSelector<RoutineListBloc, RoutineListState, String?>(
              selector: (state) => switch (state) {
                RoutineListLoaded(:final selectedValueId) => selectedValueId,
                _ => null,
              },
              builder: (context, selectedValueId) {
                final scheme = Theme.of(context).colorScheme;
                return Column(
                  children: [
                    _RoutineValueFilterRow(
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
                          final chip = value.toChipData(context);
                          return _RoutineValueFilterRow(
                            label: chip.label,
                            count: counts.byValueId[value.id],
                            selected: value.id == selectedValueId,
                            icon: chip.icon,
                            iconColor: chip.color,
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
          ),
        ),
      ],
      toggles: [
        FilterSortToggle(
          title: 'Show inactive',
          value: _showInactive,
          onChanged: (_) => _toggleShowInactive(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompactScreen = Breakpoints.isCompact(
      MediaQuery.sizeOf(context).width,
    );
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
        BlocProvider(
          create: (context) => DisplayDensityBloc(
            settingsRepository: context.read<SettingsRepositoryContract>(),
            pageKey: PageKey.routines,
            defaultDensity: isCompactScreen
                ? DisplayDensity.compact
                : DisplayDensity.standard,
          )..add(const DisplayDensityStarted()),
        ),
        BlocProvider(create: (_) => RoutineSelectionBloc()),
      ],
      child: Builder(
        builder: (context) {
          return BlocBuilder<RoutineSelectionBloc, RoutineSelectionState>(
            builder: (context, selectionState) {
              final density = context.select(
                (DisplayDensityBloc bloc) => bloc.state.density,
              );
              return Scaffold(
                appBar: selectionState.isSelectionMode
                    ? RoutineSelectionAppBar(
                        baseTitle: context.l10n.routinesTitle,
                        onExit: () {},
                      )
                    : AppBar(
                        actions: [
                          IconButton(
                            tooltip: 'Filter & sort',
                            onPressed: () {
                              final state = context
                                  .read<RoutineListBloc>()
                                  .state;
                              if (state is! RoutineListLoaded) return;
                              _showFilterSheet(
                                context,
                                values: state.values,
                                routines: state.routines,
                                density: density,
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
                                density: density,
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
    required this.density,
    required this.onEditRoutine,
    required this.onLogRoutine,
  });

  final List<RoutineListItem> routines;
  final String? selectedValueId;
  final bool showInactive;
  final RoutineSortOrder sortOrder;
  final DisplayDensity density;
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
      density: density,
      onEditRoutine: onEditRoutine,
      onLogRoutine: onLogRoutine,
    );
  }
}

class _RoutineValueFilterRow extends StatelessWidget {
  const _RoutineValueFilterRow({
    required this.label,
    required this.selected,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.count,
  });

  final String label;
  final int? count;
  final bool selected;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    final countLabel = count == null ? null : '$count';

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Icon(icon, color: iconColor),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: fg,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (countLabel != null)
            Text(
              countLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (selected) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_rounded, size: 18, color: scheme.primary),
          ],
        ],
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
