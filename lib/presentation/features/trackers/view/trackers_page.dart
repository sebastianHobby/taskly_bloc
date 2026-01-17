import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/attention/widgets/attention_bell_icon_button.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_trackers_page.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

class TrackersPage extends StatelessWidget {
  const TrackersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trackers'),
        actions: [
          AttentionBellIconButton(
            onPressed: () => Routing.toScreenKey(context, 'review_inbox'),
          ),
        ],
      ),
      body: const JournalTrackersPage(),
    );
  }
}
