import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/utils/color_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/date_display_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/emoji_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/rrule_display_utils.dart';
import 'package:taskly_bloc/presentation/widgets/date_chip.dart';
import 'package:taskly_bloc/presentation/widgets/empty_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/error_state_widget.dart';
import 'package:taskly_bloc/presentation/widgets/loading_state_widget.dart';
import 'package:taskly_bloc/core/utils/friendly_error_message.dart';
import 'package:taskly_bloc/presentation/widgets/wolt_modal_helpers.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/presentation/features/projects/bloc/project_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_create_edit_view.dart';
import 'package:taskly_bloc/presentation/features/tasks/tasks.dart';

/// Full-screen project page showing the project details and its related tasks.
class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({
    required this.projectId,
    required this.projectRepository,
    required this.taskRepository,
    required this.labelRepository,
    super.key,
  });

  final String projectId;
  final ProjectRepositoryContract projectRepository;
  final TaskRepositoryContract taskRepository;
  final LabelRepositoryContract labelRepository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProjectDetailBloc>(
          create: (_) => ProjectDetailBloc(
            projectRepository: projectRepository,
            labelRepository: labelRepository,
          )..add(ProjectDetailEvent.get(projectId: projectId)),
        ),
        BlocProvider<TaskOverviewBloc>(
          create: (_) => TaskOverviewBloc(
            taskRepository: taskRepository,
            query: TaskQuery.forProject(
              projectId: projectId,
            ),
          )..add(const TaskOverviewEvent.subscriptionRequested()),
        ),
      ],
      child: ProjectDetailPageView(
        projectId: projectId,
        projectRepository: projectRepository,
        taskRepository: taskRepository,
        labelRepository: labelRepository,
      ),
    );
  }
}

class ProjectDetailPageView extends StatelessWidget {
  const ProjectDetailPageView({
    required this.projectId,
    required this.projectRepository,
    required this.taskRepository,
    required this.labelRepository,
    super.key,
  });

  final String projectId;
  final ProjectRepositoryContract projectRepository;
  final TaskRepositoryContract taskRepository;
  final LabelRepositoryContract labelRepository;

  void _showEditProjectSheet(BuildContext context) {
    unawaited(
      showDetailModal<void>(
        context: context,
        childBuilder: (modalSheetContext) => ProjectEditSheetPage(
          projectId: projectId,
          projectRepository: projectRepository,
          labelRepository: labelRepository,
          onSaved: (savedProjectId) {
            // Refresh the project details after edit
            context.read<ProjectDetailBloc>().add(
              ProjectDetailEvent.get(projectId: savedProjectId),
            );
          },
        ),
        showDragHandle: true,
      ),
    );
  }

  void _showTaskDetailSheet(
    BuildContext context, {
    String? taskId,
    String? defaultProjectId,
  }) {
    unawaited(
      showDetailModal<void>(
        context: context,
        childBuilder: (modalSheetContext) => SafeArea(
          top: false,
          child: BlocProvider(
            create: (_) => TaskDetailBloc(
              taskRepository: taskRepository,
              projectRepository: projectRepository,
              labelRepository: labelRepository,
              taskId: taskId,
            ),
            child: TaskDetailSheet(
              defaultProjectId: defaultProjectId,
              labelRepository: labelRepository,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectDetailBloc, ProjectDetailState>(
      builder: (context, state) {
        return state.when(
          initial: () => _buildLoadingScaffold(context),
          loadInProgress: () => _buildLoadingScaffold(context),
          initialDataLoadSuccess: (_) => _buildLoadingScaffold(context),
          loadSuccess: (_, project) => _buildLoadedScaffold(context, project),
          operationSuccess: (_) => _buildLoadingScaffold(context),
          operationFailure: (errorDetails) => Scaffold(
            appBar: AppBar(title: Text(context.l10n.projectsTitle)),
            body: ErrorStateWidget(
              message: friendlyErrorMessageForUi(
                errorDetails.error,
                context.l10n,
              ),
              onRetry: () => context.read<ProjectDetailBloc>().add(
                ProjectDetailEvent.get(projectId: projectId),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.projectsTitle)),
      body: const LoadingStateWidget(),
    );
  }

  Widget _buildLoadedScaffold(BuildContext context, Project project) {
    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: context.l10n.editLabel,
            onPressed: () => _showEditProjectSheet(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) => _handleMenuAction(context, value, project),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(
                    Icons.delete_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    context.l10n.deleteProjectAction,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _ProjectHeader(
            project: project,
            onTap: () => _showEditProjectSheet(context),
            onCheckboxChanged: (value) {
              context.read<ProjectDetailBloc>().add(
                ProjectDetailEvent.update(
                  id: project.id,
                  name: project.name,
                  completed: value ?? !project.completed,
                ),
              );
            },
          ),
          Expanded(
            child: BlocBuilder<TaskOverviewBloc, TaskOverviewState>(
              builder: (context, taskState) {
                return taskState.when(
                  initial: () => const LoadingStateWidget(),
                  loading: () => const LoadingStateWidget(),
                  loaded: (tasks, _) => _buildTaskList(context, tasks, project),
                  error: (error, _) => ErrorStateWidget(
                    message: friendlyErrorMessageForUi(error, context.l10n),
                    onRetry: () => context.read<TaskOverviewBloc>().add(
                      const TaskOverviewEvent.subscriptionRequested(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AddTaskFab(
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        labelRepository: labelRepository,
        defaultProjectId: project.id,
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    List<Task> tasks,
    Project project,
  ) {
    if (tasks.isEmpty) {
      return EmptyStateWidget.noTasks(
        title: context.l10n.emptyTasksTitle,
        description: context.l10n.projectDetailEmptyTasksDescription,
      );
    }

    return TasksListView(
      tasks: tasks,
      onTap: (task) => _showTaskDetailSheet(
        context,
        taskId: task.id,
      ),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    String action,
    Project project,
  ) {
    switch (action) {
      case 'delete':
        unawaited(_showDeleteConfirmation(context, project));
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    Project project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteProjectAction),
        content: Text(
          'Are you sure you want to delete "${project.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.l10n.deleteLabel),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      context.read<ProjectDetailBloc>().add(
        ProjectDetailEvent.delete(id: project.id),
      );
      Navigator.of(context).pop();
    }
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({
    required this.project,
    this.onTap,
    this.onCheckboxChanged,
  });

  final Project project;
  final VoidCallback? onTap;
  final ValueChanged<bool?>? onCheckboxChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    final hasRepeat =
        project.repeatIcalRrule != null &&
        project.repeatIcalRrule!.trim().isNotEmpty;
    final isOverdue = DateDisplayUtils.isOverdue(project.deadlineDate);
    final isDueToday = DateDisplayUtils.isDueToday(project.deadlineDate);
    final isDueSoon = DateDisplayUtils.isDueSoon(project.deadlineDate);

    return Card(
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row with status badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Completion checkbox
                  Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: project.completed,
                      onChanged: onCheckboxChanged,
                      shape: const CircleBorder(),
                      activeColor: colorScheme.primary,
                      checkColor: colorScheme.onPrimary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Title and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            decoration: project.completed
                                ? TextDecoration.lineThrough
                                : null,
                            color: project.completed
                                ? colorScheme.onSurfaceVariant
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  _StatusBadge(
                    isCompleted: project.completed,
                    colorScheme: colorScheme,
                    l10n: l10n,
                  ),
                ],
              ),

              // Description
              if (project.description != null &&
                  project.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  project.description!.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],

              // Dates row using shared widget
              if (project.startDate != null ||
                  project.deadlineDate != null ||
                  hasRepeat) ...[
                const SizedBox(height: 12),
                _ProjectDatesRow(
                  project: project,
                  isOverdue: isOverdue,
                  isDueToday: isDueToday,
                  isDueSoon: isDueSoon,
                ),
              ],

              // Labels section
              if (project.labels.isNotEmpty) ...[
                const SizedBox(height: 12),
                _LabelsSection(
                  labels: project.labels,
                  fallbackColor: colorScheme.primary,
                ),
              ],

              // Task count summary
              BlocBuilder<TaskOverviewBloc, TaskOverviewState>(
                builder: (context, taskState) {
                  return taskState.maybeWhen(
                    loaded: (tasks, _) => _TaskSummary(
                      totalCount: tasks.length,
                      completedCount: tasks.where((t) => t.completed).length,
                      colorScheme: colorScheme,
                      l10n: l10n,
                    ),
                    orElse: () => const SizedBox.shrink(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status badge showing completed/active state.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.isCompleted,
    required this.colorScheme,
    required this.l10n,
  });

  final bool isCompleted;
  final ColorScheme colorScheme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? colorScheme.primaryContainer.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isCompleted ? l10n.projectStatusCompleted : l10n.projectStatusActive,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isCompleted
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Dates row for projects with RRULE support.
class _ProjectDatesRow extends StatelessWidget {
  const _ProjectDatesRow({
    required this.project,
    required this.isOverdue,
    required this.isDueToday,
    required this.isDueSoon,
  });

  final Project project;
  final bool isOverdue;
  final bool isDueToday;
  final bool isDueSoon;

  String formatDate(BuildContext context, DateTime date) {
    return MaterialLocalizations.of(context).formatShortDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final hasRepeat =
        project.repeatIcalRrule != null &&
        project.repeatIcalRrule!.trim().isNotEmpty;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        // Start date
        if (project.startDate != null)
          DateChip.startDate(
            context: context,
            label: formatDate(context, project.startDate!),
          ),

        // Deadline date with status color
        if (project.deadlineDate != null)
          DateChip.deadline(
            context: context,
            label: formatDate(context, project.deadlineDate!),
            isOverdue: isOverdue,
            isDueToday: isDueToday,
            isDueSoon: isDueSoon,
          ),

        // Repeat indicator with human-readable text
        if (hasRepeat)
          DateChip(
            icon: Icons.repeat_rounded,
            label: RruleDisplayUtils.formatRrule(
              context,
              project.repeatIcalRrule,
            ),
            color: Theme.of(context).colorScheme.primary,
          ),
      ],
    );
  }
}

/// Labels section with combined values and labels.
class _LabelsSection extends StatelessWidget {
  const _LabelsSection({
    required this.labels,
    required this.fallbackColor,
  });

  final List<Label> labels;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final label in labels)
          Builder(
            builder: (context) {
              final color = ColorUtils.fromHex(
                label.color,
                fallback: fallbackColor,
              );
              final colorScheme = Theme.of(context).colorScheme;
              final isValue = label.type == LabelType.value;

              // For values: use colored background with contrasting text
              // For labels: use neutral background with colored icon
              final backgroundColor = isValue
                  ? color
                  : colorScheme.surfaceContainerLow;
              final textColor = isValue
                  ? (color.computeLuminance() > 0.5
                        ? Colors.black87
                        : Colors.white)
                  : colorScheme.onSurface;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (label.type == LabelType.value)
                      Text(
                        label.iconName?.isNotEmpty ?? false
                            ? label.iconName!
                            : '❤️',
                        style: EmojiUtils.emojiTextStyle(fontSize: 12),
                      )
                    else
                      Icon(
                        Icons.label,
                        size: 14,
                        color: color,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      label.name,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Task summary showing count and completion progress.
class _TaskSummary extends StatelessWidget {
  const _TaskSummary({
    required this.totalCount,
    required this.completedCount,
    required this.colorScheme,
    required this.l10n,
  });

  final int totalCount;
  final int completedCount;
  final ColorScheme colorScheme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) {
      return const SizedBox.shrink();
    }

    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),

          // Task count text
          Row(
            children: [
              Icon(
                Icons.task_alt_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.projectDetailCompletedCount(completedCount, totalCount),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: completedCount == totalCount
                  ? colorScheme.primary
                  : colorScheme.secondary,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
