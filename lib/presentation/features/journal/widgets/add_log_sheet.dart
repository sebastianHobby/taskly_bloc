import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/domain/interfaces/journal_repository_contract.dart';
import 'package:taskly_bloc/domain/journal/model/journal_entry.dart';
import 'package:taskly_bloc/domain/journal/model/mood_rating.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_definition.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_event.dart';
import 'package:taskly_bloc/domain/journal/model/tracker_preference.dart';
import 'package:taskly_bloc/domain/time/date_only.dart';

class AddLogSheet extends StatefulWidget {
  const AddLogSheet._({required this.preselectedTrackerIds});

  static Future<void> show({
    required BuildContext context,
    Set<String> preselectedTrackerIds = const <String>{},
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: AddLogSheet._(
          preselectedTrackerIds: preselectedTrackerIds,
        ),
      ),
    );
  }

  final Set<String> preselectedTrackerIds;

  @override
  State<AddLogSheet> createState() => _AddLogSheetState();
}

class _AddLogSheetState extends State<AddLogSheet> {
  MoodRating? _mood;
  final TextEditingController _noteController = TextEditingController();
  final Set<String> _selectedTrackerIds = <String>{};

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedTrackerIds.addAll(widget.preselectedTrackerIds);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = getIt<JournalRepositoryContract>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Add Log',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<MoodRating>(
            value: _mood,
            decoration: const InputDecoration(
              labelText: 'Mood',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final rating in MoodRating.values)
                DropdownMenuItem(value: rating, child: Text(rating.label)),
            ],
            onChanged: _isSaving
                ? null
                : (value) => setState(() => _mood = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
            enabled: !_isSaving,
          ),
          const SizedBox(height: 16),
          Text(
            'Quick add',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<TrackerDefinition>>(
            stream: repo.watchTrackerDefinitions(),
            builder: (context, defsSnapshot) {
              final defs = defsSnapshot.data ?? const <TrackerDefinition>[];
              return StreamBuilder<List<TrackerPreference>>(
                stream: repo.watchTrackerPreferences(),
                builder: (context, prefsSnapshot) {
                  final prefs =
                      prefsSnapshot.data ?? const <TrackerPreference>[];
                  final prefByTrackerId = {
                    for (final p in prefs) p.trackerId: p,
                  };

                  final quickAdd =
                      defs
                          .where((d) => d.isActive && d.deletedAt == null)
                          .where(
                            (d) =>
                                (prefByTrackerId[d.id]?.showInQuickAdd ??
                                    false) ||
                                (prefByTrackerId[d.id]?.pinned ?? false),
                          )
                          .toList(growable: false)
                        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

                  if (quickAdd.isEmpty) {
                    return Text(
                      'No quick-add trackers yet. Enable some in Trackers.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  }

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tracker in quickAdd)
                        FilterChip(
                          label: Text(tracker.name),
                          selected: _selectedTrackerIds.contains(tracker.id),
                          onSelected: _isSaving
                              ? null
                              : (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedTrackerIds.add(tracker.id);
                                    } else {
                                      _selectedTrackerIds.remove(tracker.id);
                                    }
                                  });
                                },
                        ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : () => _save(context),
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Save'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final mood = _mood;
    if (mood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a mood.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = getIt<JournalRepositoryContract>();
      final nowUtc = DateTime.now().toUtc();
      final dayUtc = dateOnly(nowUtc);

      final entry = JournalEntry(
        id: '',
        entryDate: dayUtc,
        entryTime: nowUtc,
        occurredAt: nowUtc,
        localDate: dayUtc,
        createdAt: nowUtc,
        updatedAt: nowUtc,
        journalText: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        deletedAt: null,
      );

      final entryId = await repo.upsertJournalEntry(entry);

      // Mood (required)
      final trackerDefs = await repo.watchTrackerDefinitions().first;
      final moodTracker = trackerDefs.firstWhere(
        (t) => t.systemKey == 'mood',
        orElse: () => throw StateError('Missing system mood tracker'),
      );

      await repo.appendTrackerEvent(
        TrackerEvent(
          id: '',
          trackerId: moodTracker.id,
          anchorType: 'entry',
          entryId: entryId,
          op: 'set',
          value: mood.value,
          occurredAt: nowUtc,
          recordedAt: nowUtc,
        ),
      );

      // Selected quick-add trackers (best-effort boolean set=true)
      for (final trackerId in _selectedTrackerIds) {
        if (trackerId == moodTracker.id) continue;
        await repo.appendTrackerEvent(
          TrackerEvent(
            id: '',
            trackerId: trackerId,
            anchorType: 'entry',
            entryId: entryId,
            op: 'set',
            value: true,
            occurredAt: nowUtc,
            recordedAt: nowUtc,
          ),
        );
      }

      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save log: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
