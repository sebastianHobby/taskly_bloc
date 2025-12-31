import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/filtering/task_rules/task_rule_set.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/models/task.dart';

/// Priority bucket rule for grouping tasks by priority.
class TaskPriorityBucketRule {
  const TaskPriorityBucketRule({
    required this.priority,
    required this.name,
    required this.ruleSets,
    this.limit,
    this.sortCriterion,
  });

  factory TaskPriorityBucketRule.fromJson(Map<String, dynamic> json) {
    final ruleSets = (json['ruleSets'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(TaskRuleSet.fromJson)
        .toList(growable: false);

    return TaskPriorityBucketRule(
      priority: json['priority'] as int? ?? 1,
      name: json['name'] as String? ?? 'Priority 1',
      limit: json['limit'] as int?,
      sortCriterion: json['sortCriterion'] == null
          ? null
          : SortCriterion.fromJson(
              json['sortCriterion'] as Map<String, dynamic>,
            ),
      ruleSets: ruleSets,
    );
  }

  final int priority;
  final String name;
  final List<TaskRuleSet> ruleSets;
  final int? limit;
  final SortCriterion? sortCriterion;

  TaskPriorityBucketRule copyWith({
    int? priority,
    String? name,
    List<TaskRuleSet>? ruleSets,
    int? limit,
    SortCriterion? sortCriterion,
  }) {
    return TaskPriorityBucketRule(
      priority: priority ?? this.priority,
      name: name ?? this.name,
      ruleSets: ruleSets ?? this.ruleSets,
      limit: limit ?? this.limit,
      sortCriterion: sortCriterion ?? this.sortCriterion,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'priority': priority,
    'name': name,
    'ruleSets': ruleSets.map((set) => set.toJson()).toList(),
    'limit': limit,
    'sortCriterion': sortCriterion?.toJson(),
  };

  /// Evaluates whether a task matches this bucket's rule sets.
  /// A task matches if ANY of the rule sets evaluate to true (OR logic).
  bool evaluate(Task task, EvaluationContext context) {
    if (ruleSets.isEmpty) return true;
    return ruleSets.any((ruleSet) => ruleSet.evaluate(task, context));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskPriorityBucketRule &&
        other.priority == priority &&
        other.name == name &&
        other.limit == limit &&
        other.sortCriterion == sortCriterion &&
        _listEquals(other.ruleSets, ruleSets);
  }

  @override
  int get hashCode => Object.hash(
    priority,
    name,
    limit,
    sortCriterion,
    Object.hashAll(ruleSets),
  );
}

/// Helper function for list equality comparison.
bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
