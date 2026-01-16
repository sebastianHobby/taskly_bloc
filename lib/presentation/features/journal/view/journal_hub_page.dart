import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_history_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_today_page.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_trackers_page.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/add_log_sheet.dart';
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
            Tab(text: 'Today'),
            Tab(text: 'History'),
            Tab(text: 'Trackers'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddLogSheet.show(context: context),
        icon: const Icon(Icons.add),
        label: const Text('Add Log'),
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
