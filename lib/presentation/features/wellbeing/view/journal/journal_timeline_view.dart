import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/domain/journal/model/daily_tracker_response.dart';
import 'package:taskly_bloc/domain/journal/model/journal_entry.dart';
import 'package:taskly_bloc/domain/journal/model/tracker.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/journal/journal_empty_state.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/journal/journal_entry_card.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/journal/journal_new_entry_form.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/widgets/daily_tracker_section.dart';
import 'package:taskly_bloc/presentation/widgets/content_constraint.dart';

/// Timeline view showing all journal entries for a selected date.
class JournalTimelineView extends StatelessWidget {
  const JournalTimelineView({
    required this.selectedDate,
    required this.entries,
    required this.dailyResponses,
    required this.dailyTrackers,
    required this.perEntryTrackers,
    required this.isCreatingNew,
    required this.newEntryFormKey,
    required this.onCancelNew,
    required this.onSaveEntry,
    required this.onDeleteEntry,
    super.key,
  });

  final DateTime selectedDate;
  final List<JournalEntry> entries;
  final List<DailyTrackerResponse> dailyResponses;
  final List<Tracker> dailyTrackers;
  final List<Tracker> perEntryTrackers;
  final bool isCreatingNew;
  final GlobalKey<FormBuilderState> newEntryFormKey;
  final VoidCallback onCancelNew;
  final void Function(JournalEntry, List<DailyTrackerResponse>) onSaveEntry;
  final void Function(String) onDeleteEntry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ResponsiveBody(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Daily trackers summary
          if (dailyTrackers.isNotEmpty) ...[
            DailyTrackersSummary(
              trackers: dailyTrackers,
              responses: dailyResponses,
            ),
            const SizedBox(height: 16),
          ],

          // New entry form (if creating)
          if (isCreatingNew) ...[
            JournalNewEntryForm(
              formKey: newEntryFormKey,
              selectedDate: selectedDate,
              dailyTrackers: dailyTrackers,
              perEntryTrackers: perEntryTrackers,
              existingDailyResponses: dailyResponses,
              onCancel: onCancelNew,
              onSave: onSaveEntry,
            ),
            const SizedBox(height: 16),
          ],

          // Section header for entries
          if (entries.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Entries',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${entries.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Entries list (newest first)
          if (entries.isEmpty && !isCreatingNew)
            const JournalEmptyState()
          else
            ...entries.reversed.map(
              (entry) => JournalEntryCard(
                entry: entry,
                perEntryTrackers: perEntryTrackers,
                dailyTrackers: dailyTrackers,
                dailyResponses: dailyResponses,
                selectedDate: selectedDate,
                onSave: onSaveEntry,
                onDelete: onDeleteEntry,
              ),
            ),
        ],
      ),
    );
  }
}
