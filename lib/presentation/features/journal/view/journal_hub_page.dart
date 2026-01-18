import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_history_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_today_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_trackers_page.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';

class JournalHubPage extends StatefulWidget {
  const JournalHubPage({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<JournalHubPage> createState() => _JournalHubPageState();
}

class _JournalHubPageState extends State<JournalHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final safeInitialIndex = widget.initialTabIndex.clamp(0, 2);
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: safeInitialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        actions: TasklyAppBarActions.withAttentionBell(
          context,
          actions: const <Widget>[],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.today_outlined), text: 'Today'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Entries'),
            Tab(icon: Icon(Icons.tune), text: 'Trackers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          JournalTodayPage(),
          JournalHistoryPage(),
          JournalTrackersPage(),
        ],
      ),
    );
  }
}
