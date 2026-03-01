import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/journal/ui/journal_motion_tokens.dart';
import 'package:taskly_bloc/presentation/features/journal/ui/tracker_value_formatter.dart';
import 'package:taskly_bloc/presentation/features/journal/utils/tracker_icon_utils.dart';
import 'package:taskly_bloc/presentation/features/journal/widgets/journal_factor_token.dart';
import 'package:taskly_bloc/presentation/shared/utils/mood_label_utils.dart';
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
    this.choiceLabelsByTrackerId = const <String, Map<String, String>>{},
    super.key,
  });

  final JournalEntry entry;
  final List<TrackerEvent> events;
  final Map<String, TrackerDefinition> definitionById;
  final String? moodTrackerId;
  final DisplayDensity density;
  final VoidCallback onTap;
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
    final timeLabel = DateFormat.jm().format(
      widget.entry.occurredAt.toLocal(),
    );
    final tokens = TasklyTokens.of(context);
    final l10n = context.l10n;

    final mood = _findMood();
    final summaryItems = _buildSummaryItems(l10n);

    final note = widget.entry.journalText?.trim();
    final title = _deriveTitle(note);
    final excerpt = _deriveExcerpt(note: note, title: title);
    final fallbackTitle = _deriveFallbackTitle(
      l10n: l10n,
      mood: mood,
      summaryItems: summaryItems,
      timeLabel: timeLabel,
    );
    final displayTitle = title ?? fallbackTitle;
    final isRich = widget.density == DisplayDensity.standard;
    final maxChips = widget.density == DisplayDensity.compact ? 2 : 4;

    final surface = theme.colorScheme.surfaceContainerHigh;
    final border = theme.colorScheme.outlineVariant;
    final hasMood = mood != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: tokens.spaceMd),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.surface,
              width: 1.5,
            ),
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
                      if (hasMood)
                        Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: _moodTint(theme.colorScheme, mood),
                            borderRadius: BorderRadius.circular(
                              tokens.radiusPill,
                            ),
                          ),
                        ),
                      if (hasMood) SizedBox(height: tokens.spaceSm),
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
                      if (displayTitle.isNotEmpty) ...[
                        SizedBox(height: tokens.spaceSm),
                        Text(
                          displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (excerpt != null) ...[
                        SizedBox(height: tokens.spaceSm),
                        Text(
                          excerpt,
                          maxLines: isRich ? 3 : 2,
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

  String? _deriveTitle(String? note) {
    if (note == null || note.isEmpty) return null;
    final firstSentence = note.split('.').first.trim();
    if (firstSentence.isEmpty) return null;
    final words = firstSentence.split(RegExp(r'\s+'));
    if (words.length <= 4) return firstSentence;
    return words.take(4).join(' ');
  }

  String? _deriveExcerpt({required String? note, required String? title}) {
    if (note == null || note.isEmpty) return null;
    final trimmed = note.trim();
    if (trimmed.isEmpty) return null;
    if (title == null || title.isEmpty) return trimmed;
    final normalizedTitle = title.trim().toLowerCase();
    final normalizedNote = trimmed.toLowerCase();
    if (normalizedNote == normalizedTitle) return null;
    if (normalizedNote.startsWith(normalizedTitle)) {
      final suffix = trimmed.substring(title.length).trimLeft();
      if (suffix.isEmpty) return null;
      return suffix;
    }
    return trimmed;
  }

  String _deriveFallbackTitle({
    required AppLocalizations l10n,
    required MoodRating? mood,
    required List<_TrackerSummaryChip> summaryItems,
    required String timeLabel,
  }) {
    if (summaryItems.isNotEmpty) {
      final first = summaryItems.first.text.trim();
      if (first.isNotEmpty) return first;
    }
    if (mood != null) {
      return l10n.journalMoodSemanticsLabel(mood.localizedLabel(l10n));
    }
    return timeLabel;
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
