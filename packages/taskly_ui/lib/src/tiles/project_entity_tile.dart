import 'package:flutter/material.dart';

import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/models/value_chip_data.dart';
import 'package:taskly_ui/src/primitives/meta_badges.dart';
import 'package:taskly_ui/src/tiles/entity_tile_theme.dart';
import 'package:taskly_ui/src/primitives/value_chip_widget.dart';

/// Canonical Project tile aligned to Stitch mockups.
///
/// Pure UI: data in / events out.
class ProjectEntityTile extends StatelessWidget {
  const ProjectEntityTile({
    required this.model,
    this.preset = const TasklyProjectRowPreset.standard(),
    this.actions = const TasklyProjectRowActions(),
    this.leadingAccentColor,
    super.key,
  });

  final TasklyProjectRowData model;

  final TasklyProjectRowPreset preset;
  final TasklyProjectRowActions actions;

  /// Optional left-edge accent (used to subtly emphasize urgency).
  final Color? leadingAccentColor;

  bool? get _selected => switch (preset) {
    TasklyProjectRowPresetBulkSelection(:final selected) => selected,
    _ => null,
  };

  bool get _isInbox => preset is TasklyProjectRowPresetInbox;

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
    final tokens = TasklyEntityTileTheme.of(context);
    final isReadOnlyHeader =
        !_isInbox &&
        actions.onTap == null &&
        actions.onLongPress == null &&
        actions.onToggleSelected == null;

    final effectiveCompact = MediaQuery.sizeOf(context).width < 420;
    final padding = effectiveCompact
        ? const EdgeInsets.all(16)
        : tokens.projectPadding;

    final pinnedPrefix = model.pinned ? const _PinnedGlyph() : null;

    final Widget? titlePrefix = pinnedPrefix;

    final baseOpacity = model.deemphasized ? 0.6 : 1.0;
    final completedOpacity = model.completed ? 0.75 : 1.0;
    final opacity = (baseOpacity * completedOpacity).clamp(0, 1).toDouble();

    final onTap = switch (preset) {
      TasklyProjectRowPresetBulkSelection() =>
        actions.onToggleSelected ?? actions.onTap,
      _ => actions.onTap,
    };

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.cardSurfaceColor,
        borderRadius: BorderRadius.circular(tokens.projectRadius),
        border: Border.all(color: tokens.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: tokens.cardShadowColor,
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
            child: Stack(
              children: [
                if (leadingAccentColor != null)
                  Positioned.fill(
                    left: 0,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(width: 4, color: leadingAccentColor),
                    ),
                  ),
                Padding(
                  padding: padding.copyWith(
                    left: (leadingAccentColor == null)
                        ? padding.left
                        : (padding.left + 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isInbox) ...[
                            _InboxGlyph(tokens: tokens),
                            const SizedBox(width: 12),
                          ] else ...[
                            _ProgressRing(
                              progress: _progress ?? 0.0,
                              tokens: tokens,
                            ),
                            const SizedBox(width: 12),
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
                                        padding: const EdgeInsets.only(top: 2),
                                        child: titlePrefix,
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Expanded(
                                      child: Text(
                                        model.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            (isReadOnlyHeader
                                                    ? tokens.projectHeaderTitle
                                                    : tokens.projectTitle)
                                                .copyWith(
                                                  color: scheme.onSurface,
                                                  decoration: model.completed
                                                      ? TextDecoration
                                                            .lineThrough
                                                      : null,
                                                  decorationColor: scheme
                                                      .onSurface
                                                      .withValues(
                                                        alpha: 0.55,
                                                      ),
                                                ),
                                      ),
                                    ),
                                    if (_selected != null) ...[
                                      const SizedBox(width: 6),
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
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          minimumSize: const Size(40, 40),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (model.subtitle != null &&
                                    model.subtitle!.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    model.subtitle!.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: tokens.subtitle.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                if (model.taskCount != null) ...[
                                  const SizedBox(height: 6),
                                  _ProjectMetaRow(
                                    totalCount: model.taskCount!,
                                    completedCount: model.completedTaskCount,
                                    dueSoonCount: model.dueSoonCount,
                                    dueLabel: model.meta.deadlineDateLabel,
                                    isOverdue: model.meta.isOverdue,
                                    isDueToday: model.meta.isDueToday,
                                    priority: model.meta.priority,
                                    leadingChip: model.leadingChip,
                                    showCompletionRatio: !_isInbox,
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
              ],
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
    required this.totalCount,
    required this.completedCount,
    required this.dueSoonCount,
    required this.dueLabel,
    required this.isOverdue,
    required this.isDueToday,
    required this.priority,
    required this.leadingChip,
    required this.showCompletionRatio,
  });

  final int totalCount;
  final int? completedCount;
  final int? dueSoonCount;
  final String? dueLabel;
  final bool isOverdue;
  final bool isDueToday;
  final int? priority;
  final ValueChipData? leadingChip;
  final bool showCompletionRatio;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyEntityTileTheme.of(context);

    final textStyle = tokens.metaValue.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final children = <Widget>[];

    if (leadingChip != null) {
      children.add(ValueChip(data: leadingChip!));
    }

    if (showCompletionRatio && completedCount != null) {
      children.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: scheme.secondary,
            ),
            const SizedBox(width: 4),
            Text('$completedCount/$totalCount tasks', style: textStyle),
          ],
        ),
      );
    } else {
      children.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showCompletionRatio
                  ? Icons.check_circle_rounded
                  : Icons.inbox_outlined,
              size: 14,
              color: showCompletionRatio
                  ? scheme.secondary
                  : scheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 4),
            Text('$totalCount tasks', style: textStyle),
          ],
        ),
      );
    }

    if (priority != null) {
      children.add(PriorityPill(priority: priority!));
    }

    final dueSoon = dueSoonCount ?? 0;
    final label = dueLabel?.trim();
    final showLabel = label != null && label.isNotEmpty;
    final showDue = showLabel || dueSoon > 0;
    if (showDue) {
      final dueColor = (isOverdue || isDueToday)
          ? scheme.error
          : scheme.onSurfaceVariant;
      children.add(
        MetaIconLabel(
          icon: Icons.flag_rounded,
          label: showLabel ? label : '$dueSoon due soon',
          color: dueColor,
          textStyle: textStyle,
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.tokens});

  final double progress;
  final TasklyEntityTileTheme tokens;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final percent = (progress * 100).round();

    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              tokens.progressTrackColor,
            ),
          ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 2,
            strokeCap: StrokeCap.round,
            backgroundColor: scheme.surface.withValues(alpha: 0),
            valueColor: AlwaysStoppedAnimation<Color>(
              tokens.progressFillColor,
            ),
          ),
          Text(
            '$percent%',
            style: tokens.metaValue.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxGlyph extends StatelessWidget {
  const _InboxGlyph({required this.tokens});

  final TasklyEntityTileTheme tokens;

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
