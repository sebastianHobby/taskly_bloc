import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/core/shared/utils/sort_utils.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/domain.dart';

/// Context for rule evaluation containing relevant data and settings.
class EvaluationContext {
  const EvaluationContext({
    required this.today,
    this.projects = const {},
    this.labels = const {},
  });

  final DateTime today;
  final Map<String, Project> projects;
  final Map<String, Label> labels;

  EvaluationContext copyWith({
    DateTime? today,
    Map<String, Project>? projects,
    Map<String, Label>? labels,
  }) {
    return EvaluationContext(
      today: today ?? this.today,
      projects: projects ?? this.projects,
      labels: labels ?? this.labels,
    );
  }
}

/// Compiled and optimized rule set for improved performance.
class CompiledRuleSet {
  CompiledRuleSet(List<TaskRuleSet> ruleSets) : _compiled = _compile(ruleSets);

  final bool Function(Task, EvaluationContext) _compiled;

  /// Evaluates the compiled rules against a task.
  bool evaluate(Task task, EvaluationContext context) =>
      _compiled(task, context);

  static bool Function(Task, EvaluationContext) _compile(
    List<TaskRuleSet> ruleSets,
  ) {
    if (ruleSets.isEmpty) {
      return (task, context) => true;
    }

    // For single rule set, optimize directly
    if (ruleSets.length == 1) {
      final ruleSet = ruleSets.first;
      return ruleSet.evaluate;
    }

    // For multiple rule sets (OR logic between sets)
    return (task, context) {
      return ruleSets.any((ruleSet) => ruleSet.evaluate(task, context));
    };
  }
}

/// Filters tasks using typed rules that encapsulate their own evaluation.
class TaskSelector {
  TaskSelector();

  // Cache for compiled rule sets to improve performance
  final Map<String, CompiledRuleSet> _ruleSetCache = {};
  static const int _maxCacheSize = 50; // Prevent memory leaks

  /// Default ordered sort criteria used across task lists.
  static const List<SortCriterion> defaultSortCriteria = [
    SortCriterion(field: SortField.deadlineDate),
    SortCriterion(field: SortField.startDate),
    SortCriterion(field: SortField.name),
  ];

  /// Returns tasks that satisfy any of the provided [ruleSets], optionally
  /// sorted.
  List<Task> filter({
    required List<Task> tasks,
    List<TaskRuleSet>? ruleSets,
    List<SortCriterion>? sortCriteria,
    int? limit,
    DateTime? now,
    EvaluationContext? context,
  }) {
    final today = dateOnly(now ?? DateTime.now());
    final evaluationContext = context ?? EvaluationContext(today: today);
    final effectiveRuleSets = _effectiveRuleSets(ruleSets);

    List<Task> filtered;
    if (effectiveRuleSets.isEmpty) {
      filtered = List<Task>.from(tasks);
    } else {
      final compiled = _getCompiledRuleSet(effectiveRuleSets);
      filtered = tasks
          .where((task) => compiled.evaluate(task, evaluationContext))
          .toList(growable: false);
    }

    if (sortCriteria == null || sortCriteria.isEmpty) return filtered;

    final criteria = sanitizeCriteria(sortCriteria);
    filtered.sort((a, b) => _compareWithCriteria(a, b, criteria));

    if (limit == null || limit <= 0 || filtered.length <= limit) {
      return filtered;
    }

    return filtered.take(limit).toList(growable: false);
  }

  /// Groups tasks into priority buckets based on rule sets.
  ///
  /// Each bucket supplies a `priority` and a list of rules. Tasks that match
  /// multiple buckets are assigned only to the first bucket in ascending
  /// priority order.
  Map<int, List<Task>> groupByPriorityBuckets({
    required List<Task> tasks,
    required List<TaskPriorityBucketRule> bucketRules,
    List<SortCriterion>? sortCriteria,
    DateTime? now,
    EvaluationContext? context,
  }) {
    if (bucketRules.isEmpty) return const {};

    final today = dateOnly(now ?? DateTime.now());
    final evaluationContext = context ?? EvaluationContext(today: today);
    final assigned = <String>{};
    final buckets = [...bucketRules]
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final criteria = sortCriteria == null || sortCriteria.isEmpty
        ? null
        : sanitizeCriteria(sortCriteria);

    final result = <int, List<Task>>{};

    for (final bucket in buckets) {
      final effectiveRuleSets = _effectiveRuleSets(bucket.ruleSets);
      if (effectiveRuleSets.isEmpty) continue;

      final matches = <Task>[];
      for (final task in tasks) {
        if (assigned.contains(task.id)) continue;
        if (_matchesAnyRuleSet(task, effectiveRuleSets, evaluationContext)) {
          matches.add(task);
          assigned.add(task.id);
        }
      }

      if (matches.isEmpty) continue;

      if (criteria != null) {
        matches.sort((a, b) => _compareWithCriteria(a, b, criteria));
      }

      final limit = bucket.limit;
      if (limit != null && limit > 0 && matches.length > limit) {
        result[bucket.priority] = matches.take(limit).toList(growable: false);
      } else {
        result[bucket.priority] = matches;
      }
    }

    return result;
  }

  /// Returns an unfiltered configuration with default ordering.
  static TaskSelectorConfig all({
    List<SortCriterion>? sortCriteria,
  }) {
    return TaskSelectorConfig(
      ruleSets: const [],
      sortCriteria: sanitizeCriteria(
        sortCriteria ?? defaultSortCriteria,
      ),
    );
  }

  /// Filters tasks to the inbox (no project).
  static TaskSelectorConfig inbox({
    List<SortCriterion>? sortCriteria,
  }) {
    return TaskSelectorConfig(
      ruleSets: const [
        TaskRuleSet(
          operator: RuleSetOperator.and,
          rules: [
            ProjectRule(
              operator: ProjectRuleOperator.isNull,
            ),
          ],
        ),
      ],
      sortCriteria: sanitizeCriteria(
        sortCriteria ?? defaultSortCriteria,
      ),
    );
  }

  /// Filters tasks for a specific project.
  static TaskSelectorConfig forProject(
    String projectId, {
    List<SortCriterion>? sortCriteria,
  }) {
    return TaskSelectorConfig(
      ruleSets: [
        TaskRuleSet(
          operator: RuleSetOperator.and,
          rules: [
            ProjectRule(
              operator: ProjectRuleOperator.matches,
              projectId: projectId,
            ),
          ],
        ),
      ],
      sortCriteria: sanitizeCriteria(
        sortCriteria ?? defaultSortCriteria,
      ),
    );
  }

  /// Filters tasks for a specific label or value.
  static TaskSelectorConfig forLabel(
    String labelId, {
    LabelType labelType = LabelType.label,
    List<SortCriterion>? sortCriteria,
  }) {
    return TaskSelectorConfig(
      ruleSets: [
        TaskRuleSet(
          operator: RuleSetOperator.and,
          rules: [
            LabelRule(
              operator: LabelRuleOperator.hasAll,
              labelIds: [labelId],
              labelType: labelType,
            ),
          ],
        ),
      ],
      sortCriteria: sanitizeCriteria(
        sortCriteria ?? defaultSortCriteria,
      ),
    );
  }

  /// Filters tasks due or starting on/before today.
  static TaskSelectorConfig today({
    required DateTime now,
    List<SortCriterion>? sortCriteria,
  }) {
    final todayOnly = dateOnly(now);
    return TaskSelectorConfig(
      ruleSets: [
        TaskRuleSet(
          operator: RuleSetOperator.or,
          rules: [
            DateRule(
              field: DateRuleField.deadlineDate,
              operator: DateRuleOperator.onOrBefore,
              date: todayOnly,
            ),
            DateRule(
              field: DateRuleField.startDate,
              operator: DateRuleOperator.onOrBefore,
              date: todayOnly,
            ),
          ],
        ),
      ],
      sortCriteria: sanitizeCriteria(
        sortCriteria ?? defaultSortCriteria,
      ),
    );
  }

  /// Filters tasks due or starting after today.
  static TaskSelectorConfig upcoming({
    required DateTime now,
    List<SortCriterion>? sortCriteria,
  }) {
    final tomorrow = dateOnly(now.add(const Duration(days: 1)));
    return TaskSelectorConfig(
      ruleSets: [
        TaskRuleSet(
          operator: RuleSetOperator.or,
          rules: [
            DateRule(
              field: DateRuleField.startDate,
              operator: DateRuleOperator.onOrAfter,
              date: tomorrow,
            ),
            DateRule(
              field: DateRuleField.deadlineDate,
              operator: DateRuleOperator.onOrAfter,
              date: tomorrow,
            ),
          ],
        ),
      ],
      sortCriteria: sanitizeCriteria(
        sortCriteria ?? defaultSortCriteria,
      ),
    );
  }

  /// Filters active tasks for next actions, optionally including inbox tasks.
  static TaskSelectorConfig nextActions({
    required bool includeInbox,
    List<SortCriterion>? sortCriteria,
  }) {
    final rules = <TaskRule>[
      const BooleanRule(
        field: BooleanRuleField.completed,
        operator: BooleanRuleOperator.isFalse,
      ),
    ];

    if (!includeInbox) {
      rules.add(
        const ProjectRule(
          operator: ProjectRuleOperator.isNotNull,
        ),
      );
    }

    return TaskSelectorConfig(
      ruleSets: [
        TaskRuleSet(
          operator: RuleSetOperator.and,
          rules: rules,
        ),
      ],
      sortCriteria: sanitizeCriteria(
        sortCriteria ?? defaultSortCriteria,
      ),
    );
  }

  static List<SortCriterion> sanitizeCriteria(List<SortCriterion> raw) {
    final allowedFields = SortField.values.toSet();
    final sanitized = <SortCriterion>[];

    for (final criterion in raw) {
      if (!allowedFields.contains(criterion.field)) continue;
      final already = sanitized.any((c) => c.field == criterion.field);
      if (already) continue;
      sanitized.add(criterion);
    }

    if (sanitized.isEmpty) {
      sanitized.add(const SortCriterion(field: SortField.deadlineDate));
    }

    return sanitized;
  }

  /// Gets or creates a compiled rule set from cache.
  CompiledRuleSet _getCompiledRuleSet(List<TaskRuleSet> ruleSets) {
    final cacheKey = _generateCacheKey(ruleSets);

    if (_ruleSetCache.containsKey(cacheKey)) {
      return _ruleSetCache[cacheKey]!;
    }

    // Manage cache size
    if (_ruleSetCache.length >= _maxCacheSize) {
      _ruleSetCache.clear(); // Simple eviction strategy
    }

    final compiled = CompiledRuleSet(ruleSets);
    _ruleSetCache[cacheKey] = compiled;
    return compiled;
  }

  /// Generates a cache key for the given rule sets.
  String _generateCacheKey(List<TaskRuleSet> ruleSets) {
    if (ruleSets.isEmpty) return 'empty';

    final buffer = StringBuffer();
    for (int i = 0; i < ruleSets.length; i++) {
      if (i > 0) buffer.write('|');
      buffer.write(_ruleSetToKey(ruleSets[i]));
    }
    return buffer.toString();
  }

  String _ruleSetToKey(TaskRuleSet ruleSet) {
    final buffer = StringBuffer()
      ..write(ruleSet.operator.name)
      ..write(':');

    for (int i = 0; i < ruleSet.rules.length; i++) {
      if (i > 0) buffer.write(',');
      final rule = ruleSet.rules[i];
      buffer.write('${rule.type.name}:${rule.hashCode}');
    }

    return buffer.toString();
  }

  /// Clears the compiled rule set cache.
  void clearCache() {
    _ruleSetCache.clear();
  }

  List<TaskRuleSet> _effectiveRuleSets(List<TaskRuleSet>? ruleSets) {
    if (ruleSets == null || ruleSets.isEmpty) return const [];
    return ruleSets
        .where((set) => set.rules.isNotEmpty)
        .toList(growable: false);
  }

  bool _matchesAnyRuleSet(
    Task task,
    List<TaskRuleSet> ruleSets,
    EvaluationContext context,
  ) {
    for (final ruleSet in ruleSets) {
      if (ruleSet.evaluate(task, context)) return true;
    }
    return false;
  }

  int _compareWithCriteria(
    Task a,
    Task b,
    List<SortCriterion> criteria,
  ) {
    for (final criterion in criteria) {
      final compare = switch (criterion.field) {
        SortField.name => compareAsciiLowerCase(a.name, b.name),
        SortField.startDate => compareNullableDate(a.startDate, b.startDate),
        SortField.deadlineDate => compareNullableDate(
          a.deadlineDate,
          b.deadlineDate,
        ),
        SortField.createdDate => compareNullableDate(a.createdAt, b.createdAt),
        SortField.updatedDate => compareNullableDate(a.updatedAt, b.updatedAt),
      };

      if (compare == 0) continue;
      if (criterion.direction == SortDirection.descending) {
        return -compare;
      }
      return compare;
    }

    return compareAsciiLowerCase(a.name, b.name);
  }
}

class TaskSelectorConfig {
  const TaskSelectorConfig({
    required this.ruleSets,
    required this.sortCriteria,
  });

  final List<TaskRuleSet> ruleSets;
  final List<SortCriterion> sortCriteria;

  TaskSelectorConfig copyWith({
    List<TaskRuleSet>? ruleSets,
    List<SortCriterion>? sortCriteria,
  }) {
    return TaskSelectorConfig(
      ruleSets: ruleSets ?? this.ruleSets,
      sortCriteria: sortCriteria ?? this.sortCriteria,
    );
  }

  TaskSelectorConfig withCompletion(TaskCompletionFilter completion) {
    return TaskSelectorConfig(
      ruleSets: _withCompletion(ruleSets, completion),
      sortCriteria: sortCriteria,
    );
  }

  TaskCompletionFilter get completionFilter {
    for (final set in ruleSets) {
      for (final rule in set.rules) {
        if (rule is! BooleanRule) continue;
        if (rule.field != BooleanRuleField.completed) continue;
        if (rule.operator == BooleanRuleOperator.isFalse) {
          return TaskCompletionFilter.active;
        }
        if (rule.operator == BooleanRuleOperator.isTrue) {
          return TaskCompletionFilter.completed;
        }
      }
    }

    return TaskCompletionFilter.all;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskSelectorConfig &&
        _listEquals(other.ruleSets, ruleSets) &&
        _listEquals(other.sortCriteria, sortCriteria);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(ruleSets),
    Object.hashAll(sortCriteria),
  );
}

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

/// Base class for all task filtering rules.
abstract class TaskRule {
  const TaskRule();

  /// The type of this rule for serialization and UI purposes.
  RuleType get type;

  /// Evaluates whether this rule applies to the given task.
  bool applies(Task task, DateTime today) =>
      evaluate(task, EvaluationContext(today: today));

  /// Enhanced evaluation method with full context.
  bool evaluate(Task task, EvaluationContext context);

  /// Validates the rule configuration and returns error messages.
  List<String> validate() => const [];

  /// Serializes the rule to JSON.
  Map<String, dynamic> toJson();

  static TaskRule fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;
    final type = RuleType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => RuleType.boolean,
    );

    switch (type) {
      case RuleType.date:
        return DateRule.fromJson(json);
      case RuleType.boolean:
        return BooleanRule.fromJson(json);
      case RuleType.labels:
        return LabelRule.fromJson(json);
      case RuleType.value:
        return ValueRule.fromJson(json);
      case RuleType.project:
        return ProjectRule.fromJson(json);
    }
  }
}

class DateRule extends TaskRule {
  const DateRule({
    required this.field,
    required this.operator,
    this.date,
    this.startDate,
    this.endDate,
    this.relativeComparison,
    this.relativeDays,
  });

  factory DateRule.fromJson(Map<String, dynamic> json) {
    return DateRule(
      field: DateRuleField.values.byName(
        json['field'] as String? ?? DateRuleField.deadlineDate.name,
      ),
      operator: DateRuleOperator.values.byName(
        json['operator'] as String? ?? DateRuleOperator.onOrAfter.name,
      ),
      date: json['date'] == null
          ? null
          : DateTime.tryParse(json['date'] as String),
      startDate: json['startDate'] == null
          ? null
          : DateTime.tryParse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.tryParse(json['endDate'] as String),
      relativeComparison: json['relativeComparison'] == null
          ? null
          : RelativeComparison.values.byName(
              json['relativeComparison'] as String,
            ),
      relativeDays: json['relativeDays'] as int?,
    );
  }

  final DateRuleField field;
  final DateRuleOperator operator;
  final DateTime? date;
  final DateTime? startDate;
  final DateTime? endDate;
  final RelativeComparison? relativeComparison;
  final int? relativeDays;

  @override
  RuleType get type => RuleType.date;

  @override
  bool evaluate(Task task, EvaluationContext context) {
    return applies(task, context.today);
  }

  @override
  List<String> validate() {
    final errors = <String>[];

    switch (operator) {
      case DateRuleOperator.between:
        if (startDate == null || endDate == null) {
          errors.add('Between operator requires both start and end dates');
        } else if (endDate!.isBefore(startDate!)) {
          errors.add('End date must be after start date');
        }
      case DateRuleOperator.relative:
        if (relativeComparison == null) {
          errors.add('Relative operator requires comparison type');
        }
        if (relativeDays == null) {
          errors.add('Relative operator requires days value');
        } else if (relativeDays! < 0) {
          errors.add('Relative days must be non-negative');
        }
      case DateRuleOperator.onOrAfter:
      case DateRuleOperator.onOrBefore:
      case DateRuleOperator.before:
      case DateRuleOperator.after:
      case DateRuleOperator.on:
        if (date == null) {
          errors.add('${operator.name} operator requires a date value');
        }
      case DateRuleOperator.isNull:
      case DateRuleOperator.isNotNull:
        // No additional validation needed
        break;
    }

    return errors;
  }

  @override
  bool applies(Task task, DateTime today) {
    final target = _extractDate(task);
    final dateOnlyTarget = target == null ? null : dateOnly(target);

    switch (operator) {
      case DateRuleOperator.onOrAfter:
        final pivot = _pivotDate(date);
        return dateOnlyTarget != null &&
            pivot != null &&
            !dateOnlyTarget.isBefore(pivot);
      case DateRuleOperator.onOrBefore:
        final pivot = _pivotDate(date);
        return dateOnlyTarget != null &&
            pivot != null &&
            !dateOnlyTarget.isAfter(pivot);
      case DateRuleOperator.before:
        final pivot = _pivotDate(date);
        return dateOnlyTarget != null &&
            pivot != null &&
            dateOnlyTarget.isBefore(pivot);
      case DateRuleOperator.after:
        final pivot = _pivotDate(date);
        return dateOnlyTarget != null &&
            pivot != null &&
            dateOnlyTarget.isAfter(pivot);
      case DateRuleOperator.on:
        final pivot = _pivotDate(date);
        return dateOnlyTarget != null &&
            pivot != null &&
            dateOnlyTarget.isAtSameMomentAs(pivot);
      case DateRuleOperator.between:
        final start = _pivotDate(startDate);
        final end = _pivotDate(endDate);
        if (start == null || end == null || end.isBefore(start)) return false;
        if (dateOnlyTarget == null) return false;
        return !dateOnlyTarget.isBefore(start) && !dateOnlyTarget.isAfter(end);
      case DateRuleOperator.relative:
        final comparison = relativeComparison;
        final days = relativeDays;
        if (comparison == null || days == null) return false;
        if (dateOnlyTarget == null) return false;
        final pivot = dateOnly(today.add(Duration(days: days)));
        return switch (comparison) {
          RelativeComparison.on => dateOnlyTarget.isAtSameMomentAs(pivot),
          RelativeComparison.before => dateOnlyTarget.isBefore(pivot),
          RelativeComparison.after => dateOnlyTarget.isAfter(pivot),
          RelativeComparison.onOrAfter => !dateOnlyTarget.isBefore(pivot),
          RelativeComparison.onOrBefore => !dateOnlyTarget.isAfter(pivot),
        };
      case DateRuleOperator.isNull:
        return target == null;
      case DateRuleOperator.isNotNull:
        return target != null;
    }
  }

  DateTime? _extractDate(Task task) {
    return switch (field) {
      DateRuleField.startDate => task.startDate,
      DateRuleField.deadlineDate => task.deadlineDate,
    };
  }

  DateTime? _pivotDate(DateTime? value) =>
      value == null ? null : dateOnly(value);

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type.name,
    'field': field.name,
    'operator': operator.name,
    'date': date?.toIso8601String(),
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'relativeComparison': relativeComparison?.name,
    'relativeDays': relativeDays,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRule &&
        other.field == field &&
        other.operator == operator &&
        other._datesEqual(date, other.date) &&
        other._datesEqual(startDate, other.startDate) &&
        other._datesEqual(endDate, other.endDate) &&
        other.relativeComparison == relativeComparison &&
        other.relativeDays == relativeDays;
  }

  bool _datesEqual(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.isAtSameMomentAs(b);
  }

  @override
  int get hashCode => Object.hash(
    field,
    operator,
    date?.millisecondsSinceEpoch,
    startDate?.millisecondsSinceEpoch,
    endDate?.millisecondsSinceEpoch,
    relativeComparison,
    relativeDays,
  );
}

class BooleanRule extends TaskRule {
  const BooleanRule({
    required this.field,
    required this.operator,
  });

  factory BooleanRule.fromJson(Map<String, dynamic> json) {
    return BooleanRule(
      field: BooleanRuleField.values.byName(
        json['field'] as String? ?? BooleanRuleField.completed.name,
      ),
      operator: BooleanRuleOperator.values.byName(
        json['operator'] as String? ?? BooleanRuleOperator.isFalse.name,
      ),
    );
  }

  final BooleanRuleField field;
  final BooleanRuleOperator operator;

  @override
  RuleType get type => RuleType.boolean;

  @override
  bool evaluate(Task task, EvaluationContext context) {
    return applies(task, context.today);
  }

  @override
  List<String> validate() {
    // BooleanRule is always valid as it has simple structure
    return const [];
  }

  @override
  bool applies(Task task, DateTime today) {
    final value = switch (field) {
      BooleanRuleField.completed => task.completed,
    };

    return switch (operator) {
      BooleanRuleOperator.isTrue => value,
      BooleanRuleOperator.isFalse => !value,
    };
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type.name,
    'field': field.name,
    'operator': operator.name,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BooleanRule &&
        other.field == field &&
        other.operator == operator;
  }

  @override
  int get hashCode => Object.hash(field, operator);
}

class LabelRule extends TaskRule {
  const LabelRule({
    required this.operator,
    this.labelIds = const <String>[],
    this.labelType = LabelType.label,
  });

  factory LabelRule.fromJson(Map<String, dynamic> json) {
    return LabelRule(
      operator: LabelRuleOperator.values.byName(
        json['operator'] as String? ?? LabelRuleOperator.hasAll.name,
      ),
      labelIds: (json['labelIds'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
      labelType: json['labelType'] == null
          ? LabelType.label
          : LabelType.values.byName(json['labelType'] as String),
    );
  }

  final LabelRuleOperator operator;
  final List<String> labelIds;
  final LabelType labelType;

  @override
  RuleType get type => RuleType.labels;

  @override
  bool evaluate(Task task, EvaluationContext context) {
    return applies(task, context.today);
  }

  @override
  List<String> validate() {
    final errors = <String>[];

    switch (operator) {
      case LabelRuleOperator.hasAll:
      case LabelRuleOperator.hasAny:
        if (labelIds.isEmpty) {
          errors.add(
            '${operator.name} operator requires at least one label ID',
          );
        } else {
          final nonEmptyIds = labelIds.where((id) => id.trim().isNotEmpty);
          if (nonEmptyIds.isEmpty) {
            errors.add('All label IDs are empty');
          }
        }
      case LabelRuleOperator.isNull:
      case LabelRuleOperator.isNotNull:
        // No additional validation needed
        break;
    }

    return errors;
  }

  @override
  bool applies(Task task, DateTime today) {
    final labels = task.labels.where((label) => label.type == labelType);

    if (operator == LabelRuleOperator.isNull) {
      return labels.isEmpty;
    }
    if (operator == LabelRuleOperator.isNotNull) {
      return labels.isNotEmpty;
    }

    if (labelIds.isEmpty) return false;
    final ids = labelIds.where((id) => id.isNotEmpty).toSet();
    if (ids.isEmpty) return false;

    final taskLabelIds = labels.map((label) => label.id).toSet();

    if (operator == LabelRuleOperator.hasAll) {
      return ids.every(taskLabelIds.contains);
    }

    return ids.any(taskLabelIds.contains);
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type.name,
    'operator': operator.name,
    'labelIds': labelIds,
    'labelType': labelType.name,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LabelRule &&
        other.operator == operator &&
        other.labelType == labelType &&
        _listEquals(other.labelIds, labelIds);
  }

  @override
  int get hashCode => Object.hash(
    operator,
    labelType,
    Object.hashAll(labelIds),
  );
}

class ValueRule extends TaskRule {
  const ValueRule({
    required this.operator,
    this.labelIds = const <String>[],
  });

  factory ValueRule.fromJson(Map<String, dynamic> json) {
    return ValueRule(
      operator: ValueRuleOperator.values.byName(
        json['operator'] as String? ?? ValueRuleOperator.hasAll.name,
      ),
      labelIds: (json['labelIds'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  final ValueRuleOperator operator;
  final List<String> labelIds;

  @override
  RuleType get type => RuleType.value;

  @override
  bool evaluate(Task task, EvaluationContext context) {
    return applies(task, context.today);
  }

  @override
  List<String> validate() {
    final errors = <String>[];

    switch (operator) {
      case ValueRuleOperator.hasAll:
      case ValueRuleOperator.hasAny:
        if (labelIds.isEmpty) {
          errors.add(
            '${operator.name} operator requires at least one value ID',
          );
        } else {
          final nonEmptyIds = labelIds.where((id) => id.trim().isNotEmpty);
          if (nonEmptyIds.isEmpty) {
            errors.add('All value IDs are empty');
          }
        }
      case ValueRuleOperator.isNull:
      case ValueRuleOperator.isNotNull:
        // No additional validation needed
        break;
    }

    return errors;
  }

  @override
  bool applies(Task task, DateTime today) {
    final values = task.labels.where((label) => label.type == LabelType.value);

    if (operator == ValueRuleOperator.isNull) {
      return values.isEmpty;
    }
    if (operator == ValueRuleOperator.isNotNull) {
      return values.isNotEmpty;
    }

    if (labelIds.isEmpty) return false;
    final ids = labelIds.where((id) => id.isNotEmpty).toSet();
    if (ids.isEmpty) return false;

    final taskValueIds = values.map((value) => value.id).toSet();

    if (operator == ValueRuleOperator.hasAll) {
      return ids.every(taskValueIds.contains);
    }

    return ids.any(taskValueIds.contains);
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type.name,
    'operator': operator.name,
    'labelIds': labelIds,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValueRule &&
        other.operator == operator &&
        _listEquals(other.labelIds, labelIds);
  }

  @override
  int get hashCode => Object.hash(operator, Object.hashAll(labelIds));
}

class ProjectRule extends TaskRule {
  const ProjectRule({
    required this.operator,
    this.projectId,
  });

  factory ProjectRule.fromJson(Map<String, dynamic> json) {
    return ProjectRule(
      operator: ProjectRuleOperator.values.byName(
        json['operator'] as String? ?? ProjectRuleOperator.matches.name,
      ),
      projectId: json['projectId'] as String?,
    );
  }

  final ProjectRuleOperator operator;
  final String? projectId;

  @override
  RuleType get type => RuleType.project;

  @override
  bool evaluate(Task task, EvaluationContext context) {
    return applies(task, context.today);
  }

  @override
  List<String> validate() {
    final errors = <String>[];

    switch (operator) {
      case ProjectRuleOperator.matches:
        if (projectId == null || projectId!.trim().isEmpty) {
          errors.add('Matches operator requires a project ID');
        }
      case ProjectRuleOperator.isNull:
      case ProjectRuleOperator.isNotNull:
        // No additional validation needed
        break;
    }

    return errors;
  }

  @override
  bool applies(Task task, DateTime today) {
    final id = task.projectId;
    return switch (operator) {
      ProjectRuleOperator.matches =>
        id != null && projectId != null && id == projectId,
      ProjectRuleOperator.isNull => id == null,
      ProjectRuleOperator.isNotNull => id != null,
    };
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': type.name,
    'operator': operator.name,
    'projectId': projectId,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProjectRule &&
        other.operator == operator &&
        other.projectId == projectId;
  }

  @override
  int get hashCode => Object.hash(operator, projectId);
}

enum RuleType {
  date,
  boolean,
  labels,
  project,
  value,
}

enum RuleSetOperator { and, or }

enum DateRuleField { startDate, deadlineDate }

enum DateRuleOperator {
  onOrAfter,
  onOrBefore,
  before,
  after,
  on,
  between,
  relative,
  isNull,
  isNotNull,
}

enum RelativeComparison { on, before, after, onOrAfter, onOrBefore }

enum BooleanRuleField { completed }

enum BooleanRuleOperator { isTrue, isFalse }

enum LabelRuleOperator { hasAll, hasAny, isNull, isNotNull }

enum ValueRuleOperator { hasAll, hasAny, isNull, isNotNull }

enum ProjectRuleOperator { matches, isNull, isNotNull }

/// Abstract factory for creating and managing rules of a specific type.
abstract class RuleFactory<T extends TaskRule> {
  const RuleFactory();

  /// Display name for this rule type in UI.
  String get displayName;

  /// List of supported operator names for this rule type.
  List<String> get supportedOperators;

  /// Creates a default rule instance of this type.
  T createDefault();

  /// Creates a rule from JSON data.
  T fromJson(Map<String, dynamic> json);

  /// Validates if this factory can handle the given rule type.
  bool canHandle(RuleType type);
}

/// Factory for creating DateRule instances.
class DateRuleFactory extends RuleFactory<DateRule> {
  const DateRuleFactory();

  @override
  String get displayName => 'Date Rule';

  @override
  List<String> get supportedOperators =>
      DateRuleOperator.values.map((e) => e.name).toList();

  @override
  DateRule createDefault() => const DateRule(
    field: DateRuleField.deadlineDate,
    operator: DateRuleOperator.onOrBefore,
  );

  @override
  DateRule fromJson(Map<String, dynamic> json) => DateRule.fromJson(json);

  @override
  bool canHandle(RuleType type) => type == RuleType.date;
}

/// Factory for creating BooleanRule instances.
class BooleanRuleFactory extends RuleFactory<BooleanRule> {
  const BooleanRuleFactory();

  @override
  String get displayName => 'Boolean Rule';

  @override
  List<String> get supportedOperators =>
      BooleanRuleOperator.values.map((e) => e.name).toList();

  @override
  BooleanRule createDefault() => const BooleanRule(
    field: BooleanRuleField.completed,
    operator: BooleanRuleOperator.isFalse,
  );

  @override
  BooleanRule fromJson(Map<String, dynamic> json) => BooleanRule.fromJson(json);

  @override
  bool canHandle(RuleType type) => type == RuleType.boolean;
}

/// Factory for creating LabelRule instances.
class LabelRuleFactory extends RuleFactory<LabelRule> {
  const LabelRuleFactory();

  @override
  String get displayName => 'Label Rule';

  @override
  List<String> get supportedOperators =>
      LabelRuleOperator.values.map((e) => e.name).toList();

  @override
  LabelRule createDefault() => const LabelRule(
    operator: LabelRuleOperator.hasAll,
  );

  @override
  LabelRule fromJson(Map<String, dynamic> json) => LabelRule.fromJson(json);

  @override
  bool canHandle(RuleType type) => type == RuleType.labels;
}

/// Factory for creating ValueRule instances.
class ValueRuleFactory extends RuleFactory<ValueRule> {
  const ValueRuleFactory();

  @override
  String get displayName => 'Value Rule';

  @override
  List<String> get supportedOperators =>
      ValueRuleOperator.values.map((e) => e.name).toList();

  @override
  ValueRule createDefault() => const ValueRule(
    operator: ValueRuleOperator.hasAll,
  );

  @override
  ValueRule fromJson(Map<String, dynamic> json) => ValueRule.fromJson(json);

  @override
  bool canHandle(RuleType type) => type == RuleType.value;
}

/// Factory for creating ProjectRule instances.
class ProjectRuleFactory extends RuleFactory<ProjectRule> {
  const ProjectRuleFactory();

  @override
  String get displayName => 'Project Rule';

  @override
  List<String> get supportedOperators =>
      ProjectRuleOperator.values.map((e) => e.name).toList();

  @override
  ProjectRule createDefault() => const ProjectRule(
    operator: ProjectRuleOperator.isNotNull,
  );

  @override
  ProjectRule fromJson(Map<String, dynamic> json) => ProjectRule.fromJson(json);

  @override
  bool canHandle(RuleType type) => type == RuleType.project;
}

/// Registry for rule factories that provides type-safe rule creation.
class RuleRegistry {
  static const Map<RuleType, RuleFactory> _factories = {
    RuleType.date: DateRuleFactory(),
    RuleType.boolean: BooleanRuleFactory(),
    RuleType.labels: LabelRuleFactory(),
    RuleType.project: ProjectRuleFactory(),
    RuleType.value: ValueRuleFactory(),
  };

  /// Gets the factory for the specified rule type.
  static RuleFactory<T> getFactory<T extends TaskRule>(RuleType type) {
    final factory = _factories[type];
    if (factory == null) {
      throw ArgumentError('No factory registered for rule type: $type');
    }
    return factory as RuleFactory<T>;
  }

  /// Gets all available factories.
  static Map<RuleType, RuleFactory> get factories =>
      Map.unmodifiable(_factories);

  /// Creates a default rule of the specified type.
  static TaskRule createDefaultRule(RuleType type) {
    return _factories[type]?.createDefault() ??
        (throw ArgumentError('No factory for type: $type'));
  }

  /// Gets display names for all rule types.
  static Map<RuleType, String> get displayNames => {
    for (final entry in _factories.entries) entry.key: entry.value.displayName,
  };
}

enum TaskCompletionFilter {
  all,
  active,
  completed,
}

List<TaskRuleSet> _withCompletion(
  List<TaskRuleSet> ruleSets,
  TaskCompletionFilter completion,
) {
  final updated = ruleSets
      .map(
        (set) => TaskRuleSet(
          operator: set.operator,
          rules: set.rules
              .where(
                (rule) =>
                    rule is! BooleanRule ||
                    rule.field != BooleanRuleField.completed,
              )
              .toList(growable: true),
        ),
      )
      .toList(growable: true);

  if (completion == TaskCompletionFilter.all) {
    return updated;
  }

  final completionRule = BooleanRule(
    field: BooleanRuleField.completed,
    operator: completion == TaskCompletionFilter.active
        ? BooleanRuleOperator.isFalse
        : BooleanRuleOperator.isTrue,
  );

  if (updated.isEmpty) {
    return [
      TaskRuleSet(
        operator: RuleSetOperator.and,
        rules: [completionRule],
      ),
    ];
  }

  updated[0].rules.add(completionRule);
  return updated;
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
