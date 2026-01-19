import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_add_entry_cubit.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';

class AddLogSheet extends StatelessWidget {
  const AddLogSheet._({
    required this.preselectedTrackerIds,
    required this.selectedDayLocal,
  });

  static Future<void> show({
    required BuildContext context,
    DateTime? selectedDayLocal,
    Set<String> preselectedTrackerIds = const <String>{},
  }) async {
    final day =
        selectedDayLocal ??
        DateTime(
          getIt<NowService>().nowLocal().year,
          getIt<NowService>().nowLocal().month,
          getIt<NowService>().nowLocal().day,
        );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return BlocProvider<JournalAddEntryCubit>(
          create: (context) => JournalAddEntryCubit(
            repository: getIt<JournalRepositoryContract>(),
            errorReporter: context.read<AppErrorReporter>(),
            selectedDayLocal: day,
            nowUtc: getIt<NowService>().nowUtc,
            preselectedTrackerIds: preselectedTrackerIds,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: AddLogSheet._(
              preselectedTrackerIds: preselectedTrackerIds,
              selectedDayLocal: day,
            ),
          ),
        );
      },
    );
  }

  final Set<String> preselectedTrackerIds;
  final DateTime selectedDayLocal;

  @override
  Widget build(BuildContext context) {
    return const _AddLogSheetView();
  }
}

class _AddLogSheetView extends StatefulWidget {
  const _AddLogSheetView();

  @override
  State<_AddLogSheetView> createState() => _AddLogSheetViewState();
}

class _AddLogSheetViewState extends State<_AddLogSheetView> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JournalAddEntryCubit, JournalAddEntryState>(
      listenWhen: (prev, next) =>
          prev.status.runtimeType != next.status.runtimeType,
      listener: (context, state) {
        switch (state.status) {
          case JournalAddEntrySaved():
            Navigator.of(context).pop();
          case JournalAddEntryError(:final message):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          default:
            break;
        }
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        final isSaving = state.status is JournalAddEntrySaving;
        final isLoading = state.status is JournalAddEntryLoading;

        if (_noteController.text != state.note) {
          _noteController.text = state.note;
          _noteController.selection = TextSelection.collapsed(
            offset: _noteController.text.length,
          );
        }

        final groupsById = {for (final g in state.groups) g.id: g};

        bool isDailyScope(TrackerDefinition d) {
          final s = d.scope.trim().toLowerCase();
          return s == 'day' || s == 'daily' || s == 'sleep_night';
        }

        List<TrackerDefinition> scopeTrackers(bool daily) {
          return state.trackers
              .where((d) => d.systemKey != 'mood')
              .where((d) => daily ? isDailyScope(d) : !isDailyScope(d))
              .toList(growable: false)
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        }

        List<String?> groupOrderFor(List<TrackerDefinition> defs) {
          final presentIds = defs.map((d) => d.groupId).toSet();
          final known = state.groups
              .where((g) => presentIds.contains(g.id))
              .toList();
          known.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          final out = <String?>[];
          out.add(null);
          out.addAll(known.map((g) => g.id));
          return out;
        }

        Object? effectiveDailyValue(String trackerId) {
          if (state.dailyValues.containsKey(trackerId)) {
            return state.dailyValues[trackerId];
          }
          return state.dayStateByTrackerId[trackerId]?.value;
        }

        Widget trackerInputRow({
          required TrackerDefinition d,
          required bool daily,
        }) {
          final currentValue = daily
              ? effectiveDailyValue(d.id)
              : state.entryValues[d.id];

          void setValue(Object? v) {
            if (daily) {
              context.read<JournalAddEntryCubit>().setDailyValue(d.id, v);
            } else {
              context.read<JournalAddEntryCubit>().setEntryValue(d.id, v);
            }
          }

          final valueType = d.valueType.trim().toLowerCase();
          final valueKind = (d.valueKind ?? '').trim().toLowerCase();

          if (valueType == 'yes_no' || valueKind == 'boolean') {
            final boolValue = (currentValue is bool) && currentValue;
            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(d.name),
              value: boolValue,
              onChanged: isSaving ? null : setValue,
            );
          }

          if (valueType == 'rating') {
            final min = d.minInt ?? 1;
            final max = d.maxInt ?? 5;
            final step = d.stepInt ?? 1;
            final divisions = ((max - min) ~/ step).clamp(1, 50);

            final intValue = switch (currentValue) {
              final int v => v,
              final double v => v.round(),
              _ => min,
            };

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name, style: theme.textTheme.titleSmall),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: intValue.toDouble().clamp(
                          min.toDouble(),
                          max.toDouble(),
                        ),
                        min: min.toDouble(),
                        max: max.toDouble(),
                        divisions: divisions,
                        onChanged: isSaving ? null : (v) => setValue(v.round()),
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '$intValue',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          if (valueType == 'quantity') {
            final min = d.minInt;
            final max = d.maxInt;
            final step = d.stepInt ?? 1;

            final intValue = switch (currentValue) {
              final int v => v,
              final double v => v.round(),
              _ => 0,
            };

            int clamp(int v) {
              var out = v;
              if (min != null) out = out < min ? min : out;
              if (max != null) out = out > max ? max : out;
              return out;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name, style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    IconButton(
                      onPressed: isSaving
                          ? null
                          : () => setValue(clamp(intValue - step)),
                      icon: const Icon(Icons.remove),
                    ),
                    Text('$intValue', style: theme.textTheme.titleMedium),
                    IconButton(
                      onPressed: isSaving
                          ? null
                          : () => setValue(clamp(intValue + step)),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            );
          }

          if (valueType == 'choice') {
            return FutureBuilder<List<TrackerDefinitionChoice>>(
              future: context.read<JournalAddEntryCubit>().getChoices(d.id),
              builder: (context, snapshot) {
                final choices =
                    snapshot.data ?? const <TrackerDefinitionChoice>[];
                final selectedKey = currentValue is String
                    ? currentValue
                    : null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.name, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    if (choices.isEmpty)
                      Text(
                        'No options',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in choices)
                            ChoiceChip(
                              label: Text(c.label),
                              selected: selectedKey == c.choiceKey,
                              onSelected: isSaving
                                  ? null
                                  : (_) => setValue(c.choiceKey),
                            ),
                        ],
                      ),
                  ],
                );
              },
            );
          }

          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(d.name),
            subtitle: Text('Unsupported: ${d.valueType}'),
          );
        }

        Widget groupedTrackers({required bool daily}) {
          final defs = scopeTrackers(daily);
          if (defs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                daily ? 'No daily trackers yet.' : 'No entry trackers yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          final order = groupOrderFor(defs);
          return Column(
            children: [
              for (final groupId in order)
                Builder(
                  builder: (context) {
                    final groupName = groupId == null
                        ? 'Ungrouped'
                        : (groupsById[groupId]?.name ?? 'Ungrouped');
                    final inGroup = defs
                        .where((d) => (d.groupId ?? '') == (groupId ?? ''))
                        .toList(growable: false);
                    if (inGroup.isEmpty) return const SizedBox.shrink();

                    return ExpansionTile(
                      initiallyExpanded: true,
                      title: Text(groupName),
                      childrenPadding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom: 12,
                      ),
                      children: [
                        for (final d in inGroup) ...[
                          trackerInputRow(d: d, daily: daily),
                          const Divider(height: 1),
                        ],
                      ],
                    );
                  },
                ),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Add entry',
                      style: theme.textTheme.titleLarge,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: isSaving
                          ? null
                          : () => Routing.pushScreenKey(
                              context,
                              'journal_manage_trackers',
                            ),
                      child: const Text('Manage'),
                    ),
                    IconButton(
                      onPressed: isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  Text('Mood', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _MoodScalePicker(
                    value: state.mood,
                    enabled: !isSaving,
                    onChanged: (value) =>
                        context.read<JournalAddEntryCubit>().moodChanged(value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !isSaving,
                    onChanged: (v) =>
                        context.read<JournalAddEntryCubit>().noteChanged(v),
                  ),
                  const SizedBox(height: 8),
                  ExpansionTile(
                    initiallyExpanded: true,
                    title: const Text('Factors'),
                    childrenPadding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      ExpansionTile(
                        initiallyExpanded: true,
                        title: const Text('Daily (applies to the day)'),
                        childrenPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        children: [
                          groupedTrackers(daily: true),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ExpansionTile(
                        initiallyExpanded: true,
                        title: const Text('This entry (momentary)'),
                        childrenPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        children: [
                          groupedTrackers(daily: false),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isSaving
                          ? null
                          : () => context.read<JournalAddEntryCubit>().save(),
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Save'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MoodScalePicker extends StatelessWidget {
  const _MoodScalePicker({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final MoodRating? value;
  final bool enabled;
  final ValueChanged<MoodRating?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final mood in MoodRating.values)
          _MoodOptionButton(
            mood: mood,
            enabled: enabled,
            selected: value == mood,
            onTap: () => onChanged(mood),
          ),
      ],
    );
  }
}

class _MoodOptionButton extends StatelessWidget {
  const _MoodOptionButton({
    required this.mood,
    required this.enabled,
    required this.selected,
    required this.onTap,
  });

  final MoodRating mood;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moodColor = _getMoodColor(mood, theme.colorScheme);
    final bg = selected
        ? moodColor.withValues(alpha: 0.18)
        : theme.colorScheme.surface;
    final border = selected
        ? BorderSide(color: moodColor, width: 2)
        : BorderSide(color: theme.dividerColor);

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: 'Mood: ${mood.label}',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.fromBorderSide(border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mood.emoji,
                style: TextStyle(
                  fontSize: 26,
                  color: enabled ? null : theme.disabledColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${mood.value}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? moodColor
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _getMoodColor(MoodRating mood, ColorScheme colorScheme) {
  return switch (mood) {
    MoodRating.veryLow => Colors.red.shade600,
    MoodRating.low => Colors.orange.shade700,
    MoodRating.neutral => colorScheme.primary,
    MoodRating.good => Colors.teal.shade600,
    MoodRating.excellent => Colors.green.shade700,
  };
}
