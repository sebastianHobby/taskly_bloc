import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_add_entry_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/tracker_input_widgets.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

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
    final now = context.read<NowService>().nowLocal();
    final day = selectedDayLocal ?? DateTime(now.year, now.month, now.day);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return BlocProvider<JournalAddEntryBloc>(
          create: (context) => JournalAddEntryBloc(
            repository: context.read<JournalRepositoryContract>(),
            errorReporter: context.read<AppErrorReporter>(),
            nowUtc: context.read<NowService>().nowUtc,
            preselectedTrackerIds: preselectedTrackerIds,
          )..add(JournalAddEntryStarted(selectedDayLocal: day)),
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
    return BlocConsumer<JournalAddEntryBloc, JournalAddEntryState>(
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

        List<TrackerGroup?> groupOptions() {
          return <TrackerGroup?>[null, ...state.groups];
        }

        List<TrackerDefinition> trackersForGroup(String? groupId) {
          final key = groupId ?? '';
          return state.trackers
              .where((d) => (d.groupId ?? '') == key)
              .toList(growable: false)
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        }

        Widget trackerInputRow({required TrackerDefinition d}) {
          final currentValue = state.entryValues[d.id];

          void setValue(Object? v) {
            context.read<JournalAddEntryBloc>().add(
              JournalAddEntryEntryValueChanged(
                trackerId: d.id,
                value: v,
              ),
            );
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

            return TrackerQuantityInput(
              label: d.name,
              value: intValue,
              min: min,
              max: max,
              step: step,
              enabled: !isSaving,
              onChanged: setValue,
              onClear: () => setValue(null),
            );
          }

          if (valueType == 'choice') {
            return FutureBuilder<List<TrackerDefinitionChoice>>(
              future: context.read<JournalAddEntryBloc>().getChoices(d.id),
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
                    SizedBox(height: TasklyTokens.of(context).spaceSm),
                    if (choices.isEmpty)
                      Text(
                        'No options',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      TrackerChoiceInput(
                        choices: choices,
                        selectedKey: selectedKey,
                        enabled: !isSaving,
                        onSelected: setValue,
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

        return Padding(
          padding: EdgeInsets.all(TasklyTokens.of(context).spaceLg),
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
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                if (isLoading)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: TasklyTokens.of(context).spaceLg,
                    ),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  Text('Mood', style: theme.textTheme.titleMedium),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  _MoodScalePicker(
                    value: state.mood,
                    enabled: !isSaving,
                    onChanged: (value) => context
                        .read<JournalAddEntryBloc>()
                        .add(JournalAddEntryMoodChanged(value)),
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !isSaving,
                    onChanged: (v) => context.read<JournalAddEntryBloc>().add(
                      JournalAddEntryNoteChanged(v),
                    ),
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  Text('Trackers', style: theme.textTheme.titleMedium),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  for (final group in groupOptions())
                    Builder(
                      builder: (context) {
                        final groupId = group?.id;
                        final inGroup = trackersForGroup(groupId);
                        if (inGroup.isEmpty) return SizedBox.shrink();

                        final groupName = groupId == null
                            ? 'Ungrouped'
                            : (groupsById[groupId]?.name ?? 'Ungrouped');

                        return ExpansionTile(
                          initiallyExpanded: true,
                          title: Text(groupName),
                          childrenPadding: EdgeInsets.only(
                            left: TasklyTokens.of(context).spaceLg,
                            right: TasklyTokens.of(context).spaceLg,
                            bottom: TasklyTokens.of(context).spaceSm,
                          ),
                          children: [
                            for (final d in inGroup) ...[
                              trackerInputRow(d: d),
                              const Divider(height: 1),
                            ],
                          ],
                        );
                      },
                    ),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isSaving
                          ? null
                          : () => context.read<JournalAddEntryBloc>().add(
                              const JournalAddEntrySaveRequested(),
                            ),
                      icon: isSaving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Save'),
                    ),
                  ),
                  SizedBox(height: TasklyTokens.of(context).spaceSm),
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
        borderRadius: BorderRadius.circular(TasklyTokens.of(context).radiusMd),
        child: Container(
          width: 64,
          padding: EdgeInsets.symmetric(
            horizontal: TasklyTokens.of(context).spaceLg,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(
              TasklyTokens.of(context).radiusMd,
            ),
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
              SizedBox(height: TasklyTokens.of(context).spaceSm),
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
    MoodRating.veryLow => colorScheme.error,
    MoodRating.low => colorScheme.secondary,
    MoodRating.neutral => colorScheme.onSurfaceVariant,
    MoodRating.good => colorScheme.tertiary,
    MoodRating.excellent => colorScheme.primary,
  };
}
