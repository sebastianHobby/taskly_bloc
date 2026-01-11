import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/domain/wellbeing/model/daily_tracker_response.dart';
import 'package:taskly_bloc/domain/wellbeing/model/journal_entry.dart';
import 'package:taskly_bloc/domain/wellbeing/model/mood_rating.dart';
import 'package:taskly_bloc/domain/wellbeing/model/tracker.dart';
import 'package:taskly_bloc/domain/wellbeing/model/tracker_response.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/journal/tracker_field_card.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/widgets/daily_tracker_section.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_mood_field.dart';

/// Form widget for creating a new journal entry.
class JournalNewEntryForm extends StatefulWidget {
  const JournalNewEntryForm({
    required this.formKey,
    required this.selectedDate,
    required this.dailyTrackers,
    required this.perEntryTrackers,
    required this.existingDailyResponses,
    required this.onCancel,
    required this.onSave,
    super.key,
  });

  final GlobalKey<FormBuilderState> formKey;
  final DateTime selectedDate;
  final List<Tracker> dailyTrackers;
  final List<Tracker> perEntryTrackers;
  final List<DailyTrackerResponse> existingDailyResponses;
  final VoidCallback onCancel;
  final void Function(JournalEntry, List<DailyTrackerResponse>) onSave;

  @override
  State<JournalNewEntryForm> createState() => _JournalNewEntryFormState();
}

class _JournalNewEntryFormState extends State<JournalNewEntryForm> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Map<String, DailyTrackerResponse> get _existingDailyResponsesMap {
    return {for (final r in widget.existingDailyResponses) r.trackerId: r};
  }

  void _handleSave() {
    final formState = widget.formKey.currentState;
    if (formState == null) return;

    if (!formState.saveAndValidate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your mood to continue'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final values = formState.value;
    final mood = values['mood'] as MoodRating?;

    if (mood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mood is required'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final now = DateTime.now();

    // Build per-entry tracker responses (will be assigned IDs in repository)
    final perEntryResponses = <TrackerResponse>[];
    for (final tracker in widget.perEntryTrackers) {
      final value = values['tracker_${tracker.id}'] as TrackerResponseValue?;
      if (value == null) continue;

      perEntryResponses.add(
        TrackerResponse(
          id: '', // Let repository generate v5 ID
          journalEntryId:
              '', // Will be set in repository after entry ID generated
          trackerId: tracker.id,
          value: value,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    // Build daily tracker responses
    final dailyResponses = <DailyTrackerResponse>[];
    for (final tracker in widget.dailyTrackers) {
      final value =
          values['daily_tracker_${tracker.id}'] as TrackerResponseValue?;
      if (value == null) continue;

      final existing = _existingDailyResponsesMap[tracker.id];
      dailyResponses.add(
        DailyTrackerResponse(
          id: existing?.id ?? '', // Let repository generate v5 ID
          responseDate: widget.selectedDate,
          trackerId: tracker.id,
          value: value,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      );
    }

    final text = _textController.text.trim();
    final entry = JournalEntry(
      id: '', // Let repository generate v4 ID
      entryDate: widget.selectedDate,
      entryTime: now,
      moodRating: mood,
      journalText: text.isEmpty ? null : text,
      perEntryTrackerResponses: perEntryResponses,
      createdAt: now,
      updatedAt: now,
    );

    widget.onSave(entry, dailyResponses);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      child: FormBuilder(
        key: widget.formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.add_circle,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'New Entry',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onCancel,
                    tooltip: 'Cancel',
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Mood selector (required)
              Text(
                'How are you feeling? *',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              FormBuilderMoodField(
                name: 'mood',
                validator: (value) {
                  if (value == null) return 'Please select your mood';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Journal text
              Text(
                'Notes (optional)',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              FormBuilderTextField(
                name: 'journalText',
                controller: _textController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Write your thoughts…',
                  border: OutlineInputBorder(),
                ),
              ),

              // Daily trackers section
              if (widget.dailyTrackers.isNotEmpty) ...[
                const SizedBox(height: 20),
                DailyTrackerSection(
                  formKey: widget.formKey,
                  trackers: widget.dailyTrackers,
                  existingResponses: widget.existingDailyResponses,
                  selectedDate: widget.selectedDate,
                ),
              ],

              // Per-entry trackers
              if (widget.perEntryTrackers.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Per-Entry Trackers (optional)',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                ...widget.perEntryTrackers.map(
                  (tracker) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TrackerFieldCard(tracker: tracker),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _handleSave,
                      icon: const Icon(Icons.check),
                      label: const Text('Create Entry'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
