import 'package:flutter/material.dart';

import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';
import 'package:taskly_ui/src/models/value_chip_data.dart';
import 'package:taskly_ui/src/primitives/taskly_badge.dart';
import 'package:taskly_ui/src/primitives/value_tag.dart';

class RoutineEntityTile extends StatelessWidget {
  const RoutineEntityTile({
    required this.model,
    required this.actions,
    super.key,
  });

  final TasklyRoutineRowData model;
  final TasklyRoutineRowActions actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    final labels = model.labels;
    final primaryLabelText = labels?.primaryActionLabel?.trim() ?? '';
    final showPrimary =
        actions.onPrimaryAction != null && primaryLabelText.isNotEmpty;
    final badges = model.badges;
    final hasBadges = badges.isNotEmpty;


    final statusLabel = model.statusLabel.trim();
    final showStatus = statusLabel.isNotEmpty;
    final statusColor = _statusColor(model.statusTone, scheme);
    final statusStyle = theme.textTheme.labelSmall?.copyWith(
      color: statusColor,
      fontWeight: FontWeight.w600,
    );

    final valueChip = model.valueChip;
    final metaLabel =
        [
              model.remainingLabel,
              model.windowLabel,
              model.targetLabel,
            ]
            .map((text) => text.trim())
            .where((text) => text.isNotEmpty)
            .join(' \u00b7 ');
    final showMeta = metaLabel.isNotEmpty;

    final baseOpacity = model.completed ? 0.7 : 1.0;
    final opacity = baseOpacity.clamp(0.0, 1.0);

    final isSelected = model.selected || model.completed;
    final selectedTint = scheme.primaryContainer.withValues(alpha: 0.16);
    final tileSurface = isSelected
        ? Color.alphaBlend(selectedTint, scheme.surface)
        : scheme.surface;

    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      color: scheme.onSurface,
      decoration: model.completed ? TextDecoration.lineThrough : null,
      decorationColor: scheme.onSurface.withValues(alpha: 0.55),
      fontWeight: FontWeight.w700,
    );

    final metaStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    final tile = DecoratedBox(
      decoration: BoxDecoration(
        color: tileSurface,
        borderRadius: BorderRadius.circular(tokens.taskRadius),
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
        borderRadius: BorderRadius.circular(tokens.taskRadius),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: actions.onTap,
            child: Padding(
              padding: tokens.taskPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          model.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: titleStyle,
                        ),
                      ),
                    ],
                  ),
                  if (valueChip != null || showMeta || showStatus) ...[
                    SizedBox(height: tokens.spaceXs2),
                    Wrap(
                      spacing: tokens.spaceXs2,
                      runSpacing: tokens.spaceXs2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (valueChip != null)
                          _ValueInlineLabel(
                            data: valueChip,
                            textColor: scheme.onSurfaceVariant,
                          ),
                        if (showMeta) ...[
                          if (valueChip != null) _ValueMetaDot(tokens: tokens),
                          Text(metaLabel, style: metaStyle),
                        ],
                        if (showStatus) ...[
                          if (valueChip != null || showMeta)
                            _ValueMetaDot(tokens: tokens),
                          Text(statusLabel, style: statusStyle),
                        ],
                      ],
                    ),
                  ],
                  if (hasBadges) ...[
                    SizedBox(height: tokens.spaceXs2),
                    Wrap(
                      spacing: tokens.spaceXs2,
                      runSpacing: tokens.spaceXs2,
                      children: [
                        for (final badge in badges)
                          TasklyBadge(
                            label: badge.label,
                            icon: badge.icon,
                            color: badge.color,
                            style: _badgeStyle(badge.tone),
                          ),
                      ],
                    ),
                  ],
                  if (showPrimary) ...[
                    SizedBox(height: tokens.spaceSm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _PrimaryActionButton(
                        label: primaryLabelText,
                        selected: isSelected,
                        onPressed: actions.onPrimaryAction,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Opacity(
      key: Key('routine-${model.id}'),
      opacity: opacity,
      child: tile,
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? scheme.primaryContainer : scheme.primary;
    final fg = selected ? scheme.primary : scheme.onPrimary;

    return IconButton(
      onPressed: onPressed,
      tooltip: label,
      icon: Icon(selected ? Icons.check_rounded : Icons.add_rounded),
      style: IconButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        minimumSize: Size.square(tokens.minTapTargetSize),
        padding: EdgeInsets.all(tokens.spaceXs2),
      ),
    );
  }
}

Color _statusColor(TasklyRoutineStatusTone tone, ColorScheme scheme) {
  return switch (tone) {
    TasklyRoutineStatusTone.onPace => scheme.tertiary,
    TasklyRoutineStatusTone.tightWeek => scheme.secondary,
    TasklyRoutineStatusTone.catchUp => scheme.error,
    TasklyRoutineStatusTone.restWeek => scheme.onSurfaceVariant,
  };
}

TasklyBadgeStyle _badgeStyle(TasklyBadgeTone tone) {
  return switch (tone) {
    TasklyBadgeTone.solid => TasklyBadgeStyle.solid,
    TasklyBadgeTone.outline => TasklyBadgeStyle.outline,
    TasklyBadgeTone.soft => TasklyBadgeStyle.softOutline,
  };
}

class _ValueInlineLabel extends StatelessWidget {
  const _ValueInlineLabel({
    required this.data,
    required this.textColor,
  });

  final ValueChipData data;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    const maxLabelChars = 20;
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

class _ValueMetaDot extends StatelessWidget {
  const _ValueMetaDot({required this.tokens});

  final TasklyTokens tokens;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: tokens.spaceXxs2,
      height: tokens.spaceXxs2,
      decoration: BoxDecoration(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
    );
  }
}
