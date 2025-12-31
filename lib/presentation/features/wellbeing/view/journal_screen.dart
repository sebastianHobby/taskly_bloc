import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/models/wellbeing/daily_tracker_response.dart';
import 'package:taskly_bloc/domain/models/wellbeing/journal_entry.dart';
import 'package:taskly_bloc/domain/models/wellbeing/tracker.dart';
import 'package:taskly_bloc/domain/interfaces/wellbeing_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/journal_entry/journal_entry_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/journal/journal_timeline_view.dart';

/// Main journal screen supporting multiple entries per day.
///
/// Features:
/// - Timeline view showing all entries for selected date (newest first)
/// - Daily trackers (allDay scope) shown at top, persist across entries
/// - Per-entry trackers specific to each journal entry
/// - Mood is required for each entry
/// - FAB to create new entries
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  DateTime _selectedDate = dateOnly(DateTime.now());
  late final Stream<List<Tracker>> _trackersStream;

  // Form key for the "new entry" form
  final _newEntryFormKey = GlobalKey<FormBuilderState>();
  bool _isCreatingNew = false;

  @override
  void initState() {
    super.initState();
    _trackersStream = getIt<WellbeingRepositoryContract>().watchTrackers();
    unawaited(_loadForDate(_selectedDate));
  }

  Future<void> _loadForDate(DateTime date) async {
    context.read<JournalEntryBloc>().add(
      JournalEntryEvent.loadEntriesForDate(date: date),
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
      _isCreatingNew = false;
    });
    await _loadForDate(normalized);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = dateOnly(now);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return DateFormat.yMMMd().format(date);
  }

  void _startNewEntry() {
    setState(() => _isCreatingNew = true);
  }

  void _cancelNewEntry() {
    setState(() => _isCreatingNew = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Journal � ${_formatDate(_selectedDate)}'),
        actions: [
          IconButton(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Select date',
          ),
        ],
      ),
      body: StreamBuilder<List<Tracker>>(
        stream: _trackersStream,
        builder: (context, trackerSnap) {
          final allTrackers = trackerSnap.data ?? const <Tracker>[];
          final dailyTrackers = allTrackers
              .where((t) => t.entryScope == TrackerEntryScope.allDay)
              .toList();
          final perEntryTrackers = allTrackers
              .where((t) => t.entryScope == TrackerEntryScope.perEntry)
              .toList();

          return BlocConsumer<JournalEntryBloc, JournalEntryState>(
            listener: (context, state) {
              state.whenOrNull(
                saved: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Saved successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  setState(() => _isCreatingNew = false);
                  unawaited(_loadForDate(_selectedDate));
                },
                error: (message) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $message'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            },
            builder: (context, state) {
              return state.maybeWhen(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                entriesLoaded: (entries, dailyResponses, date) {
                  return JournalTimelineView(
                    selectedDate: _selectedDate,
                    entries: entries,
                    dailyResponses: dailyResponses,
                    dailyTrackers: dailyTrackers,
                    perEntryTrackers: perEntryTrackers,
                    isCreatingNew: _isCreatingNew,
                    newEntryFormKey: _newEntryFormKey,
                    onCancelNew: _cancelNewEntry,
                    onSaveEntry: _saveEntry,
                    onDeleteEntry: _deleteEntry,
                  );
                },
                orElse: () => JournalTimelineView(
                  selectedDate: _selectedDate,
                  entries: const [],
                  dailyResponses: const [],
                  dailyTrackers: dailyTrackers,
                  perEntryTrackers: perEntryTrackers,
                  isCreatingNew: _isCreatingNew,
                  newEntryFormKey: _newEntryFormKey,
                  onCancelNew: _cancelNewEntry,
                  onSaveEntry: _saveEntry,
                  onDeleteEntry: _deleteEntry,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _isCreatingNew
          ? null
          : FloatingActionButton.extended(
              onPressed: _startNewEntry,
              icon: const Icon(Icons.add),
              label: const Text('New Entry'),
            ),
    );
  }

  void _saveEntry(
    JournalEntry entry,
    List<DailyTrackerResponse> dailyResponses,
  ) {
    context.read<JournalEntryBloc>().add(
      JournalEntryEvent.saveWithDailyResponses(
        entry: entry,
        dailyResponses: dailyResponses,
      ),
    );
  }

  void _deleteEntry(String entryId) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              this.context.read<JournalEntryBloc>().add(
                JournalEntryEvent.delete(entryId),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
