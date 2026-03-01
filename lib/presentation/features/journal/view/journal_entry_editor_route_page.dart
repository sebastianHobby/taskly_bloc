import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_entry_editor_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/ui/journal_motion_tokens.dart';
import 'package:taskly_bloc/presentation/features/journal/ui/tracker_value_formatter.dart';
import 'package:taskly_bloc/presentation/features/journal/utils/tracker_icon_utils.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_factor_token.dart';
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
      sheetAnimationStyle: const AnimationStyle(
        duration: kJournalMotionDuration,
        reverseDuration: kJournalMotionDuration,
      ),
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
    extends State<JournalEntryEditorRoutePage>
    with TickerProviderStateMixin {
  late final TextEditingController _noteController;
  String? _expandedTrackerId;
  bool _showPostMoodGroups = false;
  bool _lastHasMood = false;
  Timer? _groupsRevealTimer;
  final Map<String, bool> _quickGroupExpanded = <String, bool>{};
  final Map<String, Map<String, String>> _quickChoiceLabelsByTrackerId =
      <String, Map<String, String>>{};
  final Map<String, List<TrackerDefinitionChoice>>
  _quickChoiceOptionsByTrackerId = <String, List<TrackerDefinitionChoice>>{};
  final Set<String> _quickChoicePreloadInFlight = <String>{};

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _groupsRevealTimer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  void _syncPostMoodReveal(bool hasMood) {
    if (hasMood == _lastHasMood) return;
    _lastHasMood = hasMood;
    _groupsRevealTimer?.cancel();

    if (!hasMood) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _showPostMoodGroups = false;
          _expandedTrackerId = null;
        });
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _showPostMoodGroups = false;
      });
      _groupsRevealTimer = Timer(const Duration(milliseconds: 80), () {
        if (!mounted) return;
        setState(() {
          _showPostMoodGroups = true;
        });
      });
    });
  }

  bool _isOncePerDaySleepTracker(TrackerDefinition definition) {
    final normalized = definition.name.trim().toLowerCase();
    if (definition.scope.trim().toLowerCase() == 'sleep_night') return true;
    if (normalized.contains('sleep quality')) return true;
    if (normalized.contains('sleep duration')) return true;
    return normalized.contains('sleep');
  }

  bool _shouldShowEntryTracker(
    TrackerDefinition definition,
    JournalEntryEditorState state,
  ) {
    if (!_isOncePerDaySleepTracker(definition)) return true;
    final currentValue = state.entryValues[definition.id];
    if (_hasMeaningfulValue(currentValue)) return true;
    return !state.dayEntryTrackerIds.contains(definition.id);
  }

  bool _hasMeaningfulValue(Object? value) {
    return switch (value) {
      null => false,
      final bool v => v,
      final String v => v.trim().isNotEmpty,
      _ => true,
    };
  }

  bool _isBooleanTracker(TrackerDefinition definition) {
    final valueType = definition.valueType.trim().toLowerCase();
    final valueKind = (definition.valueKind ?? '').trim().toLowerCase();
    return valueType == 'yes_no' || valueKind == 'boolean';
  }

  bool _isChoiceTracker(TrackerDefinition definition) {
    final valueType = definition.valueType.trim().toLowerCase();
    return valueType == 'choice' || valueType == 'single_choice';
  }

  bool _isNumericTracker(TrackerDefinition definition) {
    final valueType = definition.valueType.trim().toLowerCase();
    final valueKind = (definition.valueKind ?? '').trim().toLowerCase();
    return valueType == 'quantity' ||
        valueType == 'rating' ||
        valueKind == 'number';
  }

  void _syncQuickGroupExpansionDefaults(
    List<({String title, List<TrackerDefinition> trackers})> groups,
  ) {
    for (final group in groups) {
      _quickGroupExpanded.putIfAbsent(
        group.title,
        () => group.trackers.length <= 5,
      );
    }
  }

  Future<void> _primeQuickChoiceLabels(
    BuildContext context,
    List<({String title, List<TrackerDefinition> trackers})> groups,
  ) async {
    final trackerIds = <String>{};
    for (final group in groups) {
      for (final tracker in group.trackers) {
        if (_isChoiceTracker(tracker)) trackerIds.add(tracker.id);
      }
    }
    if (trackerIds.isEmpty) return;

    final bloc = context.read<JournalEntryEditorBloc>();
    final toLoad = trackerIds
        .where(
          (id) =>
              !_quickChoiceLabelsByTrackerId.containsKey(id) &&
              !_quickChoicePreloadInFlight.contains(id),
        )
        .toList(growable: false);
    if (toLoad.isEmpty) return;

    _quickChoicePreloadInFlight.addAll(toLoad);
    final results = await Future.wait(toLoad.map(bloc.getChoices));
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < toLoad.length; i++) {
        final labels = <String, String>{};
        for (final choice in results[i]) {
          labels[choice.choiceKey] = choice.label;
        }
        _quickChoiceOptionsByTrackerId[toLoad[i]] = results[i];
        _quickChoiceLabelsByTrackerId[toLoad[i]] = labels;
      }
      _quickChoicePreloadInFlight.removeAll(toLoad);
    });
  }

  bool _isFiveLevelChoiceTracker(TrackerDefinition tracker) {
    if (!_isChoiceTracker(tracker)) return false;
    final options = _quickChoiceOptionsByTrackerId[tracker.id] ?? const [];
    if (options.length != 5) return false;
    final labels = options.map((choice) => choice.label.trim()).toSet();
    final keys = options.map((choice) => choice.choiceKey.trim()).toSet();
    const expected = <String>{'1', '2', '3', '4', '5'};
    return labels.containsAll(expected) || keys.containsAll(expected);
  }

  bool _isFiveLevelRatingTracker(TrackerDefinition tracker) {
    final valueType = tracker.valueType.trim().toLowerCase();
    if (valueType != 'rating') return false;
    final min = tracker.minInt ?? 1;
    final max = tracker.maxInt ?? 5;
    final step = tracker.stepInt ?? 1;
    return min == 1 && max == 5 && step == 1;
  }

  Future<T?> _showJournalSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool useSafeArea = true,
    bool showDragHandle = true,
    bool isScrollControlled = false,
  }) async {
    final controller = BottomSheet.createAnimationController(this)
      ..duration = kJournalMotionDuration
      ..reverseDuration = kJournalMotionDuration;
    try {
      return await showModalBottomSheet<T>(
        context: context,
        useSafeArea: useSafeArea,
        showDragHandle: showDragHandle,
        isScrollControlled: isScrollControlled,
        transitionAnimationController: controller,
        builder: builder,
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showQuickChoicePicker({
    required BuildContext context,
    required TrackerDefinition definition,
    required String? selectedChoiceKey,
  }) async {
    final choices = await context.read<JournalEntryEditorBloc>().getChoices(
      definition.id,
    );
    if (!context.mounted || choices.isEmpty) return;
    final picked = await _showJournalSheet<String>(
      context: context,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            for (final choice in choices)
              ListTile(
                title: Text(choice.label),
                trailing: selectedChoiceKey == choice.choiceKey
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(context).pop(choice.choiceKey),
              ),
          ],
        );
      },
    );
    if (!context.mounted || picked == null) return;
    context.read<JournalEntryEditorBloc>().add(
      JournalEntryEditorEntryValueChanged(
        trackerId: definition.id,
        value: picked,
      ),
    );
  }

  Future<void> _showQuickNumericAdjustSheet({
    required BuildContext context,
    required TrackerDefinition definition,
    required Object? currentValue,
  }) async {
    final current = switch (currentValue) {
      final int v => v.toDouble(),
      final double v => v,
      _ => (definition.minInt ?? 0).toDouble(),
    };
    final min = (definition.minInt ?? 0).toDouble();
    final max = (definition.maxInt ?? (current + 10)).toDouble();
    final step =
        ((definition.stepInt ?? 1) <= 0 ? 1 : (definition.stepInt ?? 1))
            .toDouble();
    var draft = current;

    final next = await _showJournalSheet<double>(
      context: context,
      builder: (context) {
        final tokens = TasklyTokens.of(context);
        return StatefulBuilder(
          builder: (context, setState) {
            void apply(int direction) {
              setState(() {
                draft = (draft + (step * direction)).clamp(min, max);
              });
            }

            return Padding(
              padding: EdgeInsets.all(tokens.spaceMd),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    definition.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: tokens.spaceSm),
                  Text(
                    JournalTrackerValueFormatter.format(
                      l10n: context.l10n,
                      label: definition.name,
                      definition: definition,
                      rawValue: draft,
                      choiceLabelsByTrackerId: _quickChoiceLabelsByTrackerId,
                    ).valueText,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: tokens.spaceSm),
                  Row(
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => apply(-1),
                        icon: const Icon(Icons.remove),
                        label: const Text('Less'),
                      ),
                      SizedBox(width: tokens.spaceSm),
                      FilledButton.icon(
                        onPressed: () => apply(1),
                        icon: const Icon(Icons.add),
                        label: const Text('More'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(draft),
                        child: const Text('Done'),
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

    if (!context.mounted || next == null) return;
    final output = next == next.roundToDouble() ? next.round() : next;
    context.read<JournalEntryEditorBloc>().add(
      JournalEntryEditorEntryValueChanged(
        trackerId: definition.id,
        value: output,
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
            required bool value,
            required ValueChanged<bool> onChanged,
          }) {
            return ToggleButtons(
              isSelected: [!value, value],
              constraints: const BoxConstraints(
                minHeight: 44,
                minWidth: 68,
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
            return Wrap(
              spacing: tokens.spaceXs,
              children: [
                for (var i = min; i <= max; i++)
                  ChoiceChip(
                    label: Text('$i'),
                    selected: intValue == i,
                    visualDensity: VisualDensity.compact,
                    onSelected: isSaving ? null : (_) => onChanged(i),
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
                return TrackerChoiceInput(
                  choices: choices,
                  selectedKey: selectedKey,
                  enabled: !isSaving,
                  onSelected: onSelected,
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
                label: null,
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

          final dailyValues = effectiveDailyValues();
          final hasMood = state.mood != null;
          _syncPostMoodReveal(hasMood);

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
                      padding: EdgeInsets.all(tokens.spaceSm),
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
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surfaceContainerHigh,
                    theme.colorScheme.surfaceContainerLow,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(tokens.radiusLg),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
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

          final entryTrackers = [...state.trackers]
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          final groupsById = {for (final g in state.groups) g.id: g};
          final ungrouped =
              entryTrackers
                  .where(
                    (d) =>
                        d.groupId == null || !groupsById.containsKey(d.groupId),
                  )
                  .toList(growable: false)
                ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          final groupedTrackersByName = <String, List<TrackerDefinition>>{};
          for (final group in state.groups) {
            final inGroup =
                entryTrackers
                    .where((d) => d.groupId == group.id)
                    .toList(growable: false)
                  ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
            if (inGroup.isNotEmpty) {
              groupedTrackersByName[group.name] = inGroup;
            }
          }

          if (ungrouped.isNotEmpty) {
            if (groupedTrackersByName.isNotEmpty) {
              final firstKey = groupedTrackersByName.keys.first;
              groupedTrackersByName[firstKey] = [
                ...ungrouped,
                ...groupedTrackersByName[firstKey]!,
              ];
            } else {
              groupedTrackersByName[l10n.groupsTitle] = [...ungrouped];
            }
          }

          final entryGroups = groupedTrackersByName.entries
              .map(
                (entry) => (
                  title: entry.key,
                  trackers: entry.value
                      .where(
                        (tracker) => _shouldShowEntryTracker(tracker, state),
                      )
                      .toList(growable: false),
                ),
              )
              .toList(growable: false);

          final quickFactorGroups = entryGroups
              .where((g) => g.trackers.isNotEmpty)
              .toList(growable: false);

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
                    if (!hasMood) moodGateHint(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: _showPostMoodGroups
                          ? Padding(
                              padding: EdgeInsets.only(top: tokens.spaceLg),
                              child: entryGroups.isEmpty
                                  ? trackerGroupCard(
                                      title: l10n.journalTrackersTitle,
                                      icon: Icons.tune,
                                      trackers: const <TrackerDefinition>[],
                                      isDaily: false,
                                      emptyLabel: l10n.journalNoEntryTrackers,
                                      manageRouteKey: 'journal_manage_factors',
                                    )
                                  : Column(
                                      children: [
                                        for (final group in entryGroups) ...[
                                          trackerGroupCard(
                                            title: group.title,
                                            icon: Icons.tune,
                                            trackers: group.trackers,
                                            isDaily: false,
                                            emptyLabel:
                                                l10n.journalNoEntryTrackers,
                                            manageRouteKey:
                                                'journal_manage_factors',
                                          ),
                                          SizedBox(height: tokens.spaceLg),
                                        ],
                                      ],
                                    ),
                            )
                          : const SizedBox.shrink(),
                    ),
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
            final quickSaveButton = FilledButton(
              onPressed: canSave
                  ? () => context.read<JournalEntryEditorBloc>().add(
                      const JournalEntryEditorSaveRequested(),
                    )
                  : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
              child: isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Text(
                      state.isEditingExisting ? 'Update Entry' : 'Save Entry',
                    ),
            );
            return SafeArea(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.surface,
                      theme.colorScheme.surfaceContainerLow,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 4,
                      margin: EdgeInsets.only(top: tokens.spaceSm),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.35,
                        ),
                        borderRadius: BorderRadius.circular(tokens.radiusPill),
                      ),
                    ),
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
                            'New Moment',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
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
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(
                          tokens.spaceMd,
                          tokens.spaceXs,
                          tokens.spaceMd,
                          tokens.spaceXxl * 2,
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
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: tokens.spaceMd),
                          Text(
                            l10n.journalMoodLabel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: tokens.spaceXxs),
                          Text(
                            l10n.journalMoodPromptSubtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: tokens.spaceSm),
                          _MoodScalePicker(
                            value: state.mood,
                            enabled: !isSaving,
                            onChanged: (m) => context
                                .read<JournalEntryEditorBloc>()
                                .add(JournalEntryEditorMoodChanged(m)),
                          ),
                          if (quickFactorGroups.isNotEmpty) ...[
                            SizedBox(height: tokens.spaceLg),
                            Text(
                              'What were you doing?',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: tokens.spaceSm),
                            Builder(
                              builder: (_) {
                                _syncQuickGroupExpansionDefaults(
                                  quickFactorGroups,
                                );
                                unawaited(
                                  _primeQuickChoiceLabels(
                                    context,
                                    quickFactorGroups,
                                  ),
                                );
                                return const SizedBox.shrink();
                              },
                            ),
                            for (final group in quickFactorGroups) ...[
                              Container(
                                margin: EdgeInsets.only(bottom: tokens.spaceSm),
                                padding: EdgeInsets.all(tokens.spaceSm),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(
                                    tokens.radiusMd,
                                  ),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.title,
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    SizedBox(height: tokens.spaceXxs),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          final current =
                                              _quickGroupExpanded[group
                                                  .title] ??
                                              true;
                                          _quickGroupExpanded[group.title] =
                                              !current;
                                        });
                                      },
                                      child: Row(
                                        children: [
                                          Text(
                                            '${group.trackers.length} trackers',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                          const Spacer(),
                                          Icon(
                                            (_quickGroupExpanded[group.title] ??
                                                    true)
                                                ? Icons.expand_less
                                                : Icons.expand_more,
                                            size: 18,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: tokens.spaceXs),
                                    AnimatedCrossFade(
                                      duration: kJournalMotionDuration,
                                      firstCurve: kJournalMotionCurve,
                                      secondCurve: kJournalMotionCurve,
                                      sizeCurve: kJournalMotionCurve,
                                      crossFadeState:
                                          (_quickGroupExpanded[group.title] ??
                                              true)
                                          ? CrossFadeState.showSecond
                                          : CrossFadeState.showFirst,
                                      firstChild: const SizedBox.shrink(),
                                      secondChild: Builder(
                                        builder: (context) {
                                          final fiveLevelTrackers = group
                                              .trackers
                                              .where(_isFiveLevelChoiceTracker)
                                              .toList(growable: false);
                                          final fiveLevelRatingTrackers = group
                                              .trackers
                                              .where(_isFiveLevelRatingTracker)
                                              .toList(growable: false);
                                          final tokenTrackers = group.trackers
                                              .where(
                                                (tracker) =>
                                                    !_isFiveLevelChoiceTracker(
                                                      tracker,
                                                    ) &&
                                                    !_isFiveLevelRatingTracker(
                                                      tracker,
                                                    ),
                                              )
                                              .toList(growable: false);

                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              for (final tracker
                                                  in fiveLevelTrackers) ...[
                                                _QuickFiveLevelChoicePicker(
                                                  title: tracker.name,
                                                  icon: trackerIconData(
                                                    tracker,
                                                  ),
                                                  selectedKey:
                                                      state.entryValues[tracker
                                                              .id]
                                                          as String?,
                                                  options:
                                                      _quickChoiceOptionsByTrackerId[tracker
                                                          .id] ??
                                                      const <
                                                        TrackerDefinitionChoice
                                                      >[],
                                                  enabled: !isSaving,
                                                  onSelected: (choiceKey) {
                                                    context
                                                        .read<
                                                          JournalEntryEditorBloc
                                                        >()
                                                        .add(
                                                          JournalEntryEditorEntryValueChanged(
                                                            trackerId:
                                                                tracker.id,
                                                            value: choiceKey,
                                                          ),
                                                        );
                                                  },
                                                ),
                                                SizedBox(
                                                  height: tokens.spaceSm,
                                                ),
                                              ],
                                              for (final tracker
                                                  in fiveLevelRatingTrackers) ...[
                                                _QuickFiveLevelRatingPicker(
                                                  title: tracker.name,
                                                  icon: trackerIconData(
                                                    tracker,
                                                  ),
                                                  selectedValue: switch (state
                                                      .entryValues[tracker
                                                      .id]) {
                                                    final int v => v,
                                                    final double v => v.round(),
                                                    _ => null,
                                                  },
                                                  enabled: !isSaving,
                                                  onSelected: (value) {
                                                    context
                                                        .read<
                                                          JournalEntryEditorBloc
                                                        >()
                                                        .add(
                                                          JournalEntryEditorEntryValueChanged(
                                                            trackerId:
                                                                tracker.id,
                                                            value: value,
                                                          ),
                                                        );
                                                  },
                                                ),
                                                SizedBox(
                                                  height: tokens.spaceSm,
                                                ),
                                              ],
                                              if (tokenTrackers.isNotEmpty)
                                                Wrap(
                                                  spacing: tokens.spaceXs,
                                                  runSpacing: tokens.spaceXs,
                                                  children: [
                                                    for (final tracker
                                                        in tokenTrackers)
                                                      Builder(
                                                        builder: (context) {
                                                          final selected =
                                                              _hasMeaningfulValue(
                                                                state
                                                                    .entryValues[tracker
                                                                    .id],
                                                              );
                                                          final formatted =
                                                              JournalTrackerValueFormatter.format(
                                                                l10n: l10n,
                                                                label: tracker
                                                                    .name,
                                                                definition:
                                                                    tracker,
                                                                rawValue:
                                                                    state
                                                                        .entryValues[tracker
                                                                        .id],
                                                                choiceLabelsByTrackerId:
                                                                    _quickChoiceLabelsByTrackerId,
                                                              );
                                                          return JournalFactorToken(
                                                            icon:
                                                                trackerIconData(
                                                                  tracker,
                                                                ),
                                                            text:
                                                                formatted.text,
                                                            state:
                                                                formatted.state,
                                                            selected: selected,
                                                            enabled: !isSaving,
                                                            onTap: () async {
                                                              if (_isBooleanTracker(
                                                                tracker,
                                                              )) {
                                                                final current =
                                                                    state
                                                                        .entryValues[tracker
                                                                        .id] ==
                                                                    true;
                                                                context
                                                                    .read<
                                                                      JournalEntryEditorBloc
                                                                    >()
                                                                    .add(
                                                                      JournalEntryEditorEntryValueChanged(
                                                                        trackerId:
                                                                            tracker.id,
                                                                        value:
                                                                            !current,
                                                                      ),
                                                                    );
                                                                return;
                                                              }
                                                              if (_isChoiceTracker(
                                                                tracker,
                                                              )) {
                                                                await _showQuickChoicePicker(
                                                                  context:
                                                                      context,
                                                                  definition:
                                                                      tracker,
                                                                  selectedChoiceKey:
                                                                      state.entryValues[tracker
                                                                              .id]
                                                                          as String?,
                                                                );
                                                                return;
                                                              }
                                                              if (_isNumericTracker(
                                                                tracker,
                                                              )) {
                                                                await _showQuickNumericAdjustSheet(
                                                                  context:
                                                                      context,
                                                                  definition:
                                                                      tracker,
                                                                  currentValue:
                                                                      state
                                                                          .entryValues[tracker
                                                                          .id],
                                                                );
                                                              }
                                                            },
                                                          );
                                                        },
                                                      ),
                                                  ],
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                          SizedBox(height: tokens.spaceSm),
                          TextField(
                            controller: _noteController,
                            onChanged: (v) => context
                                .read<JournalEntryEditorBloc>()
                                .add(JournalEntryEditorNoteChanged(v)),
                            maxLines: 5,
                            enabled: !isSaving,
                            decoration: InputDecoration(
                              hintText: l10n.journalWarmNotePlaceholder,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        tokens.spaceMd,
                        0,
                        tokens.spaceMd,
                        tokens.spaceMd,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: quickSaveButton,
                      ),
                    ),
                  ],
                ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final mood in MoodRating.values) ...[
            _MoodOptionButton(
              mood: mood,
              enabled: enabled,
              selected: value == mood,
              onTap: () => onChanged(mood),
            ),
            if (mood != MoodRating.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _QuickFiveLevelChoicePicker extends StatelessWidget {
  const _QuickFiveLevelChoicePicker({
    required this.title,
    required this.icon,
    required this.selectedKey,
    required this.options,
    required this.enabled,
    required this.onSelected,
  });

  final String title;
  final IconData icon;
  final String? selectedKey;
  final List<TrackerDefinitionChoice> options;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final sorted = [...options]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (sorted.length != 5) return const SizedBox.shrink();

    String labelFor(TrackerDefinitionChoice choice) {
      final label = choice.label.trim();
      return label.isEmpty ? choice.choiceKey.trim() : label;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.spaceXs),
        Row(
          children: [
            for (var i = 0; i < sorted.length; i++) ...[
              Expanded(
                child: _QuickFiveLevelChoiceTile(
                  icon: icon,
                  label: labelFor(sorted[i]),
                  selected: selectedKey == sorted[i].choiceKey,
                  enabled: enabled,
                  onTap: () => onSelected(sorted[i].choiceKey),
                ),
              ),
              if (i != sorted.length - 1) SizedBox(width: tokens.spaceXs),
            ],
          ],
        ),
        SizedBox(height: tokens.spaceXxs),
        Row(
          children: [
            Text(
              context.l10n.lowLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              context.l10n.highLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickFiveLevelChoiceTile extends StatelessWidget {
  const _QuickFiveLevelChoiceTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = selected ? scheme.primary : scheme.onSurfaceVariant;
    final bg = selected
        ? scheme.primaryContainer.withValues(alpha: 0.45)
        : scheme.surface;
    final border = selected ? scheme.primary : scheme.outlineVariant;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      child: AnimatedContainer(
        duration: kJournalMotionDuration,
        curve: kJournalMotionCurve,
        padding: EdgeInsets.symmetric(
          vertical: tokens.spaceSm,
          horizontal: tokens.spaceXxs,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            SizedBox(height: tokens.spaceXxs),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickFiveLevelRatingPicker extends StatelessWidget {
  const _QuickFiveLevelRatingPicker({
    required this.title,
    required this.icon,
    required this.selectedValue,
    required this.enabled,
    required this.onSelected,
  });

  final String title;
  final IconData icon;
  final int? selectedValue;
  final bool enabled;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.spaceXs),
        Row(
          children: [
            for (var i = 1; i <= 5; i++) ...[
              Expanded(
                child: _QuickFiveLevelChoiceTile(
                  icon: icon,
                  label: '$i',
                  selected: selectedValue == i,
                  enabled: enabled,
                  onTap: () => onSelected(i),
                ),
              ),
              if (i != 5) SizedBox(width: tokens.spaceXs),
            ],
          ],
        ),
        SizedBox(height: tokens.spaceXxs),
        Row(
          children: [
            Text(
              context.l10n.lowLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              context.l10n.highLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
        : theme.colorScheme.surfaceContainerLow;
    final border = selected
        ? BorderSide(color: moodColor, width: 2)
        : BorderSide(color: theme.colorScheme.outlineVariant);

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
          duration: kJournalMotionDuration,
          curve: kJournalMotionCurve,
          width: 68,
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: moodColor.withValues(alpha: selected ? 0.2 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _moodFace(mood),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: enabled ? moodColor : theme.disabledColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SizedBox(height: TasklyTokens.of(context).spaceXs),
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

Color _getMoodColor(MoodRating mood, ColorScheme colorScheme) {
  return switch (mood) {
    MoodRating.veryLow => colorScheme.error,
    MoodRating.low => colorScheme.secondary,
    MoodRating.neutral => colorScheme.onSurfaceVariant,
    MoodRating.good => colorScheme.tertiary,
    MoodRating.excellent => colorScheme.primary,
  };
}

String _moodFace(MoodRating mood) {
  return switch (mood) {
    MoodRating.veryLow => 'x(',
    MoodRating.low => ':(',
    MoodRating.neutral => ':|',
    MoodRating.good => ':)',
    MoodRating.excellent => ':D',
  };
}
