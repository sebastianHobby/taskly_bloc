import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/models/screens/workflow_item.dart';
import 'package:taskly_bloc/domain/models/screens/workflow_progress.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/domain/services/analytics/task_stats_calculator.dart';
import 'package:taskly_bloc/domain/services/screens/support_block_result.dart';
import 'package:taskly_bloc/domain/services/workflow/problem_detector_service.dart';

/// Computes support block data by delegating to existing analytics services.
///
/// This service handles computing runtime data for SupportBlock instances.
/// The new unified screen architecture (DR-018, DR-019) defines support blocks
/// as auxiliary UI elements that provide contextual information.
class SupportBlockComputer {
  SupportBlockComputer({
    required TaskStatsCalculator statsCalculator,
    required AnalyticsService analyticsService,
    required ProblemDetectorService problemDetectorService,
  }) : _statsCalculator = statsCalculator,
       _analyticsService = analyticsService,
       _problemDetectorService = problemDetectorService;

  // TODO: Use for advanced StatsBlock computation
  // ignore: unused_field
  final TaskStatsCalculator _statsCalculator;
  // TODO: Use for analytics-based blocks
  // ignore: unused_field
  final AnalyticsService _analyticsService;
  final ProblemDetectorService _problemDetectorService;

  /// Compute result for a support block
  Future<SupportBlockResult> compute(
    SupportBlock block, {
    required List<Task> tasks,
    required List<Project> projects,
    required DisplayConfig displayConfig,
    List<WorkflowItem<Task>>? workflowItems,
  }) async {
    return switch (block) {
      WorkflowProgressBlock() => _computeWorkflowProgress(
        block,
        workflowItems ?? [],
      ),
      QuickActionsBlock(:final actions) => SupportBlockResult.quickActions(
        actions: actions,
      ),
      ContextSummaryBlock() => _computeContextSummary(block, projects),
      RelatedEntitiesBlock() => _computeRelatedEntities(block, tasks, projects),
      StatsBlock() => await _computeStats(block, tasks),
      ProblemSummaryBlock() => await _computeProblemSummary(
        block,
        tasks,
        projects,
        displayConfig,
      ),
      EmptyStateBlock(
        :final message,
        :final icon,
        :final actionLabel,
        :final actionRoute,
      ) =>
        SupportBlockResult.emptyState(
          message: message,
          icon: icon,
          actionLabel: actionLabel,
          actionRoute: actionRoute,
        ),
      // EntityHeaderBlock is handled by the UI layer directly,
      // not by the computer
      EntityHeaderBlock() => const SupportBlockResult.empty(),
    };
  }

  SupportBlockResult _computeWorkflowProgress(
    WorkflowProgressBlock block,
    List<WorkflowItem<Task>> items,
  ) {
    if (items.isEmpty) {
      return const SupportBlockResult.workflowProgress(
        currentStep: 0,
        totalSteps: 0,
        currentStepName: 'No items',
        progressPercent: 0,
      );
    }

    final total = items.length;
    final completed = items
        .where((i) => i.status == WorkflowItemStatus.completed)
        .length;
    final progressPercent = total > 0 ? (completed / total) * 100 : 0.0;

    // Find current item (first pending)
    final currentItem = items.firstWhere(
      (i) => i.status == WorkflowItemStatus.pending,
      orElse: () => items.last,
    );
    final currentStep = items.indexOf(currentItem) + 1;

    return SupportBlockResult.workflowProgress(
      currentStep: currentStep,
      totalSteps: total,
      currentStepName: currentItem.entity.name,
      progressPercent: progressPercent,
    );
  }

  SupportBlockResult _computeContextSummary(
    ContextSummaryBlock block,
    List<Project> projects,
  ) {
    // Return basic context, can be enhanced later
    return SupportBlockResult.contextSummary(
      title: block.title ?? 'Context',
      description: block.showDescription ? 'Context information' : null,
      metadata: block.showMetadata ? {} : null,
    );
  }

  SupportBlockResult _computeRelatedEntities(
    RelatedEntitiesBlock block,
    List<Task> tasks,
    List<Project> projects,
  ) {
    final entities = <RelatedEntityInfo>[];

    for (final entityType in block.entityTypes) {
      if (entityType == 'project' && entities.length < block.maxItems) {
        for (final project in projects.take(block.maxItems - entities.length)) {
          entities.add(
            RelatedEntityInfo(
              id: project.id,
              name: project.name,
              entityType: 'project',
              route: '/projects/${project.id}',
            ),
          );
        }
      }
    }

    return SupportBlockResult.relatedEntities(
      entities: entities.take(block.maxItems).toList(),
      totalCount: entities.length,
    );
  }

  Future<SupportBlockResult> _computeStats(
    StatsBlock block,
    List<Task> tasks,
  ) async {
    final computedStats = <ComputedStat>[];

    for (final stat in block.stats) {
      final value = await _computeStatValue(stat.metricId, tasks);
      computedStats.add(
        ComputedStat(
          label: stat.label,
          value: _formatStatValue(value, stat.format),
          icon: stat.icon,
        ),
      );
    }

    return SupportBlockResult.stats(stats: computedStats);
  }

  Future<double> _computeStatValue(String metricId, List<Task> tasks) async {
    // Use existing stats calculator for common metrics
    return switch (metricId) {
      'totalTasks' => tasks.length.toDouble(),
      'completedTasks' => tasks.where((t) => t.completed).length.toDouble(),
      'overdueTasks' =>
        tasks
            .where(
              (t) =>
                  t.deadlineDate != null &&
                  t.deadlineDate!.isBefore(DateTime.now()) &&
                  !t.completed,
            )
            .length
            .toDouble(),
      _ => 0.0,
    };
  }

  String _formatStatValue(double value, String? format) {
    return switch (format) {
      'percent' => '${value.toStringAsFixed(0)}%',
      'decimal' => value.toStringAsFixed(2),
      _ => value.toStringAsFixed(0),
    };
  }

  Future<SupportBlockResult> _computeProblemSummary(
    ProblemSummaryBlock block,
    List<Task> tasks,
    List<Project> projects,
    DisplayConfig displayConfig,
  ) async {
    // Use existing problem detector service
    final taskProblems = await _problemDetectorService.detectTaskProblems(
      tasks: tasks,
      displayConfig: displayConfig,
    );
    final projectProblems = await _problemDetectorService.detectProjectProblems(
      projects: projects,
      displayConfig: displayConfig,
    );

    var allProblems = [...taskProblems, ...projectProblems];

    // Filter by problem types if specified
    if (block.problemTypes != null && block.problemTypes!.isNotEmpty) {
      allProblems = allProblems
          .where((p) => block.problemTypes!.contains(p.type.name))
          .toList();
    }

    return SupportBlockResult.problemSummary(
      problems: allProblems,
      showCount: block.showCount,
      showList: block.showList,
      maxListItems: block.maxListItems,
      title: block.title ?? 'Issues',
    );
  }

  /// Computes workflow progress from a list of workflow items (legacy method)
  WorkflowProgress computeWorkflowProgressLegacy<T>(
    List<WorkflowItem<T>> items,
  ) {
    final total = items.length;
    final completed = items
        .where((i) => i.status == WorkflowItemStatus.completed)
        .length;
    final skipped = items
        .where((i) => i.status == WorkflowItemStatus.skipped)
        .length;
    final pending = items
        .where((i) => i.status == WorkflowItemStatus.pending)
        .length;

    return WorkflowProgress(
      total: total,
      completed: completed,
      skipped: skipped,
      pending: pending,
    );
  }

  /// Checks if a support block should be displayed based on current context.
  bool shouldDisplay(SupportBlock block) {
    // All blocks are displayed by default.
    // Specific visibility logic can be added here.
    return true;
  }

  /// Gets the display order for sorting support blocks.
  int getDisplayOrder(SupportBlock block) {
    return switch (block) {
      WorkflowProgressBlock(:final order) => order,
      QuickActionsBlock(:final order) => order,
      ContextSummaryBlock(:final order) => order,
      RelatedEntitiesBlock(:final order) => order,
      StatsBlock(:final order) => order,
      ProblemSummaryBlock(:final order) => order,
      EmptyStateBlock(:final order) => order,
      EntityHeaderBlock(:final order) => order,
    };
  }

  /// Sorts support blocks by their display order.
  List<SupportBlock> sortByOrder(List<SupportBlock> blocks) {
    return blocks.toList()
      ..sort((a, b) => getDisplayOrder(a).compareTo(getDisplayOrder(b)));
  }

  /// Computes just the problem count for a ProblemSummaryBlock.
  ///
  /// This is a convenience method for the UI layer that doesn't need the full
  /// SupportBlockResult. For full results, use [compute] instead.
  Future<int> computeProblemCount(
    ProblemSummaryBlock block, {
    List<Task>? tasks,
    List<Project>? projects,
    DisplayConfig? displayConfig,
  }) async {
    // If no data provided, return 0
    if (tasks == null || projects == null || displayConfig == null) {
      return 0;
    }

    final taskProblems = await _problemDetectorService.detectTaskProblems(
      tasks: tasks,
      displayConfig: displayConfig,
    );
    final projectProblems = await _problemDetectorService.detectProjectProblems(
      projects: projects,
      displayConfig: displayConfig,
    );

    var allProblems = [...taskProblems, ...projectProblems];

    // Filter by problem types if specified
    if (block.problemTypes != null && block.problemTypes!.isNotEmpty) {
      allProblems = allProblems
          .where((p) => block.problemTypes!.contains(p.type.name))
          .toList();
    }

    return allProblems.length;
  }
}
