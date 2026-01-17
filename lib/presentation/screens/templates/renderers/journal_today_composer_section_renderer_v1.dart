import 'package:flutter/material.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_today_shared_widgets.dart';

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
    return JournalTodayComposer(
      pinnedTrackers: pinnedTrackers,
      onAddLog: onAddLog,
      onQuickAddTracker: onQuickAddTracker,
    );
  }
}
