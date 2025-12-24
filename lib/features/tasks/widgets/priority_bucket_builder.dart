import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/tasks/utils/task_selector.dart';
import 'package:taskly_bloc/features/tasks/widgets/rule_set_builder.dart';

/// Widget for building priority bucket rules using the unified rule system.
class PriorityBucketBuilder extends StatefulWidget {
  const PriorityBucketBuilder({
    required this.buckets,
    required this.onChanged,
    super.key,
    this.availableLabels = const [],
    this.availableProjects = const [],
    this.excludeFutureStartDates = true,
    this.includeInboxTasks = false,
  });

  final List<TaskPriorityBucketRule> buckets;
  final ValueChanged<List<TaskPriorityBucketRule>> onChanged;
  final List<Label> availableLabels;
  final List<Project> availableProjects;
  final bool excludeFutureStartDates;
  final bool includeInboxTasks;

  @override
  State<PriorityBucketBuilder> createState() => _PriorityBucketBuilderState();
}

class _PriorityBucketBuilderState extends State<PriorityBucketBuilder> {
  void _addBucket() {
    final newBucket = TaskPriorityBucketRule(
      priority: widget.buckets.length + 1,
      name: 'New Priority Group',
      ruleSets: [
        TaskRuleSet(
          operator: RuleSetOperator.or,
          rules: [
            const DateRule(
              field: DateRuleField.deadlineDate,
              operator: DateRuleOperator.relative,
              relativeComparison: RelativeComparison.before,
              relativeDays: 7,
            ),
          ],
        ),
      ],
    );

    final updatedBuckets = [...widget.buckets, newBucket];
    widget.onChanged(updatedBuckets);
  }

  void _updateBucket(int index, TaskPriorityBucketRule bucket) {
    final updatedBuckets = [...widget.buckets];
    updatedBuckets[index] = bucket;
    widget.onChanged(updatedBuckets);
  }

  void _removeBucket(int index) {
    final updatedBuckets = [...widget.buckets];
    updatedBuckets.removeAt(index);
    widget.onChanged(updatedBuckets);
  }

  void _moveBucket(int from, int to) {
    final updatedBuckets = [...widget.buckets];
    final bucket = updatedBuckets.removeAt(from);
    updatedBuckets.insert(to, bucket);
    widget.onChanged(updatedBuckets);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Priority Groups',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: _addBucket,
                  icon: const Icon(Icons.add),
                  tooltip: 'Add priority group',
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (widget.buckets.isEmpty)
              const Text(
                'No priority groups configured. Add a priority group to get started.',
              )
            else
              ...widget.buckets.asMap().entries.map(
                (entry) => PriorityBucketEditor(
                  key: ValueKey(entry.key),
                  bucket: entry.value,
                  index: entry.key,
                  canMoveUp: entry.key > 0,
                  canMoveDown: entry.key < widget.buckets.length - 1,
                  availableLabels: widget.availableLabels,
                  availableProjects: widget.availableProjects,
                  excludeFutureStartDates: widget.excludeFutureStartDates,
                  includeInboxTasks: widget.includeInboxTasks,
                  onChanged: (bucket) => _updateBucket(entry.key, bucket),
                  onRemove: () => _removeBucket(entry.key),
                  onMoveUp: () => _moveBucket(entry.key, entry.key - 1),
                  onMoveDown: () => _moveBucket(entry.key, entry.key + 1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Editor for a single priority bucket rule.
class PriorityBucketEditor extends StatefulWidget {
  const PriorityBucketEditor({
    required this.bucket,
    required this.index,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onChanged,
    required this.onRemove,
    required this.onMoveUp,
    required this.onMoveDown,
    super.key,
    this.availableLabels = const [],
    this.availableProjects = const [],
    this.excludeFutureStartDates = true,
    this.includeInboxTasks = false,
  });

  final TaskPriorityBucketRule bucket;
  final int index;
  final bool canMoveUp;
  final bool canMoveDown;
  final ValueChanged<TaskPriorityBucketRule> onChanged;
  final VoidCallback onRemove;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final List<Label> availableLabels;
  final List<Project> availableProjects;
  final bool excludeFutureStartDates;
  final bool includeInboxTasks;

  @override
  State<PriorityBucketEditor> createState() => _PriorityBucketEditorState();
}

class _PriorityBucketEditorState extends State<PriorityBucketEditor> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bucket.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateBucket() {
    final name = _nameController.text.trim().isEmpty
        ? 'Priority ${widget.index + 1}'
        : _nameController.text.trim();

    final updatedBucket = widget.bucket.copyWith(
      name: name,
    );

    widget.onChanged(updatedBucket);
  }

  /// Filters rules from a rule set based on current settings.
  /// Returns a new rule set with filtered rules for display only.
  TaskRuleSet _filterRulesForDisplay(TaskRuleSet ruleSet) {
    final filteredRules = ruleSet.rules.where((rule) {
      // Filter start date rules if excludeFutureStartDates is enabled
      if (widget.excludeFutureStartDates && rule is DateRule) {
        if (rule.field == DateRuleField.startDate) {
          return false;
        }
      }

      // Filter project null/not-null rules if includeInboxTasks is disabled
      if (!widget.includeInboxTasks && rule is ProjectRule) {
        if (rule.operator == ProjectRuleOperator.isNull ||
            rule.operator == ProjectRuleOperator.isNotNull) {
          return false;
        }
      }

      return true;
    }).toList();

    return ruleSet.copyWith(rules: filteredRules);
  }

  /// Gets the list of available fields based on current settings.
  List<TaskField> _getAvailableFields() {
    final fields = <TaskField>[
      TaskField.deadlineDate,
    ];

    // Only show start date field if excludeFutureStartDates is false
    if (!widget.excludeFutureStartDates) {
      fields.insert(0, TaskField.startDate);
    }

    return fields;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with controls
            Row(
              children: [
                Text(
                  'Priority ${widget.index + 1}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove priority group',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description field with movement controls
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Group description',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _updateBucket(),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    if (widget.canMoveUp)
                      ElevatedButton(
                        onPressed: widget.onMoveUp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Icon(Icons.arrow_upward),
                      ),
                    if (widget.canMoveUp && widget.canMoveDown)
                      const SizedBox(height: 8),
                    if (widget.canMoveDown)
                      ElevatedButton(
                        onPressed: widget.onMoveDown,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Icon(Icons.arrow_downward),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Rule sets
            Text(
              'Rules',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),

            ...widget.bucket.ruleSets.asMap().entries.map(
              (entry) {
                final filteredRuleSet = _filterRulesForDisplay(entry.value);

                // Skip displaying empty rule sets
                if (filteredRuleSet.rules.isEmpty) {
                  return const SizedBox.shrink();
                }

                return RuleSetBuilder(
                  key: ValueKey('${widget.index}_${entry.key}'),
                  ruleSet: filteredRuleSet,
                  availableLabels: widget.availableLabels,
                  availableProjects: widget.availableProjects,
                  onChanged: (TaskRuleSet ruleSet) {
                    final updatedRuleSets = [...widget.bucket.ruleSets];
                    updatedRuleSets[entry.key] = ruleSet;
                    widget.onChanged(
                      widget.bucket.copyWith(ruleSets: updatedRuleSets),
                    );
                  },
                  showRemoveButton: widget.bucket.ruleSets.length > 1,
                  onRemove: widget.bucket.ruleSets.length > 1
                      ? () {
                          final updatedRuleSets = [...widget.bucket.ruleSets];
                          updatedRuleSets.removeAt(entry.key);
                          widget.onChanged(
                            widget.bucket.copyWith(ruleSets: updatedRuleSets),
                          );
                        }
                      : null,
                  compact: true,
                  availableFields: _getAvailableFields(),
                  relativeDateOnly: true,
                );
              },
            ),

            // Add rule set button
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  final newRuleSet = TaskRuleSet(
                    operator: RuleSetOperator.or,
                    rules: [
                      const DateRule(
                        field: DateRuleField.deadlineDate,
                        operator: DateRuleOperator.relative,
                        relativeComparison: RelativeComparison.before,
                        relativeDays: -7,
                      ),
                    ],
                  );
                  final updatedRuleSets = [
                    ...widget.bucket.ruleSets,
                    newRuleSet,
                  ];
                  widget.onChanged(
                    widget.bucket.copyWith(ruleSets: updatedRuleSets),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Rule Set'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
