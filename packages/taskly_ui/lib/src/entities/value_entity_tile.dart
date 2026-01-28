import 'package:flutter/material.dart';

import 'package:taskly_ui/src/feed/taskly_feed_spec.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

/// Canonical Value ("My Values") entity tile.
///
/// This widget is render-only. The app owns all domain semantics and
/// user-facing strings.
class ValueEntityTile extends StatelessWidget {
  const ValueEntityTile({
    required this.model,
    this.preset = const TasklyValueRowPreset.standard(),
    this.actions = const TasklyValueRowActions(),
    super.key,
  });

  final TasklyValueRowData model;

  final TasklyValueRowPreset preset;
  final TasklyValueRowActions actions;

  @override
  Widget build(BuildContext context) {
    return switch (preset) {
      TasklyValueRowPresetHeroSelection(:final selected) => _HeroCardRow(
        model: model,
        actions: actions,
        selected: selected,
      ),
      TasklyValueRowPresetHero() => _HeroCardRow(
        model: model,
        actions: actions,
      ),
      TasklyValueRowPresetBulkSelection(:final selected) => _StandardListRow(
        model: model,
        actions: actions,
        bulkSelected: selected,
      ),
      _ => _StandardListRow(
        model: model,
        actions: actions,
      ),
    };
  }
}

class _HeroCardRow extends StatelessWidget {
  const _HeroCardRow({
    required this.model,
    required this.actions,
    this.selected,
  });

  final TasklyValueRowData model;
  final TasklyValueRowActions actions;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    final onTap = selected == null
        ? actions.onTap
        : (actions.onToggleSelected ?? actions.onTap);

    final tileSurface = (selected ?? false)
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.08),
            scheme.surface,
          )
        : scheme.surface;

    final borderColor = (selected ?? false)
        ? scheme.primary.withValues(alpha: 0.35)
        : scheme.outlineVariant.withValues(alpha: 0.6);

    final hasPrimaryStat =
        model.primaryStatLabel != null && model.primaryStatLabel!.isNotEmpty;
    final hasEmptyTitle =
        model.emptyStatTitle != null && model.emptyStatTitle!.isNotEmpty;
    final hasEmptySubtitle =
        model.emptyStatSubtitle != null && model.emptyStatSubtitle!.isNotEmpty;
    final hasMetrics = model.metrics.isNotEmpty;

    final iconSize = tokens.progressRingSize + tokens.spaceSm2;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tileSurface,
        borderRadius: BorderRadius.circular(tokens.projectRadius),
        border: Border.all(color: borderColor),
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
              padding: EdgeInsets.all(tokens.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ValueIconAvatar(
                        icon: model.icon,
                        color: model.accentColor,
                        size: iconSize,
                      ),
                      SizedBox(width: tokens.spaceMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              model.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: scheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (model.priorityLabel != null) ...[
                              SizedBox(height: tokens.spaceXs2),
                              _PriorityPill(
                                label: model.priorityLabel!,
                                dotColor:
                                    model.priorityDotColor ??
                                    scheme.onSurfaceVariant,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (selected != null) ...[
                        SizedBox(width: tokens.spaceSm),
                        _HeroSelectIcon(
                          selected: selected!,
                          onPressed: actions.onToggleSelected ?? actions.onTap,
                        ),
                      ],
                    ],
                  ),
                  if (hasPrimaryStat || hasEmptyTitle || hasEmptySubtitle) ...[
                    SizedBox(height: tokens.spaceMd),
                    if (hasPrimaryStat)
                      _PrimaryStat(
                        label: model.primaryStatLabel!,
                        subLabel: model.primaryStatSubLabel,
                      )
                    else
                      _EmptyStat(
                        title: model.emptyStatTitle,
                        subtitle: model.emptyStatSubtitle,
                      ),
                  ],
                  if (hasMetrics) ...[
                    SizedBox(height: tokens.spaceMd),
                    Wrap(
                      spacing: tokens.spaceSm2,
                      runSpacing: tokens.spaceXs2,
                      children: [
                        for (final metric in model.metrics)
                          _MetricPill(metric: metric),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StandardListRow extends StatelessWidget {
  const _StandardListRow({
    required this.model,
    required this.actions,
    this.bulkSelected,
  });

  final TasklyValueRowData model;
  final TasklyValueRowActions actions;
  final bool? bulkSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    return Container(
      key: Key('value-${model.id}'),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: InkWell(
        onTap: bulkSelected == null
            ? actions.onTap
            : (actions.onToggleSelected ?? actions.onTap),
        onLongPress: actions.onLongPress,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spaceMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ValueIconAvatar(
                icon: model.icon,
                color: model.accentColor,
                size: 44,
              ),
              SizedBox(width: tokens.spaceMd),
              Expanded(
                child: Text(
                  model.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: tokens.spaceSm),
              SizedBox(
                width: 56,
                child: Align(
                  alignment: Alignment.topRight,
                  child: switch (bulkSelected) {
                    null => const SizedBox.shrink(),
                    final selected => _BulkSelectIcon(
                      selected: selected,
                      onPressed: actions.onToggleSelected ?? actions.onTap,
                    ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueIconAvatar extends StatelessWidget {
  const _ValueIconAvatar({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.52,
      ),
    );
  }
}

class _BulkSelectIcon extends StatelessWidget {
  const _BulkSelectIcon({
    required this.selected,
    required this.onPressed,
  });

  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);
    return IconButton(
      tooltip: selected ? 'Deselect' : 'Select',
      onPressed: onPressed,
      icon: Icon(
        selected
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      style: IconButton.styleFrom(
        minimumSize: Size.square(tokens.minTapTargetSize),
        padding: EdgeInsets.all(tokens.spaceSm2),
      ),
    );
  }
}

class _HeroSelectIcon extends StatelessWidget {
  const _HeroSelectIcon({
    required this.selected,
    required this.onPressed,
  });

  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);
    return IconButton(
      tooltip: selected ? 'Deselect' : 'Select',
      onPressed: onPressed,
      icon: Icon(
        selected
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: selected ? scheme.primary : scheme.onSurfaceVariant,
      ),
      style: IconButton.styleFrom(
        minimumSize: Size.square(tokens.minTapTargetSize),
        padding: EdgeInsets.all(tokens.spaceSm2),
      ),
    );
  }
}

class _PriorityPill extends StatelessWidget {
  const _PriorityPill({
    required this.label,
    required this.dotColor,
  });

  final String label;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dotSize = tokens.spaceXs2;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSm2,
        vertical: tokens.spaceXs2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(tokens.radiusPill),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          SizedBox(width: tokens.spaceXs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryStat extends StatelessWidget {
  const _PrimaryStat({
    required this.label,
    this.subLabel,
  });

  final String label;
  final String? subLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subLabel != null && subLabel!.isNotEmpty) ...[
          SizedBox(height: tokens.spaceXs2),
          Text(
            subLabel!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyStat extends StatelessWidget {
  const _EmptyStat({
    required this.title,
    required this.subtitle,
  });

  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    if ((title == null || title!.isEmpty) &&
        (subtitle == null || subtitle!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null && title!.isNotEmpty)
          Text(
            title!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          SizedBox(height: tokens.spaceXs2),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.metric});

  final TasklyValueRowMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = TasklyTokens.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceSm2,
        vertical: tokens.spaceXs2,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(tokens.radiusPill),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          children: [
            TextSpan(
              text: metric.value,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const TextSpan(text: ' '),
            TextSpan(text: metric.label),
          ],
        ),
      ),
    );
  }
}
