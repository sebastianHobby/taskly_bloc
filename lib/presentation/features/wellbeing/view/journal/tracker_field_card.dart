import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/journal/model/tracker.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_response.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_response_config.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_tracker_response_fields.dart';

/// A card widget that displays a tracker field based on its response type.
class TrackerFieldCard extends StatelessWidget {
  const TrackerFieldCard({
    required this.tracker,
    this.initialValue,
    this.fieldNamePrefix = 'tracker_',
    super.key,
  });

  final Tracker tracker;
  final TrackerResponseValue? initialValue;
  final String fieldNamePrefix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = '$fieldNamePrefix${tracker.id}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tracker.name,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (tracker.description != null) ...[
            const SizedBox(height: 4),
            Text(
              tracker.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildField(name),
        ],
      ),
    );
  }

  Widget _buildField(String name) {
    return switch (tracker.responseType) {
      TrackerResponseType.yesNo => FormBuilderTrackerYesNoField(
        name: name,
        initialValue: initialValue,
      ),
      TrackerResponseType.scale => switch (tracker.config) {
        ScaleConfig(:final min, :final max, :final minLabel, :final maxLabel) =>
          FormBuilderTrackerScaleField(
            name: name,
            min: min,
            max: max,
            minLabel: minLabel,
            maxLabel: maxLabel,
            initialValue: initialValue,
          ),
        _ => const SizedBox.shrink(),
      },
      TrackerResponseType.choice => switch (tracker.config) {
        ChoiceConfig(:final options) => FormBuilderTrackerChoiceField(
          name: name,
          options: options,
          initialValue: initialValue,
        ),
        _ => const SizedBox.shrink(),
      },
    };
  }
}
