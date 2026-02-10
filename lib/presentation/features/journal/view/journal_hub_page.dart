import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/view/journal_today_page.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/add_log_sheet.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_icon_resolver.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/widgets/entity_add_controls.dart';
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
        actions: [
          IconButton(
            tooltip: context.l10n.journalHistoryTooltip,
            onPressed: () => Routing.pushScreenKey(
              context,
              'journal_history',
            ),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: context.l10n.journalManageTrackersTitle,
            onPressed: () => Routing.pushScreenKey(
              context,
              'journal_manage_trackers',
            ),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: Column(
        children: [
          _JournalTitleHeader(
            dateLabel: dateLabel,
            onTap: _pickDay,
          ),
          Expanded(
            child: JournalTodayPage(day: _selectedDay),
          ),
        ],
      ),
      floatingActionButton: EntityAddFab(
        tooltip: context.l10n.journalAddEntry,
        heroTag: 'journal_add_entry_fab',
        onPressed: () => AddLogSheet.show(
          context: context,
          selectedDayLocal: _selectedDay,
        ),
      ),
    );
  }
}

class _JournalTitleHeader extends StatelessWidget {
  const _JournalTitleHeader({
    required this.dateLabel,
    required this.onTap,
  });

  final String dateLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconSet = const NavigationIconResolver().resolve(
      screenId: 'journal',
      iconName: null,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.sectionPaddingH,
        tokens.spaceMd,
        tokens.sectionPaddingH,
        tokens.spaceSm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusSm),
        child: Row(
          children: [
            Icon(
              iconSet.selectedIcon,
              color: scheme.primary,
              size: tokens.spaceLg3,
            ),
            SizedBox(width: tokens.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Journal',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    dateLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
