import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/domain/wellbeing/model/tracker_response.dart';

/// FormBuilder field for yes/no tracker responses
class FormBuilderTrackerYesNoField
    extends FormBuilderFieldDecoration<TrackerResponseValue> {
  FormBuilderTrackerYesNoField({
    required super.name,
    super.key,
    super.validator,
    super.initialValue,
    super.onChanged,
    super.enabled = true,
    super.decoration = const InputDecoration(border: InputBorder.none),
    this.yesLabel = 'Yes',
    this.noLabel = 'No',
    this.selectedColor,
  }) : super(
         builder: (FormFieldState<TrackerResponseValue> field) {
           final state =
               field
                   as FormBuilderFieldDecorationState<
                     FormBuilderTrackerYesNoField,
                     TrackerResponseValue
                   >;
           final theme = Theme.of(state.context);
           final widget = state.widget;
           final selectedColor =
               widget.selectedColor ?? theme.colorScheme.primary;

           final bool? currentValue = state.value?.mapOrNull(
             yesNo: (v) => v.value,
           );

           return InputDecorator(
             decoration: state.decoration,
             child: Row(
               children: [
                 Expanded(
                   child: _OptionButton(
                     label: widget.noLabel,
                     isSelected: currentValue == false,
                     onTap: state.enabled
                         ? () => state.didChange(
                             const TrackerResponseValue.yesNo(value: false),
                           )
                         : null,
                     selectedColor: selectedColor,
                     icon: Icons.close,
                   ),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: _OptionButton(
                     label: widget.yesLabel,
                     isSelected: currentValue ?? false,
                     onTap: state.enabled
                         ? () => state.didChange(
                             const TrackerResponseValue.yesNo(value: true),
                           )
                         : null,
                     selectedColor: selectedColor,
                     icon: Icons.check,
                   ),
                 ),
               ],
             ),
           );
         },
       );

  final String yesLabel;
  final String noLabel;
  final Color? selectedColor;

  @override
  FormBuilderFieldDecorationState<
    FormBuilderTrackerYesNoField,
    TrackerResponseValue
  >
  createState() => FormBuilderFieldDecorationState();
}

/// FormBuilder field for scale tracker responses
class FormBuilderTrackerScaleField
    extends FormBuilderFieldDecoration<TrackerResponseValue> {
  FormBuilderTrackerScaleField({
    required super.name,
    required this.min,
    required this.max,
    super.key,
    super.validator,
    super.initialValue,
    super.onChanged,
    super.enabled = true,
    super.decoration = const InputDecoration(border: InputBorder.none),
    this.minLabel,
    this.maxLabel,
    this.divisions,
    this.showValue = true,
  }) : super(
         builder: (FormFieldState<TrackerResponseValue> field) {
           final state =
               field
                   as FormBuilderFieldDecorationState<
                     FormBuilderTrackerScaleField,
                     TrackerResponseValue
                   >;
           final theme = Theme.of(state.context);
           final widget = state.widget;

           final int? currentValue = state.value?.mapOrNull(
             scale: (v) => v.value,
           );

           return InputDecorator(
             decoration: state.decoration,
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   children: [
                     if (widget.minLabel != null) ...[
                       Expanded(
                         child: Text(
                           widget.minLabel!,
                           style: theme.textTheme.bodySmall,
                         ),
                       ),
                     ],
                     if (widget.showValue && currentValue != null)
                       Container(
                         padding: const EdgeInsets.symmetric(
                           horizontal: 12,
                           vertical: 4,
                         ),
                         decoration: BoxDecoration(
                           color: theme.colorScheme.primaryContainer,
                           borderRadius: BorderRadius.circular(12),
                         ),
                         child: Text(
                           currentValue.toString(),
                           style: theme.textTheme.titleMedium?.copyWith(
                             color: theme.colorScheme.onPrimaryContainer,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                       ),
                     if (widget.maxLabel != null) ...[
                       Expanded(
                         child: Text(
                           widget.maxLabel!,
                           style: theme.textTheme.bodySmall,
                           textAlign: TextAlign.end,
                         ),
                       ),
                     ],
                   ],
                 ),
                 Slider(
                   value: currentValue?.toDouble() ?? widget.min.toDouble(),
                   min: widget.min.toDouble(),
                   max: widget.max.toDouble(),
                   divisions: widget.divisions ?? (widget.max - widget.min),
                   onChanged: state.enabled
                       ? (value) => state.didChange(
                           TrackerResponseValue.scale(
                             value: value.round(),
                           ),
                         )
                       : null,
                 ),
                 Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text(
                       widget.min.toString(),
                       style: theme.textTheme.bodySmall,
                     ),
                     Text(
                       widget.max.toString(),
                       style: theme.textTheme.bodySmall,
                     ),
                   ],
                 ),
               ],
             ),
           );
         },
       );

  final int min;
  final int max;
  final String? minLabel;
  final String? maxLabel;
  final int? divisions;
  final bool showValue;

  @override
  FormBuilderFieldDecorationState<
    FormBuilderTrackerScaleField,
    TrackerResponseValue
  >
  createState() => FormBuilderFieldDecorationState();
}

/// FormBuilder field for choice tracker responses
class FormBuilderTrackerChoiceField
    extends FormBuilderFieldDecoration<TrackerResponseValue> {
  FormBuilderTrackerChoiceField({
    required super.name,
    required this.options,
    super.key,
    super.validator,
    super.initialValue,
    super.onChanged,
    super.enabled = true,
    super.decoration = const InputDecoration(border: InputBorder.none),
    this.spacing = 8.0,
    this.selectedColor,
  }) : super(
         builder: (FormFieldState<TrackerResponseValue> field) {
           final state =
               field
                   as FormBuilderFieldDecorationState<
                     FormBuilderTrackerChoiceField,
                     TrackerResponseValue
                   >;
           final theme = Theme.of(state.context);
           final widget = state.widget;
           final selectedColor =
               widget.selectedColor ?? theme.colorScheme.primary;

           final String? currentValue = state.value?.mapOrNull(
             choice: (v) => v.selected,
           );

           return InputDecorator(
             decoration: state.decoration,
             child: Wrap(
               spacing: widget.spacing,
               runSpacing: widget.spacing,
               children: widget.options.map((option) {
                 final isSelected = currentValue == option;
                 return ChoiceChip(
                   label: Text(option),
                   selected: isSelected,
                   onSelected: state.enabled
                       ? (selected) {
                           if (selected) {
                             state.didChange(
                               TrackerResponseValue.choice(selected: option),
                             );
                           }
                         }
                       : null,
                   selectedColor: selectedColor.withValues(alpha: 0.2),
                   checkmarkColor: selectedColor,
                   labelStyle: TextStyle(
                     color: isSelected ? selectedColor : null,
                     fontWeight: isSelected
                         ? FontWeight.bold
                         : FontWeight.normal,
                   ),
                 );
               }).toList(),
             ),
           );
         },
       );

  final List<String> options;
  final double spacing;
  final Color? selectedColor;

  @override
  FormBuilderFieldDecorationState<
    FormBuilderTrackerChoiceField,
    TrackerResponseValue
  >
  createState() => FormBuilderFieldDecorationState();
}

// Helper widget for yes/no buttons
class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.selectedColor,
    required this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color selectedColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? selectedColor : theme.dividerColor,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : theme.iconTheme.color,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected ? selectedColor : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
