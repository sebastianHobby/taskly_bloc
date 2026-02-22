import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_entry_editor_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_manage_library_bloc.dart';
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
  bool _manageMode = false;
  String? _expandedDailyGroupId;
  String? _expandedEntryGroupId;

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

  Future<void> _openManageGroupMenu(
    BuildContext context,
    TrackerGroup group,
    JournalManageLibraryBloc manageBloc,
  ) async {
    final l10n = context.l10n;
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.renameLabel),
                onTap: () => Navigator.of(context).pop('rename'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.deleteLabel),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
            ],
          ),
        );
      },
    );
    if (action == null || !context.mounted) return;

    if (action == 'rename') {
      final name = await _showNameDialog(
        context,
        title: l10n.journalRenameGroupTitle,
        initialValue: group.name,
      );
      if (name == null || name.trim().isEmpty || !context.mounted) return;
      await manageBloc.renameGroup(group: group, name: name.trim());
      return;
    }

    if (action == 'delete') {
      await manageBloc.deleteGroup(group);
    }
  }

  Future<String?> _showNameDialog(
    BuildContext context, {
    required String title,
    String initialValue = '',
  }) async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => _JournalNameDialog(
        title: title,
        initialValue: initialValue,
        labelText: dialogContext.l10n.nameLabel,
        cancelLabel: dialogContext.l10n.cancelLabel,
        submitLabel: dialogContext.l10n.saveLabel,
      ),
    );
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
        BlocProvider<JournalManageLibraryBloc>(
          create: (context) => JournalManageLibraryBloc(
            repository: repository,
            errorReporter: errorReporter,
            nowUtc: nowService.nowUtc,
          ),
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
          final manageBloc = context.read<JournalManageLibraryBloc>();

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

          List<TrackerDefinition> trackersForGroup(
            List<TrackerDefinition> source,
            String? groupId,
          ) {
            final key = groupId ?? '';
            return source
                .where((d) => (d.groupId ?? '') == key)
                .toList(growable: false)
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
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
                  child: Text(
                    definition.name,
                    style: theme.textTheme.titleSmall,
                  ),
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
                Text(definition.name, style: theme.textTheme.titleSmall),
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
                    Text(definition.name, style: theme.textTheme.titleSmall),
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

          Widget groupCards({
            required String title,
            required List<TrackerDefinition> source,
            required Map<String, Object?> values,
            required String? expandedGroupId,
            required ValueChanged<String?> onExpandedGroupChanged,
            required bool isDaily,
          }) {
            final groups = groupOptions();
            final cards = <Widget>[];
            for (var index = 0; index < groups.length; index++) {
              final group = groups[index];
              final trackers = trackersForGroup(source, group?.id);
              if (trackers.isEmpty) continue;
              final groupId = group?.id ?? '__ungrouped__';
              final isExpanded = expandedGroupId == groupId;
              final selectedCount = trackers
                  .where((d) => _hasMeaningfulValue(values[d.id]))
                  .length;

              cards.add(
                Card(
                  child: ExpansionTile(
                    key: ValueKey(
                      'journal_group_${title}_${groupId}_$isExpanded',
                    ),
                    initiallyExpanded: isExpanded,
                    onExpansionChanged: (open) {
                      onExpandedGroupChanged(open ? groupId : null);
                    },
                    leading: const Icon(Icons.folder_open_outlined),
                    title: Text(
                      groupLabel(group),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '$selectedCount/${trackers.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: _manageMode && group != null
                        ? Wrap(
                            spacing: 2,
                            children: [
                              IconButton(
                                tooltip: l10n.moveUpLabel,
                                onPressed: isSaving || index == 0
                                    ? null
                                    : () => manageBloc.reorderGroups(
                                        groupId: group.id,
                                        direction: -1,
                                      ),
                                icon: const Icon(Icons.arrow_upward),
                              ),
                              IconButton(
                                tooltip: l10n.moveDownLabel,
                                onPressed:
                                    isSaving || index == groups.length - 1
                                    ? null
                                    : () => manageBloc.reorderGroups(
                                        groupId: group.id,
                                        direction: 1,
                                      ),
                                icon: const Icon(Icons.arrow_downward),
                              ),
                              IconButton(
                                tooltip: l10n.manageLabel,
                                onPressed: isSaving
                                    ? null
                                    : () => _openManageGroupMenu(
                                        context,
                                        group,
                                        manageBloc,
                                      ),
                                icon: const Icon(Icons.more_horiz),
                              ),
                            ],
                          )
                        : null,
                    childrenPadding: EdgeInsets.fromLTRB(
                      tokens.spaceMd,
                      0,
                      tokens.spaceMd,
                      tokens.spaceMd,
                    ),
                    children: [
                      for (var i = 0; i < trackers.length; i++) ...[
                        trackerInputRow(
                          d: trackers[i],
                          currentValue: values[trackers[i].id],
                          setValue: (value) {
                            if (isDaily) {
                              context.read<JournalEntryEditorBloc>().add(
                                JournalEntryEditorDailyValueChanged(
                                  trackerId: trackers[i].id,
                                  value: value,
                                ),
                              );
                            } else {
                              context.read<JournalEntryEditorBloc>().add(
                                JournalEntryEditorEntryValueChanged(
                                  trackerId: trackers[i].id,
                                  value: value,
                                ),
                              );
                            }
                          },
                          isDaily: isDaily,
                        ),
                        if (i != trackers.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () async {
                        if (_manageMode) {
                          setState(() => _manageMode = false);
                          return;
                        }
                        final name = await _showNameDialog(
                          context,
                          title: l10n.journalNewGroupTitle,
                        );
                        if (!mounted) return;
                        if (name != null && name.trim().isNotEmpty) {
                          await manageBloc.createGroup(name.trim());
                          if (!mounted) return;
                        }
                        setState(() => _manageMode = true);
                      },
                      icon: Icon(_manageMode ? Icons.check : Icons.tune),
                      label: Text(
                        _manageMode ? l10n.doneLabel : l10n.manageLabel,
                      ),
                    ),
                  ],
                ),
                if (cards.isEmpty)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(tokens.spaceMd),
                      child: Text(l10n.journalDailyNoTrackers),
                    ),
                  )
                else
                  ...cards,
              ],
            );
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
                      style: theme.textTheme.titleMedium,
                    ),
                    SizedBox(height: tokens.spaceSm),
                    _MoodScalePicker(
                      value: state.mood,
                      enabled: !isSaving,
                      onChanged: (m) => context
                          .read<JournalEntryEditorBloc>()
                          .add(JournalEntryEditorMoodChanged(m)),
                    ),
                    SizedBox(height: tokens.spaceMd),
                    groupCards(
                      title: l10n.journalAllDayTitle,
                      source: state.dailyTrackers,
                      values: effectiveDailyValues(),
                      expandedGroupId: _expandedDailyGroupId,
                      onExpandedGroupChanged: (value) =>
                          setState(() => _expandedDailyGroupId = value),
                      isDaily: true,
                    ),
                    SizedBox(height: tokens.spaceMd),
                    groupCards(
                      title: l10n.journalRightNowTitle,
                      source: state.trackers,
                      values: state.entryValues,
                      expandedGroupId: _expandedEntryGroupId,
                      onExpandedGroupChanged: (value) =>
                          setState(() => _expandedEntryGroupId = value),
                      isDaily: false,
                    ),
                    SizedBox(height: tokens.spaceMd),
                    ExpansionTile(
                      title: Text(l10n.journalNoteOptionalLabel),
                      initiallyExpanded: state.note.trim().isNotEmpty,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: tokens.spaceSm),
                          child: TextField(
                            controller: _noteController,
                            onChanged: (v) => context
                                .read<JournalEntryEditorBloc>()
                                .add(JournalEntryEditorNoteChanged(v)),
                            maxLines: 4,
                            enabled: !isSaving,
                            decoration: InputDecoration(
                              hintText: l10n.journalRightNowSubtitle,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _JournalNameDialog extends StatefulWidget {
  const _JournalNameDialog({
    required this.title,
    required this.initialValue,
    required this.labelText,
    required this.cancelLabel,
    required this.submitLabel,
  });

  final String title;
  final String initialValue;
  final String labelText;
  final String cancelLabel;
  final String submitLabel;

  @override
  State<_JournalNameDialog> createState() => _JournalNameDialogState();
}

class _JournalNameDialogState extends State<_JournalNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.labelText),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(widget.submitLabel),
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
          width: 64,
          padding: EdgeInsets.symmetric(
            horizontal: TasklyTokens.of(context).spaceLg,
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
