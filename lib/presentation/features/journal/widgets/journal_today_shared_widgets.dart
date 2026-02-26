import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/utils/tracker_icon_utils.dart';
import 'package:taskly_bloc/presentation/shared/utils/mood_label_utils.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalLogCard extends StatelessWidget {
  const JournalLogCard({
    required this.entry,
    required this.events,
    required this.definitionById,
    required this.moodTrackerId,
    required this.dayQuantityTotalsByTrackerId,
    required this.density,
    required this.onTap,
    super.key,
  });

  final JournalEntry entry;
  final List<TrackerEvent> events;
  final Map<String, TrackerDefinition> definitionById;
  final String? moodTrackerId;
  final Map<String, double> dayQuantityTotalsByTrackerId;
  final DisplayDensity density;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeLabel = DateFormat.jm().format(entry.occurredAt.toLocal());
    final tokens = TasklyTokens.of(context);
    final l10n = context.l10n;

    final mood = _findMood();
    final summaryItems = _buildSummaryItems(l10n);

    final note = entry.journalText?.trim();
    final isRich = density == DisplayDensity.standard;

    final surface = theme.colorScheme.surfaceContainerHigh;
    final border = theme.colorScheme.outlineVariant;
    final hasMood = mood != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: tokens.spaceSm),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiary,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: tokens.spaceSm),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  surface,
                  if (mood == null) theme.colorScheme.surfaceContainerHighest,
                  if (mood != null)
                    Color.lerp(
                          theme.colorScheme.surfaceContainerHighest,
                          _moodTint(theme.colorScheme, mood),
                          0.1,
                        ) ??
                        theme.colorScheme.surfaceContainerHighest,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              border: Border.all(color: border),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: tokens.spaceSm,
                            vertical: tokens.spaceXs,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(
                              tokens.radiusMd,
                            ),
                          ),
                          child: Text(
                            timeLabel,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (hasMood)
                          Tooltip(
                            message: mood.localizedLabel(l10n),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: tokens.spaceSm,
                                vertical: tokens.spaceXs,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(
                                  tokens.radiusMd,
                                ),
                              ),
                              child: Text(
                                '${mood.emoji} ${mood.value}',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (isRich && note != null && note.isNotEmpty) ...[
                      SizedBox(height: tokens.spaceSm),
                      Text(
                        note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    if (summaryItems.isNotEmpty) ...[
                      SizedBox(height: tokens.spaceSm),
                      Wrap(
                        spacing: tokens.spaceSm,
                        runSpacing: tokens.spaceSm,
                        children: [
                          for (final item
                              in (isRich ? summaryItems : summaryItems.take(2)))
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: tokens.spaceSm,
                                vertical: tokens.spaceXs,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(
                                  tokens.radiusMd,
                                ),
                                border: Border.all(color: border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 14,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  SizedBox(width: tokens.spaceXxs),
                                  Text(
                                    item.text,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  MoodRating? _findMood() {
    final id = moodTrackerId;
    if (id == null) return null;

    TrackerEvent? latestMoodEvent;
    for (final e in events) {
      if (e.trackerId != id || e.value is! int) continue;
      if (latestMoodEvent == null ||
          latestMoodEvent.occurredAt.isBefore(e.occurredAt)) {
        latestMoodEvent = e;
      }
    }

    final moodValue = latestMoodEvent?.value;
    if (moodValue is! int) return null;
    return MoodRating.fromValue(moodValue);
  }

  List<_TrackerSummaryChip> _buildSummaryItems(AppLocalizations l10n) {
    final candidates = <_TrackerSummaryChip>[];
    final moodId = moodTrackerId;
    final latestByTrackerId = <String, TrackerEvent>{};

    for (final e in events) {
      if (moodId != null && e.trackerId == moodId) continue;
      final previous = latestByTrackerId[e.trackerId];
      if (previous == null || previous.occurredAt.isBefore(e.occurredAt)) {
        latestByTrackerId[e.trackerId] = e;
      }
    }

    for (final e in latestByTrackerId.values) {
      if (moodId != null && e.trackerId == moodId) continue;

      final definition = definitionById[e.trackerId];
      final name = definition?.name ?? l10n.journalTrackerFallbackName;
      final value = e.value;
      final icon = definition == null
          ? Icons.track_changes_outlined
          : trackerIconData(definition);
      final quantity = definition != null && _isQuantity(definition);
      final unit = (definition?.unitKind ?? '').trim();

      if (quantity) {
        final total = dayQuantityTotalsByTrackerId[e.trackerId];
        if (total == null) continue;
        final rendered = _formatNumber(total);
        final valueText = unit.isEmpty ? rendered : '$rendered $unit';
        candidates.add(
          _TrackerSummaryChip(
            text: l10n.journalTrackerValueLabel(name, valueText),
            icon: icon,
          ),
        );
        continue;
      }

      if (value is bool) {
        if (!value) continue;
        candidates.add(
          _TrackerSummaryChip(
            text: name,
            icon: icon,
          ),
        );
        continue;
      }

      if (value is int) {
        candidates.add(
          _TrackerSummaryChip(
            text: l10n.journalTrackerValueLabel(name, '$value'),
            icon: icon,
          ),
        );
        continue;
      }

      if (value is double) {
        candidates.add(
          _TrackerSummaryChip(
            text: l10n.journalTrackerValueLabel(name, value.toStringAsFixed(1)),
            icon: icon,
          ),
        );
        continue;
      }

      if (value is String) {
        candidates.add(
          _TrackerSummaryChip(
            text: l10n.journalTrackerValueLabel(name, value),
            icon: icon,
          ),
        );
        continue;
      }

      if (value != null) {
        candidates.add(
          _TrackerSummaryChip(
            text: l10n.journalTrackerValueLabel(name, '$value'),
            icon: icon,
          ),
        );
      }
    }

    if (candidates.length <= 4) return candidates;

    final remaining = candidates.length - 3;
    return [
      ...candidates.take(3),
      _TrackerSummaryChip(
        text: l10n.journalTrackerMoreLabel(remaining),
        icon: Icons.more_horiz,
      ),
    ];
  }

  bool _isQuantity(TrackerDefinition definition) {
    final type = definition.valueType.trim().toLowerCase();
    final kind = (definition.valueKind ?? '').trim().toLowerCase();
    return type == 'quantity' || kind == 'number';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

final class _TrackerSummaryChip {
  const _TrackerSummaryChip({required this.text, required this.icon});

  final String text;
  final IconData icon;
}

Color _moodTint(ColorScheme scheme, MoodRating mood) {
  return switch (mood) {
    MoodRating.veryLow => scheme.error,
    MoodRating.low => scheme.secondary,
    MoodRating.neutral => scheme.onSurfaceVariant,
    MoodRating.good => scheme.tertiary,
    MoodRating.excellent => scheme.primary,
  };
}
