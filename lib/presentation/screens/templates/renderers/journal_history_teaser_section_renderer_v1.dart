import 'package:flutter/material.dart';

final class JournalHistoryTeaserSectionRendererV1 extends StatelessWidget {
  const JournalHistoryTeaserSectionRendererV1({
    required this.onOpenHistory,
    super.key,
  });

  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.history),
        title: const Text('History'),
        subtitle: const Text('See past logs and patterns.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onOpenHistory,
      ),
    );
  }
}
