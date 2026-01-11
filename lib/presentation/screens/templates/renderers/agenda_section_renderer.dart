import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/presentation/theme/taskly_typography.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/screens/language/models/agenda_data.dart';
import 'package:taskly_bloc/domain/screens/language/models/screen_item.dart';
import 'package:taskly_bloc/domain/screens/templates/params/agenda_section_params.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_result.dart';
import 'package:taskly_bloc/presentation/screens/tiles/screen_item_tile_registry.dart';

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
    required this.params,
    this.onTaskToggle,
    this.onTaskTap,
    super.key,
  });

  final AgendaSectionResult data;
  final AgendaSectionParams params;
  final void Function(String taskId, bool? value)? onTaskToggle;
  final void Function(Task task)? onTaskTap;

  @override
  State<AgendaSectionRenderer> createState() => _AgendaSectionRendererState();
}

class _AgendaSectionRendererState extends State<AgendaSectionRenderer> {
  final ScreenItemTileRegistry _tileRegistry = const ScreenItemTileRegistry();

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

  @override
  Widget build(BuildContext context) {
    final agendaData = widget.data.agendaData;

    final allItemsCount = agendaData.totalItemCount;
    if (allItemsCount == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No scheduled items'),
        ),
      );
    }

    return Column(
      children: [
        _buildMonthHeader(context),
        _buildDatePicker(context, agendaData),
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              ..._buildTimelineSlivers(context, agendaData),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ],
    );
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

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: _DateChip(
              date: date,
              isSelected: isSelected,
              isToday: isToday,
              hasDot: hasDot,
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
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: _SectionTimeline(
              dateGroups: dateGroups,
              buildAgendaItem: (item) => _buildAgendaItem(context, item),
              dateKeyFor: (date) {
                final normalized = _dateOnly(date);
                return _dateKeys.putIfAbsent(normalized, GlobalKey.new);
              },
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
      return _CondensedInProgressRow(
        title: item.name,
        onTap: () {
          if (item.isTask && item.task != null) {
            widget.onTaskTap?.call(item.task!);
          }
        },
      );
    }

    final screenItem = switch (item) {
      AgendaItem(:final task?) when item.isTask => ScreenItem.task(task),
      AgendaItem(:final project?) when item.isProject => ScreenItem.project(
        project,
      ),
      _ => null,
    };
    if (screenItem == null) return const SizedBox.shrink();

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

    final tile = _tileRegistry.build(
      context,
      item: screenItem,
      onTaskToggle: widget.onTaskToggle,
      onTap: screenItem is ScreenItemTask
          ? () => widget.onTaskTap?.call(screenItem.task)
          : null,
    );

    return Stack(
      children: [
        tile,
        Positioned(
          left: 22,
          top: 10,
          child: _TagPill(label: tagLabel, style: tagStyle),
        ),
      ],
    );
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
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool hasDot;
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
                              : colorScheme.primary,
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

class _CondensedInProgressRow extends StatelessWidget {
  const _CondensedInProgressRow({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 68,
                child: Text(
                  'ONGOING',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
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

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      alignment: Alignment.bottomCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outlineVariant.withOpacity(0.6),
            ),
          ),
        ),
        child: Row(
          children: [
            if (emphasize)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  width: 5,
                  height: 32,
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
                            fontWeight: FontWeight.bold,
                          ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!.toUpperCase(),
                        style: typography.subHeaderCaps,
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
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
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
    required this.dateKeyFor,
  });

  final List<_DateGroup> dateGroups;
  final Widget Function(AgendaItem item) buildAgendaItem;
  final GlobalKey Function(DateTime date) dateKeyFor;

  static const double _timelineWidth = 64;
  static const double _lineX = 28;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lineColor = theme.colorScheme.outlineVariant;

    return Column(
      children: [
        for (final group in dateGroups)
          _DateTimelineGroup(
            key: dateKeyFor(group.date),
            group: group,
            timelineWidth: _timelineWidth,
            lineX: _lineX,
            lineColor: lineColor,
            buildAgendaItem: buildAgendaItem,
          ),
      ],
    );
  }
}

class _DateTimelineGroup extends StatelessWidget {
  const _DateTimelineGroup({
    required this.group,
    required this.timelineWidth,
    required this.lineX,
    required this.lineColor,
    required this.buildAgendaItem,
    super.key,
  });

  final _DateGroup group;
  final double timelineWidth;
  final double lineX;
  final Color lineColor;
  final Widget Function(AgendaItem item) buildAgendaItem;

  @override
  Widget build(BuildContext context) {
    final dayName = DateFormat.E().format(group.date).toUpperCase();
    final dayNumber = group.date.day.toString();

    return Column(
      children: [
        for (var i = 0; i < group.items.length; i++)
          _TimelineRow(
            isFirstOfDate: i == 0,
            dayName: dayName,
            dayNumber: dayNumber,
            item: group.items[i],
            timelineWidth: timelineWidth,
            lineX: lineX,
            lineColor: lineColor,
            child: buildAgendaItem(group.items[i]),
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.isFirstOfDate,
    required this.dayName,
    required this.dayNumber,
    required this.item,
    required this.timelineWidth,
    required this.lineX,
    required this.lineColor,
    required this.child,
  });

  final bool isFirstOfDate;
  final String dayName;
  final String dayNumber;
  final AgendaItem item;
  final double timelineWidth;
  final double lineX;
  final Color lineColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dotColor = theme.colorScheme.primary;

    // Reserve space for the date marker so it reads like a timeline header.
    final topPad = isFirstOfDate ? 14.0 : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: 10, top: topPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: timelineWidth,
            child: Stack(
              children: [
                Positioned.fill(
                  left: lineX,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(width: 2, color: lineColor),
                  ),
                ),
                if (isFirstOfDate)
                  Align(
                    alignment: Alignment.topCenter,
                    child: _TimelineDateMarker(
                      dayName: dayName,
                      dayNumber: dayNumber,
                    ),
                  ),
                Positioned(
                  left: lineX - 6,
                  top: isFirstOfDate ? 48 : 22,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: isFirstOfDate ? 24 : 0),
              child: child,
            ),
          ),
        ],
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
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
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
