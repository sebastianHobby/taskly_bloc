import 'package:flutter/material.dart';

import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/models/value_chip_data.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';
import 'package:taskly_ui/src/primitives/meta_badges.dart';
import 'package:taskly_ui/src/primitives/value_tag.dart';

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

    final padding = tokens.projectPadding;

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
            child: Stack(
              children: [
                Padding(
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
                            _ProgressRing(
                              progress: _progress ?? 0.0,
                              tokens: tokens,
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
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            (isReadOnlyHeader
                                                    ? theme
                                                          .textTheme
                                                          .headlineSmall
                                                    : theme
                                                          .textTheme
                                                          .titleMedium)
                                                ?.copyWith(
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
                                if (model.taskCount != null) ...[
                                  SizedBox(height: tokens.spaceXs2),
                                  _ProjectMetaRow(
                                    primary: model.leadingChip,
                                    totalCount: model.taskCount!,
                                    completedCount: model.completedTaskCount,
                                    dueSoonCount: model.dueSoonCount,
                                    dueLabel: model.meta.deadlineDateLabel,
                                    isOverdue: model.meta.isOverdue,
                                    isDueToday: model.meta.isDueToday,
                                    priority: model.meta.priority,
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
    required this.primary,
    required this.totalCount,
    required this.completedCount,
    required this.dueSoonCount,
    required this.dueLabel,
    required this.isOverdue,
    required this.isDueToday,
    required this.priority,
    required this.showCompletionRatio,
  });

  final ValueChipData? primary;
  final int totalCount;
  final int? completedCount;
  final int? dueSoonCount;
  final String? dueLabel;
  final bool isOverdue;
  final bool isDueToday;
  final int? priority;
  final bool showCompletionRatio;

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

    if (primary != null) {
      children.add(
        _ValueInlineLabel(
          data: primary!,
          maxLabelChars: 18,
          textColor: scheme.onSurfaceVariant,
        ),
      );
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
            SizedBox(width: tokens.spaceXs),
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
            SizedBox(width: tokens.spaceXs),
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
      spacing: tokens.spaceSm2,
      runSpacing: tokens.spaceXs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}

class _ValueInlineLabel extends StatelessWidget {
  const _ValueInlineLabel({
    required this.data,
    required this.maxLabelChars,
    required this.textColor,
  });

  final ValueChipData data;
  final int maxLabelChars;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final label = ValueTagLayout.formatLabel(
      data.label,
      maxChars: maxLabelChars,
    );
    if (label == null || label.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(data.icon, size: tokens.spaceMd2, color: data.color),
        SizedBox(width: tokens.spaceXxs2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
              .copyWith(color: textColor, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.tokens});

  final double progress;
  final TasklyTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final percent = (progress * 100).round();

    return SizedBox(
      width: tokens.progressRingSizeSmall,
      height: tokens.progressRingSizeSmall,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: 1,
            strokeWidth: tokens.progressRingStrokeSmall,
            valueColor: AlwaysStoppedAnimation<Color>(
              scheme.surfaceContainerHighest,
            ),
          ),
          CircularProgressIndicator(
            value: progress,
            strokeWidth: tokens.progressRingStrokeSmall,
            strokeCap: StrokeCap.round,
            backgroundColor: scheme.surface.withValues(alpha: 0),
            valueColor: AlwaysStoppedAnimation<Color>(
              scheme.primary,
            ),
          ),
          Text(
            '$percent%',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
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
