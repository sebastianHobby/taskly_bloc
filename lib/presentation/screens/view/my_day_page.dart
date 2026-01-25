import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/review/utils/weekly_review_schedule.dart';
import 'package:taskly_bloc/presentation/features/review/view/weekly_review_modal.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/home_day_service.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_cubit.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/widgets/app_loading_screen.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_bloc/presentation/shared/utils/task_sorting.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/shared/ui/value_chip_data.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/plan_my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/view/plan_my_day_page.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/taskly_domain.dart' show EntityType;
import 'package:taskly_domain/time.dart';
import 'package:taskly_ui/taskly_ui_feed.dart';

enum _MyDayMode { execute, plan }

class MyDayPage extends StatefulWidget {
  const MyDayPage({super.key});

  @override
  State<MyDayPage> createState() => _MyDayPageState();
}

class _MyDayPageState extends State<MyDayPage> {
  _MyDayMode _mode = _MyDayMode.execute;

  Future<void> _openNewTaskEditor(
    BuildContext context, {
    required DateTime defaultDay,
  }) {
    return EditorLauncher.fromGetIt().openTaskEditor(
      context,
      taskId: null,
      showDragHandle: true,
      defaultStartDate: defaultDay,
      defaultDeadlineDate: defaultDay,
    );
  }

  Future<void> _openNewProjectEditor(BuildContext context) {
    return EditorLauncher.fromGetIt().openProjectEditor(
      context,
      projectId: null,
      showDragHandle: true,
    );
  }

  void _enterPlanMode(BuildContext context) {
    context.read<PlanMyDayBloc>().add(const PlanMyDayStarted());

    setState(() {
      _mode = _MyDayMode.plan;
    });
  }

  void _exitPlanMode() {
    setState(() {
      _mode = _MyDayMode.execute;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = getIt<HomeDayService>().todayDayKeyUtc().toLocal();

    return MultiBlocProvider(
      providers: [
        BlocProvider<MyDayGateBloc>(create: (_) => getIt<MyDayGateBloc>()),
        BlocProvider<MyDayBloc>(create: (_) => getIt<MyDayBloc>()),
        BlocProvider<PlanMyDayBloc>(create: (_) => getIt<PlanMyDayBloc>()),
        BlocProvider(create: (_) => SelectionCubit()),
      ],
      child: BlocBuilder<PlanMyDayBloc, PlanMyDayState>(
        builder: (context, _) {
          if (_mode == _MyDayMode.plan) {
            return PlanMyDayPage(
              onCloseRequested: _exitPlanMode,
            );
          }

          return BlocBuilder<SelectionCubit, SelectionState>(
            builder: (context, selectionState) {
              return Scaffold(
                appBar: selectionState.isSelectionMode
                    ? SelectionAppBar(
                        baseTitle: context.l10n.myDayTitle,
                        onExit: () {},
                      )
                    : AppBar(
                        toolbarHeight: 56,
                        title: Text(
                          context.l10n.myDayTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        actions: [
                          IconButton(
                            tooltip: context.l10n.settingsTitle,
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: () =>
                                Routing.toScreenKey(context, 'settings'),
                          ),
                        ],
                      ),
                floatingActionButton: selectionState.isSelectionMode
                    ? null
                    : EntityAddSpeedDial(
                        heroTag: 'add_speed_dial_my_day',
                        onCreateTask: () => _openNewTaskEditor(
                          context,
                          defaultDay: today,
                        ),
                        onCreateProject: () => _openNewProjectEditor(
                          context,
                        ),
                      ),
                body: _MyDayLoadedBody(
                  today: today,
                  onOpenPlan: () => _enterPlanMode(context),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _MyDayLoadedBody extends StatelessWidget {
  const _MyDayLoadedBody({
    required this.today,
    required this.onOpenPlan,
  });

  final DateTime today;
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<GlobalSettingsBloc>().state.settings;
    final nowLocal = getIt<NowService>().nowLocal();
    final reviewReady = isWeeklyReviewReady(settings, nowLocal);
    final showDueSoon = settings.myDayDueSoonEnabled;
    final showPlanned = settings.myDayShowAvailableToStart;

    return BlocBuilder<MyDayBloc, MyDayState>(
      builder: (context, state) {
        return switch (state) {
          MyDayLoading() => Center(
            child: AppLoadingContent(
              title: 'Preparing a calm list for today...',
              subtitle: '',
              icon: Icons.auto_awesome,
            ),
          ),
          MyDayError() => _MyDayErrorState(
            onRetry: () => context.read<MyDayBloc>().add(const MyDayStarted()),
          ),
          MyDayLoaded(
            :final acceptedDue,
            :final acceptedStarts,
            :final acceptedFocus,
            :final pinnedTasks,
          ) =>
            SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                children: [
                  if (reviewReady) ...[
                    _WeeklyReviewBanner(
                      onReview: () => showWeeklyReviewModal(
                        context,
                        settings: settings,
                      ),
                      onSettings: () =>
                          Routing.toScreenKey(context, 'settings'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _MyDayHeaderRow(
                    today: today,
                    showDueSoon: showDueSoon,
                    showPlanned: showPlanned,
                    onUpdatePlan: onOpenPlan,
                  ),
                  const SizedBox(height: 12),
                  _MyDayTaskList(
                    today: today,
                    acceptedDue: acceptedDue,
                    acceptedStarts: acceptedStarts,
                    acceptedFocus: acceptedFocus,
                    pinnedTasks: pinnedTasks,
                  ),
                ],
              ),
            ),
        };
      },
    );
  }
}

class _MyDayHeaderRow extends StatelessWidget {
  const _MyDayHeaderRow({
    required this.today,
    required this.showDueSoon,
    required this.showPlanned,
    required this.onUpdatePlan,
  });

  final DateTime today;
  final bool showDueSoon;
  final bool showPlanned;
  final VoidCallback onUpdatePlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateLabel = DateFormat('EEE, d MMM', locale).format(today);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                dateLabel,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: onUpdatePlan,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(l10n.myDayUpdatePlanTitle),
            ),
          ],
        ),
      ],
    );
  }
}

class _MyDayTaskList extends StatefulWidget {
  const _MyDayTaskList({
    required this.today,
    required this.acceptedDue,
    required this.acceptedStarts,
    required this.acceptedFocus,
    required this.pinnedTasks,
  });

  final DateTime today;
  final List<Task> acceptedDue;
  final List<Task> acceptedStarts;
  final List<Task> acceptedFocus;
  final List<Task> pinnedTasks;

  @override
  State<_MyDayTaskList> createState() => _MyDayTaskListState();
}

class _MyDayTaskListState extends State<_MyDayTaskList> {
  final Set<String> _collapsedValueKeys = <String>{};

  void _toggleValueCollapsed(String key) {
    setState(() {
      if (!_collapsedValueKeys.add(key)) {
        _collapsedValueKeys.remove(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selection = context.read<SelectionCubit>();
    final todayDate = dateOnly(widget.today);

    final merged = _mergeMyDayTasks(
      acceptedDue: widget.acceptedDue,
      acceptedStarts: widget.acceptedStarts,
      acceptedFocus: widget.acceptedFocus,
      pinnedTasks: widget.pinnedTasks,
    );

    final sorted = sortTasksByDeadlineThenStartThenPriorityThenName(
      merged,
      today: todayDate,
    );

    if (sorted.isEmpty) {
      return TasklyFeedRenderer(
        spec: TasklyFeedSpec.empty(
          empty: TasklyEmptyStateSpec(
            icon: Icons.check_circle_outline,
            title: 'All clear for today.',
            description:
                'Nothing scheduled right now. If you want, you can add something small.',
          ),
        ),
      );
    }

    _registerVisibleTasks(selection, sorted);

    final valueGroups = <String, _MyDayValueGroup>{};

    void ensureGroup(String key, Value? value) {
      valueGroups.putIfAbsent(
        key,
        () => _MyDayValueGroup(valueId: value?.id, value: value),
      );
    }

    for (final task in sorted) {
      final value = task.effectivePrimaryValue;
      final key = _myDayValueKey(value?.id);
      ensureGroup(key, value);
      valueGroups[key]!.tasks.add(task);
    }

    final groups = valueGroups.values.toList(growable: false)
      ..sort(_compareMyDayValueGroups);

    final groupedRows = <TasklyRowSpec>[];

    for (final group in groups) {
      final key = _myDayValueKey(group.valueId);
      final value = group.value;
      final chip =
          value?.toChipData(context) ?? _myDayMissingValueChip(context);
      final valueName = value?.name.trim();
      final headerTitle = (valueName?.isNotEmpty ?? false)
          ? valueName!
          : context.l10n.valueMissingLabel;
      final priorityLabel = _valuePriorityLabel(context, value?.priority);
      final countLabel = group.tasks.length.toString();
      final isCollapsed = _collapsedValueKeys.contains(key);

      groupedRows.add(
        TasklyRowSpec.valueHeader(
          key: 'myday-value-$key',
          depth: 0,
          title: headerTitle,
          leadingChip: chip,
          trailingLabel: countLabel,
          priorityLabel: priorityLabel,
          isCollapsed: isCollapsed,
          onToggleCollapsed: () => _toggleValueCollapsed(key),
        ),
      );

      groupedRows.addAll(
        _buildRows(
          context,
          group.tasks,
          depthOffset: 1,
        ),
      );
    }

    return TasklyFeedRenderer.buildSection(
      TasklySectionSpec.standardList(
        id: 'myday-execute',
        rows: groupedRows,
      ),
    );
  }
}

class _MyDayErrorState extends StatelessWidget {
  const _MyDayErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't load your list.",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your tasks are safe. Please try again.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
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

class _WeeklyReviewBanner extends StatelessWidget {
  const _WeeklyReviewBanner({
    required this.onReview,
    required this.onSettings,
  });

  final VoidCallback onReview;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onReview,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: scheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Weekly review is ready. Take 3 minutes to reset.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onSettings,
                child: Text(l10n.settingsTitle),
              ),
              TextButton(
                onPressed: onReview,
                child: const Text('Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<Task> _mergeMyDayTasks({
  required List<Task> acceptedDue,
  required List<Task> acceptedStarts,
  required List<Task> acceptedFocus,
  required List<Task> pinnedTasks,
}) {
  final byId = <String, Task>{};
  final all = [
    ...acceptedDue,
    ...acceptedStarts,
    ...acceptedFocus,
    ...pinnedTasks,
  ];

  for (final task in all) {
    if (task.completed) continue;
    byId.putIfAbsent(task.id, () => task);
  }

  return byId.values.toList(growable: false);
}

void _registerVisibleTasks(
  SelectionCubit selection,
  List<Task> tasks,
) {
  selection.updateVisibleEntities(
    tasks
        .map(
          (task) => SelectionEntityMeta(
            key: SelectionKey(
              entityType: EntityType.task,
              entityId: task.id,
            ),
            displayName: task.name,
            canDelete: true,
            completed: task.completed,
            pinned: task.isPinned,
            canCompleteSeries: task.isRepeating && !task.seriesEnded,
          ),
        )
        .toList(growable: false),
  );
}

String _myDayValueKey(String? valueId) {
  final trimmed = valueId?.trim();
  if (trimmed == null || trimmed.isEmpty) return '_myday_value_none';
  return trimmed;
}

ValueChipData _myDayMissingValueChip(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final l10n = context.l10n;

  return ValueChipData(
    label: l10n.valueMissingLabel,
    color: scheme.primary,
    icon: Icons.star_border,
    semanticLabel: l10n.valueMissingLabel,
  );
}

String? _valuePriorityLabel(BuildContext context, ValuePriority? priority) {
  return switch (priority) {
    ValuePriority.high => context.l10n.valuePriorityHighLabel,
    ValuePriority.medium => context.l10n.valuePriorityMediumLabel,
    ValuePriority.low => context.l10n.valuePriorityLowLabel,
    null => null,
  };
}

class _MyDayValueGroup {
  _MyDayValueGroup({
    required this.valueId,
    required this.value,
  });

  final String? valueId;
  final Value? value;
  final List<Task> tasks = <Task>[];
}

int _compareMyDayValueGroups(_MyDayValueGroup a, _MyDayValueGroup b) {
  final rankA = _valuePriorityRank(a.value?.priority ?? ValuePriority.medium);
  final rankB = _valuePriorityRank(b.value?.priority ?? ValuePriority.medium);
  if (rankA != rankB) return rankA.compareTo(rankB);
  final aName = (a.value?.name ?? '').toLowerCase();
  final bName = (b.value?.name ?? '').toLowerCase();
  return aName.compareTo(bName);
}

int _valuePriorityRank(ValuePriority priority) {
  return switch (priority) {
    ValuePriority.high => 0,
    ValuePriority.medium => 1,
    ValuePriority.low => 2,
  };
}

List<TasklyRowSpec> _buildRows(
  BuildContext context,
  List<Task> tasks, {
  int depthOffset = 0,
}) {
  final selection = context.read<SelectionCubit>();
  final selectionMode = selection.isSelectionMode;

  return tasks
      .map((task) {
        final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);
        final key = SelectionKey(
          entityType: EntityType.task,
          entityId: task.id,
        );
        final isSelected = selection.isSelected(key);

        final data = buildTaskRowData(
          context,
          task: task,
          tileCapabilities: tileCapabilities,
        );

        final labels = TasklyTaskRowLabels(
          pinnedSemanticLabel: context.l10n.pinnedSemanticLabel,
        );

        final updatedData = TasklyTaskRowData(
          id: data.id,
          title: data.title,
          completed: data.completed,
          meta: data.meta,
          leadingChip: data.leadingChip,
          secondaryChips: data.secondaryChips,
          deemphasized: data.deemphasized,
          checkboxSemanticLabel: data.checkboxSemanticLabel,
          labels: labels,
          pinned: task.isPinned,
        );

        return TasklyRowSpec.task(
          key: 'myday-accepted-${task.id}',
          data: updatedData,
          depth: depthOffset,
          style: selectionMode
              ? TasklyTaskRowStyle.bulkSelection(selected: isSelected)
              : const TasklyTaskRowStyle.standard(),
          actions: TasklyTaskRowActions(
            onTap: () {
              if (selection.shouldInterceptTapAsSelection()) {
                selection.handleEntityTap(key);
                return;
              }
              buildTaskOpenEditorHandler(context, task: task)();
            },
            onLongPress: () {
              selection.enterSelectionMode(initialSelection: key);
            },
            onToggleSelected: () => selection.toggleSelection(
              key,
              extendRange: false,
            ),
            onToggleCompletion: buildTaskToggleCompletionHandler(
              context,
              task: task,
              tileCapabilities: tileCapabilities,
            ),
          ),
        );
      })
      .toList(growable: false);
}
