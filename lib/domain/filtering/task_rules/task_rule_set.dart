import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/filtering/task_rules/rule_types.dart';
import 'package:taskly_bloc/domain/filtering/task_rules/task_rule.dart';
import 'package:taskly_bloc/domain/models/task.dart';

/// Rule set containing multiple task rules with a boolean operator.
class TaskRuleSet {
  const TaskRuleSet({
    required this.operator,
    required this.rules,
  });

  factory TaskRuleSet.fromJson(Map<String, dynamic> json) {
    final rules = (json['rules'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(TaskRule.fromJson)
        .toList(growable: false);
    return TaskRuleSet(
      operator: RuleSetOperator.values.byName(
        json['operator'] as String? ?? RuleSetOperator.and.name,
      ),
      rules: rules,
    );
  }

  final RuleSetOperator operator;
  final List<TaskRule> rules;

  /// Evaluates this rule set against a task with full evaluation context.
  bool evaluate(Task task, EvaluationContext context) {
    if (rules.isEmpty) return true;

    return switch (operator) {
      RuleSetOperator.and => rules.every(
        (rule) => rule.evaluate(task, context),
      ),
      RuleSetOperator.or => rules.any((rule) => rule.evaluate(task, context)),
    };
  }

  /// Validates all rules in this rule set and returns error messages.
  List<String> validate() {
    final errors = <String>[];

    if (rules.isEmpty) {
      errors.add('Rule set must contain at least one rule');
    }

    for (int i = 0; i < rules.length; i++) {
      final ruleErrors = rules[i].validate();
      for (final error in ruleErrors) {
        errors.add('Rule ${i + 1}: $error');
      }
    }

    return errors;
  }

  /// Creates a copy with optional parameter overrides.
  TaskRuleSet copyWith({
    RuleSetOperator? operator,
    List<TaskRule>? rules,
  }) {
    return TaskRuleSet(
      operator: operator ?? this.operator,
      rules: rules ?? this.rules,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'operator': operator.name,
    'rules': rules.map((rule) => rule.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskRuleSet &&
        other.operator == operator &&
        _listEquals(other.rules, rules);
  }

  @override
  int get hashCode => Object.hash(operator, Object.hashAll(rules));
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
