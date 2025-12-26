import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';

// ============================================================================
// Helper Functions
// ============================================================================

/// Parses a hex color string to a Color.
///
/// Supports formats: '#RRGGBB', 'RRGGBB', '#AARRGGBB', 'AARRGGBB'
Color _parseColor(String? hexString) {
  if (hexString == null || hexString.isEmpty) {
    return Colors.grey;
  }

  var hex = hexString.replaceFirst('#', '');

  // If 6 characters, add FF for alpha
  if (hex.length == 6) {
    hex = 'FF$hex';
  }

  // Parse the hex value
  final intValue = int.tryParse(hex, radix: 16);
  if (intValue == null) {
    return Colors.grey;
  }

  return Color(intValue);
}

// ============================================================================
// Configuration Classes
// ============================================================================

/// Configuration for the RuleEditor widget.
///
/// Allows customization of which rule types and operators are available.
/// Use [RuleEditorConfig.all] for full functionality or create a custom
/// configuration for specific use cases.
class RuleEditorConfig {
  const RuleEditorConfig({
    this.availableRuleTypes = RuleType.values,
    this.dateOperators = DateRuleOperator.values,
    this.booleanOperators = BooleanRuleOperator.values,
    this.labelOperators = LabelRuleOperator.values,
    this.valueOperators = ValueRuleOperator.values,
    this.projectOperators = ProjectRuleOperator.values,
    this.showFieldSelector = true,
    this.dateFieldsAvailable = DateRuleField.values,
    this.booleanFieldsAvailable = BooleanRuleField.values,
  });

  /// Default configuration with all rule types and operators available.
  static const RuleEditorConfig all = RuleEditorConfig();

  /// Configuration for date-only rules (useful for next actions/priority).
  static const RuleEditorConfig dateOnly = RuleEditorConfig(
    availableRuleTypes: [RuleType.date],
    dateOperators: [DateRuleOperator.relative],
  );

  /// Configuration for relative date rules only.
  static const RuleEditorConfig relativeDateOnly = RuleEditorConfig(
    availableRuleTypes: [RuleType.date],
    dateOperators: [DateRuleOperator.relative],
  );

  /// Available rule types for selection.
  final List<RuleType> availableRuleTypes;

  /// Available date operators.
  final List<DateRuleOperator> dateOperators;

  /// Available boolean operators.
  final List<BooleanRuleOperator> booleanOperators;

  /// Available label operators.
  final List<LabelRuleOperator> labelOperators;

  /// Available value operators.
  final List<ValueRuleOperator> valueOperators;

  /// Available project operators.
  final List<ProjectRuleOperator> projectOperators;

  /// Whether to show the field selector for rule types with multiple fields.
  final bool showFieldSelector;

  /// Available date fields.
  final List<DateRuleField> dateFieldsAvailable;

  /// Available boolean fields.
  final List<BooleanRuleField> booleanFieldsAvailable;

  /// Creates a copy with optional overrides.
  RuleEditorConfig copyWith({
    List<RuleType>? availableRuleTypes,
    List<DateRuleOperator>? dateOperators,
    List<BooleanRuleOperator>? booleanOperators,
    List<LabelRuleOperator>? labelOperators,
    List<ValueRuleOperator>? valueOperators,
    List<ProjectRuleOperator>? projectOperators,
    bool? showFieldSelector,
    List<DateRuleField>? dateFieldsAvailable,
    List<BooleanRuleField>? booleanFieldsAvailable,
  }) {
    return RuleEditorConfig(
      availableRuleTypes: availableRuleTypes ?? this.availableRuleTypes,
      dateOperators: dateOperators ?? this.dateOperators,
      booleanOperators: booleanOperators ?? this.booleanOperators,
      labelOperators: labelOperators ?? this.labelOperators,
      valueOperators: valueOperators ?? this.valueOperators,
      projectOperators: projectOperators ?? this.projectOperators,
      showFieldSelector: showFieldSelector ?? this.showFieldSelector,
      dateFieldsAvailable: dateFieldsAvailable ?? this.dateFieldsAvailable,
      booleanFieldsAvailable:
          booleanFieldsAvailable ?? this.booleanFieldsAvailable,
    );
  }
}

// ============================================================================
// Display Helpers
// ============================================================================

/// Extension for user-friendly rule type display names.
extension RuleTypeDisplay on RuleType {
  String get displayName => switch (this) {
    RuleType.date => 'Date',
    RuleType.boolean => 'Status',
    RuleType.labels => 'Labels',
    RuleType.value => 'Values',
    RuleType.project => 'Project',
  };

  IconData get icon => switch (this) {
    RuleType.date => Icons.calendar_today,
    RuleType.boolean => Icons.check_circle_outline,
    RuleType.labels => Icons.label_outline,
    RuleType.value => Icons.star_outline,
    RuleType.project => Icons.folder_outlined,
  };

  String get description => switch (this) {
    RuleType.date => 'Filter by start date or deadline',
    RuleType.boolean => 'Filter by completion status',
    RuleType.labels => 'Filter by assigned labels',
    RuleType.value => 'Filter by assigned values',
    RuleType.project => 'Filter by project assignment',
  };
}

/// Extension for user-friendly date operator display names.
extension DateRuleOperatorDisplay on DateRuleOperator {
  String get displayName => switch (this) {
    DateRuleOperator.onOrAfter => 'On or After',
    DateRuleOperator.onOrBefore => 'On or Before',
    DateRuleOperator.before => 'Before',
    DateRuleOperator.after => 'After',
    DateRuleOperator.on => 'On',
    DateRuleOperator.between => 'Between',
    DateRuleOperator.relative => 'Relative to Today',
    DateRuleOperator.isNull => 'Has No Date',
    DateRuleOperator.isNotNull => 'Has Any Date',
  };

  String get description => switch (this) {
    DateRuleOperator.onOrAfter => 'Date is on or after a specific date',
    DateRuleOperator.onOrBefore => 'Date is on or before a specific date',
    DateRuleOperator.before => 'Date is before a specific date',
    DateRuleOperator.after => 'Date is after a specific date',
    DateRuleOperator.on => 'Date is exactly on a specific date',
    DateRuleOperator.between => 'Date is between two dates',
    DateRuleOperator.relative => 'Date relative to today (dynamic)',
    DateRuleOperator.isNull => 'No date is set',
    DateRuleOperator.isNotNull => 'A date is set',
  };

  bool get requiresDate => switch (this) {
    DateRuleOperator.onOrAfter ||
    DateRuleOperator.onOrBefore ||
    DateRuleOperator.before ||
    DateRuleOperator.after ||
    DateRuleOperator.on => true,
    _ => false,
  };

  bool get requiresDateRange => this == DateRuleOperator.between;
  bool get requiresRelative => this == DateRuleOperator.relative;
  bool get requiresNoValue =>
      this == DateRuleOperator.isNull || this == DateRuleOperator.isNotNull;
}

/// Extension for user-friendly date field display names.
extension DateRuleFieldDisplay on DateRuleField {
  String get displayName => switch (this) {
    DateRuleField.startDate => 'Start Date',
    DateRuleField.deadlineDate => 'Deadline',
    DateRuleField.createdAt => 'Created Date',
    DateRuleField.updatedAt => 'Updated Date',
  };

  IconData get icon => switch (this) {
    DateRuleField.startDate => Icons.calendar_today,
    DateRuleField.deadlineDate => Icons.flag,
    DateRuleField.createdAt => Icons.add_circle_outline,
    DateRuleField.updatedAt => Icons.update,
  };
}

/// Extension for user-friendly relative comparison display names.
extension RelativeComparisonDisplay on RelativeComparison {
  String get displayName => switch (this) {
    RelativeComparison.on => 'Exactly',
    RelativeComparison.before => 'Before',
    RelativeComparison.after => 'After',
    RelativeComparison.onOrBefore => 'On or Before',
    RelativeComparison.onOrAfter => 'On or After',
  };

  String descriptionWithDays(int days) {
    if (days == 0) {
      return switch (this) {
        RelativeComparison.on => 'Date is exactly today',
        RelativeComparison.before => 'Date is before today',
        RelativeComparison.after => 'Date is after today',
        RelativeComparison.onOrBefore => 'Date is on or before today',
        RelativeComparison.onOrAfter => 'Date is on or after today',
      };
    }
    final dayWord = days == 1 ? 'day' : 'days';
    if (days > 0) {
      return switch (this) {
        RelativeComparison.on => 'Date is exactly today + $days $dayWord',
        RelativeComparison.before => 'Date is before today + $days $dayWord',
        RelativeComparison.after => 'Date is after today + $days $dayWord',
        RelativeComparison.onOrBefore =>
          'Date is on or before today + $days $dayWord',
        RelativeComparison.onOrAfter =>
          'Date is on or after today + $days $dayWord',
      };
    } else {
      final absDays = -days;
      final absDayWord = absDays == 1 ? 'day' : 'days';
      return switch (this) {
        RelativeComparison.on => 'Date is exactly today - $absDays $absDayWord',
        RelativeComparison.before =>
          'Date is before today - $absDays $absDayWord',
        RelativeComparison.after =>
          'Date is after today - $absDays $absDayWord',
        RelativeComparison.onOrBefore =>
          'Date is on or before today - $absDays $absDayWord',
        RelativeComparison.onOrAfter =>
          'Date is on or after today - $absDays $absDayWord',
      };
    }
  }
}

/// Extension for user-friendly boolean operator display names.
extension BooleanRuleOperatorDisplay on BooleanRuleOperator {
  String get displayName => switch (this) {
    BooleanRuleOperator.isTrue => 'Is Completed',
    BooleanRuleOperator.isFalse => 'Is Not Completed',
  };
}

/// Extension for user-friendly boolean field display names.
extension BooleanRuleFieldDisplay on BooleanRuleField {
  String get displayName => switch (this) {
    BooleanRuleField.completed => 'Completion Status',
  };
}

/// Extension for user-friendly label operator display names.
extension LabelRuleOperatorDisplay on LabelRuleOperator {
  String get displayName => switch (this) {
    LabelRuleOperator.hasAll => 'Has All Of',
    LabelRuleOperator.hasAny => 'Has Any Of',
    LabelRuleOperator.isNull => 'Has No Labels',
    LabelRuleOperator.isNotNull => 'Has Any Label',
  };

  bool get requiresSelection =>
      this == LabelRuleOperator.hasAll || this == LabelRuleOperator.hasAny;
}

/// Extension for user-friendly value operator display names.
extension ValueRuleOperatorDisplay on ValueRuleOperator {
  String get displayName => switch (this) {
    ValueRuleOperator.hasAll => 'Has All Of',
    ValueRuleOperator.hasAny => 'Has Any Of',
    ValueRuleOperator.isNull => 'Has No Values',
    ValueRuleOperator.isNotNull => 'Has Any Value',
  };

  bool get requiresSelection =>
      this == ValueRuleOperator.hasAll || this == ValueRuleOperator.hasAny;
}

/// Extension for user-friendly project operator display names.
extension ProjectRuleOperatorDisplay on ProjectRuleOperator {
  String get displayName => switch (this) {
    ProjectRuleOperator.matches => 'Is In Project',
    ProjectRuleOperator.isNull => 'Has No Project',
    ProjectRuleOperator.isNotNull => 'Has Any Project',
  };

  bool get requiresSelection => this == ProjectRuleOperator.matches;
}

// ============================================================================
// Main Rule Editor Widget
// ============================================================================

/// A configurable widget for editing task filter rules.
///
/// Provides a user-friendly interface for creating and editing rules that
/// filter tasks based on various criteria like dates, completion status,
/// labels, values, and projects.
///
/// Example usage:
/// ```dart
/// RuleEditor(
///   rule: myRule,
///   onChanged: (rule) => setState(() => myRule = rule),
///   availableLabels: labels,
///   availableProjects: projects,
///   config: RuleEditorConfig.all, // or a custom config
/// )
/// ```
class RuleEditor extends StatefulWidget {
  const RuleEditor({
    required this.rule,
    required this.onChanged,
    super.key,
    this.onRemove,
    this.availableLabels = const [],
    this.availableProjects = const [],
    this.config = const RuleEditorConfig(),
  });

  /// The current rule being edited.
  final TaskRule rule;

  /// Callback when the rule changes.
  final ValueChanged<TaskRule> onChanged;

  /// Callback when the rule should be removed.
  /// If null, no remove button is shown.
  final VoidCallback? onRemove;

  /// Available labels for label rule selection.
  final List<Label> availableLabels;

  /// Available projects for project rule selection.
  final List<Project> availableProjects;

  /// Configuration for available rule types and operators.
  final RuleEditorConfig config;

  @override
  State<RuleEditor> createState() => _RuleEditorState();
}

class _RuleEditorState extends State<RuleEditor> {
  late TaskRule _currentRule;

  @override
  void initState() {
    super.initState();
    _currentRule = widget.rule;
  }

  @override
  void didUpdateWidget(RuleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rule != widget.rule) {
      _currentRule = widget.rule;
    }
  }

  void _updateRule(TaskRule rule) {
    setState(() => _currentRule = rule);
    widget.onChanged(rule);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.onRemove != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _currentRule.type.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.close),
                    tooltip: 'Remove rule',
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Rule type selector (if multiple types available)
            if (widget.config.availableRuleTypes.length > 1) ...[
              _buildRuleTypeSelector(context),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
            ],

            // Rule-specific editor
            _buildRuleSpecificEditor(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleTypeSelector(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter Type',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.config.availableRuleTypes.map((type) {
            final isSelected = _currentRule.type == type;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.icon,
                    size: 18,
                    color: isSelected
                        ? theme.colorScheme.onSecondaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(type.displayName),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected && _currentRule.type != type) {
                  _changeRuleType(type);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _changeRuleType(RuleType type) {
    final newRule = switch (type) {
      RuleType.date => DateRule(
        field: widget.config.dateFieldsAvailable.first,
        operator: widget.config.dateOperators.first,
      ),
      RuleType.boolean => BooleanRule(
        field: widget.config.booleanFieldsAvailable.first,
        operator: widget.config.booleanOperators.first,
      ),
      RuleType.labels => LabelRule(
        operator: widget.config.labelOperators.first,
      ),
      RuleType.value => ValueRule(
        operator: widget.config.valueOperators.first,
      ),
      RuleType.project => ProjectRule(
        operator: widget.config.projectOperators.first,
      ),
    };
    _updateRule(newRule);
  }

  Widget _buildRuleSpecificEditor(BuildContext context) {
    return switch (_currentRule) {
      final DateRule rule => _DateRuleEditor(
        rule: rule,
        onChanged: _updateRule,
        config: widget.config,
      ),
      final BooleanRule rule => _BooleanRuleEditor(
        rule: rule,
        onChanged: _updateRule,
        config: widget.config,
      ),
      final LabelRule rule => _LabelRuleEditor(
        rule: rule,
        onChanged: _updateRule,
        availableLabels: widget.availableLabels
            .where((l) => l.type == LabelType.label)
            .toList(),
        config: widget.config,
      ),
      final ValueRule rule => _ValueRuleEditor(
        rule: rule,
        onChanged: _updateRule,
        availableValues: widget.availableLabels
            .where((l) => l.type == LabelType.value)
            .toList(),
        config: widget.config,
      ),
      final ProjectRule rule => _ProjectRuleEditor(
        rule: rule,
        onChanged: _updateRule,
        availableProjects: widget.availableProjects,
        config: widget.config,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

// ============================================================================
// Date Rule Editor
// ============================================================================

class _DateRuleEditor extends StatelessWidget {
  const _DateRuleEditor({
    required this.rule,
    required this.onChanged,
    required this.config,
  });

  final DateRule rule;
  final ValueChanged<TaskRule> onChanged;
  final RuleEditorConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field selector
        if (config.showFieldSelector &&
            config.dateFieldsAvailable.length > 1) ...[
          Text(
            'Date Field',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<DateRuleField>(
            segments: config.dateFieldsAvailable.map((field) {
              return ButtonSegment<DateRuleField>(
                value: field,
                label: Text(field.displayName),
                icon: Icon(field.icon),
              );
            }).toList(),
            selected: {rule.field},
            onSelectionChanged: (selected) {
              _updateField(selected.first);
            },
          ),
          const SizedBox(height: 16),
        ],

        // Operator selector
        Text(
          'Condition',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildOperatorDropdown(context),

        // Value input based on operator
        const SizedBox(height: 16),
        _buildValueEditor(context),
      ],
    );
  }

  Widget _buildOperatorDropdown(BuildContext context) {
    return DropdownButtonFormField<DateRuleOperator>(
      initialValue: rule.operator,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: config.dateOperators.map((op) {
        return DropdownMenuItem(
          value: op,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(op.displayName),
            ],
          ),
        );
      }).toList(),
      onChanged: (operator) {
        if (operator != null) {
          _updateOperator(operator);
        }
      },
    );
  }

  Widget _buildValueEditor(BuildContext context) {
    if (rule.operator.requiresNoValue) {
      return _buildInfoBox(
        context,
        rule.operator == DateRuleOperator.isNull
            ? 'Will match tasks where ${rule.field.displayName.toLowerCase()} is not set'
            : 'Will match tasks where ${rule.field.displayName.toLowerCase()} has any value',
      );
    }

    if (rule.operator.requiresRelative) {
      return _buildRelativeDateEditor(context);
    }

    if (rule.operator.requiresDateRange) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDatePicker(
            context: context,
            label: 'Start Date',
            value: rule.startDate,
            onChanged: (date) {
              onChanged(
                DateRule(
                  field: rule.field,
                  operator: rule.operator,
                  startDate: date,
                  endDate: rule.endDate,
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildDatePicker(
            context: context,
            label: 'End Date',
            value: rule.endDate,
            onChanged: (date) {
              onChanged(
                DateRule(
                  field: rule.field,
                  operator: rule.operator,
                  startDate: rule.startDate,
                  endDate: date,
                ),
              );
            },
          ),
        ],
      );
    }

    if (rule.operator.requiresDate) {
      return _buildDatePicker(
        context: context,
        label: 'Date',
        value: rule.date,
        onChanged: (date) {
          onChanged(
            DateRule(
              field: rule.field,
              operator: rule.operator,
              date: date,
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildRelativeDateEditor(BuildContext context) {
    final theme = Theme.of(context);
    final comparison = rule.relativeComparison ?? RelativeComparison.onOrBefore;
    final days = rule.relativeDays ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comparison type
        Text(
          'Relative To Today',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<RelativeComparison>(
          segments: RelativeComparison.values.map((comp) {
            return ButtonSegment<RelativeComparison>(
              value: comp,
              label: Text(comp.displayName),
            );
          }).toList(),
          selected: {comparison},
          onSelectionChanged: (selected) {
            onChanged(
              DateRule(
                field: rule.field,
                operator: rule.operator,
                relativeComparison: selected.first,
                relativeDays: days,
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // Days input
        Text(
          'Number of Days',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.outlined(
              onPressed: () {
                onChanged(
                  DateRule(
                    field: rule.field,
                    operator: rule.operator,
                    relativeComparison: comparison,
                    relativeDays: days - 1,
                  ),
                );
              },
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '$days',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      days == 1 ? 'day' : 'days',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            IconButton.outlined(
              onPressed: () {
                onChanged(
                  DateRule(
                    field: rule.field,
                    operator: rule.operator,
                    relativeComparison: comparison,
                    relativeDays: days + 1,
                  ),
                );
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Description
        _buildInfoBox(context, comparison.descriptionWithDays(days)),
      ],
    );
  }

  Widget _buildDatePicker({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onChanged,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null
              ? '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}'
              : 'Select date',
          style: value != null
              ? null
              : theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
        ),
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context, String text) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateField(DateRuleField field) {
    onChanged(
      DateRule(
        field: field,
        operator: rule.operator,
        date: rule.date,
        startDate: rule.startDate,
        endDate: rule.endDate,
        relativeComparison: rule.relativeComparison,
        relativeDays: rule.relativeDays,
      ),
    );
  }

  void _updateOperator(DateRuleOperator operator) {
    // Reset values when switching operators
    if (operator.requiresRelative) {
      onChanged(
        DateRule(
          field: rule.field,
          operator: operator,
          relativeComparison: RelativeComparison.onOrBefore,
          relativeDays: 0,
        ),
      );
    } else if (operator.requiresDateRange) {
      onChanged(
        DateRule(
          field: rule.field,
          operator: operator,
          startDate: rule.startDate ?? DateTime.now(),
          endDate: rule.endDate ?? DateTime.now().add(const Duration(days: 7)),
        ),
      );
    } else if (operator.requiresDate) {
      onChanged(
        DateRule(
          field: rule.field,
          operator: operator,
          date: rule.date ?? DateTime.now(),
        ),
      );
    } else {
      onChanged(
        DateRule(
          field: rule.field,
          operator: operator,
        ),
      );
    }
  }
}

// ============================================================================
// Boolean Rule Editor
// ============================================================================

class _BooleanRuleEditor extends StatelessWidget {
  const _BooleanRuleEditor({
    required this.rule,
    required this.onChanged,
    required this.config,
  });

  final BooleanRule rule;
  final ValueChanged<TaskRule> onChanged;
  final RuleEditorConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completion Status',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<BooleanRuleOperator>(
          segments: config.booleanOperators.map((op) {
            return ButtonSegment<BooleanRuleOperator>(
              value: op,
              label: Text(op.displayName),
              icon: Icon(
                op == BooleanRuleOperator.isTrue
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
              ),
            );
          }).toList(),
          selected: {rule.operator},
          onSelectionChanged: (selected) {
            onChanged(
              BooleanRule(
                field: rule.field,
                operator: selected.first,
              ),
            );
          },
        ),
      ],
    );
  }
}

// ============================================================================
// Label Rule Editor
// ============================================================================

class _LabelRuleEditor extends StatelessWidget {
  const _LabelRuleEditor({
    required this.rule,
    required this.onChanged,
    required this.availableLabels,
    required this.config,
  });

  final LabelRule rule;
  final ValueChanged<TaskRule> onChanged;
  final List<Label> availableLabels;
  final RuleEditorConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Operator selector
        Text(
          'Condition',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<LabelRuleOperator>(
          initialValue: rule.operator,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: config.labelOperators.map((op) {
            return DropdownMenuItem(
              value: op,
              child: Text(op.displayName),
            );
          }).toList(),
          onChanged: (operator) {
            if (operator != null) {
              onChanged(
                LabelRule(
                  operator: operator,
                  labelIds: rule.labelIds,
                  labelType: rule.labelType,
                ),
              );
            }
          },
        ),

        // Label selection (if required)
        if (rule.operator.requiresSelection) ...[
          const SizedBox(height: 16),
          Text(
            'Select Labels',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildLabelSelector(context),
        ],
      ],
    );
  }

  Widget _buildLabelSelector(BuildContext context) {
    final theme = Theme.of(context);

    if (availableLabels.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              'No labels available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableLabels.map((label) {
        final isSelected = rule.labelIds.contains(label.id);
        final color = label.color != null
            ? _parseColor(label.color)
            : theme.colorScheme.primary;

        final isValue = label.type == LabelType.value;

        // Get the icon - emoji for values, colored label icon for labels
        final Widget icon;
        if (isValue) {
          final emoji = label.iconName?.isNotEmpty ?? false
              ? label.iconName!
              : 'â¤ï¸';
          icon = Text(
            emoji,
            style: const TextStyle(fontSize: 14),
          );
        } else {
          icon = Icon(
            Icons.label,
            size: 14,
            color: color,
          );
        }

        return FilterChip(
          label: Text(label.name),
          selected: isSelected,
          onSelected: (selected) {
            final newIds = List<String>.from(rule.labelIds);
            if (selected) {
              newIds.add(label.id);
            } else {
              newIds.remove(label.id);
            }
            onChanged(
              LabelRule(
                operator: rule.operator,
                labelIds: newIds,
                labelType: rule.labelType,
              ),
            );
          },
          avatar: icon,
          backgroundColor: theme.colorScheme.surfaceContainerLow,
          selectedColor: theme.colorScheme.surfaceContainerHighest,
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          checkmarkColor: Colors.transparent,
          side: BorderSide(
            color: isSelected
                ? color
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================================
// Value Rule Editor
// ============================================================================

class _ValueRuleEditor extends StatelessWidget {
  const _ValueRuleEditor({
    required this.rule,
    required this.onChanged,
    required this.availableValues,
    required this.config,
  });

  final ValueRule rule;
  final ValueChanged<TaskRule> onChanged;
  final List<Label> availableValues;
  final RuleEditorConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Operator selector
        Text(
          'Condition',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ValueRuleOperator>(
          initialValue: rule.operator,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: config.valueOperators.map((op) {
            return DropdownMenuItem(
              value: op,
              child: Text(op.displayName),
            );
          }).toList(),
          onChanged: (operator) {
            if (operator != null) {
              onChanged(
                ValueRule(
                  operator: operator,
                  labelIds: rule.labelIds,
                ),
              );
            }
          },
        ),

        // Value selection (if required)
        if (rule.operator.requiresSelection) ...[
          const SizedBox(height: 16),
          Text(
            'Select Values',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildValueSelector(context),
        ],
      ],
    );
  }

  Widget _buildValueSelector(BuildContext context) {
    final theme = Theme.of(context);

    if (availableValues.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              'No values available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableValues.map((value) {
        final isSelected = rule.labelIds.contains(value.id);
        final color = value.color != null
            ? _parseColor(value.color)
            : theme.colorScheme.primary;

        // Calculate text color for proper contrast on the colored background
        final luminance = color.computeLuminance();
        final textColor = luminance > 0.5 ? Colors.black87 : Colors.white;

        // Get the emoji icon for values
        final emoji = value.iconName?.isNotEmpty ?? false
            ? value.iconName!
            : 'â¤ï¸';

        return FilterChip(
          label: Text(value.name),
          selected: isSelected,
          onSelected: (selected) {
            final newIds = List<String>.from(rule.labelIds);
            if (selected) {
              newIds.add(value.id);
            } else {
              newIds.remove(value.id);
            }
            onChanged(
              ValueRule(
                operator: rule.operator,
                labelIds: newIds,
              ),
            );
          },
          avatar: Text(
            emoji,
            style: const TextStyle(fontSize: 14),
          ),
          backgroundColor: theme.colorScheme.surfaceContainerLow,
          selectedColor: color,
          labelStyle: TextStyle(
            color: isSelected ? textColor : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          checkmarkColor: Colors.transparent,
          side: BorderSide(
            color: isSelected
                ? color
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        );
      }).toList(),
    );
  }
}

// ============================================================================
// Project Rule Editor
// ============================================================================

class _ProjectRuleEditor extends StatelessWidget {
  const _ProjectRuleEditor({
    required this.rule,
    required this.onChanged,
    required this.availableProjects,
    required this.config,
  });

  final ProjectRule rule;
  final ValueChanged<TaskRule> onChanged;
  final List<Project> availableProjects;
  final RuleEditorConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Operator selector
        Text(
          'Condition',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ProjectRuleOperator>(
          initialValue: rule.operator,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: config.projectOperators.map((op) {
            return DropdownMenuItem(
              value: op,
              child: Text(op.displayName),
            );
          }).toList(),
          onChanged: (operator) {
            if (operator != null) {
              onChanged(
                ProjectRule(
                  operator: operator,
                  projectId: rule.projectId,
                ),
              );
            }
          },
        ),

        // Project selection (if required)
        if (rule.operator.requiresSelection) ...[
          const SizedBox(height: 16),
          Text(
            'Select Project',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildProjectSelector(context),
        ],
      ],
    );
  }

  Widget _buildProjectSelector(BuildContext context) {
    final theme = Theme.of(context);

    if (availableProjects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              'No projects available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: rule.projectId,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintText: 'Select a project',
      ),
      items: availableProjects.map((project) {
        return DropdownMenuItem(
          value: project.id,
          child: Row(
            children: [
              Icon(
                Icons.folder,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(project.name),
            ],
          ),
        );
      }).toList(),
      onChanged: (projectId) {
        onChanged(
          ProjectRule(
            operator: rule.operator,
            projectId: projectId,
          ),
        );
      },
    );
  }
}

// ============================================================================
// Rule Description Extension
// ============================================================================

/// Extension to get a human-readable description of a rule.
extension TaskRuleDescription on TaskRule {
  String get description {
    return switch (this) {
      final DateRule rule => _describeDateRule(rule),
      final BooleanRule rule => _describeBooleanRule(rule),
      final LabelRule rule => _describeLabelRule(rule),
      final ValueRule rule => _describeValueRule(rule),
      final ProjectRule rule => _describeProjectRule(rule),
      _ => 'Unknown rule',
    };
  }

  String _describeDateRule(DateRule rule) {
    final field = rule.field.displayName;
    return switch (rule.operator) {
      DateRuleOperator.relative =>
        rule.relativeComparison != null
            ? '$field ${rule.relativeComparison!.descriptionWithDays(rule.relativeDays ?? 0)}'
            : '$field relative to today',
      DateRuleOperator.isNull => '$field is not set',
      DateRuleOperator.isNotNull => '$field is set',
      DateRuleOperator.between =>
        '$field between ${_formatDate(rule.startDate)} and ${_formatDate(rule.endDate)}',
      _ =>
        '$field ${rule.operator.displayName.toLowerCase()} ${_formatDate(rule.date)}',
    };
  }

  String _describeBooleanRule(BooleanRule rule) {
    return rule.operator.displayName;
  }

  String _describeLabelRule(LabelRule rule) {
    return switch (rule.operator) {
      LabelRuleOperator.hasAll => 'Has all selected labels',
      LabelRuleOperator.hasAny => 'Has any selected label',
      LabelRuleOperator.isNull => 'Has no labels',
      LabelRuleOperator.isNotNull => 'Has labels',
    };
  }

  String _describeValueRule(ValueRule rule) {
    return switch (rule.operator) {
      ValueRuleOperator.hasAll => 'Has all selected values',
      ValueRuleOperator.hasAny => 'Has any selected value',
      ValueRuleOperator.isNull => 'Has no values',
      ValueRuleOperator.isNotNull => 'Has values',
    };
  }

  String _describeProjectRule(ProjectRule rule) {
    return switch (rule.operator) {
      ProjectRuleOperator.matches => 'In selected project',
      ProjectRuleOperator.isNull => 'Has no project',
      ProjectRuleOperator.isNotNull => 'Has a project',
    };
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'not set';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
