import 'package:flutter/material.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_history_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/utils/journal_unit_catalog.dart';
import 'package:taskly_bloc/presentation/features/journal/utils/tracker_icon_utils.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalDayTrackersCard extends StatelessWidget {
  const JournalDayTrackersCard({
    required this.summary,
    required this.previousSummary,
    required this.dayTrackerDefinitions,
    required this.dayTrackerOrderIds,
    required this.hiddenDayTrackerIds,
    required this.onSaveValue,
    required this.onAddDelta,
    required this.onLoadChoices,
    this.ignoreHidden = false,
    super.key,
  });

  final JournalHistoryDaySummary summary;
  final JournalHistoryDaySummary? previousSummary;
  final List<TrackerDefinition> dayTrackerDefinitions;
  final List<String> dayTrackerOrderIds;
  final Set<String> hiddenDayTrackerIds;
  final void Function(TrackerDefinition definition, Object? value) onSaveValue;
  final void Function(TrackerDefinition definition, num delta) onAddDelta;
  final Future<List<String>> Function(String trackerId) onLoadChoices;
  final bool ignoreHidden;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final byId = {for (final d in dayTrackerDefinitions) d.id: d};
    final ordered = <TrackerDefinition>[];
    for (final id in dayTrackerOrderIds) {
      final definition = byId[id];
      if (definition == null) continue;
      if (!ignoreHidden && hiddenDayTrackerIds.contains(id)) continue;
      ordered.add(definition);
    }
    for (final definition in dayTrackerDefinitions) {
      if (!ignoreHidden && hiddenDayTrackerIds.contains(definition.id)) {
        continue;
      }
      if (ordered.any((d) => d.id == definition.id)) continue;
      ordered.add(definition);
    }

    final rows = [
      for (final definition in ordered)
        (
          definition: definition,
          snapshot: _snapshotFor(definition, l10n),
        ),
    ];
    final withValue = rows.where((row) => row.snapshot.hasValue).length;
    final withTrend = rows
        .where((row) => row.snapshot.trendLabel != null)
        .length;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceSm),
        child: ordered.isEmpty
            ? Padding(
                padding: EdgeInsets.all(tokens.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.journalNoDayTrackersEnabled,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: tokens.spaceXs),
                    FilledButton.icon(
                      onPressed: () =>
                          Routing.toJournalDailyCheckinWizard(context),
                      icon: const Icon(Icons.add),
                      label: Text(context.l10n.journalAddTrackerLabel),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  if (withValue > 0)
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: tokens.spaceXs),
                      padding: EdgeInsets.symmetric(
                        horizontal: tokens.spaceSm,
                        vertical: tokens.spaceXs,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(tokens.radiusMd),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.65,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.today,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          SizedBox(width: tokens.spaceXs),
                          Expanded(
                            child: Text(
                              context.l10n.journalDayTrackersLoggedLabel(
                                withValue,
                                withTrend,
                              ),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  for (var i = 0; i < rows.length; i++) ...[
                    _DayTrackerRow(
                      definition: rows[i].definition,
                      snapshot: rows[i].snapshot,
                      onTap: () => _openQuickEditSheet(
                        context: context,
                        definition: rows[i].definition,
                        snapshot: rows[i].snapshot,
                      ),
                    ),
                    if (i != rows.length - 1) SizedBox(height: tokens.spaceXs),
                  ],
                ],
              ),
      ),
    );
  }

  JournalDayTrackerSnapshot _snapshotFor(
    TrackerDefinition definition,
    AppLocalizations l10n,
  ) {
    final id = definition.id;
    final raw =
        summary.dayQuantityTotalsByTrackerId[id] ??
        summary.latestEventByTrackerId[id]?.value;
    final previousRaw = previousSummary == null
        ? null
        : (previousSummary!.dayQuantityTotalsByTrackerId[id] ??
              previousSummary!.latestEventByTrackerId[id]?.value);
    final numValue = _toDouble(raw);
    final prevNumValue = _toDouble(previousRaw);
    final unitLabel = journalUnitLabel(definition.unitKind);
    final measurementLabel = unitLabel.isNotEmpty
        ? unitLabel
        : switch (definition.valueType.trim().toLowerCase()) {
            'rating' => 'rating',
            'yes_no' => 'boolean',
            'choice' || 'single_choice' => 'selection',
            _ => 'value',
          };
    final valueLabel = _formatValue(raw, unitLabel, l10n);
    String? trendLabel;
    if (numValue != null && prevNumValue != null) {
      final delta = numValue - prevNumValue;
      if (delta.abs() > 0.0001) {
        final prefix = delta >= 0 ? '+' : '';
        trendLabel = '$prefix${_formatNumber(delta)} vs prev';
      }
    }

    return JournalDayTrackerSnapshot(
      valueLabel: valueLabel,
      hasValue: raw != null && (raw is! String || raw.trim().isNotEmpty),
      rawValue: raw,
      numericValue: numValue,
      valueType: definition.valueType.trim().toLowerCase(),
      trendLabel: trendLabel,
      measurementLabel: measurementLabel,
      opKind: definition.opKind.trim().toLowerCase(),
      min: definition.minInt?.toDouble(),
      max: definition.maxInt?.toDouble(),
      step: ((definition.stepInt ?? 1) <= 0 ? 1 : (definition.stepInt ?? 1))
          .toDouble(),
    );
  }

  Future<void> _openQuickEditSheet({
    required BuildContext context,
    required TrackerDefinition definition,
    required JournalDayTrackerSnapshot snapshot,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _DayTrackerQuickEditSheet(
        definition: definition,
        snapshot: snapshot,
        onSaveValue: (value) => onSaveValue(definition, value),
        onAddDelta: (delta) => onAddDelta(definition, delta),
        onLoadChoices: onLoadChoices,
      ),
    );
  }

  String _formatValue(
    Object? raw,
    String unitLabel,
    AppLocalizations l10n,
  ) {
    if (raw == null) return l10n.journalNotSetLabel;
    if (raw is bool) return raw ? l10n.yesLabel : l10n.noLabel;
    if (raw is String) {
      final value = raw.trim();
      return value.isEmpty ? l10n.journalNotSetLabel : value;
    }
    final number = _toDouble(raw);
    if (number == null) return raw.toString();
    final numeric = _formatNumber(number);
    return unitLabel.isEmpty ? numeric : '$numeric $unitLabel';
  }

  double? _toDouble(Object? value) => switch (value) {
    final int v => v.toDouble(),
    final double v => v,
    _ => null,
  };

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(1);
  }
}

class JournalDayTrackerSnapshot {
  const JournalDayTrackerSnapshot({
    required this.valueLabel,
    required this.hasValue,
    required this.rawValue,
    required this.numericValue,
    required this.valueType,
    required this.trendLabel,
    required this.measurementLabel,
    required this.opKind,
    required this.min,
    required this.max,
    required this.step,
  });

  final String valueLabel;
  final bool hasValue;
  final Object? rawValue;
  final double? numericValue;
  final String valueType;
  final String? trendLabel;
  final String measurementLabel;
  final String opKind;
  final double? min;
  final double? max;
  final double step;
}

class _DayTrackerRow extends StatelessWidget {
  const _DayTrackerRow({
    required this.definition,
    required this.snapshot,
    required this.onTap,
  });

  final TrackerDefinition definition;
  final JournalDayTrackerSnapshot snapshot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final hasValue = snapshot.hasValue;
    final trackerIcon = trackerIconData(definition);
    final trend = snapshot.trendLabel;
    final valueStyle = hasValue
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      child: Container(
        padding: EdgeInsets.all(tokens.spaceSm),
        decoration: BoxDecoration(
          color: hasValue
              ? theme.colorScheme.surfaceContainer
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  trackerIcon,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: tokens.spaceXs),
                Expanded(
                  child: Text(
                    definition.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceXs,
                    vertical: tokens.spaceXxs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(tokens.radiusPill),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                  child: Text(
                    snapshot.measurementLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spaceXs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    snapshot.valueLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: valueStyle,
                  ),
                ),
                if (trend != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spaceXs,
                      vertical: tokens.spaceXxs,
                    ),
                    decoration: BoxDecoration(
                      color: trend.startsWith('+')
                          ? theme.colorScheme.tertiaryContainer.withValues(
                              alpha: 0.55,
                            )
                          : theme.colorScheme.errorContainer.withValues(
                              alpha: 0.55,
                            ),
                      borderRadius: BorderRadius.circular(tokens.radiusPill),
                    ),
                    child: Text(
                      trend,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: tokens.spaceXs),
            LinearProgressIndicator(
              value: hasValue ? 1 : 0,
              minHeight: 3,
              borderRadius: BorderRadius.circular(tokens.radiusPill),
              backgroundColor: theme.colorScheme.outlineVariant.withValues(
                alpha: 0.35,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                hasValue
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayTrackerQuickEditSheet extends StatefulWidget {
  const _DayTrackerQuickEditSheet({
    required this.definition,
    required this.snapshot,
    required this.onSaveValue,
    required this.onAddDelta,
    required this.onLoadChoices,
  });

  final TrackerDefinition definition;
  final JournalDayTrackerSnapshot snapshot;
  final void Function(Object? value) onSaveValue;
  final void Function(num delta) onAddDelta;
  final Future<List<String>> Function(String trackerId) onLoadChoices;

  @override
  State<_DayTrackerQuickEditSheet> createState() =>
      _DayTrackerQuickEditSheetState();
}

class _DayTrackerQuickEditSheetState extends State<_DayTrackerQuickEditSheet> {
  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final type = widget.definition.valueType.trim().toLowerCase();
    final isAdditive = widget.snapshot.opKind == 'add';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        tokens.spaceMd,
        tokens.spaceXs,
        tokens.spaceMd,
        MediaQuery.viewInsetsOf(context).bottom + tokens.spaceMd,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.definition.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: tokens.spaceXxs),
          Text(
            context.l10n.journalCurrentValueLabel(widget.snapshot.valueLabel),
          ),
          SizedBox(height: tokens.spaceSm),
          if (type == 'yes_no')
            _buildBooleanControls(context)
          else if (type == 'choice' || type == 'single_choice')
            _buildChoiceControls(context)
          else
            _buildStepperControls(context, isAdditive),
        ],
      ),
    );
  }

  Widget _buildBooleanControls(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final isTrue = widget.snapshot.rawValue == true;
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonal(
            onPressed: isTrue
                ? null
                : () {
                    widget.onSaveValue(true);
                    Navigator.of(context).pop();
                  },
            child: Text(context.l10n.yesLabel),
          ),
        ),
        SizedBox(width: tokens.spaceSm),
        Expanded(
          child: FilledButton.tonal(
            onPressed: !isTrue
                ? null
                : () {
                    widget.onSaveValue(false);
                    Navigator.of(context).pop();
                  },
            child: Text(context.l10n.noLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceControls(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return FutureBuilder<List<String>>(
      future: widget.onLoadChoices(widget.definition.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        final values = (snapshot.data ?? const <String>[])
            .where((e) => e.trim().isNotEmpty)
            .toList(growable: false);
        final choices = values.isEmpty
            ? <String>[
                context.l10n.noneLabel,
                context.l10n.lowLabel,
                context.l10n.mediumLabel,
                context.l10n.highLabel,
              ]
            : values;
        return Wrap(
          spacing: tokens.spaceXs,
          runSpacing: tokens.spaceXs,
          children: [
            for (final option in choices)
              ChoiceChip(
                label: Text(option),
                selected: widget.snapshot.rawValue == option,
                onSelected: (_) {
                  widget.onSaveValue(option);
                  Navigator.of(context).pop();
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildStepperControls(BuildContext context, bool isAdditive) {
    final tokens = TasklyTokens.of(context);
    final value = widget.snapshot.numericValue ?? 0;
    final min = widget.snapshot.min ?? 0;
    final max = widget.snapshot.max ?? (value + widget.snapshot.step * 10);
    final canDown = isAdditive || value > min;
    final canUp = isAdditive || value < max;

    void apply(int direction) {
      final delta = widget.snapshot.step * direction;
      if (isAdditive) {
        widget.onAddDelta(delta);
      } else {
        final next = (value + delta).clamp(min, max);
        final output = next == next.roundToDouble() ? next.round() : next;
        widget.onSaveValue(output);
      }
      Navigator.of(context).pop();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.journalMeasurementLabel(
            widget.snapshot.measurementLabel,
          ),
        ),
        SizedBox(height: tokens.spaceXs),
        Row(
          children: [
            FilledButton.tonalIcon(
              onPressed: canDown ? () => apply(-1) : null,
              icon: const Icon(Icons.remove),
              label: Text(context.l10n.minusLabel),
            ),
            SizedBox(width: tokens.spaceSm),
            FilledButton.icon(
              onPressed: canUp ? () => apply(1) : null,
              icon: const Icon(Icons.add),
              label: Text(context.l10n.plusLabel),
            ),
          ],
        ),
        SizedBox(height: tokens.spaceXs),
        Text(
          context.l10n.journalStepLabel(
            widget.snapshot.step,
            widget.snapshot.measurementLabel,
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
