import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/ui/journal_motion_tokens.dart';
import 'package:taskly_bloc/presentation/features/journal/ui/tracker_value_formatter.dart';
import 'package:taskly_bloc/presentation/features/journal/utils/tracker_icon_utils.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_factor_token.dart';
import 'package:taskly_domain/journal.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

class JournalLogCard extends StatefulWidget {
  const JournalLogCard({
    required this.entry,
    required this.events,
    required this.definitionById,
    required this.moodTrackerId,
    required this.density,
    required this.onTap,
    this.showTimelineLine = false,
    this.choiceLabelsByTrackerId = const <String, Map<String, String>>{},
    super.key,
  });

  final JournalEntry entry;
  final List<TrackerEvent> events;
  final Map<String, TrackerDefinition> definitionById;
  final String? moodTrackerId;
  final DisplayDensity density;
  final VoidCallback onTap;
  final bool showTimelineLine;
  final Map<String, Map<String, String>> choiceLabelsByTrackerId;

  @override
  State<JournalLogCard> createState() => _JournalLogCardState();
}

class _JournalLogCardState extends State<JournalLogCard> {
  bool _expandedSummary = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);
    final l10n = context.l10n;

    final mood = _findMood();
    final summaryItems = _buildSummaryItems(l10n);

    final note = widget.entry.journalText?.trim();
    final maxChips = widget.density == DisplayDensity.compact ? 2 : 4;

    final surface = theme.colorScheme.surfaceContainer;
    final border = theme.colorScheme.outlineVariant;
    final hasMood = mood != null;
    final moodColor = hasMood
        ? _moodTint(theme.colorScheme, mood)
        : theme.colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: moodColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _timelineMoodIcon(mood),
                  size: 19,
                  color: moodColor,
                ),
              ),
              SizedBox(height: tokens.spaceXxs),
              Text(
                DateFormat.Hm().format(widget.entry.occurredAt.toLocal()),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: tokens.spaceXxs),
              if (widget.showTimelineLine)
                Container(
                  width: 2,
                  height: 84,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: tokens.spaceSm),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              border: Border.all(color: border),
            ),
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (value) {
                if (_pressed == value) return;
                setState(() => _pressed = value);
              },
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              child: AnimatedScale(
                duration: kJournalMotionDuration,
                curve: kJournalMotionCurve,
                scale: _pressed ? 0.985 : 1,
                child: Padding(
                  padding: EdgeInsets.all(tokens.spaceMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (note != null && note.isNotEmpty)
                        Text(
                          note,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge,
                        ),
                      if (summaryItems.isNotEmpty) ...[
                        SizedBox(height: tokens.spaceSm),
                        Wrap(
                          spacing: tokens.spaceSm,
                          runSpacing: tokens.spaceSm,
                          children: [
                            for (final item in _visibleSummaryItems(
                              allItems: summaryItems,
                              maxChips: maxChips,
                            ))
                              JournalFactorToken(
                                icon: item.icon,
                                text: item.text,
                                state: item.state,
                                onTap: item.isOverflow
                                    ? () => setState(() {
                                        _expandedSummary = true;
                                      })
                                    : null,
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
        ),
      ],
    );
  }

  MoodRating? _findMood() {
    final id = widget.moodTrackerId;
    if (id == null) return null;

    TrackerEvent? latestMoodEvent;
    for (final e in widget.events) {
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
    final moodId = widget.moodTrackerId;
    final latestByTrackerId = <String, TrackerEvent>{};

    for (final e in widget.events) {
      if (moodId != null && e.trackerId == moodId) continue;
      final previous = latestByTrackerId[e.trackerId];
      if (previous == null || previous.occurredAt.isBefore(e.occurredAt)) {
        latestByTrackerId[e.trackerId] = e;
      }
    }

    final orderedEvents = latestByTrackerId.values.toList(growable: false)
      ..sort((a, b) => a.trackerId.compareTo(b.trackerId));
    for (final e in orderedEvents) {
      if (moodId != null && e.trackerId == moodId) continue;

      final definition = widget.definitionById[e.trackerId];
      final name = definition?.name ?? l10n.journalTrackerFallbackName;
      final icon = definition == null
          ? Icons.track_changes_outlined
          : trackerIconData(definition);
      final formatted = JournalTrackerValueFormatter.format(
        l10n: l10n,
        label: name,
        definition: definition,
        rawValue: e.value,
        choiceLabelsByTrackerId: widget.choiceLabelsByTrackerId,
      );
      candidates.add(
        _TrackerSummaryChip(
          text: formatted.text,
          icon: icon,
          state: formatted.state,
        ),
      );
    }
    return candidates;
  }

  List<_TrackerSummaryChip> _visibleSummaryItems({
    required List<_TrackerSummaryChip> allItems,
    required int maxChips,
  }) {
    if (_expandedSummary || allItems.length <= maxChips) return allItems;
    final remaining = allItems.length - maxChips;
    return [
      ...allItems.take(maxChips),
      _TrackerSummaryChip(
        text: '+$remaining',
        icon: Icons.more_horiz,
        state: JournalTrackerValueState.normal,
        isOverflow: true,
      ),
    ];
  }
}

final class _TrackerSummaryChip {
  const _TrackerSummaryChip({
    required this.text,
    required this.icon,
    required this.state,
    this.isOverflow = false,
  });

  final String text;
  final IconData icon;
  final JournalTrackerValueState state;
  final bool isOverflow;
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

IconData _timelineMoodIcon(MoodRating? mood) {
  return switch (mood) {
    MoodRating.veryLow => Icons.sentiment_very_dissatisfied_rounded,
    MoodRating.low => Icons.sentiment_dissatisfied_rounded,
    MoodRating.neutral => Icons.sentiment_neutral_rounded,
    MoodRating.good => Icons.sentiment_satisfied_rounded,
    MoodRating.excellent => Icons.sentiment_very_satisfied_rounded,
    null => Icons.brightness_1,
  };
}
