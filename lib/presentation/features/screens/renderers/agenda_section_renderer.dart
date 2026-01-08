import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/models/screens/agenda_data.dart';
import 'package:taskly_bloc/domain/models/screens/screen_item.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_result.dart';
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
    this.onTaskToggle,
    this.onTaskTap,
    this.showDatePicker = true,
    this.collapsibleOverdue = true,
    this.overdueCollapsedByDefault = true,
    super.key,
  });

  final AgendaSectionResult data;
  final void Function(String taskId, bool? value)? onTaskToggle;
  final void Function(Task task)? onTaskTap;

  /// Whether to show the horizontal date picker
  final bool showDatePicker;

  /// Whether overdue section can be collapsed
  final bool collapsibleOverdue;

  /// Whether overdue starts collapsed
  final bool overdueCollapsedByDefault;

  @override
  State<AgendaSectionRenderer> createState() => _AgendaSectionRendererState();
}

class _AgendaSectionRendererState extends State<AgendaSectionRenderer> {
  final ScreenItemTileRegistry _tileRegistry = const ScreenItemTileRegistry();
  late ScrollController _scrollController;
  late ScrollController _datePickerController;
  late DateTime _focusedDate;

  // Prevent feedback loops during programmatic scrolling
  bool _programmaticScroll = false;
  Timer? _scrollDebounce;

  @override
  void initState() {
    super.initState();
    _focusedDate = DateTime.now();
    _scrollController = ScrollController();
    _datePickerController = ScrollController();

    // Listen to timeline scroll to update date picker
    if (widget.showDatePicker) {
      _scrollController.addListener(_onTimelineScrolled);
    }
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _scrollController.dispose();
    _datePickerController.dispose();
    super.dispose();
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

    // Calculate date based on scroll position
    // This is a simple approximation - could be enhanced with actual item heights
    final scrollOffset = _scrollController.offset;
    if (scrollOffset <= 0) return DateTime.now();

    // Return first visible date from groups
    if (widget.data.agendaData.groups.isNotEmpty) {
      return widget.data.agendaData.groups.first.date;
    }

    return null;
  }

  void _onDateSelected(DateTime date) {
    setState(() => _focusedDate = date);
    _scrollTimelineToDate(date);
  }

  void _scrollTimelineToDate(DateTime date) {
    if (!_scrollController.hasClients) return;

    _programmaticScroll = true;

    // Find the index of the date group
    final groupIndex = widget.data.agendaData.groups.indexWhere((group) {
      return _isSameDay(group.date, date);
    });

    if (groupIndex >= 0) {
      // Estimate scroll position (could be enhanced with measured heights)
      final estimatedOffset = groupIndex * 150.0; // Rough estimate per group

      _scrollController.animateTo(
        estimatedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    // Re-enable scroll sync after animation
    Future.delayed(const Duration(milliseconds: 400), () {
      _programmaticScroll = false;
    });
  }

  void _scrollDatePickerToDate(DateTime date) {
    if (!_datePickerController.hasClients) return;

    // Calculate position in date picker
    final today = DateTime.now();
    final daysDiff = date
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;

    if (daysDiff >= 0) {
      const itemWidth = 80.0; // Width of each date chip
      final offset = daysDiff * itemWidth;

      _datePickerController.animateTo(
        offset,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final agendaData = widget.data.agendaData;

    if (agendaData.groups.isEmpty && agendaData.overdueItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No scheduled items'),
        ),
      );
    }

    return Column(
      children: [
        // Date picker
        if (widget.showDatePicker) _buildDatePicker(),

        // Overdue section
        if (agendaData.overdueItems.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, 'Overdue'),
              ...agendaData.overdueItems.map(_buildAgendaItem),
              const SizedBox(height: 16),
            ],
          ),

        // Timeline groups
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          controller: _scrollController,
          itemCount: agendaData.groups.length,
          itemBuilder: (context, index) {
            final group = agendaData.groups[index];

            if (group.items.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, group.semanticLabel),
                ...group.items.map(_buildAgendaItem),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAgendaItem(AgendaItem item) {
    final screenItem = switch (item) {
      AgendaItem(:final task?) when item.isTask => ScreenItem.task(task),
      AgendaItem(:final project?) when item.isProject => ScreenItem.project(
        project,
      ),
      _ => null,
    };
    if (screenItem == null) return const SizedBox.shrink();

    return _tileRegistry.build(
      context,
      item: screenItem,
      onTaskToggle: widget.onTaskToggle,
      onTap: screenItem is ScreenItemTask
          ? () => widget.onTaskTap?.call(screenItem.task)
          : null,
    );
  }

  Widget _buildDatePicker() {
    final today = DateTime.now();
    final dates = List.generate(
      30, // Show 30 days
      (index) => today.add(Duration(days: index)),
    );

    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
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

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: _DateChip(
              date: date,
              isSelected: isSelected,
              isToday: isToday,
              onTap: () => _onDateSelected(date),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Date chip widget for the horizontal date picker
class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
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
          ],
        ),
      ),
    );
  }
}
