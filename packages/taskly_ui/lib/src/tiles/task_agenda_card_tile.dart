import 'package:flutter/material.dart';

import 'package:taskly_ui/src/tiles/entity_meta_line.dart';
import 'package:taskly_ui/src/tiles/entity_tile_models.dart';
import 'package:taskly_ui/src/tiles/_agenda_card_container.dart';

class TaskAgendaCardTile extends StatelessWidget {
  const TaskAgendaCardTile({
    required this.model,
    this.onTap,
    this.onToggleCompletion,
    this.trailing,
    this.titlePrefix,
    this.statusBadge,
    super.key,
  });

  final TaskAgendaCardModel model;

  final VoidCallback? onTap;
  final ValueChanged<bool?>? onToggleCompletion;

  /// App-owned trailing widget (overflow/menu/actions).
  final Widget? trailing;

  final Widget? titlePrefix;
  final Widget? statusBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final base = model.base;

    final outline = scheme.outlineVariant.withValues(alpha: 0.35);

    final backgroundColor = model.backgroundBlendPrimary
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.06),
            scheme.surfaceContainerLow,
          )
        : scheme.surfaceContainerLow;

    return Material(
      key: Key('task-${base.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AgendaCardContainer(
          dashedOutline: model.inProgressStyle,
          accentColor: model.accentColor,
          outlineColor: outline,
          backgroundColor: backgroundColor,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              model.inProgressStyle ? 28 : 14,
              14,
              14,
              14,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: base.completed,
                      onChanged: onToggleCompletion,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      side: BorderSide(
                        color: base.meta.isOverdue
                            ? scheme.error
                            : base.completed
                            ? scheme.primary
                            : scheme.outline,
                        width: 2,
                      ),
                      activeColor: scheme.primary,
                      checkColor: scheme.onPrimary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
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
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: Text(
                              base.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                decoration: base.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: base.completed
                                    ? scheme.onSurface.withValues(alpha: 0.5)
                                    : scheme.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (statusBadge != null) ...[
                            const SizedBox(width: 10),
                            statusBadge!,
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: EntityMetaLine(model: base.meta)),
                          if (model.inProgressStyle &&
                              model.endDayLabel != null) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 72,
                              child: Align(
                                alignment: Alignment.topRight,
                                child: trailing ?? const SizedBox.shrink(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            EndDayMarker(label: model.endDayLabel!),
                          ],
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
  }
}
