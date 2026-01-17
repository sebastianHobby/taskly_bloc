import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_history_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_today_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_trackers_page.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/features/attention/widgets/attention_bell_icon_button.dart';

class JournalHubPage extends StatefulWidget {
  const JournalHubPage({super.key});

  @override
  State<JournalHubPage> createState() => _JournalHubPageState();
}

class _JournalHubPageState extends State<JournalHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        actions: [
          AttentionBellIconButton(
            onPressed: () => Routing.toScreenKey(context, 'review_inbox'),
          ),
        ],
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
