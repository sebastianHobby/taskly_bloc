import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/domain/models/wellbeing/mood_rating.dart';

/// FormBuilder field for mood selection with validation support.
///
/// Integrates with FormBuilder for consistent form handling and validation.
/// Displays mood options as selectable emoji chips with color coding.
class FormBuilderMoodField extends FormBuilderFieldDecoration<MoodRating> {
  FormBuilderMoodField({
    required super.name,
    super.key,
    super.validator,
    super.initialValue,
    super.onChanged,
    super.enabled = true,
    super.decoration = const InputDecoration(border: InputBorder.none),
    this.compact = false,
  }) : super(
         builder: (FormFieldState<MoodRating> field) {
           final state =
               field
                   as FormBuilderFieldDecorationState<
                     FormBuilderMoodField,
                     MoodRating
                   >;
           final widget = state.widget;

           return InputDecorator(
             decoration: state.decoration,
             child: widget.compact
                 ? _CompactMoodSelector(
                     selected: state.value,
                     enabled: state.enabled,
                     onSelected: state.didChange,
                   )
                 : _ExpandedMoodSelector(
                     selected: state.value,
                     enabled: state.enabled,
                     onSelected: state.didChange,
                   ),
           );
         },
       );

  /// If true, displays a more compact horizontal layout.
  final bool compact;

  @override
  FormBuilderFieldDecorationState<FormBuilderMoodField, MoodRating>
  createState() => FormBuilderFieldDecorationState();
}

class _ExpandedMoodSelector extends StatelessWidget {
  const _ExpandedMoodSelector({
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final MoodRating? selected;
  final bool enabled;
  final ValueChanged<MoodRating?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: MoodRating.values.map((mood) {
        final isSelected = selected == mood;
        return Expanded(
          child: _MoodOption(
            mood: mood,
            isSelected: isSelected,
            enabled: enabled,
            onTap: () => onSelected(mood),
          ),
        );
      }).toList(),
    );
  }
}

class _CompactMoodSelector extends StatelessWidget {
  const _CompactMoodSelector({
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final MoodRating? selected;
  final bool enabled;
  final ValueChanged<MoodRating?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: MoodRating.values.map((mood) {
        final isSelected = selected == mood;
        return ChoiceChip(
          label: Text('${mood.emoji} ${mood.label}'),
          selected: isSelected,
          onSelected: enabled ? (_) => onSelected(mood) : null,
          selectedColor: _getMoodColor(mood).withValues(alpha: 0.2),
          labelStyle: TextStyle(
            color: isSelected ? _getMoodColor(mood) : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}

class _MoodOption extends StatelessWidget {
  const _MoodOption({
    required this.mood,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final MoodRating mood;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getMoodColor(mood);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            border: Border.all(
              color: isSelected ? color : theme.dividerColor,
              width: isSelected ? 2.5 : 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mood.emoji,
                style: TextStyle(
                  fontSize: isSelected ? 28 : 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mood.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected ? color : theme.textTheme.bodySmall?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _getMoodColor(MoodRating mood) {
  return switch (mood) {
    MoodRating.veryLow => Colors.red.shade700,
    MoodRating.low => Colors.orange.shade700,
    MoodRating.neutral => Colors.grey.shade600,
    MoodRating.good => Colors.lightGreen.shade700,
    MoodRating.excellent => Colors.green.shade700,
  };
}
