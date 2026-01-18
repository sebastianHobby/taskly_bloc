import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/taskly_domain.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/project_tile_mapper.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/entity_tiles/widgets/widgets.dart';
import 'package:taskly_bloc/presentation/features/scheduled/bloc/scheduled_feed_bloc.dart';
import 'package:taskly_bloc/presentation/features/scheduled/bloc/scheduled_screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/scheduled/view/scheduled_scope_header.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/services/time/home_day_service.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_ui/taskly_ui.dart';

class ScheduledPage extends StatelessWidget {
  const ScheduledPage({super.key, this.scope = const GlobalScheduledScope()});

  final ScheduledScope scope;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ScheduledScreenBloc()),
        BlocProvider(
          create: (_) => ScheduledFeedBloc(
            scheduledOccurrencesService: getIt(),
            homeDayService: getIt(),
            scope: scope,
          ),
        ),
      ],
      child: _ScheduledView(scope: scope),
    );
  }
}

class _ScheduledView extends StatefulWidget {
  const _ScheduledView({required this.scope});

  final ScheduledScope scope;

  @override
  State<_ScheduledView> createState() => _ScheduledViewState();
}

class _ScheduledViewState extends State<_ScheduledView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _todayHeaderKey = GlobalKey(debugLabel: 'scheduled_today');
  int _lastScrollToTodaySignal = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTodayIfPresent() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _todayHeaderKey.currentContext;
      if (ctx == null) return;

      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        alignment: 0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final showScopeHeader = scope is! GlobalScheduledScope;
    final isCompact = WindowSizeClass.of(context).isCompact;
    final todayUtc = getIt<HomeDayService>().todayDayKeyUtc();
    final today = DateTime(todayUtc.year, todayUtc.month, todayUtc.day);

    return MultiBlocListener(
      listeners: [
        BlocListener<ScheduledFeedBloc, ScheduledFeedState>(
          listenWhen: (previous, current) => current is ScheduledFeedLoaded,
          listener: (context, state) {
            if (state is! ScheduledFeedLoaded) return;
            if (state.scrollToTodaySignal == _lastScrollToTodaySignal) return;
            _lastScrollToTodaySignal = state.scrollToTodaySignal;
            _scrollToTodayIfPresent();
          },
        ),
        BlocListener<ScheduledScreenBloc, ScheduledScreenState>(
          listenWhen: (prev, next) => prev.effect != next.effect,
          listener: (context, state) async {
            final effect = state.effect;
            if (effect == null) return;

            switch (effect) {
              case ScheduledOpenTaskNew(:final defaultDeadlineDay):
                await EditorLauncher.fromGetIt().openTaskEditor(
                  context,
                  taskId: null,
                  defaultDeadlineDate: defaultDeadlineDay,
                  showDragHandle: true,
                );
              case ScheduledOpenProjectNew():
                await EditorLauncher.fromGetIt().openProjectEditor(
                  context,
                  projectId: null,
                  showDragHandle: true,
                );
            }

            if (context.mounted) {
              context.read<ScheduledScreenBloc>().add(
                const ScheduledEffectHandled(),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scheduled'),
          actions: TasklyAppBarActions.withAttentionBell(
            context,
            actions: [
              if (!isCompact)
                EntityAddMenuButton(
                  onCreateTask: () => context.read<ScheduledScreenBloc>().add(
                    ScheduledCreateTaskForDayRequested(day: today),
                  ),
                  onCreateProject: () =>
                      context.read<ScheduledScreenBloc>().add(
                        const ScheduledCreateProjectRequested(),
                      ),
                ),
              IconButton(
                tooltip: 'Jump to today',
                icon: const Icon(Icons.today),
                onPressed: () {
                  context.read<ScheduledFeedBloc>().add(
                    const ScheduledJumpToTodayRequested(),
                  );
                },
              ),
            ],
          ),
        ),
        floatingActionButton: isCompact
            ? EntityAddSpeedDial(
                heroTag: 'add_speed_dial_scheduled',
                onCreateTask: () => context.read<ScheduledScreenBloc>().add(
                  ScheduledCreateTaskForDayRequested(day: today),
                ),
                onCreateProject: () => context.read<ScheduledScreenBloc>().add(
                  const ScheduledCreateProjectRequested(),
                ),
              )
            : null,
        body: BlocBuilder<ScheduledFeedBloc, ScheduledFeedState>(
          builder: (context, state) {
            final feed = switch (state) {
              ScheduledFeedLoading() => const FeedBody.loading(),
              ScheduledFeedError(:final message) => FeedBody.error(
                message: message,
                retryLabel: context.l10n.retryButton,
                onRetry: () => context.read<ScheduledFeedBloc>().add(
                  const ScheduledFeedRetryRequested(),
                ),
              ),
              ScheduledFeedLoaded(:final rows) when rows.isEmpty =>
                FeedBody.empty(
                  child: EmptyStateWidget.noTasks(
                    title: 'Nothing scheduled',
                    description:
                        'Add start dates or deadlines to see items here.',
                  ),
                ),
              ScheduledFeedLoaded(:final rows) => FeedBody.list(
                controller: _scrollController,
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];

                  final child = _ScheduledRow(row: row);
                  final withTodayKey =
                      row is DateHeaderRowUiModel && _isSameDay(row.date, today)
                      ? KeyedSubtree(key: _todayHeaderKey, child: child)
                      : child;

                  return KeyedSubtree(
                    key: ValueKey(row.rowKey),
                    child: withTodayKey,
                  );
                },
              ),
            };

            if (!showScopeHeader) return feed;

            return Column(
              children: [
                ScheduledScopeHeader(scope: scope),
                Expanded(child: feed),
              ],
            );
          },
        ),
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class _ScheduledRow extends StatelessWidget {
  const _ScheduledRow({required this.row});

  final ListRowUiModel row;

  @override
  Widget build(BuildContext context) {
    return switch (row) {
      BucketHeaderRowUiModel(
        :final bucketKey,
        :final title,
        :final isCollapsed,
      ) =>
        InkWell(
          onTap: () => context.read<ScheduledFeedBloc>().add(
            ScheduledBucketCollapseToggled(bucketKey: bucketKey),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(
                  isCollapsed ? Icons.chevron_right : Icons.expand_more,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      DateHeaderRowUiModel(:final title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      EmptyDayRowUiModel() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Text(
          'No items',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
      ScheduledEntityRowUiModel(:final occurrence) => _ScheduledOccurrenceTile(
        occurrence: occurrence,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _ScheduledOccurrenceTile extends StatelessWidget {
  const _ScheduledOccurrenceTile({required this.occurrence});

  final ScheduledOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final isOngoing = occurrence.ref.tag == ScheduledDateTag.ongoing;

    if (occurrence.ref.entityType == EntityType.task &&
        occurrence.task != null) {
      final task = occurrence.task!;

      final tileCapabilities = EntityTileCapabilitiesResolver.forTask(task);

      return TaskListRowTile(
        model: buildTaskListRowTileModel(
          context,
          task: task,
          tileCapabilities: tileCapabilities,
        ),
        onTap: () => Routing.toTaskEdit(context, task.id),
        onToggleCompletion: buildTaskToggleCompletionHandler(
          context,
          task: task,
          tileCapabilities: tileCapabilities,
        ),
        trailing: TaskTodayStatusMenuButton(
          taskId: task.id,
          taskName: task.name,
          isPinnedToMyDay: task.isPinned,
          isInMyDayAuto: false,
          isRepeating: task.isRepeating,
          seriesEnded: task.seriesEnded,
          tileCapabilities: tileCapabilities,
          compact: true,
        ),
        statusBadge: isOngoing
            ? TasklyBadge(
                label: 'Ongoing',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                isOutlined: true,
              )
            : null,
      );
    }

    if (occurrence.ref.entityType == EntityType.project &&
        occurrence.project != null) {
      final project = occurrence.project!;

      final tileCapabilities = EntityTileCapabilitiesResolver.forProject(
        project,
      );

      return ProjectListRowTile(
        model: buildProjectListRowTileModel(
          context,
          project: project,
          tileCapabilities: tileCapabilities,
          taskCount: project.taskCount,
          completedTaskCount: project.completedTaskCount,
        ),
        onTap: () => Routing.toProjectEdit(context, project.id),
        trailing: ProjectTodayStatusMenuButton(
          projectId: project.id,
          projectName: project.name,
          isPinnedToMyDay: project.isPinned,
          isInMyDayAuto: false,
          isRepeating: project.isRepeating,
          seriesEnded: project.seriesEnded,
          tileCapabilities: tileCapabilities,
        ),
        statusBadge: isOngoing
            ? TasklyBadge(
                label: 'Ongoing',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                isOutlined: true,
              )
            : null,
      );
    }

    return const SizedBox.shrink();
  }
}
