import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';
import 'package:taskly_ui/src/primitives/meta_badges.dart';

/// Canonical Project tile aligned to Stitch mockups.
///
/// Pure UI: data in / events out.
class ProjectEntityTile extends StatelessWidget {
  const ProjectEntityTile({
    required this.model,
    this.preset = const TasklyProjectRowPreset.standard(),
    this.actions = const TasklyProjectRowActions(),
    super.key,
  });

  final TasklyProjectRowData model;

  final TasklyProjectRowPreset preset;
  final TasklyProjectRowActions actions;

  bool? get _selected => switch (preset) {
    TasklyProjectRowPresetBulkSelection(:final selected) => selected,
    _ => null,
  };

  bool get _isInbox => preset is TasklyProjectRowPresetInbox;
  bool get _isCompact => preset is TasklyProjectRowPresetCompact;

  double? get _progress {
    final total = model.taskCount;
    final done = model.completedTaskCount;
    if (total == null || total <= 0) return 0;
    final safeDone = (done ?? 0).clamp(0, total);
    return (safeDone / total).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    final isReadOnlyHeader =
        !_isInbox &&
        actions.onTap == null &&
        actions.onLongPress == null &&
        actions.onToggleSelected == null;

    final padding = _isCompact
        ? tokens.projectPadding.copyWith(
            top: tokens.spaceSm2,
            bottom: tokens.spaceSm2,
          )
        : tokens.projectPadding;

    final pinnedPrefix = model.pinned ? const _PinnedGlyph() : null;
    final Widget? titlePrefix = pinnedPrefix;

    final valueChip = model.leadingChip;
    final showValueIcon = valueChip != null;

    final startLabel = model.meta.startDateLabel?.trim() ?? '';
    final deadlineLabel = model.meta.deadlineDateLabel?.trim() ?? '';
    final hasDeadline = deadlineLabel.isNotEmpty;
    final hasStart = !model.meta.showOnlyDeadlineDate && startLabel.isNotEmpty;
    final compactLabel = hasDeadline
        ? (model.meta.isOverdue
              ? 'Overdue'
              : (model.meta.isDueToday ? 'Due today' : deadlineLabel))
        : (hasStart ? startLabel : '');
    final compactIcon = hasDeadline
        ? Icons.flag_rounded
        : (hasStart ? Icons.calendar_today_rounded : null);
    final compactLabelColor =
        hasDeadline && (model.meta.isOverdue || model.meta.isDueToday)
        ? scheme.error
        : scheme.onSurfaceVariant;

    final baseOpacity = model.deemphasized ? 0.6 : 1;
    final completedOpacity = model.completed ? 0.75 : 1;
    final opacity = (baseOpacity * completedOpacity).clamp(0, 1).toDouble();

    final onTap = switch (preset) {
      TasklyProjectRowPresetBulkSelection() =>
        actions.onToggleSelected ?? actions.onTap,
      _ => actions.onTap,
    };

    final titleStyle =
        (isReadOnlyHeader
            ? theme.textTheme.headlineSmall
            : (_isCompact
                  ? theme.textTheme.titleMedium
                  : theme.textTheme.headlineSmall)) ??
        const TextStyle();
    final weightedTitleStyle = titleStyle.copyWith(fontWeight: FontWeight.w700);

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(tokens.projectRadius),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.05),
            blurRadius: tokens.cardShadowBlur,
            offset: tokens.cardShadowOffset,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.projectRadius),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            onLongPress: actions.onLongPress,
            child: Padding(
              padding: padding.copyWith(
                left: padding.left,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isInbox) ...[
                        _InboxGlyph(tokens: tokens),
                        SizedBox(width: tokens.spaceMd),
                      ] else ...[
                        _ProjectGlyph(
                          tokens: tokens,
                          progress: _progress ?? 0,
                          isCompact: _isCompact,
                        ),
                        SizedBox(width: tokens.spaceMd),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (titlePrefix != null) ...[
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: tokens.spaceXxs,
                                    ),
                                    child: titlePrefix,
                                  ),
                                  SizedBox(width: tokens.spaceXs2),
                                ],
                                Expanded(
                                  child: Text(
                                    model.title,
                                    maxLines: _isCompact ? 1 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: weightedTitleStyle.copyWith(
                                      color: scheme.onSurface,
                                      decoration: model.completed
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: scheme.onSurface
                                          .withValues(alpha: 0.55),
                                    ),
                                  ),
                                ),
                                if (_isCompact &&
                                    compactLabel.isNotEmpty &&
                                    compactIcon != null) ...[
                                  SizedBox(width: tokens.spaceSm),
                                  Icon(
                                    compactIcon,
                                    size: tokens.spaceMd2,
                                    color: compactLabelColor,
                                  ),
                                  SizedBox(width: tokens.spaceXxs2),
                                  Text(
                                    compactLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: compactLabelColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                                if (showValueIcon) ...[
                                  SizedBox(width: tokens.spaceSm),
                                  Icon(
                                    valueChip.icon,
                                    size: tokens.spaceMd2,
                                    color: valueChip.color,
                                  ),
                                ],
                                if (_selected != null) ...[
                                  SizedBox(width: tokens.spaceXs2),
                                  IconButton(
                                    tooltip: (_selected ?? false)
                                        ? 'Deselect'
                                        : 'Select',
                                    onPressed: actions.onToggleSelected,
                                    icon: Icon(
                                      (_selected ?? false)
                                          ? Icons.check_circle_rounded
                                          : Icons
                                                .radio_button_unchecked_rounded,
                                      color: (_selected ?? false)
                                          ? scheme.primary
                                          : scheme.onSurfaceVariant,
                                    ),
                                    style: IconButton.styleFrom(
                                      minimumSize: Size.square(
                                        tokens.minTapTargetSize,
                                      ),
                                      padding: EdgeInsets.all(
                                        tokens.spaceSm,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (!_isCompact && _hasMetaRow(model)) ...[
                              SizedBox(height: tokens.spaceXs2),
                              _ProjectMetaRow(
                                startLabel: model.meta.startDateLabel,
                                deadlineLabel: model.meta.deadlineDateLabel,
                                showOnlyDeadline:
                                    model.meta.showOnlyDeadlineDate,
                                isOverdue: model.meta.isOverdue,
                                isDueToday: model.meta.isDueToday,
                                priority: model.meta.priority,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Opacity(
      key: Key('project-${model.id}'),
      opacity: opacity,
      child: card,
    );
  }
}

class _ProjectMetaRow extends StatelessWidget {
  const _ProjectMetaRow({
    required this.startLabel,
    required this.deadlineLabel,
    required this.showOnlyDeadline,
    required this.isOverdue,
    required this.isDueToday,
    required this.priority,
  });

  final String? startLabel;
  final String? deadlineLabel;
  final bool showOnlyDeadline;
  final bool isOverdue;
  final bool isDueToday;
  final int? priority;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    final textStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );

    final children = <Widget>[];

    if (priority != null) {
      children.add(PriorityPill(priority: priority!));
    }

    final start = showOnlyDeadline ? '' : (startLabel?.trim() ?? '');
    final deadline = deadlineLabel?.trim() ?? '';
    final showStart = start.isNotEmpty;
    final showDeadline = deadline.isNotEmpty;

    if (showStart) {
      children.add(
        MetaIconLabel(
          icon: Icons.calendar_today_rounded,
          label: start,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
          textStyle: textStyle,
        ),
      );
    }

    if (showDeadline) {
      final dueColor = (isOverdue || isDueToday)
          ? scheme.error
          : scheme.onSurfaceVariant;
      children.add(
        MetaIconLabel(
          icon: Icons.flag_rounded,
          label: deadline,
          color: dueColor,
          textStyle: textStyle,
        ),
      );
    }

    return Wrap(
      spacing: tokens.spaceSm2,
      runSpacing: tokens.spaceXs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

bool _hasMetaRow(TasklyProjectRowData model) {
  final startLabel = model.meta.startDateLabel?.trim();
  final deadlineLabel = model.meta.deadlineDateLabel?.trim();
  final hasDeadline = deadlineLabel != null && deadlineLabel.isNotEmpty;
  final hasStart =
      !model.meta.showOnlyDeadlineDate &&
      startLabel != null &&
      startLabel.isNotEmpty;
  final hasPriority = model.meta.priority != null;
  return hasStart || hasDeadline || hasPriority;
}

class _ProjectGlyph extends StatelessWidget {
  const _ProjectGlyph({
    required this.tokens,
    required this.progress,
    required this.isCompact,
  });

  final TasklyTokens tokens;
  final double progress;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = isCompact
        ? tokens.progressRingSizeSmall
        : tokens.progressRingSize - tokens.spaceXs;
    final stroke = tokens.progressRingStrokeSmall;
    final trackColor = scheme.outlineVariant.withValues(alpha: 0.7);
    final ringColor = scheme.primary;
    final innerSize = math.max<double>(
      0,
      size - (stroke * 2) - tokens.spaceXs2,
    );

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ProgressRingPainter(
          progress: progress,
          trackColor: trackColor,
          ringColor: ringColor,
          strokeWidth: stroke,
        ),
        child: Center(
          child: Container(
            width: innerSize,
            height: innerSize,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.folder_rounded,
              size: isCompact ? 16 : 18,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _InboxGlyph extends StatelessWidget {
  const _InboxGlyph({required this.tokens});

  final TasklyTokens tokens;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: tokens.progressRingSize,
      height: tokens.progressRingSize,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: BoxShape.circle,
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Icon(
        Icons.inbox_outlined,
        size: 20,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

class _PinnedGlyph extends StatelessWidget {
  const _PinnedGlyph();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Pinned',
      child: SizedBox(
        width: 18,
        child: Align(
          alignment: Alignment.topCenter,
          child: Icon(
            Icons.push_pin_rounded,
            size: 16,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.ringColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color ringColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.max<double>(
      0,
      (size.shortestSide - strokeWidth) / 2,
    );
    if (radius <= 0) return;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    final clamped = progress.clamp(0, 1);
    if (clamped == 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;
    final sweep = (math.pi * 2) * clamped;
    canvas.drawArc(rect, startAngle, sweep, false, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
