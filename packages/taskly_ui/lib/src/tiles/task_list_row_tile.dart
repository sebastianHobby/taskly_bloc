import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskly_ui/src/tiles/entity_meta_line.dart';
import 'package:taskly_ui/src/tiles/entity_tile_models.dart';

class TaskListRowTile extends StatelessWidget {
  const TaskListRowTile({
    required this.model,
    this.onTap,
    this.onLongPress,
    this.onToggleCompletion,
    this.trailing,
    this.titlePrefix,
    this.subtitle,
    this.footer,
    this.leadingAccentColor,
    this.compact = false,
    super.key,
  });

  final TaskTileModel model;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Called when the completion checkbox is toggled.
  ///
  /// If null, the checkbox is disabled.
  final ValueChanged<bool?>? onToggleCompletion;

  /// App-owned trailing widget (overflow/menu/actions).
  final Widget? trailing;

  final Widget? titlePrefix;

  /// Optional subtitle widget shown between title and meta line.
  final Widget? subtitle;

  /// Optional footer widget shown below the meta line.
  final Widget? footer;

  /// Optional left-edge accent (used to subtly emphasize urgency).
  final Color? leadingAccentColor;

  /// When true, uses tighter vertical spacing and typically forces
  /// single-line titles.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final isCompact = compact || MediaQuery.sizeOf(context).width < 420;

    return Container(
      key: Key('task-${model.id}'),
      decoration: BoxDecoration(
        color: model.completed
            ? scheme.surfaceContainerLowest.withValues(alpha: 0.5)
            : scheme.surface,
        border: Border(
          left: leadingAccentColor == null
              ? BorderSide.none
              : BorderSide(color: leadingAccentColor!, width: 3),
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isCompact ? 8 : 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox.square(
                    dimension: isCompact ? 36 : 44,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.only(top: isCompact ? 2 : 4),
                        child: _TaskCompletionCheckbox(
                          completed: model.completed,
                          isOverdue: model.meta.isOverdue,
                          onChanged: onToggleCompletion,
                          semanticLabel: model.checkboxSemanticLabel,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isCompact ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (titlePrefix != null) ...[
                              titlePrefix!,
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                model.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  decoration: model.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: model.completed
                                      ? scheme.onSurface.withValues(alpha: 0.5)
                                      : scheme.onSurface,
                                ),
                                maxLines: isCompact ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          subtitle!,
                        ],
                        EntityMetaLine(model: model.meta),
                        if (footer != null) ...[
                          const SizedBox(height: 6),
                          footer!,
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: isCompact ? 44 : 56,
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: trailing ?? const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCompletionCheckbox extends StatelessWidget {
  const _TaskCompletionCheckbox({
    required this.completed,
    required this.isOverdue,
    required this.onChanged,
    required this.semanticLabel,
  });

  final bool completed;
  final bool isOverdue;
  final ValueChanged<bool?>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        width: 24,
        height: 24,
        child: Checkbox(
          value: completed,
          onChanged: onChanged == null
              ? null
              : (bool? value) {
                  HapticFeedback.lightImpact();
                  onChanged!(value);
                },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          side: BorderSide(
            color: isOverdue
                ? colorScheme.error
                : completed
                ? colorScheme.primary
                : colorScheme.outline,
            width: 2,
          ),
          activeColor: colorScheme.primary,
          checkColor: colorScheme.onPrimary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
