import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_trackers_page.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';

class TrackersPage extends StatelessWidget {
  const TrackersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trackers'),
        actions: TasklyAppBarActions.withAttentionBell(
          context,
          actions: const <Widget>[],
        ),
      ),
      body: const JournalTrackersPage(),
    );
  }
}
