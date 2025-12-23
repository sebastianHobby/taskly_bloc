import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/tasks/utils/task_selector.dart';
import 'package:taskly_bloc/features/tasks/widgets/rule_editor.dart';

/// Represents all available fields that can be used for task filtering
enum TaskField {
  startDate('Start Date', Icons.play_arrow),
  deadlineDate('Deadline Date', Icons.flag),
  completed('Completed Status', Icons.check_circle),
  labels('Labels', Icons.label),
  taskValues('Values', Icons.star),
  project('Project', Icons.folder);

  const TaskField(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
}

/// Widget for editing task rule sets with boolean operators.
class RuleSetBuilder extends StatefulWidget {
  const RuleSetBuilder({
    required this.ruleSet,
    required this.onChanged,
    super.key,
    this.onRemove,
    this.availableRuleTypes = RuleType.values,
    this.availableLabels = const [],
    this.availableProjects = const [],
    this.title,
    this.showRemoveButton = false,
    this.compact = false,
    this.availableFields,
    this.availableDateOperators,
    this.relativeDateOnly = false,
  });

  final TaskRuleSet ruleSet;
  final ValueChanged<TaskRuleSet> onChanged;
  final VoidCallback? onRemove;
  final List<RuleType> availableRuleTypes;
  final List<Label> availableLabels;
  final List<Project> availableProjects;
  final String? title;
  final bool showRemoveButton;
  final bool compact;
  final List<TaskField>? availableFields;
  final List<DateRuleOperator>? availableDateOperators;
  final bool relativeDateOnly;

  @override
  State<RuleSetBuilder> createState() => _RuleSetBuilderState();
}

class _RuleSetBuilderState extends State<RuleSetBuilder> {
  late TaskRuleSet _currentRuleSet;

  @override
  void initState() {
    super.initState();
    _currentRuleSet = widget.ruleSet;
  }

  @override
  void didUpdateWidget(RuleSetBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ruleSet != widget.ruleSet) {
      _currentRuleSet = widget.ruleSet;
    }
  }

  void _updateOperator(RuleSetOperator operator) {
    final updated = _currentRuleSet.copyWith(operator: operator);
    setState(() => _currentRuleSet = updated);
    widget.onChanged(updated);
  }

  RuleEditorConfig _buildRuleEditorConfig() {
    // Determine date operators
    List<DateRuleOperator> dateOperators;
    if (widget.relativeDateOnly) {
      dateOperators = [DateRuleOperator.relative];
    } else if (widget.availableDateOperators != null) {
      dateOperators = widget.availableDateOperators!;
    } else {
      dateOperators = DateRuleOperator.values;
    }

    return RuleEditorConfig(
      availableRuleTypes: widget.availableRuleTypes,
      dateOperators: dateOperators,
    );
  }

  Future<void> _showAddRuleDialog() async {
    final newRule = _createDefaultRule();

    final result = await showDialog<TaskRule>(
      context: context,
      builder: (context) {
        return _RuleEditorDialog(
          title: 'Add Rule',
          initialRule: newRule,
          config: _buildRuleEditorConfig(),
          availableLabels: widget.availableLabels,
          availableProjects: widget.availableProjects,
        );
      },
    );

    if (result != null) {
      final updated = _currentRuleSet.copyWith(
        rules: [..._currentRuleSet.rules, result],
      );
      setState(() => _currentRuleSet = updated);
      widget.onChanged(updated);
    }
  }

  Future<void> _showEditRuleDialog(int index) async {
    final currentRule = _currentRuleSet.rules[index];

    final result = await showDialog<TaskRule>(
      context: context,
      builder: (context) {
        return _RuleEditorDialog(
          title: 'Edit Rule',
          initialRule: currentRule,
          config: _buildRuleEditorConfig(),
          availableLabels: widget.availableLabels,
          availableProjects: widget.availableProjects,
        );
      },
    );

    if (result != null) {
      _updateRule(index, result);
    }
  }

  TaskRule _createDefaultRule() {
    // Create a rule based on the first available rule type
    final firstType = widget.availableRuleTypes.first;
    return switch (firstType) {
      RuleType.date => DateRule(
        field: DateRuleField.startDate,
        operator: widget.relativeDateOnly
            ? DateRuleOperator.relative
            : (widget.availableDateOperators?.first ??
                  DateRuleOperator.onOrBefore),
      ),
      RuleType.boolean => BooleanRule(
        field: BooleanRuleField.completed,
        operator: BooleanRuleOperator.isFalse,
      ),
      RuleType.labels => LabelRule(
        operator: LabelRuleOperator.hasAny,
      ),
      RuleType.value => ValueRule(
        operator: ValueRuleOperator.hasAny,
      ),
      RuleType.project => ProjectRule(
        operator: ProjectRuleOperator.isNotNull,
      ),
    };
  }

  void _updateRule(int index, TaskRule rule) {
    final newRules = [..._currentRuleSet.rules];
    newRules[index] = rule;
    final updated = _currentRuleSet.copyWith(rules: newRules);
    setState(() => _currentRuleSet = updated);
    widget.onChanged(updated);
  }

  void _removeRule(int index) {
    if (_currentRuleSet.rules.length <= 1) return; // Don't remove the last rule

    final newRules = [..._currentRuleSet.rules];
    newRules.removeAt(index);
    final updated = _currentRuleSet.copyWith(rules: newRules);
    setState(() => _currentRuleSet = updated);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final errors = _currentRuleSet.validate();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(widget.compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            if (widget.title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (widget.showRemoveButton && widget.onRemove != null) ...[
                    IconButton(
                      onPressed: widget.onRemove,
                      icon: const Icon(Icons.remove_circle),
                      tooltip: 'Remove rule set',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Operator selection
            Text(
              'Tasks must match:',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            SizedBox(height: widget.compact ? 4 : 8),
            SegmentedButton<RuleSetOperator>(
              segments: const [
                ButtonSegment(
                  value: RuleSetOperator.or,
                  label: Text('Any rule'),
                  icon: Icon(Icons.check_box_outline_blank),
                ),
                ButtonSegment(
                  value: RuleSetOperator.and,
                  label: Text('All rules'),
                  icon: Icon(Icons.check_box),
                ),
              ],
              selected: {_currentRuleSet.operator},
              onSelectionChanged: (selection) =>
                  _updateOperator(selection.first),
            ),

            SizedBox(height: widget.compact ? 8 : 16),

            // Rules list
            Text(
              'Rules (${_currentRuleSet.rules.length}):',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            SizedBox(height: widget.compact ? 4 : 8),

            if (_currentRuleSet.rules.isEmpty)
              Container(
                padding: EdgeInsets.all(widget.compact ? 12 : 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('No rules defined. Add a rule to get started.'),
                ),
              )
            else
              ...List.generate(_currentRuleSet.rules.length, (index) {
                final rule = _currentRuleSet.rules[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: widget.compact ? 4 : 8),
                  child: _RuleSummaryTile(
                    key: ValueKey('${rule.type.name}_$index'),
                    rule: rule,
                    onEdit: () => _showEditRuleDialog(index),
                    onRemove: _currentRuleSet.rules.length > 1
                        ? () => _removeRule(index)
                        : null,
                    compact: widget.compact,
                    availableLabels: widget.availableLabels,
                    availableProjects: widget.availableProjects,
                  ),
                );
              }),

            SizedBox(height: widget.compact ? 8 : 16),

            // Add rule button
            OutlinedButton.icon(
              onPressed: _showAddRuleDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Rule'),
            ),

            // Validation errors
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Validation Errors:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...errors.map(
                      (error) => Text(
                        '• $error',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Rule Summary Tile
// ============================================================================

/// A compact tile displaying a summary of a rule with edit and delete actions.
class _RuleSummaryTile extends StatelessWidget {
  const _RuleSummaryTile({
    required this.rule,
    required this.onEdit,
    super.key,
    this.onRemove,
    this.compact = false,
    this.availableLabels = const [],
    this.availableProjects = const [],
  });

  final TaskRule rule;
  final VoidCallback onEdit;
  final VoidCallback? onRemove;
  final bool compact;
  final List<Label> availableLabels;
  final List<Project> availableProjects;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(compact ? 8 : 12),
          child: Row(
            children: [
              // Rule type icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  rule.type.icon,
                  size: compact ? 18 : 20,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              SizedBox(width: compact ? 8 : 12),

              // Rule details - expanded with more info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type and field row
                    Row(
                      children: [
                        Text(
                          rule.type.displayName,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_getFieldName() != null) ...[
                          Text(
                            ' • ',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _getFieldName()!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Operator chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getOperatorDisplay(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Condition value if applicable
                    if (_hasConditionContent()) ...[
                      const SizedBox(height: 4),
                      _buildConditionWidget(context),
                    ],
                  ],
                ),
              ),

              // Actions
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                iconSize: compact ? 18 : 20,
                tooltip: 'Edit rule',
                visualDensity: VisualDensity.compact,
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  iconSize: compact ? 18 : 20,
                  tooltip: 'Remove rule',
                  visualDensity: VisualDensity.compact,
                  color: colorScheme.error,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _getFieldName() {
    return switch (rule) {
      final DateRule r => r.field.displayName,
      final BooleanRule r => r.field.displayName,
      _ => null,
    };
  }

  String _getOperatorDisplay() {
    return switch (rule) {
      final DateRule r => r.operator.displayName,
      final BooleanRule r => r.operator.displayName,
      final LabelRule r => r.operator.displayName,
      final ValueRule r => r.operator.displayName,
      final ProjectRule r => r.operator.displayName,
      _ => 'Unknown',
    };
  }

  bool _hasConditionContent() {
    return switch (rule) {
      final DateRule r => _getDateConditionValue(r) != null,
      final LabelRule r => r.labelIds.isNotEmpty,
      final ValueRule r => r.labelIds.isNotEmpty,
      final ProjectRule r => r.projectId != null,
      _ => false,
    };
  }

  Widget _buildConditionWidget(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return switch (rule) {
      final DateRule r => Text(
        _getDateConditionValue(r) ?? '',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      final LabelRule r => _buildLabelChips(
        context,
        r.labelIds,
        availableLabels.where((l) => l.type == LabelType.label).toList(),
      ),
      final ValueRule r => _buildLabelChips(
        context,
        r.labelIds,
        availableLabels.where((l) => l.type == LabelType.value).toList(),
      ),
      final ProjectRule r => _buildProjectDisplay(context, r.projectId),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildLabelChips(
    BuildContext context,
    List<String> selectedIds,
    List<Label> available,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get labels for selected IDs
    final selectedLabels = <Label>[];
    for (final id in selectedIds) {
      final item = available.where((l) => l.id == id).firstOrNull;
      if (item != null) {
        selectedLabels.add(item);
      }
    }

    if (selectedLabels.isEmpty) {
      final count = selectedIds.length;
      return Text(
        '$count item${count == 1 ? '' : 's'} selected',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface,
        ),
      );
    }

    // Use constrained wrap with max 2 lines
    const chipHeight = 22.0;
    const runSpacing = 4.0;
    const maxLines = 2;
    const maxHeight = (chipHeight * maxLines) + (runSpacing * (maxLines - 1));

    return _TwoLineWrap(
      maxHeight: maxHeight,
      spacing: 6,
      runSpacing: runSpacing,
      allLabels: selectedLabels,
      chipBuilder: (label) => _buildColoredLabelChip(context, label),
      moreTextStyle: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildColoredLabelChip(BuildContext context, Label label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Parse color from hex string
    Color chipColor = colorScheme.primary;
    if (label.color != null && label.color!.isNotEmpty) {
      try {
        final hexColor = label.color!.replaceFirst('#', '');
        chipColor = Color(int.parse('FF$hexColor', radix: 16));
      } catch (_) {
        // Use default color if parsing fails
      }
    }

    final isValue = label.type == LabelType.value;

    // For values: use colored background with contrasting text
    // For labels: use neutral background with colored icon
    final backgroundColor = isValue
        ? chipColor
        : colorScheme.surfaceContainerLow;
    final textColor = isValue
        ? (chipColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white)
        : colorScheme.onSurface;

    // Get the icon - emoji for values, colored label icon for labels
    final Widget icon;
    if (isValue) {
      final emoji = label.iconName?.isNotEmpty ?? false
          ? label.iconName!
          : '❤️';
      icon = Text(
        emoji,
        style: const TextStyle(fontSize: 10),
      );
    } else {
      icon = Icon(
        Icons.label,
        size: 10,
        color: chipColor,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 4),
          Text(
            label.name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDisplay(BuildContext context, String? projectId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (projectId == null) return const SizedBox.shrink();

    final project = availableProjects
        .where((p) => p.id == projectId)
        .firstOrNull;

    if (project == null) {
      return Text(
        'Unknown project',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurface,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.folder_outlined,
            size: 12,
            color: colorScheme.tertiary,
          ),
          const SizedBox(width: 4),
          Text(
            project.name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String? _getDateConditionValue(DateRule r) {
    if (r.operator == DateRuleOperator.isNull ||
        r.operator == DateRuleOperator.isNotNull) {
      return null;
    }

    if (r.operator == DateRuleOperator.relative) {
      final days = r.relativeDays ?? 0;
      final comparison = r.relativeComparison ?? RelativeComparison.onOrBefore;
      return comparison.descriptionWithDays(days);
    }

    if (r.operator == DateRuleOperator.between) {
      return '${_formatDate(r.startDate)} to ${_formatDate(r.endDate)}';
    }

    if (r.date != null) {
      return _formatDate(r.date);
    }

    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'not set';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// ============================================================================
// Rule Editor Dialog
// ============================================================================

/// A dialog for editing a rule with full RuleEditor controls.
class _RuleEditorDialog extends StatefulWidget {
  const _RuleEditorDialog({
    required this.title,
    required this.initialRule,
    required this.config,
    required this.availableLabels,
    required this.availableProjects,
  });

  final String title;
  final TaskRule initialRule;
  final RuleEditorConfig config;
  final List<Label> availableLabels;
  final List<Project> availableProjects;

  @override
  State<_RuleEditorDialog> createState() => _RuleEditorDialogState();
}

class _RuleEditorDialogState extends State<_RuleEditorDialog> {
  late TaskRule _currentRule;

  @override
  void initState() {
    super.initState();
    _currentRule = widget.initialRule;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Rule editor
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: RuleEditor(
                  rule: _currentRule,
                  onChanged: (rule) => setState(() => _currentRule = rule),
                  availableLabels: widget.availableLabels,
                  availableProjects: widget.availableProjects,
                  config: widget.config,
                ),
              ),
            ),

            // Actions
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_currentRule),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for building multiple rule sets (priority buckets).
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
  late List<TaskPriorityBucketRule> _buckets;

  @override
  void initState() {
    super.initState();
    _buckets = List.from(widget.buckets);
  }

  @override
  void didUpdateWidget(PriorityBucketBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buckets != widget.buckets) {
      _buckets = List.from(widget.buckets);
    }
  }

  void _addBucket() {
    final newBucket = TaskPriorityBucketRule(
      priority: _buckets.length + 1,
      name: 'New Priority Bucket',
      ruleSets: [
        TaskRuleSet(
          operator: RuleSetOperator.and,
          rules: [RuleRegistry.createDefaultRule(RuleType.date)],
        ),
      ],
    );

    setState(() => _buckets.add(newBucket));
    widget.onChanged(_buckets);
  }

  void _removeBucket(int index) {
    setState(() => _buckets.removeAt(index));
    _reorderPriorities();
    widget.onChanged(_buckets);
  }

  void _updateBucket(int index, TaskPriorityBucketRule bucket) {
    setState(() => _buckets[index] = bucket);
    widget.onChanged(_buckets);
  }

  void _reorderBuckets(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final bucket = _buckets.removeAt(oldIndex);
      _buckets.insert(newIndex, bucket);
    });
    _reorderPriorities();
    widget.onChanged(_buckets);
  }

  void _reorderPriorities() {
    setState(() {
      for (int i = 0; i < _buckets.length; i++) {
        _buckets[i] = _buckets[i].copyWith(priority: i + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Priority Buckets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _addBucket,
              icon: const Icon(Icons.add),
              label: const Text('Add Bucket'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (_buckets.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No priority buckets defined',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a bucket to organize tasks by priority',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: _reorderBuckets,
            itemCount: _buckets.length,
            itemBuilder: (context, index) {
              final bucket = _buckets[index];
              return _BucketTile(
                key: ValueKey(bucket.priority),
                bucket: bucket,
                index: index,
                onChanged: (updatedBucket) =>
                    _updateBucket(index, updatedBucket),
                onRemove: () => _removeBucket(index),
                availableLabels: widget.availableLabels,
                availableProjects: widget.availableProjects,
              );
            },
          ),
      ],
    );
  }
}

class _BucketTile extends StatefulWidget {
  const _BucketTile({
    required this.bucket,
    required this.index,
    required this.onChanged,
    required this.onRemove,
    super.key,
    this.availableLabels = const [],
    this.availableProjects = const [],
  });

  final TaskPriorityBucketRule bucket;
  final int index;
  final ValueChanged<TaskPriorityBucketRule> onChanged;
  final VoidCallback onRemove;
  final List<Label> availableLabels;
  final List<Project> availableProjects;

  @override
  State<_BucketTile> createState() => _BucketTileState();
}

class _BucketTileState extends State<_BucketTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Text('${widget.bucket.priority}'),
            ),
            title: Text(widget.bucket.name),
            subtitle: Text(
              '${widget.bucket.ruleSets.length} rule set(s)${widget.bucket.limit != null ? ', limit: ${widget.bucket.limit}' : ''}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.onRemove,
                ),
                const Icon(Icons.drag_handle),
              ],
            ),
          ),

          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _BucketEditor(
                bucket: widget.bucket,
                onChanged: widget.onChanged,
                availableLabels: widget.availableLabels,
                availableProjects: widget.availableProjects,
              ),
            ),
        ],
      ),
    );
  }
}

class _BucketEditor extends StatefulWidget {
  const _BucketEditor({
    required this.bucket,
    required this.onChanged,
    this.availableLabels = const [],
    this.availableProjects = const [],
  });

  final TaskPriorityBucketRule bucket;
  final ValueChanged<TaskPriorityBucketRule> onChanged;
  final List<Label> availableLabels;
  final List<Project> availableProjects;

  @override
  State<_BucketEditor> createState() => _BucketEditorState();
}

class _BucketEditorState extends State<_BucketEditor> {
  late TextEditingController _nameController;
  late TextEditingController _limitController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.bucket.name);
    _limitController = TextEditingController(
      text: widget.bucket.limit?.toString() ?? '',
    );

    _nameController.addListener(_updateBucket);
    _limitController.addListener(_updateBucket);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  void _updateBucket() {
    final name = _nameController.text.trim().isEmpty
        ? 'Unnamed bucket'
        : _nameController.text.trim();
    final limitText = _limitController.text.trim();
    final limit = limitText.isEmpty ? null : int.tryParse(limitText);

    final updated = widget.bucket.copyWith(
      name: name,
      limit: limit,
    );

    widget.onChanged(updated);
  }

  void _updateRuleSet(int index, TaskRuleSet ruleSet) {
    final newRuleSets = [...widget.bucket.ruleSets];
    newRuleSets[index] = ruleSet;
    final updated = widget.bucket.copyWith(ruleSets: newRuleSets);
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Bucket Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _limitController,
                decoration: const InputDecoration(
                  labelText: 'Task Limit',
                  border: OutlineInputBorder(),
                  helperText: 'Optional',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Rule sets
        ...List.generate(widget.bucket.ruleSets.length, (index) {
          final ruleSet = widget.bucket.ruleSets[index];
          return RuleSetBuilder(
            key: ValueKey('ruleset_$index'),
            ruleSet: ruleSet,
            title: 'Rule Set ${index + 1}',
            onChanged: (updatedRuleSet) =>
                _updateRuleSet(index, updatedRuleSet),
            availableLabels: widget.availableLabels,
            availableProjects: widget.availableProjects,
          );
        }),
      ],
    );
  }
}

// ============================================================================
// Two Line Wrap Widget
// ============================================================================

/// A widget that displays label chips in up to 2 lines, with truncation.
class _TwoLineWrap extends StatefulWidget {
  const _TwoLineWrap({
    required this.maxHeight,
    required this.spacing,
    required this.runSpacing,
    required this.allLabels,
    required this.chipBuilder,
    this.moreTextStyle,
  });

  final double maxHeight;
  final double spacing;
  final double runSpacing;
  final List<Label> allLabels;
  final Widget Function(Label) chipBuilder;
  final TextStyle? moreTextStyle;

  @override
  State<_TwoLineWrap> createState() => _TwoLineWrapState();
}

class _TwoLineWrapState extends State<_TwoLineWrap> {
  int _visibleCount = 0;
  bool _measured = false;
  final List<GlobalKey> _chipKeys = [];

  @override
  void initState() {
    super.initState();
    _initKeys();
  }

  @override
  void didUpdateWidget(_TwoLineWrap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.allLabels.length != widget.allLabels.length) {
      _measured = false;
      _initKeys();
    }
  }

  void _initKeys() {
    _chipKeys.clear();
    for (var i = 0; i < widget.allLabels.length; i++) {
      _chipKeys.add(GlobalKey());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureChips();
    });
  }

  void _measureChips() {
    if (!mounted) return;

    // Count how many chips fit within maxHeight
    double currentY = 0;
    double currentX = 0;
    double lineHeight = 0;
    int count = 0;

    for (var i = 0; i < _chipKeys.length; i++) {
      final key = _chipKeys[i];
      final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) continue;

      final size = renderBox.size;
      lineHeight = size.height;

      // Check if we need a new line
      if (currentX > 0 && currentX + size.width > 300) {
        // Approximate width
        currentX = 0;
        currentY += lineHeight + widget.runSpacing;
      }

      // Check if still within max height
      if (currentY + lineHeight <= widget.maxHeight) {
        count++;
        currentX += size.width + widget.spacing;
      } else {
        break;
      }
    }

    if (mounted && count != _visibleCount) {
      setState(() {
        _visibleCount = count > 0 ? count : widget.allLabels.length;
        _measured = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveVisible = _measured
        ? _visibleCount
        : widget.allLabels.length;
    final remaining = widget.allLabels.length - effectiveVisible;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight + 4),
      child: Wrap(
        spacing: widget.spacing,
        runSpacing: widget.runSpacing,
        clipBehavior: Clip.hardEdge,
        children: [
          // Build chips with keys for measuring
          for (var i = 0; i < widget.allLabels.length; i++)
            if (!_measured || i < effectiveVisible)
              KeyedSubtree(
                key: _chipKeys.length > i ? _chipKeys[i] : null,
                child: widget.chipBuilder(widget.allLabels[i]),
              ),
          // Show "+X more" if items are hidden
          if (_measured && remaining > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '+$remaining more',
                style: widget.moreTextStyle,
              ),
            ),
        ],
      ),
    );
  }
}
