import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_daily_edit_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalDailyDetailSheet extends StatelessWidget {
  const JournalDailyDetailSheet._({
    required this.readOnly,
  });

  static Future<void> show({
    required BuildContext context,
    required DateTime selectedDayLocal,
    required bool readOnly,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return BlocProvider<JournalDailyEditBloc>(
          create: (context) =>
              JournalDailyEditBloc(
                repository: getIt<JournalRepositoryContract>(),
                errorReporter: context.read<AppErrorReporter>(),
                nowUtc: getIt<NowService>().nowUtc,
              )..add(
                JournalDailyEditStarted(selectedDayLocal: selectedDayLocal),
              ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: JournalDailyDetailSheet._(
              readOnly: readOnly,
            ),
          ),
        );
      },
    );
  }

  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JournalDailyEditBloc, JournalDailyEditState>(
      listenWhen: (prev, next) =>
          prev.status.runtimeType != next.status.runtimeType,
      listener: (context, state) {
        if (state.status case final JournalDailyEditError status) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(status.message)),
          );
        }
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        final isSaving = state.status is JournalDailyEditSaving;
        final isLoading = state.status is JournalDailyEditLoading;

        List<TrackerGroup?> groupOptions() {
          return <TrackerGroup?>[null, ...state.groups];
        }

        String groupLabel(TrackerGroup? group) => group?.name ?? 'Ungrouped';

        List<TrackerDefinition> trackersForGroup(String? groupId) {
          final key = groupId ?? '';
          return state.dailyTrackers
              .where((d) => (d.groupId ?? '') == key)
              .toList(growable: false)
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        }

        Object? effectiveValue(String trackerId) {
          if (state.draftValues.containsKey(trackerId)) {
            return state.draftValues[trackerId];
          }
          return state.dayStateByTrackerId[trackerId]?.value;
        }

        Widget trackerInputRow({
          required TrackerDefinition d,
        }) {
          final currentValue = effectiveValue(d.id);
          final disabled = readOnly || isSaving;

          void setValue(Object? v) {
            if (disabled) return;
            context.read<JournalDailyEditBloc>().add(
              JournalDailyEditValueChanged(trackerId: d.id, value: v),
            );
          }

          void addDelta(int delta) {
            if (disabled) return;
            context.read<JournalDailyEditBloc>().add(
              JournalDailyEditDeltaAdded(trackerId: d.id, delta: delta),
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
              onChanged: disabled ? null : setValue,
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
                        onChanged: disabled ? null : (v) => setValue(v.round()),
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
            final step = d.stepInt ?? 1;
            final intValue = switch (currentValue) {
              final int v => v,
              final double v => v.round(),
              _ => 0,
            };

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name, style: theme.textTheme.titleSmall),
                SizedBox(height: TasklyTokens.of(context).spaceSm),
                Row(
                  children: [
                    IconButton(
                      onPressed: disabled ? null : () => addDelta(-step),
                      icon: const Icon(Icons.remove),
                    ),
                    Text('$intValue', style: theme.textTheme.titleMedium),
                    IconButton(
                      onPressed: disabled ? null : () => addDelta(step),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            );
          }

          if (valueType == 'choice') {
            return FutureBuilder<List<TrackerDefinitionChoice>>(
              future: context.read<JournalDailyEditBloc>().getChoices(d.id),
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in choices)
                            ChoiceChip(
                              label: Text(c.label),
                              selected: selectedKey == c.choiceKey,
                              onSelected: disabled
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
                      readOnly ? 'Daily summary' : 'Edit daily',
                      style: theme.textTheme.titleLarge,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
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
                  for (final group in groupOptions())
                    Builder(
                      builder: (context) {
                        final groupId = group?.id;
                        final inGroup = trackersForGroup(groupId);
                        if (inGroup.isEmpty) return SizedBox.shrink();

                        return ExpansionTile(
                          initiallyExpanded: true,
                          title: Text(groupLabel(group)),
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
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
