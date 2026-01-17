import 'package:flutter/material.dart';
import 'package:taskly_bloc/domain/journal/model/journal_entry.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_event.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_today_shared_widgets.dart';

final class JournalTodayEntriesSectionRendererV1 extends StatelessWidget {
  const JournalTodayEntriesSectionRendererV1({
    required this.entries,
    required this.eventsByEntryId,
    required this.definitionById,
    required this.moodTrackerId,
    required this.onEntryTap,
    super.key,
  });

  final List<JournalEntry> entries;
  final Map<String, List<TrackerEvent>> eventsByEntryId;
  final Map<String, TrackerDefinition> definitionById;
  final String? moodTrackerId;
  final ValueChanged<JournalEntry> onEntryTap;

  @override
  Widget build(BuildContext context) {
    return JournalTodayEntriesSection(
      entries: entries,
      eventsByEntryId: eventsByEntryId,
      definitionById: definitionById,
      moodTrackerId: moodTrackerId,
      onEntryTap: onEntryTap,
    );
  }
}
