import 'package:flutter/material.dart';

import 'package:taskly_ui/src/tiles/entity_tile_intents.dart';
import 'package:taskly_ui/src/tiles/entity_tile_models.dart';

/// Canonical Value ("My Values") entity tile.
///
/// This widget is render-only. The app owns all domain semantics and
/// user-facing strings.
class ValueEntityTile extends StatelessWidget {
  const ValueEntityTile({
    required this.model,
    this.intent = const ValueTileIntent.standardList(),
    this.actions = const ValueTileActions(),
    super.key,
  });

  final ValueTileModel model;

  final ValueTileIntent intent;
  final ValueTileActions actions;

  @override
  Widget build(BuildContext context) {
    return switch (intent) {
      ValueTileIntentMyValuesCardV1() => _MyValuesCardV1(
        model: model,
        actions: actions,
      ),
      _ => _StandardListRow(
        model: model,
        actions: actions,
      ),
    };
  }
}

class _StandardListRow extends StatelessWidget {
  const _StandardListRow({
    required this.model,
    required this.actions,
  });

  final ValueTileModel model;
  final ValueTileActions actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
        onTap: actions.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ValueIconAvatar(
                icon: model.icon,
                color: model.accentColor,
                size: 44,
              ),
              const SizedBox(width: 12),
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
              const SizedBox(width: 8),
              SizedBox(
                width: 56,
                child: actions.onOverflowMenuRequestedAt == null
                    ? const SizedBox.shrink()
                    : Align(
                        alignment: Alignment.topRight,
                        child: _TrailingOverflowButton(
                          onOverflowRequestedAt:
                              actions.onOverflowMenuRequestedAt!,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyValuesCardV1 extends StatelessWidget {
  const _MyValuesCardV1({
    required this.model,
    required this.actions,
  });

  final ValueTileModel model;
  final ValueTileActions actions;

  bool get _hasStatsLines =>
      model.firstLineLabel != null &&
      model.firstLineValue != null &&
      model.secondLineLabel != null &&
      model.secondLineValue != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant.withOpacity(0.6)),
      ),
      child: InkWell(
        onTap: actions.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ValueIconAvatar(
                icon: model.icon,
                color: model.accentColor,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            model.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (actions.onOverflowMenuRequestedAt != null)
                          _TrailingOverflowButton(
                            onOverflowRequestedAt:
                                actions.onOverflowMenuRequestedAt!,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_hasStatsLines) ...[
                      _StatsRow(
                        label: model.firstLineLabel!,
                        value: model.firstLineValue!,
                      ),
                      const SizedBox(height: 6),
                      _StatsRow(
                        label: model.secondLineLabel!,
                        value: model.secondLineValue!,
                      ),
                    ] else
                      Text(
                        model.loadingLabel ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
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

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrailingOverflowButton extends StatelessWidget {
  const _TrailingOverflowButton({
    required this.onOverflowRequestedAt,
  });

  final ValueChanged<Offset> onOverflowRequestedAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = scheme.onSurfaceVariant.withValues(alpha: 0.85);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => onOverflowRequestedAt(details.globalPosition),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Icon(
          Icons.more_horiz,
          size: 20,
          color: iconColor,
        ),
      ),
    );
  }
}
