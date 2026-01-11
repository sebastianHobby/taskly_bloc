import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/presentation/theme/app_colors.dart';

/// A form field for selecting task priority (1-4).
class FormBuilderPriorityPicker extends FormBuilderFieldDecoration<int?> {
  FormBuilderPriorityPicker({
    required super.name,
    super.key,
    super.initialValue,
    super.validator,
    super.onChanged,
    super.decoration = const InputDecoration(
      labelText: 'Priority',
      border: InputBorder.none,
      contentPadding: EdgeInsets.zero,
    ),
  }) : super(
         builder: (FormFieldState<int?> field) {
           return InputDecorator(
             decoration: decoration,
             child: Row(
               children: [
                 _PriorityChip(
                   label: 'P1',
                   color: AppColors.rambutan80,
                   isSelected: field.value == 1,
                   onTap: () => field.didChange(field.value == 1 ? null : 1),
                 ),
                 const SizedBox(width: 8),
                 _PriorityChip(
                   label: 'P2',
                   color: AppColors.cempedak80,
                   isSelected: field.value == 2,
                   onTap: () => field.didChange(field.value == 2 ? null : 2),
                 ),
                 const SizedBox(width: 8),
                 _PriorityChip(
                   label: 'P3',
                   color: AppColors.blueberry80,
                   isSelected: field.value == 3,
                   onTap: () => field.didChange(field.value == 3 ? null : 3),
                 ),
                 const SizedBox(width: 8),
                 _PriorityChip(
                   label: 'P4',
                   color: Colors.grey,
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

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      backgroundColor: isDark ? Colors.transparent : Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
      side: BorderSide(
        color: isSelected ? color : theme.colorScheme.outline.withOpacity(0.3),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
