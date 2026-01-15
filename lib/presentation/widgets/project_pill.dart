import 'package:flutter/material.dart';

/// A compact pill for showing a task's project in meta lines.
///
/// This is intentionally visually distinct from `ValueChip` so values remain the
/// primary semantic chips.
class ProjectPill extends StatelessWidget {
  const ProjectPill({
    required this.projectName,
    this.isTertiary = false,
    this.maxWidth = 160,
    super.key,
  });

  final String projectName;

  /// When true, uses lower emphasis colors (e.g. when the project is implied by
  /// surrounding UI like a grouped header).
  final bool isTertiary;

  /// Max width before ellipsis.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final backgroundColor = isTertiary
        ? scheme.surfaceContainerHigh
        : scheme.tertiaryContainer.withValues(alpha: 0.55);

    final contentColor = isTertiary ? scheme.onSurfaceVariant : scheme.tertiary;

    return Tooltip(
      message: projectName,
      child: Semantics(
        label: 'Project',
        value: projectName,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.65),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.folder_rounded,
                  size: 12,
                  color: contentColor,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    projectName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: contentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      height: 1.15,
                    ),
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
