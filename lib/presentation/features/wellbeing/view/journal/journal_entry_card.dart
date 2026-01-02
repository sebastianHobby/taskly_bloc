import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/domain/models/wellbeing/daily_tracker_response.dart';
import 'package:taskly_bloc/domain/models/wellbeing/journal_entry.dart';
import 'package:taskly_bloc/domain/models/wellbeing/mood_rating.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker_response.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/journal/tracker_field_card.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/widgets/daily_tracker_section.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_mood_field.dart';

/// Card widget displaying a journal entry with expandable edit mode.
class JournalEntryCard extends StatefulWidget {
  const JournalEntryCard({
    required this.entry,
    required this.perEntryTrackers,
    required this.dailyTrackers,
    required this.dailyResponses,
    required this.selectedDate,
    required this.onSave,
    required this.onDelete,
    super.key,
  });

  final JournalEntry entry;
  final List<Tracker> perEntryTrackers;
  final List<Tracker> dailyTrackers;
  final List<DailyTrackerResponse> dailyResponses;
  final DateTime selectedDate;
  final void Function(JournalEntry, List<DailyTrackerResponse>) onSave;
  final void Function(String) onDelete;

  @override
  State<JournalEntryCard> createState() => _JournalEntryCardState();
}

class _JournalEntryCardState extends State<JournalEntryCard> {
  bool _isExpanded = false;
  final _formKey = GlobalKey<FormBuilderState>();
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.entry.journalText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    return DateFormat.jm().format(time);
  }

  Map<String, DailyTrackerResponse> get _dailyResponsesMap {
    return {for (final r in widget.dailyResponses) r.trackerId: r};
  }

  void _handleSave() {
    final formState = _formKey.currentState;
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
    final existingResponses = {
      for (final r in widget.entry.perEntryTrackerResponses) r.trackerId: r,
    };

    // Build per-entry tracker responses
    final perEntryResponses = <TrackerResponse>[];
    for (final tracker in widget.perEntryTrackers) {
      final value = values['tracker_${tracker.id}'] as TrackerResponseValue?;
      if (value == null) continue;

      final existing = existingResponses[tracker.id];
      perEntryResponses.add(
        TrackerResponse(
          id: existing?.id ?? '${widget.entry.id}_${tracker.id}',
          journalEntryId: widget.entry.id,
          trackerId: tracker.id,
          value: value,
          createdAt: existing?.createdAt ?? now,
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

      final existing = _dailyResponsesMap[tracker.id];
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
    final entry = widget.entry.copyWith(
      moodRating: mood,
      journalText: text.isEmpty ? null : text,
      perEntryTrackerResponses: perEntryResponses,
      updatedAt: now,
    );

    widget.onSave(entry, dailyResponses);
    setState(() => _isExpanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mood = widget.entry.moodRating;

    return Card(
      elevation: _isExpanded ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: _isExpanded
            ? _buildExpandedView(theme)
            : _buildCollapsedView(theme, mood),
      ),
    );
  }

  Widget _buildCollapsedView(ThemeData theme, MoodRating? mood) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = true),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Time badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatTime(widget.entry.entryTime),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Mood emoji
            if (mood != null)
              Text(
                mood.emoji,
                style: const TextStyle(fontSize: 28),
              ),
            const SizedBox(width: 12),

            // Journal text preview
            Expanded(
              child: Text(
                widget.entry.journalText ?? 'No notes',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: widget.entry.journalText == null
                      ? theme.textTheme.bodySmall?.color
                      : null,
                  fontStyle: widget.entry.journalText == null
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Tracker count badge
            if (widget.entry.perEntryTrackerResponses.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.entry.perEntryTrackerResponses.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],

            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: theme.iconTheme.color?.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedView(ThemeData theme) {
    final existingPerEntryResponses = {
      for (final r in widget.entry.perEntryTrackerResponses) r.trackerId: r,
    };

    return FormBuilder(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatTime(widget.entry.entryTime),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Edit Entry',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => widget.onDelete(widget.entry.id),
                  color: theme.colorScheme.error,
                  tooltip: 'Delete entry',
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _isExpanded = false),
                  tooltip: 'Collapse',
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
              initialValue: widget.entry.moodRating,
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
                formKey: _formKey,
                trackers: widget.dailyTrackers,
                existingResponses: widget.dailyResponses,
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
                  child: TrackerFieldCard(
                    tracker: tracker,
                    initialValue: existingPerEntryResponses[tracker.id]?.value,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isExpanded = false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _handleSave,
                    icon: const Icon(Icons.check),
                    label: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
