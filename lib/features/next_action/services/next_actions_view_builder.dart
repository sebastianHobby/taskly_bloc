import 'package:collection/collection.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/tasks/utils/task_selector.dart';

class NextActionsSelection {
  const NextActionsSelection({
    required this.priorityBuckets,
    required this.projectsById,
    required this.bucketRuleByPriority,
    required this.sortedPriorities,
    required this.fallbackCriterion,
  });

  final Map<int, Map<String, List<Task>>> priorityBuckets;
  final Map<String, Project> projectsById;
  final Map<int, TaskPriorityBucketRule> bucketRuleByPriority;
  final List<int> sortedPriorities;
  final SortCriterion fallbackCriterion;

  int get totalCount => priorityBuckets.values
      .map((bucket) => bucket.values.map((tasks) => tasks.length).sum)
      .sum;
}

/// Builds next actions groupings using TaskSelector for bucketing and sorting.
class NextActionsViewBuilder {
  NextActionsViewBuilder({
    TaskSelector? taskSelector,
  }) : _taskSelector = taskSelector ?? TaskSelector();

  final TaskSelector _taskSelector;

  NextActionsSelection build({
    required List<Task> tasks,
    required NextActionsSettings settings,
    DateTime? now,
  }) {
    final bucketRules = settings.bucketRules.isEmpty
        ? NextActionsSettings.defaultBucketRules
        : settings.bucketRules;
    final bucketRuleByPriority = {
      for (final rule in bucketRules) rule.priority: rule,
    };
    final criteria = settings.sortPreferences.sanitizedCriteria(
      SortField.values.toList(growable: false),
    );
    final fallbackCriterion = criteria.isNotEmpty
        ? criteria.first
        : const SortCriterion(field: SortField.deadlineDate);
    final tasksPerProject = settings.tasksPerProject < 1
        ? 1
        : settings.tasksPerProject;
    final includeInbox = settings.includeInboxTasks;

    final today = dateOnly(now ?? DateTime.now());

    // Create evaluation context for enhanced rule evaluation
    final evaluationContext = EvaluationContext(
      today: today,
      // Could be extended with projects and labels if needed
    );

    final bucketed = _taskSelector.groupByPriorityBuckets(
      tasks: tasks,
      bucketRules: bucketRules,
      sortCriteria: criteria,
      now: today,
      context: evaluationContext,
    );

    final priorityBuckets = <int, Map<String, List<Task>>>{};
    final projectsById = <String, Project>{};

    bucketed.forEach((priority, bucketTasks) {
      final criterion =
          bucketRuleByPriority[priority]?.sortCriterion ?? fallbackCriterion;
      final grouped = _groupTasksByProject(
        bucketTasks,
        includeInbox: includeInbox,
      );

      final ordering = <SortCriterion>[
        criterion,
        ...criteria.where((c) => c.field != criterion.field),
      ];

      for (final entry in grouped.values) {
        final tasksForProject = [...entry.tasks]
          ..sort((a, b) => _compareWithCriteria(a, b, ordering));
        final limited = tasksForProject.take(tasksPerProject);
        final bucket = priorityBuckets.putIfAbsent(priority, () => {});
        bucket[entry.project.id] = limited.toList(growable: false);
        projectsById[entry.project.id] = entry.project;
      }
    });

    final sortedPriorities = priorityBuckets.keys.toList()..sort();

    return NextActionsSelection(
      priorityBuckets: priorityBuckets,
      projectsById: projectsById,
      bucketRuleByPriority: bucketRuleByPriority,
      sortedPriorities: sortedPriorities,
      fallbackCriterion: fallbackCriterion,
    );
  }

  Map<String, ({Project project, List<Task> tasks})> _groupTasksByProject(
    List<Task> tasks, {
    required bool includeInbox,
  }) {
    final map = <String, ({Project project, List<Task> tasks})>{};
    final inboxProject = includeInbox
        ? Project(
            id: 'inbox',
            name: 'Inbox',
            createdAt: DateTime.fromMillisecondsSinceEpoch(0),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
            completed: false,
          )
        : null;

    for (final task in tasks) {
      final project = task.project ?? inboxProject;
      if (project == null) continue;
      final existing = map[project.id];
      if (existing != null) {
        existing.tasks.add(task);
        continue;
      }
      map[project.id] = (project: project, tasks: [task]);
    }

    return map;
  }

  int _compareNullableDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  int _compareWithCriteria(
    Task a,
    Task b,
    List<SortCriterion> criteria,
  ) {
    for (final criterion in criteria) {
      final compare = switch (criterion.field) {
        SortField.name => a.name.compareTo(b.name),
        SortField.startDate => _compareNullableDate(a.startDate, b.startDate),
        SortField.deadlineDate => _compareNullableDate(
          a.deadlineDate,
          b.deadlineDate,
        ),
        SortField.createdDate => _compareNullableDate(a.createdAt, b.createdAt),
        SortField.updatedDate => _compareNullableDate(a.updatedAt, b.updatedAt),
      };

      if (compare == 0) continue;
      if (criterion.direction == SortDirection.descending) {
        return -compare;
      }
      return compare;
    }

    return a.name.compareTo(b.name);
  }
}
