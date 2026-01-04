import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/models/analytics/entity_type.dart';
import 'package:taskly_bloc/domain/models/priority/allocation_result.dart';
import 'package:taskly_bloc/domain/models/screens/enrichment_result.dart';
import 'package:taskly_bloc/domain/models/screens/value_stats.dart'
    as domain_stats;
import 'package:taskly_bloc/domain/models/settings/allocation_config.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/presentation/features/projects/widgets/project_list_tile.dart';
import 'package:taskly_bloc/presentation/features/tasks/widgets/task_list_tile.dart';
import 'package:taskly_bloc/presentation/features/labels/widgets/label_list_tile.dart';
import 'package:taskly_bloc/presentation/features/labels/widgets/enhanced_value_card.dart';
import 'package:taskly_bloc/presentation/widgets/allocation_alert_banner.dart';
import 'package:taskly_bloc/presentation/widgets/delete_confirmation.dart';
import 'package:taskly_bloc/presentation/widgets/focus_hero_card.dart';
import 'package:taskly_bloc/presentation/widgets/outside_focus_section.dart';
import 'package:taskly_bloc/presentation/widgets/swipe_to_delete.dart';
import 'package:taskly_bloc/presentation/widgets/allocated_task_tile.dart';

/// Widget that renders a section from ScreenBloc state.
///
/// Handles different section types (data, allocation, agenda) and
/// displays appropriate UI for each.
class SectionWidget extends StatefulWidget {
  /// Creates a SectionWidget.
  const SectionWidget({
    required this.section,
    super.key,
    this.displayConfig,
    this.persona,
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

  /// Allocation persona for section titles (defaults to custom)
  final AllocationPersona? persona;

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
  State<SectionWidget> createState() => _SectionWidgetState();
}

class _SectionWidgetState extends State<SectionWidget> {
  final GlobalKey<State<StatefulWidget>> _outsideFocusKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    talker.debug(
      '[SectionWidget] Building section[${widget.section.index}]: title=${widget.section.title}',
    );
    talker.debug(
      '[SectionWidget] isLoading=${widget.section.isLoading}, error=${widget.section.error}',
    );
    talker.debug(
      '[SectionWidget] data type: ${widget.section.result.runtimeType}',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.section.title != null) _buildHeader(context),
        if (widget.section.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (widget.section.error != null)
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
        widget.section.title!,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Error: ${widget.section.error}',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    talker.debug(
      '[SectionWidget] _buildContent: ${widget.section.result.runtimeType}',
    );

    return switch (widget.section.result) {
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
    // Build main content based on display mode
    final mainContent = switch (result.displayMode) {
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

    // Get alert banner if alerts present
    final alertResult = result.alertEvaluationResult;
    final showAlertBanner = alertResult != null && alertResult.hasAlerts;

    // Show excluded section if enabled and has excluded tasks
    final showExcluded =
        result.showExcludedSection && result.excludedTasks.isNotEmpty;

    // If no extras, return main content directly
    if (!showAlertBanner && !showExcluded) {
      return mainContent;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Alert banner at top
        if (showAlertBanner)
          AllocationAlertBanner(
            alertResult: alertResult,
            onReviewTap: showExcluded ? _scrollToOutsideFocus : () {},
          ),

        // Main allocation content
        mainContent,

        // Outside Focus section at bottom
        if (showExcluded && alertResult != null)
          OutsideFocusSection(
            scrollKey: _outsideFocusKey,
            alertResult: alertResult,
            persona: widget.persona ?? AllocationPersona.custom,
            onTaskTap: (excludedTask) {
              widget.onEntityTap?.call(excludedTask.task.id, 'task');
            },
            onTaskComplete: (excludedTask, value) {
              widget.onTaskCheckboxChanged?.call(excludedTask.task, value);
            },
          ),
      ],
    );
  }

  /// Scrolls to the Outside Focus section
  void _scrollToOutsideFocus() {
    final context = _outsideFocusKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Focus Hero Card
        FocusHeroCard(result: result),

        // Today's Focus Container
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Today's Focus" header
              Row(
                children: [
                  Icon(
                    Icons.center_focus_strong,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Focus",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(
                thickness: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 16),

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
          ),
        ),
      ],
    );
  }

  /// Builds a pinned tasks section with modern design
  Widget _buildPinnedSection(
    BuildContext context,
    List<AllocatedTask> pinnedTasks,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: colorScheme.primary,
                width: 4,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern header with subtle background
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.push_pin,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Pinned',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${pinnedTasks.length} of ${pinnedTasks.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Task list
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pinnedTasks.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 16,
                  endIndent: 16,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                ),
                itemBuilder: (context, index) {
                  final allocatedTask = pinnedTasks[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: TaskListTile(
                      task: allocatedTask.task,
                      onTap: widget.onEntityTap != null
                          ? (_) => widget.onEntityTap!(
                              allocatedTask.task.id,
                              'task',
                            )
                          : null,
                      onCheckboxChanged:
                          widget.onTaskCheckboxChanged ?? (_, __) {},
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a single allocation group with clean inset badge header style
  Widget _buildAllocationGroup(
    BuildContext context,
    AllocationValueGroup group,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Parse value color or use default
    Color? accentColor;
    if (group.color != null) {
      try {
        final hexColor = group.color!.replaceAll('#', '');
        accentColor = Color(int.parse('FF$hexColor', radix: 16));
      } catch (_) {
        accentColor = null;
      }
    }
    accentColor ??= colorScheme.primary;

    // Get emoji or fallback icon
    final emoji = group.iconName?.isNotEmpty ?? false ? group.iconName! : '⭐';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with underline
            Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.valueName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${group.tasks.where((t) => t.task.completed).length}/${group.tasks.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.5),
                    accentColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 12),
            // Task list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: group.tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final allocatedTask = group.tasks[index];
                return AllocatedTaskTile(
                  allocatedTask: allocatedTask,
                  onCheckboxChanged: widget.onTaskCheckboxChanged ?? (_, __) {},
                  onTap: widget.onEntityTap != null
                      ? (_) =>
                            widget.onEntityTap!(allocatedTask.task.id, 'task')
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Values setup gateway for allocation section.dget
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
                onPressed: () => Routing.toScreenKey(context, 'values'),
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

    final config = widget.displayConfig;
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
    final completedCollapsed = widget.displayConfig?.completedCollapsed ?? true;

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
      onTap: widget.onEntityTap != null
          ? (_) => widget.onEntityTap!(task.id, 'task')
          : null,
      onCheckboxChanged: widget.onTaskCheckboxChanged ?? (_, __) {},
    );

    if (!enableSwipe || widget.onTaskDelete == null) {
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
        widget.onTaskDelete!(task);
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
          onTap: widget.onEntityTap != null
              ? (_) => widget.onEntityTap!(project.id, 'project')
              : null,
          onCheckboxChanged: widget.onProjectCheckboxChanged ?? (_, __) {},
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
          onTap: widget.onEntityTap != null
              ? (_) => widget.onEntityTap!(label.id, 'label')
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

        return EnhancedValueCard(
          value: value,
          rank: index + 1,
          stats: stats,
          onTap: widget.onEntityTap != null
              ? () => widget.onEntityTap!(value.id, 'value')
              : () => Routing.toEntity(context, EntityType.value, value.id),
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
