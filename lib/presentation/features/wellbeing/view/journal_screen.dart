import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/models/wellbeing/journal_entry.dart';
import 'package:taskly_bloc/domain/models/wellbeing/mood_rating.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker_response.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker_response_config.dart';
import 'package:taskly_bloc/domain/repositories/wellbeing_repository.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/journal_entry/journal_entry_bloc.dart';
import 'package:taskly_bloc/presentation/widgets/form_fields/form_builder_tracker_response_fields.dart';
import 'package:uuid/uuid.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _textController = TextEditingController();

  DateTime _selectedDate = dateOnly(DateTime.now());
  MoodRating? _selectedMood;
  JournalEntry? _loadedEntry;

  late final Stream<List<Tracker>> _trackersStream;

  @override
  void initState() {
    super.initState();
    _trackersStream = getIt<WellbeingRepository>().watchTrackers();
    unawaited(_loadForDate(_selectedDate));
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadForDate(DateTime date) async {
    context.read<JournalEntryBloc>().add(
      JournalEntryEvent.loadByDate(date: date),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    final normalized = dateOnly(picked);
    setState(() {
      _selectedDate = normalized;
      _loadedEntry = null;
      _selectedMood = null;
      _textController.text = '';
      _formKey.currentState?.reset();
    });
    await _loadForDate(normalized);
  }

  void _applyLoadedEntry(JournalEntry? entry) {
    _loadedEntry = entry;
    _selectedMood = entry?.moodRating;
    _textController.text = entry?.journalText ?? '';

    final responsesByTrackerId = {
      for (final r in entry?.trackerResponses ?? <TrackerResponse>[])
        r.trackerId: r,
    };

    final fields = _formKey.currentState?.fields;
    if (fields == null) return;
    for (final field in fields.entries) {
      final name = field.key;
      if (!name.startsWith('tracker_')) continue;
      final trackerId = name.substring('tracker_'.length);
      final response = responsesByTrackerId[trackerId];
      field.value.didChange(response?.value);
    }
  }

  Future<void> _save(List<Tracker> trackers) async {
    final formState = _formKey.currentState;
    if (formState == null) return;
    formState.save();

    final now = DateTime.now();
    final entryId = (_loadedEntry?.id ?? '').isNotEmpty
        ? _loadedEntry!.id
        : const Uuid().v4();

    final existingResponsesByTrackerId = {
      for (final r in _loadedEntry?.trackerResponses ?? <TrackerResponse>[])
        r.trackerId: r,
    };

    final trackerResponses = <TrackerResponse>[];
    for (final tracker in trackers) {
      final value =
          formState.value['tracker_${tracker.id}'] as TrackerResponseValue?;
      if (value == null) continue;

      final existing = existingResponsesByTrackerId[tracker.id];
      trackerResponses.add(
        TrackerResponse(
          id: '${entryId}_${tracker.id}',
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
      id: entryId,
      entryDate: _selectedDate,
      entryTime: now,
      moodRating: _selectedMood,
      journalText: text.isEmpty ? null : text,
      trackerResponses: trackerResponses,
      createdAt: _loadedEntry?.createdAt ?? now,
      updatedAt: now,
    );

    context.read<JournalEntryBloc>().add(JournalEntryEvent.save(entry));
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Journal • ${_formatDate(_selectedDate)}'),
        actions: [
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
          ),
        ],
      ),
      body: StreamBuilder<List<Tracker>>(
        stream: _trackersStream,
        builder: (context, trackerSnap) {
          final trackers = trackerSnap.data ?? const <Tracker>[];

          return BlocConsumer<JournalEntryBloc, JournalEntryState>(
            listener: (context, state) {
              state.whenOrNull(
                loaded: (entry) {
                  setState(() {
                    _applyLoadedEntry(entry);
                  });
                },
                saved: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved')),
                  );
                  unawaited(_loadForDate(_selectedDate));
                },
                error: (message) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $message')),
                  );
                },
              );
            },
            builder: (context, state) {
              final isLoading = state.maybeWhen(
                loading: () => true,
                orElse: () => false,
              );

              return Stack(
                children: [
                  FormBuilder(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'How are you feeling?',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        _MoodSelector(
                          selected: _selectedMood,
                          onSelected: (m) => setState(() => _selectedMood = m),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Journal Entry',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _textController,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            hintText: 'Write your thoughts…',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (trackers.isNotEmpty) ...[
                          Text(
                            'Trackers',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          ...trackers.map(
                            (tracker) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tracker.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      if (tracker.description != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          tracker.description!,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      _buildTrackerField(tracker),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () => _save(trackers),
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLoading)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black12,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTrackerField(Tracker tracker) {
    final name = 'tracker_${tracker.id}';
    return switch (tracker.responseType) {
      TrackerResponseType.yesNo => FormBuilderTrackerYesNoField(name: name),
      TrackerResponseType.scale => switch (tracker.config) {
        ScaleConfig(:final min, :final max, :final minLabel, :final maxLabel) =>
          FormBuilderTrackerScaleField(
            name: name,
            min: min,
            max: max,
            minLabel: minLabel,
            maxLabel: maxLabel,
          ),
        _ => const SizedBox.shrink(),
      },
      TrackerResponseType.choice => switch (tracker.config) {
        ChoiceConfig(:final options) => FormBuilderTrackerChoiceField(
          name: name,
          options: options,
        ),
        _ => const SizedBox.shrink(),
      },
    };
  }
}

class _MoodSelector extends StatelessWidget {
  const _MoodSelector({
    required this.selected,
    required this.onSelected,
  });

  final MoodRating? selected;
  final ValueChanged<MoodRating?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MoodRating.values.map((rating) {
        final isSelected = selected == rating;
        return ChoiceChip(
          label: Text('${rating.emoji} ${rating.label}'),
          selected: isSelected,
          onSelected: (_) => onSelected(rating),
        );
      }).toList(),
    );
  }
}
