import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/widgets/filters/filter_enums.dart';

/// Type-safe selection mode toggle widget.
///
/// Provides a consistent UI for choosing between "All" and "Specific" modes
/// across different entity types.
///
/// Example:
/// ```dart
/// SelectionModeChoice(
///   mode: SelectionMode.specific,
///   onChanged: (mode) => setState(() => _mode = mode),
///   entityName: 'projects',
/// )
/// ```
class SelectionModeChoice extends StatelessWidget {
  const SelectionModeChoice({
    required this.mode,
    required this.onChanged,
    required this.entityName,
    this.allIcon,
    this.specificIcon,
    super.key,
  });

  /// Current selection mode.
  final SelectionMode mode;

  /// Called when the mode changes.
  final ValueChanged<SelectionMode> onChanged;

  /// Name of the entity type (e.g., 'projects', 'tasks').
  final String entityName;

  /// Optional icon for "All" mode.
  final IconData? allIcon;

  /// Optional icon for "Specific" mode.
  final IconData? specificIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: Text(SelectionMode.all.label(entityName)),
            avatar: allIcon != null ? Icon(allIcon, size: 18) : null,
            selected: mode == SelectionMode.all,
            onSelected: (_) => onChanged(SelectionMode.all),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceChip(
            label: Text(SelectionMode.specific.label(entityName)),
            avatar: specificIcon != null ? Icon(specificIcon, size: 18) : null,
            selected: mode == SelectionMode.specific,
            onSelected: (_) => onChanged(SelectionMode.specific),
          ),
        ),
      ],
    );
  }
}
