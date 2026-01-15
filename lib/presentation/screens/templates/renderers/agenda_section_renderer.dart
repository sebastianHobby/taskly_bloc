import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/presentation/entity_views/project_view.dart';
import 'package:taskly_bloc/presentation/entity_views/task_view.dart';
import 'package:taskly_bloc/presentation/theme/taskly_typography.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/screens/language/models/agenda_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params_v2.dart';

/// Renders the Scheduled agenda section as a day-cards feed.
///
/// Features:
/// - Range selection (presets + jump to week/month)
/// - Grouping (Today/Next 7/Later) with collapse policies
/// - Search + filter sheets
/// - Semantic labels (Today, Tomorrow)
class AgendaSectionRenderer extends StatefulWidget {
  const AgendaSectionRenderer({
    required this.params,
    required this.data,
    this.showTagPills = false,
    this.onTaskToggle,
    this.onTaskTap,
    super.key,
  });

  final AgendaSectionParamsV2 params;
  final AgendaSectionResult data;
  final bool showTagPills;
  final void Function(String taskId, bool? value)? onTaskToggle;
  final void Function(Task task)? onTaskTap;

  @override
  State<AgendaSectionRenderer> createState() => _AgendaSectionRendererState();
}

class _AgendaSectionRendererState extends State<AgendaSectionRenderer> {
  String _searchQuery = '';
  _AgendaEntityFilter _entityFilter = _AgendaEntityFilter.all;
  Set<AgendaDateTag> _tagFilter = {
    AgendaDateTag.starts,
    AgendaDateTag.due,
    AgendaDateTag.inProgress,
  };

  _DateRangePreset _rangePreset = _DateRangePreset.thisMonth;
  late DateTime _rangeStart;
  late DateTime _rangeEndExclusive;

  bool _thisWeekExpanded = true;
  bool _nextWeekExpanded = true;
  bool _laterExpanded = false;
  final Set<DateTime> _expandedInProgressDates = <DateTime>{};

  @override
  void initState() {
    super.initState();
    final today = _dateOnly(DateTime.now());
    _rangeStart = today;
    _rangeEndExclusive = DateTime(today.year, today.month + 1, 1);
  }

  @override
  void dispose() {
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Color _tagAccentColor(ThemeData theme, AgendaDateTag tag) {
    final scheme = theme.colorScheme;
    return switch (tag) {
      AgendaDateTag.due => scheme.error,
      AgendaDateTag.inProgress => scheme.tertiary,
      AgendaDateTag.starts => scheme.primary,
    };
  }

  DateTime _startOfWeekMonday(DateTime date) {
    final d = _dateOnly(date);
    return d.subtract(Duration(days: d.weekday - DateTime.monday));
  }

  String _formatWeekRangeLabel(BuildContext context, DateTime startInclusive) {
    final locale = Localizations.localeOf(context);
    final start = _dateOnly(startInclusive);
    final endInclusive = start.add(const Duration(days: 6));

    final startFmt = DateFormat.MMMd(locale.toLanguageTag()).format(start);
    if (start.year == endInclusive.year && start.month == endInclusive.month) {
      final endDay = DateFormat.d(locale.toLanguageTag()).format(endInclusive);
      return '$startFmt - $endDay';
    }

    final endFmt = DateFormat.MMMd(locale.toLanguageTag()).format(endInclusive);
    return '$startFmt - $endFmt';
  }

  @override
  Widget build(BuildContext context) {
    final buildStart = kDebugMode ? DateTime.now() : null;
    final agendaData = widget.data.agendaData;

    if (kDebugMode) {
      developer.log(
        '🎨 Scheduled UI: Building renderer - '
        'Groups: ${agendaData.groups.length}, Items: ${agendaData.totalItemCount}',
        name: 'perf.scheduled.ui',
      );
      talker.perf(
        'Scheduled UI: build start (groups=${agendaData.groups.length}, items=${agendaData.totalItemCount})',
        category: 'scheduled_ui',
      );
    }

    final allItemsCount = agendaData.totalItemCount;
    if (allItemsCount == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No scheduled items'),
        ),
      );
    }

    final layout = widget.params.layout;
    if (kDebugMode && layout == AgendaLayoutV2.timeline) {
      developer.log(
        'Scheduled UI: timeline layout requested; using day-cards feed (back-compat).',
        name: 'scheduled_ui',
      );
    }

    final result = switch (layout) {
      AgendaLayoutV2.dayCardsFeed => _buildDayCardsFeed(context, agendaData),
      AgendaLayoutV2.timeline => _buildDayCardsFeed(context, agendaData),
    };

    if (kDebugMode && buildStart != null) {
      final buildMs = DateTime.now().difference(buildStart).inMilliseconds;
      if (buildMs > 100) {
        final slowBuildMsg = '⚠️ Scheduled UI: Slow build - ${buildMs}ms';
        developer.log(
          slowBuildMsg,
          name: 'perf.scheduled.ui',
          level: 900,
        );
        talker.perf(slowBuildMsg, category: 'scheduled_ui');
      } else if (buildMs > 50) {
        talker.perf(
          'Scheduled UI: build ${buildMs}ms',
          category: 'scheduled_ui',
        );
      }
    }

    return result;
  }

  Widget _buildDayCardsFeed(BuildContext context, AgendaData agendaData) {
    final today = _dateOnly(DateTime.now());
    final selectedStart = _dateOnly(_rangeStart);
    final selectedEndExclusive = _dateOnly(_rangeEndExclusive);

    final loadedHorizonEnd = agendaData.loadedHorizonEnd;
    final effectiveEndExclusive = (loadedHorizonEnd == null)
        ? selectedEndExclusive
        : () {
            final horizonEndExclusive = _dateOnly(
              loadedHorizonEnd,
            ).add(const Duration(days: 1));
            return selectedEndExclusive.isAfter(horizonEndExclusive)
                ? horizonEndExclusive
                : selectedEndExclusive;
          }();

    final showHorizonNote = effectiveEndExclusive != selectedEndExclusive;
    final anchorDay = selectedStart.isAfter(today) ? selectedStart : today;

    final filteredGroups = <({DateTime date, List<AgendaItem> items})>[];
    for (final group in agendaData.groups) {
      final date = _dateOnly(group.date);
      if (date.isBefore(selectedStart)) continue;
      if (!date.isBefore(effectiveEndExclusive)) continue;

      final items = group.items.where(_matchesFilters).toList(growable: false);
      if (items.isEmpty) continue;

      filteredGroups.add((date: date, items: items));
    }

    final anchorEnd = anchorDay.add(const Duration(days: 1));
    final weekStart = _startOfWeekMonday(anchorDay);
    final thisWeekEndExclusive = weekStart.add(const Duration(days: 7));
    final nextWeekStart = thisWeekEndExclusive;
    final nextWeekEndExclusive = nextWeekStart.add(const Duration(days: 7));

    final anchorGroups = filteredGroups
        .where((g) => !g.date.isBefore(anchorDay) && g.date.isBefore(anchorEnd))
        .toList(growable: false);

    final thisWeekGroups = filteredGroups
        .where(
          (g) =>
              !g.date.isBefore(anchorEnd) &&
              g.date.isBefore(thisWeekEndExclusive),
        )
        .toList(growable: false);

    final nextWeekGroups = filteredGroups
        .where(
          (g) =>
              !g.date.isBefore(nextWeekStart) &&
              g.date.isBefore(nextWeekEndExclusive),
        )
        .toList(growable: false);

    final laterGroups = filteredGroups
        .where((g) => !g.date.isBefore(nextWeekEndExclusive))
        .toList(growable: false);

    final laterDateCount = laterGroups.length;
    final laterTooLong = laterDateCount > 7;
    final visibleLaterGroups = laterTooLong && !_laterExpanded
        ? laterGroups.take(3).toList()
        : laterGroups;

    final children = <Widget>[];

    if (showHorizonNote) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Text(
            'More dates not loaded yet.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final anchorLabel = _isSameDay(anchorDay, today)
        ? 'Today'
        : 'Starts ${DateFormat('EEE, MMM d').format(anchorDay)}';

    void addBlock(
      String label,
      List<({DateTime date, List<AgendaItem> items})> groups,
    ) {
      if (groups.isEmpty) return;
      children.add(_DayCardsBlockHeader(label: label));
      for (final g in groups) {
        children.add(
          _DayCard(
            date: g.date,
            items: g.items,
            inProgressExpanded: _expandedInProgressDates.contains(g.date),
            onToggleInProgress: () {
              setState(() {
                if (!_expandedInProgressDates.add(g.date)) {
                  _expandedInProgressDates.remove(g.date);
                }
              });
            },
            itemBuilder: (day, item) => _buildDayCardsItem(context, day, item),
            sortItems: _sortedAgendaItems,
          ),
        );
      }
    }

    void addWeekBlock({
      required String label,
      required String rangeLabel,
      required bool expanded,
      required VoidCallback onToggle,
      required List<({DateTime date, List<AgendaItem> items})> groups,
    }) {
      if (groups.isEmpty) return;

      children.add(
        _DayCardsSuperHeader(
          label: label,
          rangeLabel: rangeLabel,
          expanded: expanded,
          onToggle: onToggle,
        ),
      );

      if (!expanded) return;
      for (final g in groups) {
        children.add(
          _DayCard(
            date: g.date,
            items: g.items,
            inProgressExpanded: _expandedInProgressDates.contains(g.date),
            onToggleInProgress: () {
              setState(() {
                if (!_expandedInProgressDates.add(g.date)) {
                  _expandedInProgressDates.remove(g.date);
                }
              });
            },
            itemBuilder: (day, item) => _buildDayCardsItem(context, day, item),
            sortItems: _sortedAgendaItems,
          ),
        );
      }
    }

    addBlock(anchorLabel, anchorGroups);

    addWeekBlock(
      label: 'This week',
      rangeLabel: _formatWeekRangeLabel(context, weekStart),
      expanded: _thisWeekExpanded,
      onToggle: () => setState(() => _thisWeekExpanded = !_thisWeekExpanded),
      groups: thisWeekGroups,
    );

    addWeekBlock(
      label: 'Next week',
      rangeLabel: _formatWeekRangeLabel(context, nextWeekStart),
      expanded: _nextWeekExpanded,
      onToggle: () => setState(() => _nextWeekExpanded = !_nextWeekExpanded),
      groups: nextWeekGroups,
    );

    if (laterGroups.isNotEmpty) {
      children.add(_DayCardsBlockHeader(label: 'Later'));
      for (final g in visibleLaterGroups) {
        children.add(
          _DayCard(
            date: g.date,
            items: g.items,
            inProgressExpanded: _expandedInProgressDates.contains(g.date),
            onToggleInProgress: () {
              setState(() {
                if (!_expandedInProgressDates.add(g.date)) {
                  _expandedInProgressDates.remove(g.date);
                }
              });
            },
            itemBuilder: (day, item) => _buildDayCardsItem(context, day, item),
            sortItems: _sortedAgendaItems,
          ),
        );
      }

      if (laterTooLong) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton(
              onPressed: () => setState(() => _laterExpanded = !_laterExpanded),
              child: Text(
                _laterExpanded
                    ? 'Collapse later'
                    : 'Show all later ($laterDateCount dates)',
              ),
            ),
          ),
        );
      }
    }

    if (children.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Text(
            'No scheduled items in this range.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildDayCardsHeader(context),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDayCardsHeader(BuildContext context) {
    final theme = Theme.of(context);
    final typography =
        theme.extension<TasklyTypography>() ??
        TasklyTypography.from(
          textTheme: theme.textTheme,
          colorScheme: theme.colorScheme,
        );

    final label = _rangeLabel();

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _openRange,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: typography.screenTitleTight),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Search',
            onPressed: _openSearch,
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Filter',
            onPressed: _openFilter,
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
    );
  }

  String _rangeLabel() {
    return switch (_rangePreset) {
      _DateRangePreset.today => 'Today',
      _DateRangePreset.next7Days => 'Next 7 days',
      _DateRangePreset.thisMonth => 'This month',
      _DateRangePreset.nextMonth => 'Next month',
      _DateRangePreset.custom =>
        '${DateFormat('MMM d').format(_rangeStart)} – ${DateFormat('MMM d').format(_rangeEndExclusive.subtract(const Duration(days: 1)))}',
    };
  }

  Future<void> _openRange() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Range',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _RangeTile(
                title: 'Today',
                selected: _rangePreset == _DateRangePreset.today,
                onTap: () {
                  _setPresetRange(_DateRangePreset.today);
                  Navigator.of(sheetContext).pop();
                },
              ),
              _RangeTile(
                title: 'Next 7 days',
                selected: _rangePreset == _DateRangePreset.next7Days,
                onTap: () {
                  _setPresetRange(_DateRangePreset.next7Days);
                  Navigator.of(sheetContext).pop();
                },
              ),
              _RangeTile(
                title: 'This month',
                selected: _rangePreset == _DateRangePreset.thisMonth,
                onTap: () {
                  _setPresetRange(_DateRangePreset.thisMonth);
                  Navigator.of(sheetContext).pop();
                },
              ),
              _RangeTile(
                title: 'Next month',
                selected: _rangePreset == _DateRangePreset.nextMonth,
                onTap: () {
                  _setPresetRange(_DateRangePreset.nextMonth);
                  Navigator.of(sheetContext).pop();
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Jump',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _RangeTile(
                title: 'Jump to week',
                selected: false,
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: sheetContext,
                    initialDate: _rangeStart,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked == null) return;
                  _setWeekRange(picked);
                  if (!mounted) return;
                  Navigator.of(context).pop();
                },
              ),
              _RangeTile(
                title: 'Jump to month',
                selected: false,
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: sheetContext,
                    initialDate: _rangeStart,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked == null) return;
                  _setMonthRange(picked);
                  if (!mounted) return;
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _setPresetRange(_DateRangePreset preset) {
    final today = _dateOnly(DateTime.now());

    final (DateTime start, DateTime endExclusive) = switch (preset) {
      _DateRangePreset.today => (
        today,
        today.add(const Duration(days: 1)),
      ),
      _DateRangePreset.next7Days => (
        today,
        today.add(const Duration(days: 8)),
      ),
      _DateRangePreset.thisMonth => (
        today,
        DateTime(today.year, today.month + 1, 1),
      ),
      _DateRangePreset.nextMonth => () {
        final nextMonthStart = DateTime(today.year, today.month + 1, 1);
        return (
          nextMonthStart,
          DateTime(nextMonthStart.year, nextMonthStart.month + 1, 1),
        );
      }(),
      _DateRangePreset.custom => (_rangeStart, _rangeEndExclusive),
    };

    setState(() {
      _rangePreset = preset;
      _rangeStart = start;
      _rangeEndExclusive = endExclusive;
      _thisWeekExpanded = true;
      _nextWeekExpanded = true;
      _laterExpanded = false;
      _expandedInProgressDates.clear();
    });
  }

  void _setWeekRange(DateTime picked) {
    final d = _dateOnly(picked);
    final weekStart = d.subtract(Duration(days: d.weekday - DateTime.monday));
    final endExclusive = weekStart.add(const Duration(days: 7));

    setState(() {
      _rangePreset = _DateRangePreset.custom;
      _rangeStart = weekStart;
      _rangeEndExclusive = endExclusive;
      _thisWeekExpanded = true;
      _nextWeekExpanded = true;
      _laterExpanded = false;
      _expandedInProgressDates.clear();
    });
  }

  void _setMonthRange(DateTime picked) {
    final d = _dateOnly(picked);
    final start = DateTime(d.year, d.month, 1);
    final endExclusive = DateTime(d.year, d.month + 1, 1);

    setState(() {
      _rangePreset = _DateRangePreset.custom;
      _rangeStart = start;
      _rangeEndExclusive = endExclusive;
      _thisWeekExpanded = true;
      _nextWeekExpanded = true;
      _laterExpanded = false;
      _expandedInProgressDates.clear();
    });
  }

  List<AgendaItem> _sortedAgendaItems(Iterable<AgendaItem> items) {
    final list = items.toList(growable: false);
    final sorted = List<AgendaItem>.of(list);

    int entityRank(AgendaItem i) => i.isTask ? 0 : 1;
    bool pinned(AgendaItem i) =>
        (i.task?.isPinned ?? false) || (i.project?.isPinned ?? false);

    sorted.sort((a, b) {
      final er = entityRank(a).compareTo(entityRank(b));
      if (er != 0) return er;

      final pr = (pinned(a) ? 0 : 1).compareTo(pinned(b) ? 0 : 1);
      if (pr != 0) return pr;

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return sorted;
  }

  Widget _buildStatusBadge(BuildContext context, AgendaDateTag tag) {
    final scheme = Theme.of(context).colorScheme;
    return switch (tag) {
      AgendaDateTag.starts => _StatusPill(
        label: 'START',
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
      ),
      AgendaDateTag.due => _StatusPill(
        label: 'DUE',
        background: scheme.errorContainer,
        foreground: scheme.onErrorContainer,
      ),
      AgendaDateTag.inProgress => _StatusPill(
        label: 'IN PROGRESS',
        background: scheme.surfaceContainerHighest,
        foreground: scheme.onSurfaceVariant,
      ),
    };
  }

  Widget _buildDayCardsItem(
    BuildContext context,
    DateTime day,
    AgendaItem item,
  ) {
    if (item.isCondensed && item.tag == AgendaDateTag.inProgress) {
      final endDate = item.task?.deadlineDate ?? item.project?.deadlineDate;
      return _InProgressCard(
        title: item.name,
        endDate: endDate,
        accentColor: _tagAccentColor(
          Theme.of(context),
          AgendaDateTag.inProgress,
        ),
        onTap: () {
          if (item.isTask && item.task != null) {
            widget.onTaskTap?.call(item.task!);
          }
        },
      );
    }

    final statusBadge = _buildStatusBadge(context, item.tag);
    final accentColor = _tagAccentColor(Theme.of(context), item.tag);

    if (item.isTask && item.task != null) {
      final isAllocated =
          widget.data.enrichment?.isAllocatedByTaskId[item.task!.id] ?? false;
      return TaskView(
        task: item.task!,
        variant: TaskViewVariant.agendaCard,
        onCheckboxChanged: (t, val) => widget.onTaskToggle?.call(t.id, val),
        onTap: widget.onTaskTap,
        isInFocus: isAllocated,
        accentColor: accentColor,
        titlePrefix: statusBadge,
      );
    }

    if (item.isProject && item.project != null) {
      return ProjectView(
        project: item.project!,
        variant: ProjectViewVariant.agendaCard,
        taskCount: item.project!.taskCount,
        completedTaskCount: item.project!.completedTaskCount,
        accentColor: accentColor,
        titlePrefix: statusBadge,
      );
    }

    return const SizedBox.shrink();
  }

  bool _matchesFilters(AgendaItem item) {
    if (_entityFilter == _AgendaEntityFilter.tasksOnly && !item.isTask) {
      return false;
    }
    if (_entityFilter == _AgendaEntityFilter.projectsOnly && !item.isProject) {
      return false;
    }
    if (!_tagFilter.contains(item.tag)) return false;

    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return true;
    return item.name.toLowerCase().contains(q);
  }

  Future<void> _openSearch() async {
    final controller = TextEditingController(text: _searchQuery);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    'Search',
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Clear',
                    onPressed: controller.clear,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search scheduled items',
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (value) => Navigator.of(sheetContext).pop(value),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    Navigator.of(sheetContext).pop(controller.text),
                child: const Text('Apply'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    if (result == null) return;
    setState(() => _searchQuery = result);
  }

  Future<void> _openFilter() async {
    final current = _AgendaFilterSelection(
      entityFilter: _entityFilter,
      tagFilter: _tagFilter,
    );

    final result = await showModalBottomSheet<_AgendaFilterSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        var entity = current.entityFilter;
        var tags = current.tagFilter.toSet();
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Filter',
                        style: Theme.of(sheetContext).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            entity = _AgendaEntityFilter.all;
                            tags = {
                              AgendaDateTag.starts,
                              AgendaDateTag.due,
                              AgendaDateTag.inProgress,
                            };
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Type',
                    style: Theme.of(sheetContext).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<_AgendaEntityFilter>(
                    segments: const [
                      ButtonSegment(
                        value: _AgendaEntityFilter.all,
                        label: Text('All'),
                      ),
                      ButtonSegment(
                        value: _AgendaEntityFilter.tasksOnly,
                        label: Text('Tasks'),
                      ),
                      ButtonSegment(
                        value: _AgendaEntityFilter.projectsOnly,
                        label: Text('Projects'),
                      ),
                    ],
                    selected: {entity},
                    onSelectionChanged: (value) => setModalState(
                      () => entity = value.first,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Status',
                    style: Theme.of(sheetContext).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Start'),
                        selected: tags.contains(AgendaDateTag.starts),
                        onSelected: (value) => setModalState(() {
                          value
                              ? tags.add(AgendaDateTag.starts)
                              : tags.remove(AgendaDateTag.starts);
                        }),
                      ),
                      FilterChip(
                        label: const Text('Due'),
                        selected: tags.contains(AgendaDateTag.due),
                        onSelected: (value) => setModalState(() {
                          value
                              ? tags.add(AgendaDateTag.due)
                              : tags.remove(AgendaDateTag.due);
                        }),
                      ),
                      FilterChip(
                        label: const Text('In Progress'),
                        selected: tags.contains(AgendaDateTag.inProgress),
                        onSelected: (value) => setModalState(() {
                          value
                              ? tags.add(AgendaDateTag.inProgress)
                              : tags.remove(AgendaDateTag.inProgress);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(
                      _AgendaFilterSelection(
                        entityFilter: entity,
                        tagFilter: tags,
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (!mounted) return;
    if (result == null) return;
    setState(() {
      _entityFilter = result.entityFilter;
      _tagFilter = result.tagFilter;
    });
  }
}

class _DayCardsSuperHeader extends StatelessWidget {
  const _DayCardsSuperHeader({
    required this.label,
    required this.rangeLabel,
    required this.expanded,
    required this.onToggle,
  });

  final String label;
  final String rangeLabel;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  rangeLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                expanded ? Icons.expand_less : Icons.expand_more,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InProgressCard extends StatelessWidget {
  const _InProgressCard({
    required this.title,
    required this.accentColor,
    required this.onTap,
    this.endDate,
  });

  final String title;
  final DateTime? endDate;
  final Color accentColor;
  final VoidCallback onTap;

  String? _endDayLabel(BuildContext context) {
    final end = endDate;
    if (end == null) return null;
    final locale = Localizations.localeOf(context);
    return DateFormat.E(locale.toLanguageTag()).format(end);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final endDay = _endDayLabel(context);

    final dashColor = Color.lerp(
      accentColor,
      scheme.onSurfaceVariant,
      0.35,
    )!.withOpacity(0.55);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: CustomPaint(
            foregroundPainter: _DashedRoundedRectPainter(
              color: dashColor,
              strokeWidth: 1.5,
              radius: 14,
              dashLength: 7,
              gapLength: 5,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  left: 0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 6,
                      margin: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _StatusPill(
                            label: 'IN PROGRESS',
                            background: scheme.surfaceContainerHighest,
                            foreground: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          if (endDay != null)
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.hourglass_bottom,
                                      size: 16,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      endDay,
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            const Spacer(),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

enum _AgendaEntityFilter { all, tasksOnly, projectsOnly }

enum _DateRangePreset {
  today,
  next7Days,
  thisMonth,
  nextMonth,
  custom,
}

class _RangeTile extends StatelessWidget {
  const _RangeTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: trailing ?? (selected ? const Icon(Icons.check) : null),
      onTap: onTap,
    );
  }
}

class _DayCardsBlockHeader extends StatelessWidget {
  const _DayCardsBlockHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.date,
    required this.items,
    required this.inProgressExpanded,
    required this.onToggleInProgress,
    required this.itemBuilder,
    required this.sortItems,
  });

  final DateTime date;
  final List<AgendaItem> items;
  final bool inProgressExpanded;
  final VoidCallback onToggleInProgress;
  final Widget Function(DateTime date, AgendaItem item) itemBuilder;
  final List<AgendaItem> Function(Iterable<AgendaItem> items) sortItems;

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final semantic = _isSameDay(date, today)
        ? 'Today'
        : _isSameDay(date, tomorrow)
        ? 'Tomorrow'
        : null;
    final absolute = DateFormat('EEE, MMM d').format(date);

    final dueItems = sortItems(
      items.where((i) => i.tag == AgendaDateTag.due),
    );
    final startsItems = sortItems(
      items.where((i) => i.tag == AgendaDateTag.starts),
    );
    final inProgressItems = sortItems(
      items.where((i) => i.tag == AgendaDateTag.inProgress),
    );

    Widget buildSection(String label, List<AgendaItem> sectionItems) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...sectionItems.map((i) => itemBuilder(date, i)),
        ],
      );
    }

    Widget? buildInProgressSection() {
      if (inProgressItems.isEmpty) return null;

      if (!inProgressExpanded) {
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('In progress (${inProgressItems.length})'),
            trailing: const Icon(Icons.expand_more),
            onTap: onToggleInProgress,
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'In progress',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onToggleInProgress,
                  child: const Text('Hide'),
                ),
              ],
            ),
          ),
          ...inProgressItems.map((i) => itemBuilder(date, i)),
        ],
      );
    }

    final inProgressSection = buildInProgressSection();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (semantic != null) ...[
                    Text(
                      semantic,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    absolute,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (dueItems.isNotEmpty) buildSection('Due', dueItems),
              if (startsItems.isNotEmpty) buildSection('Starts', startsItems),
              ?inProgressSection,
            ],
          ),
        ),
      ),
    );
  }
}

class _AgendaFilterSelection {
  const _AgendaFilterSelection({
    required this.entityFilter,
    required this.tagFilter,
  });

  final _AgendaEntityFilter entityFilter;
  final Set<AgendaDateTag> tagFilter;
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        final extracted = metric.extractPath(
          distance,
          next.clamp(0, metric.length),
        );
        canvas.drawPath(extracted, paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength;
  }
}
