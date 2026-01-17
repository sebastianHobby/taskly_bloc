import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_history_bloc.dart';

class JournalHistoryPage extends StatelessWidget {
  const JournalHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalHistoryBloc>(
      create: (_) => getIt<JournalHistoryBloc>(),
      child: BlocBuilder<JournalHistoryBloc, JournalHistoryState>(
        builder: (context, state) {
          return switch (state) {
            JournalHistoryLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            JournalHistoryError() => const Center(
              child: Text('Failed to load history.'),
            ),
            JournalHistoryLoaded(:final entries) => _HistoryList(entries),
          };
        },
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList(this.entries);

  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('No recent logs.'));
    }

    final grouped = <DateTime, List<JournalEntry>>{};
    for (final entry in entries) {
      final day = dateOnly(entry.entryDate.toUtc());
      (grouped[day] ??= <JournalEntry>[]).add(entry);
    }

    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final dayEntries = grouped[day] ?? const <JournalEntry>[];

        return _DaySection(day: day, entries: dayEntries);
      },
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({required this.day, required this.entries});

  final DateTime day;
  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat.yMMMEd().format(day.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final entry in entries) _HistoryRow(entry: entry),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(entry.occurredAt.toLocal()).format(
      context,
    );

    final note = entry.journalText?.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(time),
        subtitle: (note == null || note.isEmpty) ? null : Text(note),
      ),
    );
  }
}
