import 'package:collection/collection.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';

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

/// Builds next actions groupings for bucketing and sorting.
class NextActionsViewBuilder {
  NextActionsViewBuilder();

  /// Filters bucket rules for evaluation based on settings.
  /// Returns new bucket rules with filtered rule sets, preserving structure.
  List<TaskPriorityBucketRule> _filterBucketRulesForEvaluation(
    List<TaskPriorityBucketRule> bucketRules,
    NextActionsSettings settings,
  ) {
    return bucketRules.map((bucket) {
      final filteredRuleSets = bucket.ruleSets.map((ruleSet) {
        final filteredRules = ruleSet.rules.where((rule) {
          // Filter start date rules if excludeFutureStartDates is enabled
          if (settings.excludeFutureStartDates && rule is DateRule) {
            if (rule.field == DateRuleField.startDate) {
              return false;
            }
          }

          // Filter project null/not-null rules if includeInboxTasks is disabled
          if (!settings.includeInboxTasks && rule is ProjectRule) {
            if (rule.operator == ProjectRuleOperator.isNull ||
                rule.operator == ProjectRuleOperator.isNotNull) {
              return false;
            }
          }

          return true;
        }).toList();

        return ruleSet.copyWith(rules: filteredRules);
      }).toList();

      return bucket.copyWith(ruleSets: filteredRuleSets);
    }).toList();
  }

  NextActionsSelection build({
    required List<Task> tasks,
    required NextActionsSettings settings,
    DateTime? now,
  }) {
    final bucketRules = settings.effectiveBucketRules;
    // Filter rules for evaluation based on settings
    final filteredBucketRules = _filterBucketRulesForEvaluation(
      bucketRules,
      settings,
    );
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

    // Group tasks by priority buckets by evaluating bucket rules
    final bucketed = <int, List<Task>>{};
    for (final task in tasks) {
      for (final bucketRule in filteredBucketRules) {
        if (bucketRule.evaluate(task, evaluationContext)) {
          bucketed.putIfAbsent(bucketRule.priority, () => []).add(task);
          break; // Task assigned to first matching bucket
        }
      }
    }

    final priorityBuckets = <int, Map<String, List<Task>>>{};
    final projectsById = <String, Project>{};
    final projectTaskCounts = <String, int>{};

    // Include all configured priorities, not just those with tasks
    // This ensures empty priority groups are displayed
    final allPriorities = bucketRules.map((r) => r.priority).toSet();
    final sortedPriorities = <int>{
      ...allPriorities,
      ...bucketed.keys.cast<int>(),
    }.toList()..sort();

    // Process each priority bucket in order
    for (final priority in sortedPriorities) {
      final bucketTasks = bucketed[priority];
      if (bucketTasks == null || bucketTasks.isEmpty) {
        // Keep the priority in the list but with no tasks
        continue;
      }

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
        final projectId = entry.project.id;
        final currentCount = projectTaskCounts[projectId] ?? 0;

        // Calculate how many more tasks this project can take
        final remainingSlots = tasksPerProject - currentCount;

        if (remainingSlots <= 0) {
          // Project has already reached its limit
          continue;
        }

        final tasksForProject = [...entry.tasks]
          ..sort((a, b) => _compareWithCriteria(a, b, ordering));

        // Take only as many tasks as we have slots for
        final tasksToInclude = tasksForProject
            .take(remainingSlots)
            .toList(growable: false);

        if (tasksToInclude.isNotEmpty) {
          final bucket = priorityBuckets.putIfAbsent(priority, () => {});
          bucket[projectId] = tasksToInclude;
          projectsById[projectId] = entry.project;
          projectTaskCounts[projectId] = currentCount + tasksToInclude.length;
        }
      }
    }

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
