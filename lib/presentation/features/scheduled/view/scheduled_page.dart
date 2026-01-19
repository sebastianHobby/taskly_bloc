import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/taskly_domain.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/project_tile_mapper.dart';
import 'package:taskly_bloc/presentation/entity_tiles/mappers/task_tile_mapper.dart';
import 'package:taskly_bloc/presentation/features/scheduled/bloc/scheduled_feed_bloc.dart';
import 'package:taskly_bloc/presentation/features/scheduled/bloc/scheduled_screen_bloc.dart';
import 'package:taskly_bloc/presentation/features/scheduled/view/scheduled_scope_header.dart';
import 'package:taskly_bloc/presentation/feeds/rows/list_row_ui_model.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_overflow_action_catalog.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_overflow_menu.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/services/time/home_day_service.dart';
import 'package:taskly_bloc/presentation/shared/responsive/responsive.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_ui/taskly_ui.dart' hide ProjectTileModel, TaskTileModel;
import 'package:taskly_ui/taskly_ui_catalog.dart';

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
              ScheduledFeedLoaded(:final rows) => _ScheduledAgenda(
                rows: rows,
                today: today,
                scrollController: _scrollController,
                todayAnchorKey: _todayHeaderKey,
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

class _ScheduledAgenda extends StatelessWidget {
  const _ScheduledAgenda({
    required this.rows,
    required this.today,
    required this.scrollController,
    required this.todayAnchorKey,
  });

  final List<ListRowUiModel> rows;
  final DateTime today;
  final ScrollController scrollController;
  final Key todayAnchorKey;

  @override
  Widget build(BuildContext context) {
    final agendaRows = <TasklyAgendaRowModel>[];

    for (final row in rows) {
      switch (row) {
        case BucketHeaderRowUiModel(
          :final bucketKey,
          :final title,
          :final isCollapsed,
        ):
          agendaRows.add(
            TasklyAgendaBucketHeaderRowModel(
              key: row.rowKey,
              depth: row.depth,
              bucketKey: bucketKey,
              title: title,
              isCollapsed: isCollapsed,
              onTap: () => context.read<ScheduledFeedBloc>().add(
                ScheduledBucketCollapseToggled(bucketKey: bucketKey),
              ),
            ),
          );
        case DateHeaderRowUiModel(:final date, :final title):
          agendaRows.add(
            TasklyAgendaDateHeaderRowModel(
              key: row.rowKey,
              depth: row.depth,
              day: date,
              title: title,
              isTodayAnchor: _isSameDay(date, today),
            ),
          );
        case EmptyDayRowUiModel(:final date):
          agendaRows.add(
            TasklyAgendaEmptyDayRowModel(
              key: row.rowKey,
              depth: row.depth,
              day: date,
              label: 'No items',
            ),
          );
        case ScheduledEntityRowUiModel(:final occurrence):
          if (occurrence.ref.entityType == EntityType.task &&
              occurrence.task != null) {
            final task = occurrence.task!;
            final tileCapabilities = EntityTileCapabilitiesResolver.forTask(
              task,
            );

            final overflowActions = TileOverflowActionCatalog.forTask(
              taskId: task.id,
              taskName: task.name,
              isPinnedToMyDay: task.isPinned,
              isRepeating: task.isRepeating,
              seriesEnded: task.seriesEnded,
              tileCapabilities: tileCapabilities,
            );

            final hasAnyEnabledAction = overflowActions.any((a) => a.enabled);

            agendaRows.add(
              TasklyAgendaTaskRowModel(
                key: row.rowKey,
                depth: row.depth,
                entityId: task.id,
                model: buildTaskListRowTileModel(
                  context,
                  task: task,
                  tileCapabilities: tileCapabilities,
                ),
                badges: [
                  if (task.isPinned)
                    const BadgeSpec(kind: BadgeKind.pinned, label: 'Pinned'),
                ],
                trailing: hasAnyEnabledAction
                    ? TrailingSpec.overflowButton
                    : TrailingSpec.none,
                onToggleCompletion: buildTaskToggleCompletionHandler(
                  context,
                  task: task,
                  tileCapabilities: tileCapabilities,
                ),
                onOverflowRequestedAt: hasAnyEnabledAction
                    ? (Offset pos) async {
                        await showTileOverflowMenu(
                          context,
                          position: pos,
                          entityTypeLabel: 'task',
                          entityId: task.id,
                          actions: overflowActions,
                        );
                      }
                    : null,
              ),
            );
            continue;
          }

          if (occurrence.ref.entityType == EntityType.project &&
              occurrence.project != null) {
            final project = occurrence.project!;
            final tileCapabilities = EntityTileCapabilitiesResolver.forProject(
              project,
            );

            final overflowActions = TileOverflowActionCatalog.forProject(
              projectId: project.id,
              projectName: project.name,
              isPinnedToMyDay: project.isPinned,
              isRepeating: project.isRepeating,
              seriesEnded: project.seriesEnded,
              tileCapabilities: tileCapabilities,
            );

            final hasAnyEnabledAction = overflowActions.any((a) => a.enabled);

            agendaRows.add(
              TasklyAgendaProjectRowModel(
                key: row.rowKey,
                depth: row.depth,
                entityId: project.id,
                model: buildProjectListRowTileModel(
                  context,
                  project: project,
                  taskCount: project.taskCount,
                  completedTaskCount: project.completedTaskCount,
                ),
                badges: const [],
                trailing: hasAnyEnabledAction
                    ? TrailingSpec.overflowButton
                    : TrailingSpec.none,
                onTap: () => Routing.toProjectEdit(context, project.id),
                onOverflowRequestedAt: hasAnyEnabledAction
                    ? (Offset pos) async {
                        await showTileOverflowMenu(
                          context,
                          position: pos,
                          entityTypeLabel: 'project',
                          entityId: project.id,
                          actions: overflowActions,
                        );
                      }
                    : null,
              ),
            );
            continue;
          }

        default:
          continue;
      }
    }

    return TasklyAgendaSection(
      rows: agendaRows,
      controller: scrollController,
      todayAnchorKey: todayAnchorKey,
    );
  }
}
