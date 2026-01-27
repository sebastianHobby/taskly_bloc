import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

class TasklyFormProjectRow extends StatelessWidget {
  const TasklyFormProjectRow({
    required this.label,
    required this.hasValue,
    required this.onTap,
    this.icon = Icons.folder_rounded,
    super.key,
  });

  final String label;
  final bool hasValue;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);
    final textColor = hasValue ? scheme.onSurface : scheme.onSurfaceVariant;

    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.radiusMd2),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusMd2),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceMd2,
            vertical: tokens.spaceMd,
          ),
          child: Row(
            children: [
              Container(
                width: tokens.spaceXl + tokens.spaceXs,
                height: tokens.spaceXl + tokens.spaceXs,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(tokens.radiusSm),
                ),
                child: Icon(
                  icon,
                  size: tokens.spaceLg,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: tokens.spaceMd),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: hasValue ? FontWeight.w600 : null,
                  ),
                ),
              ),
              Icon(
                Icons.expand_more,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
