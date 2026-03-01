import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_history_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

Future<void> showJournalFiltersSheet(
  BuildContext context, {
  required JournalHistoryFilters filters,
  required List<TrackerDefinition> factorDefinitions,
  required List<TrackerGroup> factorGroups,
  required void Function(JournalHistoryFilters) onApply,
}) async {
  DateTime? rangeStart = filters.rangeStart;
  DateTime? rangeEnd = filters.rangeEnd;
  final selectedFactorIds = <String>{...filters.factorTrackerIds};
  String? factorGroupId = filters.factorGroupId;
  final now = context.read<NowService>().nowLocal();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final dateLabel = rangeStart == null || rangeEnd == null
              ? context.l10n.journalAnyTimeLabel
              : '${DateFormat.yMMMd().format(rangeStart!.toLocal())} - '
                    '${DateFormat.yMMMd().format(rangeEnd!.toLocal())}';

          DateTime dayOnlyLocal(DateTime d) => DateTime(d.year, d.month, d.day);
          final today = dayOnlyLocal(now);
          final last7Start = today.subtract(const Duration(days: 6));
          final thisMonthStart = DateTime(today.year, today.month);
          final thisMonthEnd = DateTime(today.year, today.month + 1, 0);
          final isAnyTime = rangeStart == null || rangeEnd == null;
          final isToday =
              rangeStart != null &&
              rangeEnd != null &&
              dayOnlyLocal(rangeStart!) == today &&
              dayOnlyLocal(rangeEnd!) == today;
          final isLast7 =
              rangeStart != null &&
              rangeEnd != null &&
              dayOnlyLocal(rangeStart!) == last7Start &&
              dayOnlyLocal(rangeEnd!) == today;
          final isThisMonth =
              rangeStart != null &&
              rangeEnd != null &&
              dayOnlyLocal(rangeStart!) == thisMonthStart &&
              dayOnlyLocal(rangeEnd!) == thisMonthEnd;

          return Container(
            padding: EdgeInsets.only(
              left: TasklyTokens.of(context).spaceLg,
              right: TasklyTokens.of(context).spaceLg,
              top: TasklyTokens.of(context).spaceLg,
              bottom:
                  MediaQuery.viewInsetsOf(context).bottom +
                  TasklyTokens.of(context).spaceLg,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(TasklyTokens.of(context).radiusXxl),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.filtersLabel,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          rangeStart = null;
                          rangeEnd = null;
                          factorGroupId = null;
                          selectedFactorIds.clear();
                        });
                      },
                      child: Text(context.l10n.resetLabel),
                    ),
                  ],
                ),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(width: TasklyTokens.of(context).spaceXs),
                    Text(
                      context.l10n.dateRangeLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: TasklyTokens.of(context).spaceXs),
                Wrap(
                  spacing: TasklyTokens.of(context).spaceXs,
                  runSpacing: TasklyTokens.of(context).spaceXs,
                  children: [
                    ChoiceChip(
                      label: Text(context.l10n.journalAnyTimeLabel),
                      selected: isAnyTime,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isAnyTime
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) {
                        setState(() {
                          rangeStart = null;
                          rangeEnd = null;
                        });
                      },
                    ),
                    ChoiceChip(
                      label: Text(context.l10n.dateToday),
                      selected: isToday,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isToday
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) {
                        setState(() {
                          rangeStart = today;
                          rangeEnd = today;
                        });
                      },
                    ),
                    ChoiceChip(
                      label: Text(context.l10n.last7DaysLabel),
                      selected: isLast7,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isLast7
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) {
                        setState(() {
                          rangeStart = last7Start;
                          rangeEnd = today;
                        });
                      },
                    ),
                    ChoiceChip(
                      label: Text(context.l10n.thisMonthLabel),
                      selected: isThisMonth,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isThisMonth
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) {
                        setState(() {
                          rangeStart = thisMonthStart;
                          rangeEnd = thisMonthEnd;
                        });
                      },
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.calendar_today, size: 16),
                      label: Text(context.l10n.customLabel),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          initialDateRange:
                              rangeStart != null && rangeEnd != null
                              ? DateTimeRange(
                                  start: rangeStart!,
                                  end: rangeEnd!,
                                )
                              : null,
                        );
                        if (picked == null) return;
                        setState(() {
                          rangeStart = picked.start;
                          rangeEnd = picked.end;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: TasklyTokens.of(context).spaceXs),
                Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                DropdownButtonFormField<String?>(
                  value: factorGroupId,
                  decoration: InputDecoration(
                    labelText: context.l10n.groupsTitle,
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(context.l10n.allLabel),
                    ),
                    for (final group in factorGroups)
                      DropdownMenuItem<String?>(
                        value: group.id,
                        child: Text(group.name),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      factorGroupId = value;
                    });
                  },
                ),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                Text(
                  context.l10n.journalTrackersTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: TasklyTokens.of(context).spaceXs),
                Wrap(
                  spacing: TasklyTokens.of(context).spaceXs,
                  runSpacing: TasklyTokens.of(context).spaceXs,
                  children: [
                    for (final definition in factorDefinitions)
                      FilterChip(
                        avatar: Icon(
                          Icons.circle,
                          size: 8,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        label: Text(definition.name),
                        selected: selectedFactorIds.contains(definition.id),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedFactorIds.add(definition.id);
                            } else {
                              selectedFactorIds.remove(definition.id);
                            }
                          });
                        },
                      ),
                  ],
                ),
                SizedBox(height: TasklyTokens.of(context).spaceMd),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(context.l10n.cancelLabel),
                      ),
                    ),
                    SizedBox(width: TasklyTokens.of(context).spaceSm),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          onApply(
                            filters.copyWith(
                              rangeStart: rangeStart,
                              rangeEnd: rangeEnd,
                              factorGroupId: factorGroupId,
                              factorTrackerIds: selectedFactorIds,
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.filter_alt_outlined),
                        label: Text(
                          '${context.l10n.applyLabel} (${selectedFactorIds.length + (factorGroupId == null ? 0 : 1) + (rangeStart != null && rangeEnd != null ? 1 : 0)})',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
