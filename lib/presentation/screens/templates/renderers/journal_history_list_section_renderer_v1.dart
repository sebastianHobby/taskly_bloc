import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_domain/domain/journal/model/journal_entry.dart';
import 'package:taskly_domain/domain/time/date_only.dart';

final class JournalHistoryListSectionRendererV1 extends StatelessWidget {
  const JournalHistoryListSectionRendererV1({
    required this.entries,
    required this.onEntryTap,
    super.key,
  });

  final List<JournalEntry> entries;
  final ValueChanged<JournalEntry> onEntryTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Text('No recent logs.');
    }

    final grouped = <DateTime, List<JournalEntry>>{};
    for (final entry in entries) {
      final day = dateOnly(entry.entryDate.toUtc());
      (grouped[day] ??= <JournalEntry>[]).add(entry);
    }

    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final day in days) ...[
          Text(
            DateFormat.yMMMEd().format(day.toLocal()),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final entry in grouped[day] ?? const <JournalEntry>[]) ...[
            Card(
              child: ListTile(
                title: Text(DateFormat.jm().format(entry.occurredAt.toLocal())),
                subtitle: switch (entry.journalText?.trim()) {
                  final t? when t.isNotEmpty => Text(t),
                  _ => null,
                },
                onTap: () => onEntryTap(entry),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
