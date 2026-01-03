import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';

/// FormBuilder field for selecting entity type.
///
/// Displays chip options for task, project, and label entity types.
class FormBuilderEntityTypePicker
    extends FormBuilderFieldDecoration<EntityType> {
  FormBuilderEntityTypePicker({
    required super.name,
    super.key,
    super.initialValue,
    super.decoration,
    super.onChanged,
    super.valueTransformer,
    super.enabled,
    super.onReset,
    super.focusNode,
    super.validator,
    super.autovalidateMode,
  }) : super(
         builder: (FormFieldState<EntityType> field) {
           final state =
               field
                   as FormBuilderFieldDecorationState<
                     FormBuilderEntityTypePicker,
                     EntityType
                   >;

           return InputDecorator(
             decoration: state.decoration,
             child: _EntityTypeSelector(
               value: state.value,
               enabled: state.enabled,
               onChanged: state.didChange,
             ),
           );
         },
       );
}

class _EntityTypeSelector extends StatelessWidget {
  const _EntityTypeSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final EntityType? value;
  final bool enabled;
  final ValueChanged<EntityType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: EntityType.values.map((type) {
        final isSelected = value == type;

        return FilterChip(
          label: Text(_getLabel(type)),
          avatar: Icon(
            _getIcon(type),
            size: 18,
            color: isSelected
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onSurfaceVariant,
          ),
          selected: isSelected,
          onSelected: enabled
              ? (selected) {
                  if (selected) {
                    onChanged(type);
                  }
                }
              : null,
        );
      }).toList(),
    );
  }

  String _getLabel(EntityType type) {
    switch (type) {
      case EntityType.task:
        return 'Tasks';
      case EntityType.project:
        return 'Projects';
      case EntityType.label:
        return 'Labels';
      case EntityType.goal:
        return 'Goals';
      case EntityType.journal:
        return 'Journal Entries';
      case EntityType.tracker:
        return 'Trackers';
    }
  }

  IconData _getIcon(EntityType type) {
    switch (type) {
      case EntityType.task:
        return Icons.check_circle_outline;
      case EntityType.project:
        return Icons.folder_outlined;
      case EntityType.label:
        return Icons.label_outline;
      case EntityType.goal:
        return Icons.flag_outlined;
      case EntityType.journal:
        return Icons.edit_note;
      case EntityType.tracker:
        return Icons.checklist;
    }
  }
}
