import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/services/time/home_day_service.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_app_bar.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_cubit.dart';
import 'package:taskly_bloc/presentation/shared/selection/selection_models.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_ritual_bloc.dart';
import 'package:taskly_bloc/presentation/screens/widgets/my_day_ritual_sections_card.dart';
import 'package:taskly_bloc/presentation/screens/view/my_day_ritual_wizard_page.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/core.dart' as domain;

class MyDayPage extends StatelessWidget {
  const MyDayPage({super.key});

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
      child: BlocListener<MyDayRitualBloc, MyDayRitualState>(
        listenWhen: (previous, next) {
          final prevReady = previous is MyDayRitualReady ? previous : null;
          final nextReady = next is MyDayRitualReady ? next : null;

          final prevNeeds = prevReady?.needsRitual;
          final nextNeeds = nextReady?.needsRitual;

          if (prevNeeds != nextNeeds) return true;
          if (prevReady?.dayKeyUtc != nextReady?.dayKeyUtc) return true;
          return false;
        },
        listener: (_, state) {
          final ready = state is MyDayRitualReady ? state : null;
          myDayTrace(
            'MyDayPage gate: state=${state.runtimeType} '
            'needsRitual=${ready?.needsRitual} '
            'dayKey=${ready?.dayKeyUtc.toIso8601String()}',
          );
        },
        child: BlocBuilder<MyDayRitualBloc, MyDayRitualState>(
          builder: (context, ritualState) {
            final needsRitual =
                ritualState is MyDayRitualReady && ritualState.needsRitual;

            if (needsRitual) {
              return const MyDayRitualWizardPage();
            }

            if (ritualState is MyDayRitualLoading) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('My Day'),
                  actions: TasklyAppBarActions.withAttentionBell(
                    context,
                    actions: const <Widget>[],
                  ),
                ),
                body: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            return BlocBuilder<SelectionCubit, SelectionState>(
              builder: (context, selectionState) {
                return Scaffold(
                  appBar: selectionState.isSelectionMode
                      ? SelectionAppBar(baseTitle: 'My Day', onExit: () {})
                      : AppBar(
                          title: const Text('My Day'),
                          actions: TasklyAppBarActions.withAttentionBell(
                            context,
                            actions: const <Widget>[],
                          ),
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
                  body: const _MyDayLoadedBody(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MyDayLoadedBody extends StatelessWidget {
  const _MyDayLoadedBody();

  Future<void> _showAddOneMoreFocusSheet(
    BuildContext context, {
    required Set<String> excludedTaskIds,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);

        final ritualState = context.watch<MyDayRitualBloc>().state;
        if (ritualState is! MyDayRitualReady) {
          return const SizedBox.shrink();
        }

        final available = ritualState.curated
            .where((t) => !excludedTaskIds.contains(t.id))
            .toList(growable: false);

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add one more focus',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Only if you feel like it.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (available.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No extra focus suggestions right now.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 520),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: available.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final task = available[index];
                        final reason = ritualState.curatedReasons[task.id];

                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant
                                  .withOpacity(0.6),
                            ),
                          ),
                          tileColor: theme.colorScheme.surface,
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: const EdgeInsets.fromLTRB(
                            12,
                            10,
                            10,
                            10,
                          ),
                          title: Text(
                            task.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: reason != null && reason.isNotEmpty
                              ? Text(
                                  reason,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: Icon(
                            Icons.add_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          onTap: () {
                            context.read<MyDayRitualBloc>().add(
                              MyDayRitualAppendToToday(
                                bucket: MyDayRitualAppendBucket.focus,
                                taskId: task.id,
                              ),
                            );
                            Navigator.of(context).pop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Added to Today's Focus."),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddMissingSheet(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<domain.Task> tasks,
    required MyDayRitualAppendBucket bucket,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        final justAdded = <String>{};

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                final visible = tasks
                    .where((t) => !justAdded.contains(t.id))
                    .toList(growable: false);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (visible.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Nothing to add right now.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 520),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final task = visible[index];

                            return ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: theme.colorScheme.outlineVariant
                                      .withOpacity(0.6),
                                ),
                              ),
                              tileColor: theme.colorScheme.surface,
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              contentPadding: const EdgeInsets.fromLTRB(
                                12,
                                10,
                                10,
                                10,
                              ),
                              title: Text(
                                task.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Icon(
                                Icons.add_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              onTap: () {
                                context.read<MyDayRitualBloc>().add(
                                  MyDayRitualAppendToToday(
                                    bucket: bucket,
                                    taskId: task.id,
                                  ),
                                );
                                setState(() => justAdded.add(task.id));

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added to today.'),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Done'),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ritualState = context.watch<MyDayRitualBloc>().state;
    final focusReasons = ritualState is MyDayRitualReady
        ? ritualState.curatedReasons
        : const <String, String>{};

    return BlocBuilder<MyDayBloc, MyDayState>(
      builder: (context, state) {
        return switch (state) {
          MyDayLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          MyDayError(:final message) => Center(child: Text(message)),
          MyDayLoaded(
            :final acceptedDue,
            :final acceptedStarts,
            :final acceptedFocus,
            :final dueAcceptedTotalCount,
            :final startsAcceptedTotalCount,
            :final focusAcceptedTotalCount,
            :final selectedTotalCount,
            :final missingDueCount,
            :final missingStartsCount,
            :final missingDueTasks,
            :final missingStartsTasks,
            :final todaySelectedTaskIds,
          ) =>
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: MyDayRitualSectionsCard(
                          acceptedDue: acceptedDue,
                          acceptedStarts: acceptedStarts,
                          acceptedFocus: acceptedFocus,
                          focusReasons: focusReasons,
                          showCompletionMessage:
                              selectedTotalCount > 0 &&
                              acceptedDue.isEmpty &&
                              acceptedStarts.isEmpty &&
                              acceptedFocus.isEmpty,
                          onAddOneMoreFocus: () => _showAddOneMoreFocusSheet(
                            context,
                            excludedTaskIds: todaySelectedTaskIds,
                          ),
                          dueCounts: MyDayBucketCounts(
                            acceptedCount: dueAcceptedTotalCount,
                            otherCount: missingDueCount,
                          ),
                          startsCounts: MyDayBucketCounts(
                            acceptedCount: startsAcceptedTotalCount,
                            otherCount: missingStartsCount,
                          ),
                          onAddMissingDue: missingDueCount > 0
                              ? () => _showAddMissingSheet(
                                  context,
                                  title: 'Add overdue & due',
                                  subtitle:
                                      "These were eligible when you planned today, but you didn't add them.",
                                  tasks: missingDueTasks,
                                  bucket: MyDayRitualAppendBucket.due,
                                )
                              : null,
                          onAddMissingStarts: missingStartsCount > 0
                              ? () => _showAddMissingSheet(
                                  context,
                                  title: 'Add starts today',
                                  subtitle:
                                      "These were eligible when you planned today, but you didn't add them.",
                                  tasks: missingStartsTasks,
                                  bucket: MyDayRitualAppendBucket.starts,
                                )
                              : null,
                          focusCounts: MyDayBucketCounts(
                            acceptedCount: focusAcceptedTotalCount,
                            otherCount: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        };
      },
    );
  }
}
