import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/routing/routes.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/screens/enrichment_result.dart';
import 'package:taskly_bloc/domain/models/screens/value_stats.dart'
    as domain_stats;
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/presentation/navigation/entity_navigator.dart';
import 'package:taskly_bloc/presentation/features/projects/widgets/project_list_tile.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_list_tile.dart';
import 'package:taskly_bloc/presentation/features/labels/widgets/label_list_tile.dart';
import 'package:taskly_bloc/presentation/features/labels/widgets/enhanced_value_card.dart';
import 'package:taskly_bloc/presentation/widgets/delete_confirmation.dart';
import 'package:taskly_bloc/presentation/widgets/swipe_to_delete.dart';

/// Widget that renders a section from ScreenBloc state.
///
/// Handles different section types (data, allocation, agenda) and
/// displays appropriate UI for each.
class SectionWidget extends StatelessWidget {
  /// Creates a SectionWidget.
  const SectionWidget({
    required this.section,
    super.key,
    this.displayConfig,
    this.onEntityTap,
    this.onTaskComplete,
    this.onTaskCheckboxChanged,
    this.onProjectCheckboxChanged,
    this.onTaskDelete,
    this.onProjectDelete,
  });

  /// The section data to render
  final SectionDataWithMeta section;

  /// Display configuration for enhanced features (swipe-to-delete, grouping)
  final DisplayConfig? displayConfig;

  /// Optional custom entity tap callback
  final void Function(String entityId, String entityType)? onEntityTap;

  /// Optional task completion callback
  final void Function(String taskId)? onTaskComplete;

  /// Optional task checkbox change callback
  final void Function(Task task, bool? value)? onTaskCheckboxChanged;

  /// Optional project checkbox change callback
  final void Function(Project project, bool? value)? onProjectCheckboxChanged;

  /// Optional task delete callback
  final void Function(Task task)? onTaskDelete;

  /// Optional project delete callback
  final void Function(Project project)? onProjectDelete;

  @override
  Widget build(BuildContext context) {
    talker.debug(
      '[SectionWidget] Building section[${section.index}]: title=${section.title}',
    );
    talker.debug(
      '[SectionWidget] isLoading=${section.isLoading}, error=${section.error}',
    );
    talker.debug('[SectionWidget] data type: ${section.result.runtimeType}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title != null) _buildHeader(context),
        if (section.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (section.error != null)
          _buildError(context)
        else
          _buildContent(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        section.title!,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Error: ${section.error}',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    talker.debug(
      '[SectionWidget] _buildContent: ${section.result.runtimeType}',
    );

    return switch (section.result) {
      DataSectionResult(
        :final primaryEntities,
        :final primaryEntityType,
        :final relatedEntities,
        :final enrichment,
      ) =>
        () {
          talker.debug(
            '[SectionWidget] DataSectionResult: entityType=$primaryEntityType, count=${primaryEntities.length}, related=${relatedEntities.keys}, enrichment=${enrichment?.runtimeType}',
          );
          return _buildDataSection(
            context,
            primaryEntities,
            primaryEntityType,
            relatedEntities,
            enrichment,
          );
        }(),
      final AllocationSectionResult result => () {
        talker.debug(
          '[SectionWidget] AllocationSectionResult: tasks=${result.allocatedTasks.length}, '
          'pinned=${result.pinnedTasks.length}, groups=${result.tasksByValue.length}, '
          'mode=${result.displayMode}, requiresValueSetup=${result.requiresValueSetup}',
        );
        // Show gateway if value setup is required
        if (result.requiresValueSetup) {
          return _buildValuesGateway(context);
        }
        return _buildAllocationSection(context, result);
      }(),
      AgendaSectionResult(:final groupedTasks, :final groupOrder) => () {
        talker.debug(
          '[SectionWidget] AgendaSectionResult: groups=${groupedTasks.length}, order=$groupOrder',
        );
        return _buildAgendaSection(context, groupedTasks, groupOrder);
      }(),
    };
  }

  /// Builds allocation section based on display mode (DR-020, DR-021)
  Widget _buildAllocationSection(
    BuildContext context,
    AllocationSectionResult result,
  ) {
    return switch (result.displayMode) {
      AllocationDisplayMode.flat => _buildFlatAllocation(context, result),
      AllocationDisplayMode.groupedByValue => _buildGroupedAllocation(
        context,
        result,
      ),
      AllocationDisplayMode.pinnedFirst => _buildPinnedFirstAllocation(
        context,
        result,
      ),
    };
  }

  /// Flat list of all allocated tasks
  Widget _buildFlatAllocation(
    BuildContext context,
    AllocationSectionResult result,
  ) {
    if (result.allocatedTasks.isEmpty) {
      return _buildEmptyAllocation(context, result);
    }
    return _buildTaskList(context, result.allocatedTasks);
  }

  /// Tasks grouped by their qualifying value
  Widget _buildGroupedAllocation(
    BuildContext context,
    AllocationSectionResult result,
  ) {
    if (result.tasksByValue.isEmpty) {
      return _buildEmptyAllocation(context, result);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: result.tasksByValue.entries.map((entry) {
        final group = entry.value;
        return _buildAllocationGroup(context, group);
      }).toList(),
    );
  }

  /// Pinned tasks first, then grouped by value (default mode)
  Widget _buildPinnedFirstAllocation(
    BuildContext context,
    AllocationSectionResult result,
  ) {
    final isEmpty = result.pinnedTasks.isEmpty && result.tasksByValue.isEmpty;
    if (isEmpty) {
      return _buildEmptyAllocation(context, result);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pinned section
        if (result.pinnedTasks.isNotEmpty) ...[
          _buildPinnedSection(context, result.pinnedTasks),
          const SizedBox(height: 16),
        ],

        // Value groups
        ...result.tasksByValue.entries.map((entry) {
          final group = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildAllocationGroup(context, group),
          );
        }),
      ],
    );
  }

  /// Builds a pinned tasks section
  Widget _buildPinnedSection(
    BuildContext context,
    List<AllocatedTask> pinnedTasks,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.push_pin,
                  size: 18,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'PINNED',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                Text(
                  '${pinnedTasks.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pinnedTasks.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final allocatedTask = pinnedTasks[index];
              return TaskListTile(
                task: allocatedTask.task,
                onTap: onEntityTap != null
                    ? (_) => onEntityTap!(allocatedTask.task.id, 'task')
                    : null,
                onCheckboxChanged: onTaskCheckboxChanged ?? (_, __) {},
              );
            },
          ),
        ],
      ),
    );
  }

  /// Builds a single allocation group (value header + tasks)
  Widget _buildAllocationGroup(
    BuildContext context,
    AllocationValueGroup group,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.valueName.toUpperCase(),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: group.quota > 0
                            ? group.tasks.length / group.quota
                            : 0,
                        backgroundColor: Colors.grey[300],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${group.tasks.length} of ${group.quota}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.tasks.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final allocatedTask = group.tasks[index];
              return TaskListTile(
                task: allocatedTask.task,
                onTap: onEntityTap != null
                    ? (_) => onEntityTap!(allocatedTask.task.id, 'task')
                    : null,
                onCheckboxChanged: onTaskCheckboxChanged ?? (_, __) {},
              );
            },
          ),
        ],
      ),
    );
  }

  /// Values setup gateway for allocation section.
  ///
  /// Shown when user has no values defined and allocation cannot proceed.
  Widget _buildValuesGateway(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(
              Icons.balance,
              size: 72,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              l10n.valuesGatewayTitle,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              l10n.valuesGatewayDescription,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Primary CTA
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoutePath.values),
                icon: const Icon(Icons.star_outline),
                label: Text(l10n.setUpMyValues),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state for allocation section
  Widget _buildEmptyAllocation(
    BuildContext context,
    AllocationSectionResult result,
  ) {
    final hasMore = result.excludedCount > 0;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasMore ? Icons.celebration_outlined : Icons.inbox_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              hasMore ? 'All tasks completed!' : 'No tasks to show',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (hasMore) ...[
              const SizedBox(height: 8),
              Text(
                '${result.excludedCount} more tasks available',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataSection(
    BuildContext context,
    List<dynamic> entities,
    String entityType,
    Map<String, List<dynamic>> relatedEntities,
    EnrichmentResult? enrichment,
  ) {
    final primaryWidget = switch (entityType) {
      'task' => _buildTaskList(context, entities.cast<Task>()),
      'project' => _buildProjectList(context, entities.cast<Project>()),
      'label' || 'value' => _buildLabelList(
        context,
        entities.cast<Label>(),
        enrichment,
      ),
      _ => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Unknown entity type: $entityType'),
      ),
    };

    // Build related entity sections
    final relatedWidgets = <Widget>[];

    final relatedTasks = relatedEntities['tasks'];
    if (relatedTasks != null && relatedTasks.isNotEmpty) {
      relatedWidgets.add(
        _buildRelatedSection(
          context,
          title: 'Tasks',
          child: _buildTaskList(context, relatedTasks.cast<Task>()),
        ),
      );
    }

    final relatedProjects = relatedEntities['projects'];
    if (relatedProjects != null && relatedProjects.isNotEmpty) {
      relatedWidgets.add(
        _buildRelatedSection(
          context,
          title: 'Projects',
          child: _buildProjectList(context, relatedProjects.cast<Project>()),
        ),
      );
    }

    final relatedLabels = relatedEntities['labels'];
    if (relatedLabels != null && relatedLabels.isNotEmpty) {
      relatedWidgets.add(
        _buildRelatedSection(
          context,
          title: 'Labels',
          child: _buildLabelList(context, relatedLabels.cast<Label>(), null),
        ),
      );
    }

    if (relatedWidgets.isEmpty) {
      return primaryWidget;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        primaryWidget,
        ...relatedWidgets,
      ],
    );
  }

  Widget _buildRelatedSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildTaskList(BuildContext context, List<Task> tasks) {
    if (tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No tasks'),
      );
    }

    final config = displayConfig;
    final enableSwipe = config?.enableSwipeToDelete ?? false;
    final groupByCompletion = config?.groupByCompletion ?? false;

    // If grouping by completion, separate and show in sections
    if (groupByCompletion) {
      return _buildGroupedTaskList(context, tasks, enableSwipe);
    }

    // Simple flat list
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskItem(context, task, enableSwipe);
      },
    );
  }

  Widget _buildGroupedTaskList(
    BuildContext context,
    List<Task> tasks,
    bool enableSwipe,
  ) {
    final activeTasks = tasks.where((t) => !t.completed).toList();
    final completedTasks = tasks.where((t) => t.completed).toList();
    final completedCollapsed = displayConfig?.completedCollapsed ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Active tasks
        ...activeTasks.map(
          (task) => _buildTaskItem(context, task, enableSwipe),
        ),

        // Completed section (collapsible)
        if (completedTasks.isNotEmpty)
          _CompletedTasksSection(
            tasks: completedTasks,
            initiallyCollapsed: completedCollapsed,
            itemBuilder: (task) => _buildTaskItem(context, task, enableSwipe),
          ),
      ],
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task, bool enableSwipe) {
    final item = TaskListTile(
      task: task,
      onTap: onEntityTap != null ? (_) => onEntityTap!(task.id, 'task') : null,
      onCheckboxChanged: onTaskCheckboxChanged ?? (_, __) {},
    );

    if (!enableSwipe || onTaskDelete == null) {
      return item;
    }

    return SwipeToDelete(
      itemKey: ValueKey(task.id),
      confirmDismiss: () => showDeleteConfirmationDialog(
        context: context,
        title: 'Delete Task',
        itemName: task.name,
        description: 'This action cannot be undone.',
      ),
      onDismissed: () {
        onTaskDelete!(task);
        showDeleteSnackBar(context: context, message: 'Task deleted');
      },
      child: item,
    );
  }

  Widget _buildProjectList(BuildContext context, List<Project> projects) {
    if (projects.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No projects'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return ProjectListTile(
          project: project,
          onTap: onEntityTap != null
              ? (_) => onEntityTap!(project.id, 'project')
              : null,
          onCheckboxChanged: onProjectCheckboxChanged ?? (_, __) {},
        );
      },
    );
  }

  Widget _buildLabelList(
    BuildContext context,
    List<Label> labels,
    EnrichmentResult? enrichment,
  ) {
    if (labels.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No labels'),
      );
    }

    // Separate labels and values
    final regularLabels = labels
        .where((l) => l.type == LabelType.label)
        .toList();
    final values = labels.where((l) => l.type == LabelType.value).toList();

    // If mixed, show both sections
    if (regularLabels.isNotEmpty && values.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabelTileList(context, regularLabels),
          const SizedBox(height: 16),
          _buildValueCardList(context, values, enrichment),
        ],
      );
    }

    // Only labels
    if (regularLabels.isNotEmpty) {
      return _buildLabelTileList(context, regularLabels);
    }

    // Only values
    return _buildValueCardList(context, values, enrichment);
  }

  /// Builds a list of label tiles for regular labels.
  Widget _buildLabelTileList(BuildContext context, List<Label> labels) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: labels.length,
      itemBuilder: (context, index) {
        final label = labels[index];
        return LabelListTile(
          label: label,
          onTap: onEntityTap != null
              ? (_) => onEntityTap!(label.id, 'label')
              : null,
        );
      },
    );
  }

  /// Builds a list of enhanced value cards for values.
  Widget _buildValueCardList(
    BuildContext context,
    List<Label> values,
    EnrichmentResult? enrichment,
  ) {
    // Extract value stats from enrichment if available
    final statsMap = switch (enrichment) {
      ValueStatsEnrichmentResult(:final statsByValueId) => statsByValueId,
      _ => <String, domain_stats.ValueStats>{},
    };

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: values.length,
      itemBuilder: (context, index) {
        final value = values[index];
        final domainStats = statsMap[value.id];

        // Convert domain ValueStats to presentation ValueStats if available
        final stats = domainStats != null
            ? ValueStats(
                targetPercent: domainStats.targetPercent,
                actualPercent: domainStats.actualPercent,
                taskCount: domainStats.taskCount,
                projectCount: domainStats.projectCount,
                weeklyTrend: domainStats.weeklyTrend,
                gapWarningThreshold: domainStats.gapWarningThreshold,
              )
            : null;

        return EnhancedValueCard.compact(
          value: value,
          rank: index + 1,
          stats: stats,
          onTap: onEntityTap != null
              ? () => onEntityTap!(value.id, 'value')
              : () => EntityNavigator.toValue(context, value.id),
        );
      },
    );
  }

  Widget _buildAgendaSection(
    BuildContext context,
    Map<String, List<Task>> groupedTasks,
    List<String> groupOrder,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupOrder.map((group) {
        final tasks = groupedTasks[group] ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                group,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            _buildTaskList(context, tasks),
          ],
        );
      }).toList(),
    );
  }
}

/// Collapsible section for completed tasks
class _CompletedTasksSection extends StatefulWidget {
  const _CompletedTasksSection({
    required this.tasks,
    required this.itemBuilder,
    this.initiallyCollapsed = true,
  });

  final List<Task> tasks;
  final Widget Function(Task task) itemBuilder;
  final bool initiallyCollapsed;

  @override
  State<_CompletedTasksSection> createState() => _CompletedTasksSectionState();
}

class _CompletedTasksSectionState extends State<_CompletedTasksSection> {
  late bool _isCollapsed;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.initiallyCollapsed;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: !_isCollapsed,
            onExpansionChanged: (expanded) {
              setState(() => _isCollapsed = !expanded);
            },
            leading: Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.6),
            ),
            title: Text(
              'Completed (${widget.tasks.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            children: widget.tasks.map(widget.itemBuilder).toList(),
          ),
        ),
      ],
    );
  }
}
