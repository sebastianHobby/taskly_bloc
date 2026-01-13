import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/core/logging/perf_phase_timer.dart';
import 'package:taskly_bloc/presentation/entity_views/project_view.dart';
import 'package:taskly_bloc/presentation/entity_views/task_view.dart';
import 'package:taskly_bloc/presentation/theme/taskly_typography.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/screens/language/models/agenda_data.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';

/// Renders an agenda section with date-based timeline.
///
/// Features:
/// - Horizontal date picker with scroll sync
/// - Collapsible overdue section
/// - Semantic date labels (Today, Tomorrow, etc.)
/// - Smooth scroll coordination between timeline and date picker
class AgendaSectionRenderer extends StatefulWidget {
  const AgendaSectionRenderer({
    required this.data,
    this.showTagPills = false,
    this.onTaskToggle,
    this.onTaskTap,
    super.key,
  });

  final AgendaSectionResult data;
  final bool showTagPills;
  final void Function(String taskId, bool? value)? onTaskToggle;
  final void Function(Task task)? onTaskTap;

  @override
  State<AgendaSectionRenderer> createState() => _AgendaSectionRendererState();
}

class _AgendaSectionRendererState extends State<AgendaSectionRenderer> {
  static const double _timelineWidth = 64;

  String _searchQuery = '';
  _AgendaEntityFilter _entityFilter = _AgendaEntityFilter.all;
  Set<AgendaDateTag> _tagFilter = {
    AgendaDateTag.starts,
    AgendaDateTag.due,
    AgendaDateTag.inProgress,
  };

  late ScrollController _scrollController;
  late ScrollController _datePickerController;

  late DateTime _selectedMonth;
  late DateTime _focusedDate;

  // Prevent feedback loops during programmatic scrolling
  bool _programmaticScroll = false;
  Timer? _scrollDebounce;

  final Map<DateTime, GlobalKey> _dateKeys = <DateTime, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = _monthStart(now);
    _focusedDate = _dateOnly(now);
    _scrollController = ScrollController();
    _datePickerController = ScrollController();

    _scrollController.addListener(_onTimelineScrolled);
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _scrollController.dispose();
    _datePickerController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _monthStart(DateTime d) => DateTime(d.year, d.month);

  DateTime _monthEnd(DateTime d) => DateTime(d.year, d.month + 1, 0);

  DateTime? get _loadedHorizonEnd => widget.data.agendaData.loadedHorizonEnd;

  bool get _selectedMonthContainsToday {
    final today = _dateOnly(DateTime.now());
    return _selectedMonth.year == today.year &&
        _selectedMonth.month == today.month;
  }

  void _onTimelineScrolled() {
    if (_programmaticScroll) return;

    // Debounce scroll events to avoid excessive updates
    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(milliseconds: 100), () {
      // Calculate which date is currently visible
      final visibleDate = _calculateVisibleDate();
      if (visibleDate != null && !_isSameDay(visibleDate, _focusedDate)) {
        setState(() => _focusedDate = visibleDate);
        _scrollDatePickerToDate(visibleDate);
      }
    });
  }

  DateTime? _calculateVisibleDate() {
    if (!_scrollController.hasClients) return null;

    // Find the first date section that is currently visible.
    final entries = _dateKeys.entries.toList(growable: false);
    if (entries.isEmpty) return null;

    DateTime? bestDate;
    double bestDy = double.infinity;

    for (final entry in entries) {
      final context = entry.value.currentContext;
      if (context == null) continue;
      final box = context.findRenderObject();
      if (box is! RenderBox) continue;
      final dy = box.localToGlobal(Offset.zero).dy;
      // Prefer the first element below the app bar region.
      if (dy >= 0 && dy < bestDy) {
        bestDy = dy;
        bestDate = entry.key;
      }
    }

    return bestDate;
  }

  void _onDateSelected(DateTime date) {
    setState(() => _focusedDate = date);
    _scrollTimelineToDate(date);
  }

  void _scrollTimelineToDate(DateTime date) {
    final key = _dateKeys[_dateOnly(date)];
    final ctx = key?.currentContext;
    if (ctx == null) return;

    _programmaticScroll = true;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      alignment: 0.05,
    ).whenComplete(() {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 150), () {
        _programmaticScroll = false;
      });
    });
  }

  void _scrollDatePickerToDate(DateTime date) {
    if (!_datePickerController.hasClients) return;

    final dates = _datePickerDates();
    final idx = dates.indexWhere((d) => _isSameDay(d, date));
    if (idx < 0) return;

    const itemWidth = 80.0;
    final targetOffset = (idx * itemWidth) - (itemWidth * 2);
    _datePickerController.animateTo(
      targetOffset.clamp(0, _datePickerController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  AgendaDateTag _dominantTag(Iterable<AgendaItem> items) {
    var hasStarts = false;
    var hasInProgress = false;
    var hasDue = false;

    for (final item in items) {
      switch (item.tag) {
        case AgendaDateTag.due:
          hasDue = true;
        case AgendaDateTag.inProgress:
          hasInProgress = true;
        case AgendaDateTag.starts:
          hasStarts = true;
      }
    }

    if (hasDue) return AgendaDateTag.due;
    if (hasInProgress) return AgendaDateTag.inProgress;
    if (hasStarts) return AgendaDateTag.starts;

    // Fallback (should not happen since groups are non-empty)
    return AgendaDateTag.starts;
  }

  Color _tagAccentColor(ThemeData theme, AgendaDateTag tag) {
    final scheme = theme.colorScheme;
    return switch (tag) {
      AgendaDateTag.due => scheme.error,
      AgendaDateTag.inProgress => scheme.tertiary,
      AgendaDateTag.starts => scheme.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final buildStart = kDebugMode ? DateTime.now() : null;
    final agendaData = widget.data.agendaData;

    final phaseTimer = PerfPhaseTimer(
      'Scheduled UI build',
      category: 'scheduled_ui',
      // Keep these fairly low so we get signal while iterating.
      slowPhaseThresholdMs: 50,
      slowTotalThresholdMs: 100,
    );

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

    final monthHeader = phaseTimer.phase(
      'monthHeader',
      () => _buildMonthHeader(context),
    );
    final datePicker = phaseTimer.phase(
      'datePicker',
      () => _buildDatePicker(context, agendaData),
    );
    final timelineSlivers = phaseTimer.phase(
      'timelineSlivers',
      () => _buildTimelineSlivers(context, agendaData),
    );

    final result = Column(
      children: [
        monthHeader,
        datePicker,
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              ...timelineSlivers,
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ],
    );

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

    // Coarse-grained breakdown of where build time is spent.
    // This is intentionally independent of the existing total build logging
    // above (which is debug-only); this runs in profile too.
    phaseTimer.finish();

    return result;
  }

  Widget _buildMonthHeader(BuildContext context) {
    final theme = Theme.of(context);
    final typography =
        theme.extension<TasklyTypography>() ??
        TasklyTypography.from(
          textTheme: theme.textTheme,
          colorScheme: theme.colorScheme,
        );
    final selectedMonthLabel = DateFormat.yMMMM().format(_selectedMonth);
    final showTodayPill = !_selectedMonthContainsToday;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _pickDate(context, initial: _selectedMonth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedMonthLabel,
                    style: typography.screenTitleTight,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          const Spacer(),
          if (showTodayPill)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: const Text('Today'),
                onPressed: _jumpToToday,
              ),
            ),
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
          IconButton(
            tooltip: 'Calendar',
            onPressed: () => _pickDate(context, initial: _focusedDate),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime initial,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    _setSelectedMonthAndFocus(_monthStart(picked), _dateOnly(picked));
  }

  void _jumpToToday() {
    final today = _dateOnly(DateTime.now());
    _setSelectedMonthAndFocus(_monthStart(today), today);
  }

  void _setSelectedMonthAndFocus(DateTime month, DateTime focus) {
    setState(() {
      _selectedMonth = month;
      _focusedDate = focus;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollDatePickerToDate(_focusedDate);
      _scrollTimelineToDate(_focusedDate);
    });
  }

  List<DateTime> _datePickerDates() {
    final today = _dateOnly(DateTime.now());
    final monthStart = _monthStart(_selectedMonth);
    final start = _selectedMonthContainsToday ? today : monthStart;

    // Show up to ~2 weeks of chips (enough for scroll-sync + next-week spill).
    final end = start.add(const Duration(days: 13));
    final hardEnd = _loadedHorizonEnd;
    final effectiveEnd = hardEnd == null
        ? end
        : (end.isAfter(hardEnd) ? hardEnd : end);

    final days = effectiveEnd.difference(start).inDays;
    return List.generate(
      days + 1,
      (i) => start.add(Duration(days: i)),
      growable: false,
    );
  }

  Widget _buildDatePicker(BuildContext context, AgendaData agendaData) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dates = _datePickerDates();
    final datesWithItems = _datesWithAnyItems(agendaData);
    final today = _dateOnly(DateTime.now());

    return Container(
      height: 84,
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
      child: ListView.builder(
        controller: _datePickerController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = _isSameDay(date, _focusedDate);
          final isToday = _isSameDay(date, today);
          final hasDot = datesWithItems.contains(_dateOnly(date));

          Color? dotColor;
          if (hasDot) {
            final itemsForDate = _filteredItemsForDate(agendaData, date);
            if (itemsForDate.isNotEmpty) {
              dotColor = _tagAccentColor(
                theme,
                _dominantTag(itemsForDate),
              );
            }
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: _DateChip(
              date: date,
              isSelected: isSelected,
              isToday: isToday,
              hasDot: hasDot,
              dotColor: dotColor,
              onTap: () => _onDateSelected(date),
            ),
          );
        },
      ),
    );
  }

  Set<DateTime> _datesWithAnyItems(AgendaData agendaData) {
    final set = <DateTime>{};
    for (final group in agendaData.groups) {
      if (group.items.isNotEmpty) set.add(_dateOnly(group.date));
    }
    return set;
  }

  List<Widget> _buildTimelineSlivers(
    BuildContext context,
    AgendaData agendaData,
  ) {
    final slivers = <Widget>[];

    final today = _dateOnly(DateTime.now());
    final monthStart = _monthStart(_selectedMonth);
    final monthEnd = _monthEnd(_selectedMonth);

    final restOfWeekEnd = _endOfWeekSunday(today);
    final restOfWeekStart = today.add(const Duration(days: 1));

    final nextWeekStart = _startOfWeekMonday(today).add(
      const Duration(days: 7),
    );
    final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));

    final sections = <_AgendaSectionSpec>[];
    if (_selectedMonthContainsToday) {
      sections.add(
        _AgendaSectionSpec(
          title: 'Today',
          subtitle: DateFormat('EEEE, MMM d').format(today),
          dates: [today],
          alwaysShowHeader: true,
          emphasizeHeader: true,
        ),
      );
      sections.add(
        _AgendaSectionSpec(
          title: 'REST OF WEEK',
          rangeLabel: _formatRangeLabel(restOfWeekStart, restOfWeekEnd),
          dates: _datesInRange(restOfWeekStart, restOfWeekEnd),
        ),
      );
      sections.add(
        _AgendaSectionSpec(
          title: 'NEXT WEEK',
          rangeLabel: _formatRangeLabel(nextWeekStart, nextWeekEnd),
          dates: _datesInRange(nextWeekStart, nextWeekEnd),
        ),
      );
    }

    final laterStart = _selectedMonthContainsToday
        ? nextWeekEnd.add(const Duration(days: 1))
        : monthStart;
    final laterEnd = monthEnd;
    if (!laterStart.isAfter(laterEnd)) {
      sections.add(
        _AgendaSectionSpec(
          title: 'LATER',
          rangeLabel: _formatRangeLabel(laterStart, laterEnd),
          dates: _datesInRange(laterStart, laterEnd),
        ),
      );
    }

    var anyContent = false;
    for (final section in sections) {
      final dateGroups = _buildDateGroupsForDates(
        agendaData: agendaData,
        dates: section.dates,
      );

      if (!section.alwaysShowHeader && dateGroups.isEmpty) {
        continue;
      }
      anyContent = true;

      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _SectionHeaderDelegate(
            title: section.title,
            subtitle: section.subtitle,
            rangeLabel: section.rangeLabel,
            emphasize: section.emphasizeHeader,
          ),
        ),
      );

      if (dateGroups.isEmpty) {
        slivers.add(
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Text('No scheduled items.'),
            ),
          ),
        );
        continue;
      }

      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _SectionTimeline(
              dateGroups: dateGroups,
              buildAgendaItem: (item) => _buildAgendaItem(context, item),
              dominantTagFor: _dominantTag,
              accentColorFor: (tag) => _tagAccentColor(Theme.of(context), tag),
              dateKeyFor: (date) {
                final normalized = _dateOnly(date);
                return _dateKeys.putIfAbsent(normalized, GlobalKey.new);
              },
              showDateMarkers: section.title != 'Today',
            ),
          ),
        ),
      );
    }

    if (!anyContent) {
      slivers.add(
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('No scheduled items in this month.'),
          ),
        ),
      );
    }

    return slivers;
  }

  List<_DateGroup> _buildDateGroupsForDates({
    required AgendaData agendaData,
    required List<DateTime> dates,
  }) {
    final dateGroups = <_DateGroup>[];
    for (final date in dates) {
      final items = _filteredItemsForDate(agendaData, date);
      if (items.isEmpty) continue;
      dateGroups.add(_DateGroup(date: date, items: items));
    }
    return dateGroups;
  }

  DateTime _startOfWeekMonday(DateTime date) {
    return _dateOnly(date).subtract(Duration(days: date.weekday - 1));
  }

  DateTime _endOfWeekSunday(DateTime date) {
    return _dateOnly(
      date,
    ).add(Duration(days: DateTime.daysPerWeek - date.weekday));
  }

  List<DateTime> _datesInRange(DateTime start, DateTime end) {
    if (start.isAfter(end)) return const [];
    final s = _dateOnly(start);
    final e = _dateOnly(end);
    final days = e.difference(s).inDays;
    return List.generate(days + 1, (i) => s.add(Duration(days: i)));
  }

  String _formatRangeLabel(DateTime start, DateTime end) {
    final s = _dateOnly(start);
    final e = _dateOnly(end);
    // Example: Oct 26 - 29, or Oct 30 - Nov 5
    final startFmt = DateFormat.MMMd().format(s);
    final endFmt = s.month == e.month
        ? DateFormat.d().format(e)
        : DateFormat.MMMd().format(e);
    return '$startFmt - $endFmt';
  }

  List<AgendaItem> _itemsForDate(AgendaData agendaData, DateTime date) {
    final normalized = _dateOnly(date);
    for (final group in agendaData.groups) {
      if (_dateOnly(group.date) == normalized) return group.items;
    }
    return const [];
  }

  List<AgendaItem> _filteredItemsForDate(AgendaData agendaData, DateTime date) {
    final items = _itemsForDate(agendaData, date);
    if (items.isEmpty) return const [];
    return items.where(_matchesFilters).toList(growable: false);
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

  Widget _buildAgendaItem(BuildContext context, AgendaItem item) {
    if (item.isCondensed) {
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

    // Scheduled mock shows tag pills on items consistently.
    final tagLabel = switch (item.tag) {
      AgendaDateTag.starts => 'START',
      AgendaDateTag.due => 'DUE',
      AgendaDateTag.inProgress => 'IN PROGRESS',
    };

    final tagStyle = switch (item.tag) {
      AgendaDateTag.starts => _TagStyle.start,
      AgendaDateTag.due => _TagStyle.due,
      AgendaDateTag.inProgress => _TagStyle.inProgress,
    };

    final titlePrefix = _TagPill(label: tagLabel, style: tagStyle);

    // Prefer entity-level view variants for Scheduled so the styling lives at
    // the entity layer (consistent with the unified screen architecture).
    if (item.isTask && item.task != null) {
      return TaskView(
        task: item.task!,
        variant: TaskViewVariant.agendaCard,
        showNextActionIndicator: false,
        onCheckboxChanged: (t, val) => widget.onTaskToggle?.call(t.id, val),
        onTap: widget.onTaskTap,
        titlePrefix: titlePrefix,
      );
    }

    if (item.isProject && item.project != null) {
      return ProjectView(
        project: item.project!,
        variant: ProjectViewVariant.agendaCard,
        titlePrefix: titlePrefix,
      );
    }

    // Fallback for unexpected data.
    return const SizedBox.shrink();
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

/// Date chip widget for the horizontal date picker
class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.hasDot,
    required this.dotColor,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool hasDot;
  final Color? dotColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typography =
        theme.extension<TasklyTypography>() ??
        TasklyTypography.from(
          textTheme: theme.textTheme,
          colorScheme: theme.colorScheme,
        );

    final dayName = DateFormat.E().format(date).toUpperCase();
    final dayNumber = date.day.toString();

    return Transform.scale(
      scale: isSelected ? 1.05 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 72,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer
                : isToday
                ? colorScheme.secondaryContainer.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : isToday
                  ? colorScheme.secondary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayName,
                style: typography.badgeTinyCaps.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dayNumber,
                style:
                    (isSelected
                            ? typography.agendaChipDateNumberSelected
                            : typography.agendaChipDateNumber)
                        .copyWith(
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 6,
                child: hasDot
                    ? Container(
                        width: 6,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : (dotColor ?? colorScheme.primary),
                          shape: BoxShape.circle,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TagStyle { start, due, inProgress }

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, required this.style});

  final String label;
  final _TagStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (bg, fg) = switch (style) {
      _TagStyle.start => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      _TagStyle.due => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
      _TagStyle.inProgress => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: style == _TagStyle.inProgress
            ? Border.all(color: colorScheme.outlineVariant)
            : null,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
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

class _DateGroup {
  const _DateGroup({required this.date, required this.items});

  final DateTime date;
  final List<AgendaItem> items;
}

enum _AgendaEntityFilter { all, tasksOnly, projectsOnly }

class _AgendaFilterSelection {
  const _AgendaFilterSelection({
    required this.entityFilter,
    required this.tagFilter,
  });

  final _AgendaEntityFilter entityFilter;
  final Set<AgendaDateTag> tagFilter;
}

class _AgendaSectionSpec {
  const _AgendaSectionSpec({
    required this.title,
    required this.dates,
    this.subtitle,
    this.rangeLabel,
    this.alwaysShowHeader = false,
    this.emphasizeHeader = false,
  });

  final String title;
  final String? subtitle;
  final String? rangeLabel;
  final List<DateTime> dates;
  final bool alwaysShowHeader;
  final bool emphasizeHeader;
}

class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SectionHeaderDelegate({
    required this.title,
    required this.emphasize,
    this.subtitle,
    this.rangeLabel,
  });

  final String title;
  final String? subtitle;
  final String? rangeLabel;
  final bool emphasize;

  double get _extent => subtitle == null ? 64 : 84;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final typography =
        theme.extension<TasklyTypography>() ??
        TasklyTypography.from(
          textTheme: theme.textTheme,
          colorScheme: theme.colorScheme,
        );

    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.35),
            ),
          ),
        ),
        child: Row(
          children: [
            if (emphasize)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: emphasize
                        ? typography.agendaSectionHeaderHeavy
                        : theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!.toUpperCase(),
                        style: typography.subHeaderCaps.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.85),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (rangeLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                child: Text(rangeLabel!, style: theme.textTheme.labelMedium),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SectionHeaderDelegate oldDelegate) {
    return title != oldDelegate.title ||
        subtitle != oldDelegate.subtitle ||
        rangeLabel != oldDelegate.rangeLabel ||
        emphasize != oldDelegate.emphasize;
  }
}

class _SectionTimeline extends StatelessWidget {
  const _SectionTimeline({
    required this.dateGroups,
    required this.buildAgendaItem,
    required this.dominantTagFor,
    required this.accentColorFor,
    required this.dateKeyFor,
    required this.showDateMarkers,
  });

  final List<_DateGroup> dateGroups;
  final Widget Function(AgendaItem item) buildAgendaItem;
  final AgendaDateTag Function(Iterable<AgendaItem> items) dominantTagFor;
  final Color Function(AgendaDateTag tag) accentColorFor;
  final GlobalKey Function(DateTime date) dateKeyFor;
  final bool showDateMarkers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseLineColor = theme.colorScheme.outlineVariant;

    return Column(
      children: [
        for (final group in dateGroups)
          _DateTimelineGroup(
            key: dateKeyFor(group.date),
            group: group,
            timelineWidth: _AgendaSectionRendererState._timelineWidth,
            dominantTag: dominantTagFor(group.items),
            baseLineColor: baseLineColor,
            accentColorFor: accentColorFor,
            buildAgendaItem: buildAgendaItem,
            showDateMarker: showDateMarkers,
          ),
      ],
    );
  }
}

class _DateTimelineGroup extends StatefulWidget {
  const _DateTimelineGroup({
    required this.group,
    required this.timelineWidth,
    required this.dominantTag,
    required this.baseLineColor,
    required this.accentColorFor,
    required this.buildAgendaItem,
    required this.showDateMarker,
    super.key,
  });

  final _DateGroup group;
  final double timelineWidth;
  final AgendaDateTag dominantTag;
  final Color baseLineColor;
  final Color Function(AgendaDateTag tag) accentColorFor;
  final Widget Function(AgendaItem item) buildAgendaItem;
  final bool showDateMarker;

  @override
  State<_DateTimelineGroup> createState() => _DateTimelineGroupState();
}

class _DateTimelineGroupState extends State<_DateTimelineGroup> {
  final GlobalKey _groupKey = GlobalKey();

  final List<GlobalKey> _itemKeys = <GlobalKey>[];

  double? _anchorY;
  List<double> _itemAnchorYs = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAnchor());
  }

  @override
  void didUpdateWidget(covariant _DateTimelineGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.items != widget.group.items) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureAnchor());
    }
  }

  void _measureAnchor() {
    if (!mounted) return;

    final groupBox = _groupKey.currentContext?.findRenderObject() as RenderBox?;
    final firstItemBox = _itemKeys.isEmpty
        ? null
        : (_itemKeys.first.currentContext?.findRenderObject() as RenderBox?);

    if (groupBox == null || firstItemBox == null) return;

    double anchorOffsetFor(AgendaItem item) {
      if (item.isCondensed) return 24;
      if (item.isTask) return 28;
      if (item.isProject) return 36;
      return 24;
    }

    final firstItemTop = firstItemBox.localToGlobal(
      Offset.zero,
      ancestor: groupBox,
    );
    final first = widget.group.items.first;
    final newAnchorY = firstItemTop.dy + anchorOffsetFor(first);

    // Also compute a dot anchor for every item so the timeline reads like an
    // event stream (closer to the mockup).
    final measuredAnchors = <double>[];
    for (var i = 0; i < widget.group.items.length; i++) {
      if (i >= _itemKeys.length) continue;
      final itemBox =
          _itemKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (itemBox == null) continue;
      final itemTop = itemBox.localToGlobal(
        Offset.zero,
        ancestor: groupBox,
      );
      measuredAnchors.add(itemTop.dy + anchorOffsetFor(widget.group.items[i]));
    }

    if (_anchorY == null || (_anchorY! - newAnchorY).abs() > 1) {
      setState(() => _anchorY = newAnchorY);
    }

    if (measuredAnchors.isNotEmpty) {
      final sameCount = measuredAnchors.length == _itemAnchorYs.length;
      var changed = !sameCount;
      if (!changed) {
        for (var i = 0; i < measuredAnchors.length; i++) {
          if ((measuredAnchors[i] - _itemAnchorYs[i]).abs() > 1) {
            changed = true;
            break;
          }
        }
      }
      if (changed) {
        setState(() => _itemAnchorYs = measuredAnchors);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure we have stable keys for each rendered item.
    while (_itemKeys.length < widget.group.items.length) {
      _itemKeys.add(GlobalKey());
    }

    final dayName = DateFormat.E().format(widget.group.date).toUpperCase();
    final dayNumber = widget.group.date.day.toString();

    final dotColor = widget.accentColorFor(widget.dominantTag);
    final lineColor = Color.lerp(
      widget.baseLineColor,
      dotColor,
      0.45,
    )!.withOpacity(0.7);

    // Keep the marker/dot aligned with the first item, rather than floating at
    // the top of the group.
    final anchorY = _anchorY ?? 36;
    final markerTop = (anchorY - 28).clamp(0.0, double.infinity);
    final dotTop = (anchorY - 7).clamp(0.0, double.infinity);

    // Geometry (mockup-like): date badge sits to the left of the line, and the
    // dot sits on the line. Keeping this as local constants makes it easy to
    // tweak without changing the widget API.
    const dateMarkerWidth = 44.0;
    const dotSize = 14.0;
    const smallDotSize = 10.0;

    // Place the line toward the right edge of the timeline gutter so the date
    // marker doesn't overlap it.
    final lineCenterX = (widget.timelineWidth - 12).clamp(
      0.0,
      widget.timelineWidth,
    );
    final dotLeft = lineCenterX - (dotSize / 2);
    final smallDotLeft = lineCenterX - (smallDotSize / 2);

    return Padding(
      key: _groupKey,
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: widget.timelineWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: lineCenterX - 1,
                    child: Container(width: 2, color: lineColor),
                  ),
                  if (widget.showDateMarker)
                    Positioned(
                      top: markerTop,
                      left: 0,
                      child: SizedBox(
                        width: dateMarkerWidth,
                        child: _TimelineDateMarker(
                          dayName: dayName,
                          dayNumber: dayNumber,
                        ),
                      ),
                    ),
                  Positioned(
                    top: dotTop,
                    left: dotLeft,
                    child: _TimelineDot(
                      color: dotColor,
                      borderColor: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),

                  // Additional, smaller dots for each item to strengthen the
                  // timeline-to-card mapping (mockup-like readability).
                  for (var i = 1; i < _itemAnchorYs.length; i++)
                    Positioned(
                      top: (_itemAnchorYs[i] - 5).clamp(0.0, double.infinity),
                      left: smallDotLeft,
                      child: _TimelineDot(
                        color: dotColor.withOpacity(0.55),
                        borderColor: Theme.of(context).scaffoldBackgroundColor,
                        size: smallDotSize,
                        borderWidth: 1.5,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < widget.group.items.length; i++) ...[
                    KeyedSubtree(
                      key: _itemKeys[i],
                      child: widget.buildAgendaItem(widget.group.items[i]),
                    ),
                    if (i != widget.group.items.length - 1)
                      const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({
    required this.color,
    required this.borderColor,
    this.size = 14,
    this.borderWidth = 2,
  });

  final Color color;
  final Color borderColor;
  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: borderWidth),
      ),
    );
  }
}

class _TimelineDateMarker extends StatelessWidget {
  const _TimelineDateMarker({required this.dayName, required this.dayNumber});

  final String dayName;
  final String dayNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typography =
        theme.extension<TasklyTypography>() ??
        TasklyTypography.from(
          textTheme: theme.textTheme,
          colorScheme: theme.colorScheme,
        );
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.7),
        ),
      ),
      child: Column(
        children: [
          Text(
            dayName,
            style: typography.badgeTinyCaps,
          ),
          const SizedBox(height: 4),
          Text(
            dayNumber,
            style: typography.agendaChipDateNumber,
          ),
        ],
      ),
    );
  }
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
