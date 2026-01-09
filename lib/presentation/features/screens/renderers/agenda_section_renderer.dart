import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/models/screens/agenda_data.dart';
import 'package:taskly_bloc/domain/models/screens/screen_item.dart';
import 'package:taskly_bloc/domain/models/screens/templates/agenda_section_params.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
import 'package:taskly_bloc/domain/services/screens/agenda_section_data_service.dart';
import 'package:taskly_bloc/presentation/features/screens/tiles/screen_item_tile_registry.dart';

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
  final AgendaSectionDataService _agendaDataService =
      getIt<AgendaSectionDataService>();

  late ScrollController _scrollController;
  late ScrollController _datePickerController;

  late DateTime _selectedMonth;
  late DateTime _focusedDate;

  StreamSubscription<AgendaData>? _agendaSubscription;
  AgendaData? _agendaData;
  int _loadedMonths = 2;

  bool _isLoading = true;
  bool _isLoadingMore = false;

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
    _subscribeAgenda();
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _agendaSubscription?.cancel();
    _scrollController.dispose();
    _datePickerController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _monthStart(DateTime d) => DateTime(d.year, d.month);

  DateTime _monthEnd(DateTime d) => DateTime(d.year, d.month + 1, 0);

  DateTime _rangeEndForLoadedMonths() {
    // End of (selectedMonth + loadedMonths - 1)
    return DateTime(
      _selectedMonth.year,
      _selectedMonth.month + _loadedMonths,
      0,
    );
  }

  bool get _selectedMonthContainsToday {
    final today = _dateOnly(DateTime.now());
    return _selectedMonth.year == today.year &&
        _selectedMonth.month == today.month;
  }

  void _subscribeAgenda() {
    _agendaSubscription?.cancel();
    setState(() {
      _isLoading = true;
    });

    final rangeStart = _monthStart(_selectedMonth);
    final rangeEnd = _rangeEndForLoadedMonths();
    final referenceDate = DateTime.now();

    _agendaSubscription = _agendaDataService
        .watchAgendaData(
          referenceDate: referenceDate,
          focusDate: _focusedDate,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        )
        .listen((data) {
          if (!mounted) return;
          setState(() {
            _agendaData = data;
            _isLoading = false;
            _isLoadingMore = false;
          });
        });
  }

  void _onTimelineScrolled() {
    if (_programmaticScroll) return;

    if (_scrollController.hasClients &&
        !_isLoadingMore &&
        _scrollController.position.extentAfter < 800) {
      _loadMoreIfNeeded();
    }

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

  void _loadMoreIfNeeded() {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    _loadedMonths += 1;
    _subscribeAgenda();
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
    final agendaData = _agendaData ?? widget.data.agendaData;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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

    return Column(
      children: [
        _buildMonthHeader(context),
        _buildDatePicker(context, agendaData),
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              ..._buildTimelineSections(context, agendaData),
              if (_isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthHeader(BuildContext context) {
    final theme = Theme.of(context);
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
                    style: theme.textTheme.titleMedium,
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
      _loadedMonths = 2;
    });
    _subscribeAgenda();

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
    final hardEnd = _rangeEndForLoadedMonths();
    final effectiveEnd = end.isAfter(hardEnd) ? hardEnd : end;

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
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
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

  List<Widget> _buildTimelineSections(
    BuildContext context,
    AgendaData agendaData,
  ) {
    final widgets = <Widget>[];

    final today = _dateOnly(DateTime.now());
    final monthStart = _monthStart(_selectedMonth);
    final monthEnd = _monthEnd(_selectedMonth);

    final restOfWeekEnd = _endOfWeekSunday(today);
    final restOfWeekStart = today.add(const Duration(days: 1));

    final nextWeekStart = _startOfWeekMonday(
      today,
    ).add(const Duration(days: 7));
    final nextWeekEnd = nextWeekStart.add(const Duration(days: 6));

    if (_selectedMonthContainsToday) {
      widgets.addAll(
        _buildSection(
          context,
          title: 'Today',
          subtitle: DateFormat('EEEE, MMM d').format(today),
          dates: [today],
          agendaData: agendaData,
        ),
      );

      widgets.addAll(
        _buildSection(
          context,
          title: 'REST OF WEEK',
          rangeLabel: _formatRangeLabel(restOfWeekStart, restOfWeekEnd),
          dates: _datesInRange(restOfWeekStart, restOfWeekEnd),
          agendaData: agendaData,
        ),
      );

      widgets.addAll(
        _buildSection(
          context,
          title: 'NEXT WEEK',
          rangeLabel: _formatRangeLabel(nextWeekStart, nextWeekEnd),
          dates: _datesInRange(nextWeekStart, nextWeekEnd),
          agendaData: agendaData,
        ),
      );
    }

    // Later: strictly capped to selected month.
    final laterStart = _selectedMonthContainsToday
        ? nextWeekEnd.add(const Duration(days: 1))
        : monthStart;
    final laterEnd = monthEnd;
    if (!laterStart.isAfter(laterEnd)) {
      widgets.addAll(
        _buildSection(
          context,
          title: 'LATER',
          rangeLabel: _formatRangeLabel(laterStart, laterEnd),
          dates: _datesInRange(laterStart, laterEnd),
          agendaData: agendaData,
        ),
      );
    }

    if (widgets.isEmpty) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text('No scheduled items in this month.'),
        ),
      );
    }

    return widgets;
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

  List<Widget> _buildSection(
    BuildContext context, {
    required String title,
    required List<DateTime> dates,
    required AgendaData agendaData,
    String? subtitle,
    String? rangeLabel,
  }) {
    final theme = Theme.of(context);

    final dateGroups = <_DateGroup>[];
    for (final date in dates) {
      final items = _itemsForDate(agendaData, date);
      if (items.isEmpty) continue;
      dateGroups.add(_DateGroup(date: date, items: items));
      _dateKeys.putIfAbsent(_dateOnly(date), GlobalKey.new);
    }

    if (dateGroups.isEmpty) return const [];

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle.toUpperCase(),
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
              ],
            ),
          ),
          if (rangeLabel != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                rangeLabel,
                style: theme.textTheme.labelMedium,
              ),
            ),
        ],
      ),
    );

    return [
      header,
      ...dateGroups.map((g) => _buildDateGroup(context, g)),
    ];
  }

  List<AgendaItem> _itemsForDate(AgendaData agendaData, DateTime date) {
    final normalized = _dateOnly(date);
    for (final group in agendaData.groups) {
      if (_dateOnly(group.date) == normalized) return group.items;
    }
    return const [];
  }

  Widget _buildDateGroup(BuildContext context, _DateGroup group) {
    final theme = Theme.of(context);
    final key = _dateKeys[_dateOnly(group.date)]!;

    final dayName = DateFormat.E().format(group.date).toUpperCase();
    final dayNumber = group.date.day.toString();

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 56,
              child: _TimelineMarker(
                dayName: dayName,
                dayNumber: dayNumber,
                color: theme.colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  for (final item in group.items)
                    _buildAgendaItem(context, item),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

    final dayName = DateFormat.E().format(date);
    final dayNumber = date.day.toString();

    return InkWell(
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
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayNumber,
              style: theme.textTheme.titleLarge?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
                fontWeight: FontWeight.bold,
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
    );
  }
}

class _TimelineMarker extends StatelessWidget {
  const _TimelineMarker({
    required this.dayName,
    required this.dayNumber,
    required this.color,
  });

  final String dayName;
  final String dayNumber;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Positioned.fill(
          left: 27,
          child: Container(
            width: 2,
            color: color,
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Text(dayName, style: theme.textTheme.labelSmall),
                const SizedBox(height: 4),
                Text(
                  dayNumber,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'ONGOING',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
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
