import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/review/utils/weekly_review_schedule.dart';
import 'package:taskly_bloc/presentation/features/review/view/weekly_review_modal.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
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
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_ritual_bloc.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_ritual_wizard_page.dart';
import 'package:taskly_bloc/presentation/screens/widgets/my_day_suggestion_settings_sheet.dart';
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
  MyDayRitualWizardInitialSection? _planInitialSection;

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

  void _enterPlanMode(
    BuildContext context, {
    MyDayRitualWizardInitialSection? initialSection,
  }) {
    context.read<MyDayRitualBloc>().add(const MyDayRitualStarted());

    setState(() {
      _mode = _MyDayMode.plan;
      _planInitialSection = initialSection;
    });
  }

  void _exitPlanMode() {
    setState(() {
      _mode = _MyDayMode.execute;
      _planInitialSection = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = getIt<HomeDayService>().todayDayKeyUtc().toLocal();

    return MultiBlocProvider(
      providers: [
        BlocProvider<MyDayGateBloc>(create: (_) => getIt<MyDayGateBloc>()),
        BlocProvider<MyDayBloc>(create: (_) => getIt<MyDayBloc>()),
        BlocProvider<MyDayRitualBloc>(create: (_) => getIt<MyDayRitualBloc>()),
        BlocProvider(create: (_) => SelectionCubit()),
      ],
      child: BlocBuilder<MyDayRitualBloc, MyDayRitualState>(
        builder: (context, ritualState) {
          final needsRitual =
              ritualState is MyDayRitualReady && ritualState.needsRitual;
          final ritualReady = ritualState is MyDayRitualReady
              ? ritualState
              : null;
          final suggestionSettingsEnabled = ritualReady != null;

          final effectiveMode = needsRitual ? _MyDayMode.plan : _mode;

          if (effectiveMode == _MyDayMode.plan) {
            return MyDayRitualWizardPage(
              allowClose: !needsRitual,
              initialSection: _planInitialSection,
              onCloseRequested: _exitPlanMode,
            );
          }

          if (ritualState is MyDayRitualLoading) {
            return AppLoadingScreen(
              appBarTitle: context.l10n.myDayTitle,
              title: 'Preparing a calm list for today...',
              subtitle: '',
              icon: Icons.auto_awesome,
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
                            tooltip: context.l10n.myDaySuggestionSettingsTitle,
                            icon: const Icon(Icons.settings_outlined),
                            onPressed: !suggestionSettingsEnabled
                                ? null
                                : () => openSuggestionSettingsSheet(
                                    context,
                                    dueWindowDays: ritualReady.dueWindowDays,
                                    showAvailableToStart:
                                        ritualReady.showAvailableToStart,
                                  ),
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
                  onOpenPlan: (initialSection) => _enterPlanMode(
                    context,
                    initialSection: initialSection,
                  ),
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
  final void Function(MyDayRitualWizardInitialSection? initialSection)
  onOpenPlan;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<GlobalSettingsBloc>().state.settings;
    final nowLocal = getIt<NowService>().nowLocal();
    final reviewReady = isWeeklyReviewReady(settings, nowLocal);

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
                    ),
                    const SizedBox(height: 12),
                  ],
                  _MyDayHeaderRow(
                    onUpdatePlan: () => onOpenPlan(null),
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
    required this.onUpdatePlan,
  });

  final VoidCallback onUpdatePlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today, aligned with your values.',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Here's what supports what matters.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.tonal(
          onPressed: onUpdatePlan,
          style: FilledButton.styleFrom(
            backgroundColor: cs.primaryContainer.withOpacity(0.6),
            foregroundColor: cs.primary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(context.l10n.myDayUpdatePlanTitle),
        ),
      ],
    );
  }
}

class _MyDayTaskList extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final selection = context.read<SelectionCubit>();
    final todayDate = dateOnly(today);

    final merged = _mergeMyDayTasks(
      acceptedDue: acceptedDue,
      acceptedStarts: acceptedStarts,
      acceptedFocus: acceptedFocus,
      pinnedTasks: pinnedTasks,
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

    final rows = _buildRows(context, sorted);

    return TasklyFeedRenderer.buildSection(
      TasklySectionSpec.standardList(
        id: 'myday-execute',
        rows: rows,
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
  const _WeeklyReviewBanner({required this.onReview});

  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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

List<TasklyRowSpec> _buildRows(
  BuildContext context,
  List<Task> tasks,
) {
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
          supportingText: null,
          supportingTooltipText: null,
          deemphasized: data.deemphasized,
          checkboxSemanticLabel: data.checkboxSemanticLabel,
          labels: labels,
        );

        return TasklyRowSpec.task(
          key: 'myday-accepted-${task.id}',
          data: updatedData,
          preset: selectionMode
              ? TasklyTaskRowPreset.bulkSelection(selected: isSelected)
              : const TasklyTaskRowPreset.standard(),
          markers: TasklyTaskRowMarkers(
            pinned: task.isPinned,
          ),
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
