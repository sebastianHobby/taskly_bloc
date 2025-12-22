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
  });

  final List<TaskPriorityBucketRule> buckets;
  final ValueChanged<List<TaskPriorityBucketRule>> onChanged;
  final List<Label> availableLabels;
  final List<Project> availableProjects;

  @override
  State<PriorityBucketBuilder> createState() => _PriorityBucketBuilderState();
}

class _PriorityBucketBuilderState extends State<PriorityBucketBuilder> {
  void _addBucket() {
    final newBucket = TaskPriorityBucketRule(
      priority: widget.buckets.length + 1,
      name: 'New Bucket',
      ruleSets: [
        TaskRuleSet(
          operator: RuleSetOperator.and,
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
                  'Priority Buckets',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: _addBucket,
                  icon: const Icon(Icons.add),
                  tooltip: 'Add bucket',
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (widget.buckets.isEmpty)
              const Text('No buckets configured. Add a bucket to get started.')
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

  @override
  State<PriorityBucketEditor> createState() => _PriorityBucketEditorState();
}

class _PriorityBucketEditorState extends State<PriorityBucketEditor> {
  late TextEditingController _nameController;
  late TextEditingController _limitController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bucket.name);
    _limitController = TextEditingController(
      text: widget.bucket.limit?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _updateBucket() {
    final name = _nameController.text.trim().isEmpty
        ? 'Bucket ${widget.index + 1}'
        : _nameController.text.trim();
    final limitText = _limitController.text.trim();
    final limit = limitText.isEmpty ? null : int.tryParse(limitText);

    final updatedBucket = widget.bucket.copyWith(
      name: name,
      limit: limit,
    );

    widget.onChanged(updatedBucket);
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
                  'Bucket ${widget.index + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                if (widget.canMoveUp)
                  IconButton(
                    onPressed: widget.onMoveUp,
                    icon: const Icon(Icons.arrow_upward),
                    tooltip: 'Move up',
                  ),
                if (widget.canMoveDown)
                  IconButton(
                    onPressed: widget.onMoveDown,
                    icon: const Icon(Icons.arrow_downward),
                    tooltip: 'Move down',
                  ),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove bucket',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Name and limit fields
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Bucket Name',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _updateBucket(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _limitController,
                    decoration: const InputDecoration(
                      labelText: 'Task Limit',
                      hintText: 'Optional',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _updateBucket(),
                  ),
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
              (entry) => RuleSetBuilder(
                key: ValueKey('${widget.index}_${entry.key}'),
                ruleSet: entry.value,
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
                availableFields: const [
                  TaskField.startDate,
                  TaskField.deadlineDate,
                ],
                relativeDateOnly: true,
              ),
            ),

            // Add rule set button
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  final newRuleSet = TaskRuleSet(
                    operator: RuleSetOperator.and,
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
