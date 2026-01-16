import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';

/// Journal Today "composer" section.
///
/// Phase 02: minimal UI for quick-add + add-log entry point.
final class JournalTodayComposerSectionRendererV1 extends StatelessWidget {
  const JournalTodayComposerSectionRendererV1({
    required this.pinnedTrackers,
    required this.onAddLog,
    required this.onQuickAddTracker,
    super.key,
  });

  final List<TrackerDefinition> pinnedTrackers;
  final VoidCallback onAddLog;
  final ValueChanged<String> onQuickAddTracker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Today',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: onAddLog,
              icon: const Icon(Icons.add),
              label: const Text('Add log'),
            ),
          ],
        ),
        if (pinnedTrackers.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Quick add',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tracker in pinnedTrackers)
                ActionChip(
                  label: Text(tracker.name),
                  onPressed: () => onQuickAddTracker(tracker.id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
