import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_entry_editor_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/utils/tracker_icon_utils.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/tracker_input_widgets.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/utils/mood_label_utils.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalEntryEditorRoutePage extends StatefulWidget {
  const JournalEntryEditorRoutePage({
    required this.entryId,
    required this.preselectedTrackerIds,
    required this.selectedDayLocal,
    this.quickCapture = false,
    super.key,
  });

  final String? entryId;
  final Set<String> preselectedTrackerIds;
  final DateTime? selectedDayLocal;
  final bool quickCapture;

  static Future<bool?> showQuickCapture(
    BuildContext context, {
    required DateTime selectedDayLocal,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: JournalEntryEditorRoutePage(
            entryId: null,
            preselectedTrackerIds: const <String>{},
            selectedDayLocal: selectedDayLocal,
            quickCapture: true,
          ),
        );
      },
    );
  }

  @override
  State<JournalEntryEditorRoutePage> createState() =>
      _JournalEntryEditorRoutePageState();
}

class _JournalEntryEditorRoutePageState
    extends State<JournalEntryEditorRoutePage> {
  late final TextEditingController _noteController;
  String? _expandedTrackerId;

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

  bool _hasMeaningfulValue(Object? value) {
    return switch (value) {
      null => false,
      final bool v => v,
      final String v => v.trim().isNotEmpty,
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.read<JournalRepositoryContract>();
    final errorReporter = context.read<AppErrorReporter>();
    final nowService = context.read<NowService>();

    return MultiBlocProvider(
      providers: [
        BlocProvider<JournalEntryEditorBloc>(
          create: (context) => JournalEntryEditorBloc(
            repository: repository,
            errorReporter: errorReporter,
            entryId: widget.entryId,
            preselectedTrackerIds: widget.preselectedTrackerIds,
            nowUtc: nowService.nowUtc,
            selectedDayLocal: widget.selectedDayLocal,
          )..add(const JournalEntryEditorStarted()),
        ),
      ],
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
          final tokens = TasklyTokens.of(context);
          final isSaving = state.status is JournalEntryEditorSaving;
          final isLoading = state.status is JournalEntryEditorLoading;
          final canSave = !isSaving && state.mood != null;

          if (_noteController.text != state.note && !isLoading) {
            _noteController.text = state.note;
            _noteController.selection = TextSelection.fromPosition(
              TextPosition(offset: _noteController.text.length),
            );
          }

          Map<String, Object?> effectiveDailyValues() {
            final out = <String, Object?>{};
            for (final d in state.dailyTrackers) {
              if (state.dailyDraftValues.containsKey(d.id)) {
                out[d.id] = state.dailyDraftValues[d.id];
              } else {
                out[d.id] = state.dayStateByTrackerId[d.id]?.value;
              }
            }
            return out;
          }

          Widget boolInputRow({
            required TrackerDefinition definition,
            required bool value,
            required ValueChanged<bool> onChanged,
          }) {
            return Row(
              children: [
                Expanded(
                  child: _TrackerTitle(definition: definition),
                ),
                ToggleButtons(
                  isSelected: [!value, value],
                  constraints: const BoxConstraints(
                    minHeight: 40,
                    minWidth: 60,
                  ),
                  borderRadius: BorderRadius.circular(tokens.radiusPill),
                  onPressed: isSaving ? null : (index) => onChanged(index == 1),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: tokens.spaceXs),
                      child: Text(l10n.offLabel),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: tokens.spaceXs),
                      child: Text(l10n.onLabel),
                    ),
                  ],
                ),
              ],
            );
          }

          Widget ratingInputRow({
            required TrackerDefinition definition,
            required Object? currentValue,
            required ValueChanged<Object?> onChanged,
          }) {
            final min = definition.minInt ?? 1;
            final max = definition.maxInt ?? 5;
            final intValue = switch (currentValue) {
              final int v => v,
              final double v => v.round(),
              _ => min,
            };
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TrackerTitle(definition: definition),
                SizedBox(height: tokens.spaceSm),
                Wrap(
                  spacing: tokens.spaceSm,
                  children: [
                    for (var i = min; i <= max; i++)
                      ChoiceChip(
                        label: Text('$i'),
                        selected: intValue == i,
                        onSelected: isSaving ? null : (_) => onChanged(i),
                      ),
                  ],
                ),
              ],
            );
          }

          Widget choiceInput({
            required TrackerDefinition definition,
            required Object? currentValue,
            required ValueChanged<Object?> onSelected,
          }) {
            return FutureBuilder<List<TrackerDefinitionChoice>>(
              future: context.read<JournalEntryEditorBloc>().getChoices(
                definition.id,
              ),
              builder: (context, snapshot) {
                final choices =
                    snapshot.data ?? const <TrackerDefinitionChoice>[];
                final selectedKey = currentValue is String
                    ? currentValue
                    : null;
                if (choices.isEmpty) {
                  return Text(
                    l10n.journalNoOptions,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TrackerTitle(definition: definition),
                    SizedBox(height: tokens.spaceSm),
                    TrackerChoiceInput(
                      choices: choices,
                      selectedKey: selectedKey,
                      enabled: !isSaving,
                      onSelected: onSelected,
                    ),
                  ],
                );
              },
            );
          }

          Widget trackerInputRow({
            required TrackerDefinition d,
            required Object? currentValue,
            required ValueChanged<Object?> setValue,
            required bool isDaily,
          }) {
            final valueType = d.valueType.trim().toLowerCase();
            final valueKind = (d.valueKind ?? '').trim().toLowerCase();
            if (valueType == 'yes_no' || valueKind == 'boolean') {
              final boolValue = (currentValue is bool) && currentValue;
              return boolInputRow(
                definition: d,
                value: boolValue,
                onChanged: (v) => setValue(v),
              );
            }
            if (valueType == 'rating') {
              return ratingInputRow(
                definition: d,
                currentValue: currentValue,
                onChanged: setValue,
              );
            }
            if (valueType == 'quantity') {
              final intValue = switch (currentValue) {
                final int v => v,
                final double v => v.round(),
                _ => 0,
              };
              return TrackerQuantityInput(
                label: d.name,
                value: intValue,
                min: d.minInt,
                max: d.maxInt,
                step: d.stepInt ?? 1,
                enabled: !isSaving,
                onChanged: (v) {
                  if (!isDaily) {
                    setValue(v);
                    return;
                  }
                  final delta = v - intValue;
                  if (delta != 0) {
                    context.read<JournalEntryEditorBloc>().add(
                      JournalEntryEditorDailyDeltaAdded(
                        trackerId: d.id,
                        delta: delta,
                      ),
                    );
                  }
                },
                onClear: isDaily ? null : () => setValue(null),
              );
            }
            if (valueType == 'choice') {
              return choiceInput(
                definition: d,
                currentValue: currentValue,
                onSelected: setValue,
              );
            }
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(d.name),
              subtitle: Text(l10n.journalUnsupportedValueType(d.valueType)),
            );
          }

          final dailyTrackers = [...state.dailyTrackers]
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          final entryTrackers = [...state.trackers]
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          final dailyValues = effectiveDailyValues();
          final hasMood = state.mood != null;

          String dailyTrackerValueLabel({
            required TrackerDefinition definition,
            required Object? value,
          }) {
            final valueType = definition.valueType.trim().toLowerCase();
            final valueKind = (definition.valueKind ?? '').trim().toLowerCase();
            if (valueType == 'yes_no' || valueKind == 'boolean') {
              final v = value is bool && value;
              return v ? l10n.onLabel : l10n.offLabel;
            }
            if (valueType == 'rating') {
              final min = definition.minInt ?? 1;
              final max = definition.maxInt ?? 5;
              final rating = switch (value) {
                final int v => v,
                final double v => v.round(),
                _ => min,
              };
              return '$rating/$max';
            }
            if (valueType == 'quantity') {
              final quantity = switch (value) {
                final int v => v,
                final double v => v.round(),
                _ => 0,
              };
              return '$quantity';
            }
            if (valueType == 'choice') {
              return (value is String && value.trim().isNotEmpty)
                  ? value
                  : l10n.journalNotSetLabel;
            }
            return l10n.journalNotSetLabel;
          }

          Widget trackerRowTile({
            required TrackerDefinition definition,
            required bool isDaily,
          }) {
            final value = isDaily
                ? dailyValues[definition.id]
                : state.entryValues[definition.id];
            final expanded = hasMood && _expandedTrackerId == definition.id;
            final canExpand = hasMood && !isSaving;
            final valueLabel = _hasMeaningfulValue(value)
                ? dailyTrackerValueLabel(definition: definition, value: value)
                : l10n.journalNotSetLabel;

            return Container(
              margin: EdgeInsets.only(bottom: tokens.spaceXs),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(tokens.radiusMd),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(tokens.radiusMd),
                    onTap: canExpand
                        ? () {
                            setState(() {
                              _expandedTrackerId = expanded
                                  ? null
                                  : definition.id;
                            });
                          }
                        : null,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spaceMd,
                        vertical: tokens.spaceSm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            trackerIconData(definition),
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: tokens.spaceSm),
                          Expanded(
                            child: Text(
                              definition.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            valueLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(width: tokens.spaceXxs),
                          Icon(
                            expanded
                                ? Icons.keyboard_arrow_up
                                : Icons.chevron_right,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (expanded) ...[
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    Padding(
                      padding: EdgeInsets.all(tokens.spaceMd),
                      child: trackerInputRow(
                        d: definition,
                        currentValue: value,
                        setValue: (updatedValue) {
                          final bloc = context.read<JournalEntryEditorBloc>();
                          if (isDaily) {
                            bloc.add(
                              JournalEntryEditorDailyValueChanged(
                                trackerId: definition.id,
                                value: updatedValue,
                              ),
                            );
                          } else {
                            bloc.add(
                              JournalEntryEditorEntryValueChanged(
                                trackerId: definition.id,
                                value: updatedValue,
                              ),
                            );
                          }
                        },
                        isDaily: isDaily,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          Widget moodGateHint() {
            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(tokens.spaceMd),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(tokens.radiusMd),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  SizedBox(width: tokens.spaceSm),
                  Expanded(
                    child: Text(
                      l10n.journalMoodGateHelper,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            );
          }

          Widget trackerGroupCard({
            required String title,
            required IconData icon,
            required List<TrackerDefinition> trackers,
            required bool isDaily,
            required String emptyLabel,
            required String manageRouteKey,
            String? subtitle,
          }) {
            return Card(
              color: theme.colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: theme.colorScheme.primary),
                        SizedBox(width: tokens.spaceXs),
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: tokens.spaceXxs),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    SizedBox(height: tokens.spaceSm),
                    if (trackers.isEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(emptyLabel),
                        trailing: TextButton(
                          onPressed: () =>
                              Routing.pushScreenKey(context, manageRouteKey),
                          child: Text(l10n.manageLabel),
                        ),
                      )
                    else if (!hasMood)
                      moodGateHint()
                    else
                      for (final definition in trackers)
                        trackerRowTile(
                          definition: definition,
                          isDaily: isDaily,
                        ),
                  ],
                ),
              ),
            );
          }

          final groupsById = {for (final g in state.groups) g.id: g};
          final ungrouped =
              entryTrackers
                  .where(
                    (d) =>
                        d.groupId == null || !groupsById.containsKey(d.groupId),
                  )
                  .toList(growable: false)
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          final entryGroups =
              <({String title, List<TrackerDefinition> trackers})>[];
          if (ungrouped.isNotEmpty) {
            entryGroups.add(
              (title: l10n.journalGroupUngrouped, trackers: ungrouped),
            );
          }
          for (final group in state.groups) {
            final inGroup =
                entryTrackers
                    .where((d) => d.groupId == group.id)
                    .toList(growable: false)
                  ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            if (inGroup.isNotEmpty) {
              entryGroups.add((title: group.name, trackers: inGroup));
            }
          }

          final body = isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                    tokens.spaceMd,
                    tokens.spaceMd,
                    tokens.spaceMd,
                    tokens.spaceXxl * 3 + tokens.spaceXl,
                  ),
                  children: [
                    Text(
                      DateFormat.yMMMEd().format(
                        DateTime(
                          state.selectedDayLocal.year,
                          state.selectedDayLocal.month,
                          state.selectedDayLocal.day,
                        ),
                      ),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: tokens.spaceSm),
                    Text(
                      l10n.journalMoodLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: tokens.spaceXxs),
                    Text(
                      l10n.journalMoodPromptSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: tokens.spaceSm2),
                    _MoodScalePicker(
                      value: state.mood,
                      enabled: !isSaving,
                      onChanged: (m) => context
                          .read<JournalEntryEditorBloc>()
                          .add(JournalEntryEditorMoodChanged(m)),
                    ),
                    SizedBox(height: tokens.spaceLg),
                    trackerGroupCard(
                      title: l10n.journalDailyCheckInsTitle,
                      icon: Icons.calendar_today_outlined,
                      trackers: dailyTrackers,
                      isDaily: true,
                      emptyLabel: l10n.journalNoDailyCheckIns,
                      manageRouteKey: 'journal_manage_daily_checkins',
                      subtitle: l10n.journalDailyAppliesTodaySubtitle,
                    ),
                    SizedBox(height: tokens.spaceLg),
                    if (entryGroups.isEmpty)
                      trackerGroupCard(
                        title: l10n.journalTrackersTitle,
                        icon: Icons.tune,
                        trackers: const <TrackerDefinition>[],
                        isDaily: false,
                        emptyLabel: l10n.journalNoEntryTrackers,
                        manageRouteKey: 'journal_manage_trackers',
                      )
                    else
                      for (final group in entryGroups) ...[
                        trackerGroupCard(
                          title: group.title,
                          icon: Icons.tune,
                          trackers: group.trackers,
                          isDaily: false,
                          emptyLabel: l10n.journalNoEntryTrackers,
                          manageRouteKey: 'journal_manage_trackers',
                        ),
                        SizedBox(height: tokens.spaceLg),
                      ],
                    if (hasMood) ...[
                      TextField(
                        controller: _noteController,
                        onChanged: (v) => context
                            .read<JournalEntryEditorBloc>()
                            .add(JournalEntryEditorNoteChanged(v)),
                        maxLines: 4,
                        enabled: !isSaving,
                        decoration: InputDecoration(
                          hintText: l10n.journalWarmNotePlaceholder,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                );

          final saveButton = FilledButton.icon(
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
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.check),
            label: Text(l10n.journalSaveLogButton),
          );

          if (widget.quickCapture) {
            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.spaceMd,
                      tokens.spaceSm,
                      tokens.spaceMd,
                      0,
                    ),
                    child: Row(
                      children: [
                        Text(
                          l10n.journalNewLogTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: l10n.closeLabel,
                          onPressed: () => context.pop(false),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: body),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.spaceMd,
                      0,
                      tokens.spaceMd,
                      tokens.spaceMd,
                    ),
                    child: Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            context.pop(false);
                            Routing.toJournalEntryNew(
                              context,
                              selectedDayLocal: state.selectedDayLocal,
                            );
                          },
                          child: Text(l10n.editLabel),
                        ),
                        SizedBox(width: tokens.spaceSm),
                        Expanded(child: saveButton),
                      ],
                    ),
                  ),
                ],
              ),
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
                  tokens.spaceLg,
                  tokens.spaceSm2,
                  tokens.spaceLg,
                  tokens.spaceLg,
                ),
                child: saveButton,
              ),
            ),
            body: SafeArea(child: body),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 84,
          padding: EdgeInsets.symmetric(
            horizontal: TasklyTokens.of(context).spaceSm,
            vertical: TasklyTokens.of(context).spaceXs,
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
                mood.localizedLabel(context.l10n),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

class _TrackerTitle extends StatelessWidget {
  const _TrackerTitle({required this.definition});

  final TrackerDefinition definition;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          trackerIconData(definition),
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: TasklyTokens.of(context).spaceXs),
        Expanded(
          child: Text(
            definition.name,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
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
