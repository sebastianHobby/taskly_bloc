import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_domain/journal.dart';

/// FormBuilder field for selecting a mood rating
class FormBuilderMoodRatingField
    extends FormBuilderFieldDecoration<MoodRating> {
  FormBuilderMoodRatingField({
    required super.name,
    super.key,
    super.validator,
    super.initialValue,
    super.onChanged,
    super.enabled = true,
    super.decoration = const InputDecoration(border: InputBorder.none),
    this.spacing = 8.0,
    this.showLabels = true,
    this.selectedBorderColor,
    this.selectedBackgroundColor,
  }) : super(
         builder: (FormFieldState<MoodRating> field) {
           final state =
               field
                   as FormBuilderFieldDecorationState<
                     FormBuilderMoodRatingField,
                     MoodRating
                   >;
           final theme = Theme.of(state.context);
           final colorScheme = theme.colorScheme;
           final widget = state.widget;

           return InputDecorator(
             decoration: state.decoration,
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
               children: MoodRating.values.map((mood) {
                 final isSelected = state.value == mood;

                 return Expanded(
                   child: Padding(
                     padding: EdgeInsets.symmetric(
                       horizontal: widget.spacing / 2,
                     ),
                     child: InkWell(
                       onTap: state.enabled
                           ? () => state.didChange(mood)
                           : null,
                       borderRadius: BorderRadius.circular(12),
                       child: Container(
                         padding: const EdgeInsets.symmetric(
                           vertical: 12,
                           horizontal: 8,
                         ),
                         decoration: BoxDecoration(
                           color: isSelected
                               ? (widget.selectedBackgroundColor ??
                                     _getMoodColor(
                                       mood,
                                       colorScheme,
                                     ).withValues(alpha: 0.2))
                               : Colors.transparent,
                           border: Border.all(
                             color: isSelected
                                 ? (widget.selectedBorderColor ??
                                       _getMoodColor(mood, colorScheme))
                                 : theme.dividerColor,
                             width: 2,
                           ),
                           borderRadius: BorderRadius.circular(12),
                         ),
                         child: Column(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Text(
                               mood.emoji,
                               style: TextStyle(
                                 fontSize: 32,
                                 color: state.enabled
                                     ? null
                                     : theme.disabledColor,
                               ),
                             ),
                             if (widget.showLabels) ...[
                               const SizedBox(height: 4),
                               Text(
                                 mood.label,
                                 style: theme.textTheme.bodySmall?.copyWith(
                                   color: isSelected
                                       ? _getMoodColor(mood, colorScheme)
                                       : theme.textTheme.bodySmall?.color,
                                   fontWeight: isSelected
                                       ? FontWeight.bold
                                       : FontWeight.normal,
                                 ),
                                 textAlign: TextAlign.center,
                                 maxLines: 1,
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ],
                           ],
                         ),
                       ),
                     ),
                   ),
                 );
               }).toList(),
             ),
           );
         },
       );

  final double spacing;
  final bool showLabels;
  final Color? selectedBorderColor;
  final Color? selectedBackgroundColor;

  @override
  FormBuilderFieldDecorationState<FormBuilderMoodRatingField, MoodRating>
  createState() => FormBuilderFieldDecorationState();

  static Color _getMoodColor(MoodRating mood, ColorScheme colorScheme) {
    return switch (mood) {
      MoodRating.veryLow => Colors.red.shade700,
      MoodRating.low => Colors.orange.shade700,
      MoodRating.neutral => Colors.grey.shade600,
      MoodRating.good => Colors.lightGreen.shade700,
      MoodRating.excellent => Colors.green.shade700,
    };
  }
}
