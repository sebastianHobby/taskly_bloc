import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

/// A form field for selecting task priority (1-4).
class FormBuilderPriorityPicker extends FormBuilderFieldDecoration<int?> {
  FormBuilderPriorityPicker({
    required super.name,
    super.key,
    super.initialValue,
    super.validator,
    super.onChanged,
    super.decoration = const InputDecoration(
      border: InputBorder.none,
      contentPadding: EdgeInsets.zero,
    ),
  }) : super(
         builder: (field) {
           final scheme = Theme.of(field.context).colorScheme;
           final tokens = TasklyTokens.of(field.context);
           final l10n = field.context.l10n;
           final effectiveDecoration = decoration.copyWith(
             labelText: decoration.labelText ?? l10n.priorityLabel,
           );
           return InputDecorator(
             decoration: effectiveDecoration,
             child: Row(
               children: [
                 _PriorityChip(
                   label: 'P1',
                   color: scheme.error,
                   isSelected: field.value == 1,
                   onTap: () => field.didChange(field.value == 1 ? null : 1),
                 ),
                 SizedBox(width: tokens.spaceSm),
                 _PriorityChip(
                   label: 'P2',
                   color: scheme.tertiary,
                   isSelected: field.value == 2,
                   onTap: () => field.didChange(field.value == 2 ? null : 2),
                 ),
                 SizedBox(width: tokens.spaceSm),
                 _PriorityChip(
                   label: 'P3',
                   color: scheme.primary,
                   isSelected: field.value == 3,
                   onTap: () => field.didChange(field.value == 3 ? null : 3),
                 ),
                 SizedBox(width: tokens.spaceSm),
                 _PriorityChip(
                   label: 'P4',
                   color: scheme.outline,
                   isSelected: field.value == 4,
                   onTap: () => field.didChange(field.value == 4 ? null : 4),
                 ),
               ],
             ),
           );
         },
       );
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color.withValues(alpha: 0.16),
      checkmarkColor: color,
      backgroundColor: isDark
          ? scheme.surface.withValues(alpha: 0)
          : scheme.surfaceContainerLowest,
      labelStyle: TextStyle(
        color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
      side: BorderSide(
        color: isSelected
            ? color
            : theme.colorScheme.outline.withValues(alpha: 0.3),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusSm),
      ),
    );
  }
}
