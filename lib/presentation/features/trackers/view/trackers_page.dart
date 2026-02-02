import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_trackers_page.dart';

class TrackersPage extends StatelessWidget {
  const TrackersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trackers'),
      ),
      body: const JournalTrackersPage(),
    );
  }
}
