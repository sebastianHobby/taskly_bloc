import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/models/wellbeing/mood_rating.dart';

class MoodSelector extends StatelessWidget {
  const MoodSelector({
    required this.onMoodSelected,
    this.selectedMood,
    super.key,
  });
  final MoodRating? selectedMood;
  final ValueChanged<MoodRating> onMoodSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: MoodRating.values.map((mood) {
        final isSelected = selectedMood == mood;
        return InkWell(
          onTap: () => onMoodSelected(mood),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? _getMoodColor(mood).withValues(alpha: 0.2)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? _getMoodColor(mood)
                    : Theme.of(context).dividerColor,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getMoodEmoji(mood),
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 4),
                Text(
                  _getMoodLabel(mood),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? _getMoodColor(mood)
                        : Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _getMoodEmoji(MoodRating mood) {
    return mood.emoji;
  }

  String _getMoodLabel(MoodRating mood) {
    return mood.label;
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
}
