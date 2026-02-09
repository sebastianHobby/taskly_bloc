import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/shared/utils/mood_label_utils.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_entry_editor_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_daily_detail_sheet.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/tracker_input_widgets.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalEntryEditorRoutePage extends StatefulWidget {
  const JournalEntryEditorRoutePage({
    required this.entryId,
    required this.preselectedTrackerIds,
    super.key,
  });

  final String? entryId;
  final Set<String> preselectedTrackerIds;

  @override
  State<JournalEntryEditorRoutePage> createState() =>
      _JournalEntryEditorRoutePageState();
}

class _JournalEntryEditorRoutePageState
    extends State<JournalEntryEditorRoutePage> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JournalEntryEditorBloc>(
      create: (context) => JournalEntryEditorBloc(
        repository: context.read<JournalRepositoryContract>(),
        errorReporter: context.read<AppErrorReporter>(),
        entryId: widget.entryId,
        preselectedTrackerIds: widget.preselectedTrackerIds,
        nowUtc: context.read<NowService>().nowUtc,
      )..add(const JournalEntryEditorStarted()),
      child: BlocConsumer<JournalEntryEditorBloc, JournalEntryEditorState>(
        listenWhen: (prev, next) =>
            prev.status.runtimeType != next.status.runtimeType,
        listener: (context, state) {
          switch (state.status) {
            case JournalEntryEditorSaved():
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.journalSavedLogSnack),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.pop(true);
            case JournalEntryEditorError(:final message):
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            default:
              break;
          }
        },
        builder: (context, state) {
          final theme = Theme.of(context);
          final l10n = context.l10n;
          final isSaving = state.status is JournalEntryEditorSaving;
          final isLoading = state.status is JournalEntryEditorLoading;
          final canSave =
              !isSaving &&
              state.mood != null &&
              (!state.isEditingExisting || state.isDirty);

          if (_noteController.text != state.note && !isLoading) {
            _noteController.text = state.note;
            _noteController.selection = TextSelection.fromPosition(
              TextPosition(offset: _noteController.text.length),
            );
          }

          List<TrackerGroup?> groupOptions() {
            return <TrackerGroup?>[null, ...state.groups];
          }

          String groupLabel(TrackerGroup? group) =>
              group?.name ?? l10n.journalGroupUngrouped;

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
              context.read<JournalEntryEditorBloc>().add(
                JournalEntryEditorEntryValueChanged(
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
                          onChanged: isSaving
                              ? null
                              : (v) => setValue(v.round()),
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
                future: context.read<JournalEntryEditorBloc>().getChoices(d.id),
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
                          l10n.journalNoOptions,
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
              subtitle: Text(l10n.journalUnsupportedValueType(d.valueType)),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(
                state.isEditingExisting
                    ? l10n.journalEditLogTitle
                    : l10n.journalNewLogTitle,
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  TasklyTokens.of(context).spaceLg,
                  TasklyTokens.of(context).spaceSm2,
                  TasklyTokens.of(context).spaceLg,
                  TasklyTokens.of(context).spaceLg,
                ),
                child: FilledButton.icon(
                  onPressed: canSave
                      ? () => context.read<JournalEntryEditorBloc>().add(
                          const JournalEntryEditorSaveRequested(),
                        )
                      : null,
                  icon: isSaving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(l10n.journalSaveLogButton),
                ),
              ),
            ),
            body: SafeArea(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: EdgeInsets.fromLTRB(
                        TasklyTokens.of(context).spaceMd,
                        TasklyTokens.of(context).spaceMd,
                        TasklyTokens.of(context).spaceMd,
                        TasklyTokens.of(context).spaceXxl * 3 +
                            TasklyTokens.of(context).spaceXl,
                      ),
                      children: [
                        Text(
                          l10n.journalMoodLabel,
                          style: theme.textTheme.titleMedium,
                        ),
                        SizedBox(height: TasklyTokens.of(context).spaceSm),
                        _MoodScalePicker(
                          value: state.mood,
                          enabled: !isSaving,
                          onChanged: (m) => context
                              .read<JournalEntryEditorBloc>()
                              .add(JournalEntryEditorMoodChanged(m)),
                        ),
                        SizedBox(height: TasklyTokens.of(context).spaceSm),
                        TextField(
                          controller: _noteController,
                          onChanged: (v) => context
                              .read<JournalEntryEditorBloc>()
                              .add(JournalEntryEditorNoteChanged(v)),
                          maxLines: 6,
                          enabled: !isSaving,
                          decoration: InputDecoration(
                            labelText: l10n.journalNoteOptionalLabel,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: TasklyTokens.of(context).spaceSm),
                        Text(
                          l10n.journalRightNowTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                        SizedBox(height: TasklyTokens.of(context).spaceSm),
                        Text(
                          l10n.journalRightNowSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: TasklyTokens.of(context).spaceSm),
                        for (final group in groupOptions())
                          Builder(
                            builder: (context) {
                              final groupId = group?.id;
                              final inGroup = trackersForGroup(groupId);
                              if (inGroup.isEmpty) {
                                return SizedBox.shrink();
                              }

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
                        _AllDaySummarySection(
                          items: state.dailySummaryItems,
                          selectedDayLocal: state.selectedDayLocal,
                          onShowMore: () => JournalDailyDetailSheet.show(
                            context: context,
                            selectedDayLocal: state.selectedDayLocal,
                            readOnly: false,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
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
      label: context.l10n.journalMoodSemanticsLabel(
        mood.localizedLabel(context.l10n),
      ),
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

class _AllDaySummarySection extends StatelessWidget {
  const _AllDaySummarySection({
    required this.items,
    required this.selectedDayLocal,
    required this.onShowMore,
  });

  final List<JournalDailySummaryItem> items;
  final DateTime selectedDayLocal;
  final VoidCallback onShowMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);
    final hasItems = items.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.journalAllDayTitle,
          style: theme.textTheme.titleMedium,
        ),
        SizedBox(height: tokens.spaceSm),
        if (!hasItems)
          Text(
            context.l10n.journalAllDayEmpty,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Column(
            children: [
              for (final item in items)
                Padding(
                  padding: EdgeInsets.only(bottom: tokens.spaceXs),
                  child: Row(
                    children: [
                      Expanded(child: Text(item.label)),
                      Text(
                        item.value,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onShowMore,
            child: Text(context.l10n.journalShowAll),
          ),
        ),
      ],
    );
  }
}
