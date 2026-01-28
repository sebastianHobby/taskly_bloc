import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_today_page.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/add_log_sheet.dart';
import 'package:taskly_bloc/presentation/shared/app_bar/taskly_app_bar_actions.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalHubPage extends StatefulWidget {
  const JournalHubPage({
    super.key,
    @Deprecated(
      'Tabs were removed from Journal. Use dedicated routes like '
      '`journal_history` and `journal_manage_trackers` instead.',
    )
    this.initialTabIndex = 0,
  });

  @Deprecated(
    'Tabs were removed from Journal. Use dedicated routes like '
    '`journal_history` and `journal_manage_trackers` instead.',
  )
  final int initialTabIndex;

  @override
  State<JournalHubPage> createState() => _JournalHubPageState();
}

class _JournalHubPageState extends State<JournalHubPage> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = context.read<NowService>().nowLocal();
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(
        _selectedDay.year,
        _selectedDay.month,
        _selectedDay.day,
      ),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;
    if (!mounted) return;

    setState(() {
      _selectedDay = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE d MMM').format(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _pickDay,
          borderRadius: BorderRadius.circular(
            TasklyTokens.of(context).radiusMd,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: TasklyTokens.of(context).spaceLg,
            ),
            child: Text(dateLabel),
          ),
        ),
        actions: TasklyAppBarActions.withAttentionBell(
          context,
          actions: [
            IconButton(
              tooltip: 'History',
              onPressed: () => Routing.pushScreenKey(
                context,
                'journal_history',
              ),
              icon: const Icon(Icons.search),
            ),
            IconButton(
              tooltip: 'Manage trackers',
              onPressed: () => Routing.pushScreenKey(
                context,
                'journal_manage_trackers',
              ),
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
      ),
      body: JournalTodayPage(day: _selectedDay),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddLogSheet.show(
          context: context,
          selectedDayLocal: _selectedDay,
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add entry'),
      ),
    );
  }
}
