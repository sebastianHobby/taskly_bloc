import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';

/// Shows a modern sort bottom sheet with Material 3 design.
///
/// Features:
/// - Consistent styling with other bottom sheets
/// - Modern chip-based sort field selection
/// - Clear visual hierarchy
/// - Animated direction toggle
Future<void> showSortBottomSheet({
  required BuildContext context,
  required SortPreferences current,
  required List<SortField> availableSortFields,
  required ValueChanged<SortPreferences> onChanged,
}) {
  assert(availableSortFields.isNotEmpty, 'Provide at least one sort field');

  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _SortBottomSheetContent(
        current: current,
        availableSortFields: availableSortFields,
        onChanged: onChanged,
      );
    },
  );
}

class _SortBottomSheetContent extends StatefulWidget {
  const _SortBottomSheetContent({
    required this.current,
    required this.availableSortFields,
    required this.onChanged,
  });

  final SortPreferences current;
  final List<SortField> availableSortFields;
  final ValueChanged<SortPreferences> onChanged;

  @override
  State<_SortBottomSheetContent> createState() =>
      _SortBottomSheetContentState();
}

class _SortBottomSheetContentState extends State<_SortBottomSheetContent> {
  late List<SortCriterion?> _slotValues;

  @override
  void initState() {
    super.initState();
    final slotCount = widget.availableSortFields.length.clamp(1, 3);
    _slotValues = List<SortCriterion?>.generate(
      slotCount,
      (index) => index < widget.current.criteria.length
          ? widget.current.criteria[index]
          : null,
    );
  }

  List<SortCriterion> _sanitizeSelection() {
    final sanitized = <SortCriterion>[];
    for (final criterion in _slotValues) {
      if (criterion == null) continue;
      if (!widget.availableSortFields.contains(criterion.field)) continue;
      final exists = sanitized.any((c) => c.field == criterion.field);
      if (exists) continue;
      sanitized.add(criterion);
    }
    if (sanitized.isEmpty) {
      sanitized.add(
        SortCriterion(field: widget.availableSortFields.first),
      );
    }
    return sanitized;
  }

  void _emitSelection() {
    widget.onChanged(
      SortPreferences(criteria: _sanitizeSelection()),
    );
  }

  void _updateSlotField(int index, SortField? value) {
    setState(() {
      for (var i = 0; i < _slotValues.length; i++) {
        if (i == index) continue;
        if (_slotValues[i]?.field == value) _slotValues[i] = null;
      }
      if (value == null) {
        _slotValues[index] = null;
      } else {
        final direction =
            _slotValues[index]?.direction ?? SortDirection.ascending;
        _slotValues[index] = SortCriterion(
          field: value,
          direction: direction,
        );
      }
    });
    _emitSelection();
  }

  void _updateSlotDirection(int index, SortDirection? value) {
    if (value == null) return;
    setState(() {
      final current = _slotValues[index];
      if (current == null) return;
      _slotValues[index] = current.copyWith(direction: value);
    });
    _emitSelection();
  }

  void _toggleDirection(int index) {
    final current = _slotValues[index];
    if (current == null) return;
    final newDirection = current.direction == SortDirection.ascending
        ? SortDirection.descending
        : SortDirection.ascending;
    _updateSlotDirection(index, newDirection);
  }

  String _fieldLabel(BuildContext context, SortField field) {
    final l10n = context.l10n;
    return switch (field) {
      SortField.name => l10n.sortFieldNameLabel,
      SortField.startDate => l10n.sortFieldStartDateLabel,
      SortField.deadlineDate => l10n.sortFieldDeadlineDateLabel,
      SortField.createdDate => 'Created date',
      SortField.updatedDate => 'Updated date',
      SortField.nextActionPriority => 'Next action priority',
    };
  }

  IconData _fieldIcon(SortField field) {
    return switch (field) {
      SortField.name => Icons.sort_by_alpha_rounded,
      SortField.startDate => Icons.calendar_today_rounded,
      SortField.deadlineDate => Icons.flag_rounded,
      SortField.createdDate => Icons.add_circle_outline_rounded,
      SortField.updatedDate => Icons.update_rounded,
      SortField.nextActionPriority => Icons.low_priority_rounded,
    };
  }

  String _slotLabel(BuildContext context, int index) {
    final l10n = context.l10n;
    return switch (index) {
      0 => l10n.sortSlotPrimaryLabel,
      1 => l10n.sortSlotSecondaryLabel,
      _ => l10n.sortSlotTertiaryLabel,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.swap_vert_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.sortMenuTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Choose how to order items',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Sort options
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _slotValues.length; i++) ...[
                    _SortSlotCard(
                      index: i,
                      label: _slotLabel(context, i),
                      selectedField: _slotValues[i]?.field,
                      selectedDirection: _slotValues[i]?.direction,
                      availableFields: widget.availableSortFields,
                      fieldLabel: (field) => _fieldLabel(context, field),
                      fieldIcon: _fieldIcon,
                      onFieldChanged: (field) => _updateSlotField(i, field),
                      onDirectionToggle: () => _toggleDirection(i),
                      isFirst: i == 0,
                    ),
                    if (i < _slotValues.length - 1) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A modern card representing a single sort slot.
class _SortSlotCard extends StatelessWidget {
  const _SortSlotCard({
    required this.index,
    required this.label,
    required this.selectedField,
    required this.selectedDirection,
    required this.availableFields,
    required this.fieldLabel,
    required this.fieldIcon,
    required this.onFieldChanged,
    required this.onDirectionToggle,
    required this.isFirst,
  });

  final int index;
  final String label;
  final SortField? selectedField;
  final SortDirection? selectedDirection;
  final List<SortField> availableFields;
  final String Function(SortField) fieldLabel;
  final IconData Function(SortField) fieldIcon;
  final ValueChanged<SortField?> onFieldChanged;
  final VoidCallback onDirectionToggle;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final isActive = selectedField != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primaryContainer.withValues(alpha: 0.15)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slot label with priority indicator
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isFirst
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isFirst
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Field selection chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // "None" option for non-primary slots
              if (!isFirst)
                _SortFieldChip(
                  label: l10n.sortFieldNoneLabel,
                  icon: Icons.remove_circle_outline_rounded,
                  isSelected: selectedField == null,
                  onTap: () => onFieldChanged(null),
                ),
              // Available field options
              ...availableFields.map(
                (field) => _SortFieldChip(
                  label: fieldLabel(field),
                  icon: fieldIcon(field),
                  isSelected: selectedField == field,
                  onTap: () => onFieldChanged(field),
                ),
              ),
            ],
          ),

          // Direction toggle (only when field selected)
          if (isActive) ...[
            const SizedBox(height: 16),
            _DirectionToggle(
              direction: selectedDirection ?? SortDirection.ascending,
              onToggle: onDirectionToggle,
            ),
          ],
        ],
      ),
    );
  }
}

/// A chip for selecting a sort field.
class _SortFieldChip extends StatelessWidget {
  const _SortFieldChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A toggle button for sort direction.
class _DirectionToggle extends StatelessWidget {
  const _DirectionToggle({
    required this.direction,
    required this.onToggle,
  });

  final SortDirection direction;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final isAscending = direction == SortDirection.ascending;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedRotation(
                turns: isAscending ? 0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isAscending
                    ? l10n.sortDirectionAscending
                    : l10n.sortDirectionDescending,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.swap_vert_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
