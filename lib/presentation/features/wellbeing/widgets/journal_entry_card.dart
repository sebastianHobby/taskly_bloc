import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/domain/wellbeing/model/journal_entry.dart';
import 'package:taskly_bloc/domain/wellbeing/model/mood_rating.dart';
import 'package:taskly_bloc/domain/wellbeing/model/tracker.dart';
import 'package:taskly_bloc/domain/wellbeing/model/tracker_response.dart';
import 'package:taskly_bloc/domain/wellbeing/model/tracker_response_config.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_mood_field.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_tracker_response_fields.dart';

/// Card widget for displaying and editing a single journal entry.
///
/// Supports viewing mode (collapsed) and editing mode (expanded with form).
/// Handles per-entry trackers only - daily trackers are managed separately.
class JournalEntryCard extends StatefulWidget {
  const JournalEntryCard({
    required this.entry,
    required this.perEntryTrackers,
    required this.onSave,
    required this.onDelete,
    this.isExpanded = false,
    this.isNew = false,
    super.key,
  });

  final JournalEntry? entry;
  final List<Tracker> perEntryTrackers;
  final void Function(JournalEntry entry) onSave;
  final void Function(String entryId) onDelete;
  final bool isExpanded;
  final bool isNew;

  @override
  State<JournalEntryCard> createState() => _JournalEntryCardState();
}

class _JournalEntryCardState extends State<JournalEntryCard> {
  final _formKey = GlobalKey<FormBuilderState>();
  late bool _isExpanded;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded || widget.isNew;
    _textController = TextEditingController(text: widget.entry?.journalText);
  }

  @override
  void didUpdateWidget(JournalEntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry?.id != widget.entry?.id) {
      _textController.text = widget.entry?.journalText ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime time) {
    return DateFormat.jm().format(time);
  }

  Map<String, TrackerResponseValue> _getExistingResponses() {
    final responses =
        widget.entry?.perEntryTrackerResponses ?? <TrackerResponse>[];
    return {
      for (final r in responses) r.trackerId: r.value,
    };
  }

  void _handleSave() {
    final formState = _formKey.currentState;
    if (formState == null) return;

    // Validate form
    if (!formState.saveAndValidate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your mood to continue'),
          backgroundColor: Colors.orange,
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
        ),
      );
      return;
    }

    final now = DateTime.now();
    final responses =
        widget.entry?.perEntryTrackerResponses ?? <TrackerResponse>[];
    final existingResponses = <String, TrackerResponse>{
      for (final r in responses) r.trackerId: r,
    };

    // Build per-entry tracker responses
    final trackerResponses = <TrackerResponse>[];
    for (final tracker in widget.perEntryTrackers) {
      final value = values['tracker_${tracker.id}'] as TrackerResponseValue?;
      if (value == null) continue;

      final existing = existingResponses[tracker.id];
      final entryId = widget.entry?.id ?? '';
      trackerResponses.add(
        TrackerResponse(
          id: existing?.id ?? '${entryId}_${tracker.id}',
          journalEntryId: entryId,
          trackerId: tracker.id,
          value: value,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      );
    }

    final text = _textController.text.trim();
    final entry = JournalEntry(
      id: widget.entry?.id ?? '',
      entryDate: widget.entry?.entryDate ?? now,
      entryTime: widget.entry?.entryTime ?? now,
      moodRating: mood,
      journalText: text.isEmpty ? null : text,
      perEntryTrackerResponses: trackerResponses,
      createdAt: widget.entry?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(entry);

    if (!widget.isNew) {
      setState(() => _isExpanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;

    return Card(
      elevation: _isExpanded ? 4 : 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        child: _isExpanded
            ? _buildExpandedView(theme)
            : _buildCollapsedView(theme, entry),
      ),
    );
  }

  Widget _buildCollapsedView(ThemeData theme, JournalEntry? entry) {
    if (entry == null) return const SizedBox.shrink();

    final mood = entry.moodRating;

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
                _formatTime(entry.entryTime),
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
                entry.journalText ?? 'No notes',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: entry.journalText == null
                      ? theme.textTheme.bodySmall?.color
                      : null,
                  fontStyle: entry.journalText == null
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Tracker count badge
            if (entry.perEntryTrackerResponses.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${entry.perEntryTrackerResponses.length}',
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
    final existingResponses = _getExistingResponses();

    return FormBuilder(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with time and collapse button
            Row(
              children: [
                if (!widget.isNew) ...[
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
                      _formatTime(
                        widget.entry?.entryTime ?? DateTime.now(),
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.isNew ? 'New Entry' : 'Edit Entry',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!widget.isNew)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      if (widget.entry != null) {
                        widget.onDelete(widget.entry!.id);
                      }
                    },
                    color: theme.colorScheme.error,
                    tooltip: 'Delete entry',
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    if (widget.isNew) {
                      // For new entries, closing should not be allowed
                      // User must save or navigate away
                    } else {
                      setState(() => _isExpanded = false);
                    }
                  },
                  tooltip: 'Collapse',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mood selector (required)
            Text(
              'How are you feeling? *',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            FormBuilderMoodField(
              name: 'mood',
              initialValue: widget.entry?.moodRating,
              validator: (value) {
                if (value == null) {
                  return 'Please select your mood';
                }
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
                  child: _TrackerField(
                    tracker: tracker,
                    initialValue: existingResponses[tracker.id],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _handleSave,
                icon: const Icon(Icons.check),
                label: Text(widget.isNew ? 'Create Entry' : 'Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackerField extends StatelessWidget {
  const _TrackerField({
    required this.tracker,
    this.initialValue,
  });

  final Tracker tracker;
  final TrackerResponseValue? initialValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = 'tracker_${tracker.id}';

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
