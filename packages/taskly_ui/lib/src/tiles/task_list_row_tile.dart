import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:taskly_ui/src/primitives/pinned_gutter_marker.dart';
import 'package:taskly_ui/src/tiles/entity_meta_line.dart';
import 'package:taskly_ui/src/tiles/entity_tile_models.dart';

class TaskListRowTile extends StatelessWidget {
  const TaskListRowTile({
    required this.model,
    this.onTap,
    this.onToggleCompletion,
    this.trailing,
    this.titlePrefix,
    this.statusBadge,
    super.key,
    this.compact = false,
  });

  final TaskTileModel model;
  final VoidCallback? onTap;

  /// Called when the completion checkbox is toggled.
  ///
  /// If null, the checkbox is disabled.
  final ValueChanged<bool?>? onToggleCompletion;

  /// App-owned trailing widget (overflow/menu/actions).
  final Widget? trailing;

  final Widget? titlePrefix;
  final Widget? statusBadge;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      key: Key('task-${model.id}'),
      decoration: BoxDecoration(
        color: model.completed
            ? scheme.surfaceContainerLowest.withValues(alpha: 0.5)
            : scheme.surface,
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: compact ? 10 : 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox.square(
                    dimension: 44,
                    child: Center(
                      child: _TaskCompletionCheckbox(
                        completed: model.completed,
                        isOverdue: model.meta.isOverdue,
                        onChanged: onToggleCompletion,
                        semanticLabel: model.checkboxSemanticLabel,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                                maxLines: compact ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (statusBadge != null) ...[
                              const SizedBox(width: 10),
                              statusBadge!,
                            ],
                          ],
                        ),
                        EntityMetaLine(model: model.meta),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 72,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: trailing ?? const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
            if (model.pinned)
              Positioned(
                left: 0,
                top: compact ? 12 : 14,
                child: IgnorePointer(
                  child: PinnedGutterMarker(color: scheme.primary),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
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
