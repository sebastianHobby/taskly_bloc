import 'package:flutter/material.dart';
import 'package:taskly_ui/taskly_ui_tokens.dart';

enum TasklySettingsCardDensity { regular, compact }

class TasklySettingsCard extends StatelessWidget {
  const TasklySettingsCard({
    required this.title,
    this.subtitle,
    this.summary,
    this.trailing,
    this.isExpanded = false,
    this.onExpandedChanged,
    this.child,
    this.density = TasklySettingsCardDensity.regular,
    this.expandLabel = 'Configure',
    this.collapseLabel = 'Hide settings',
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? summary;
  final Widget? trailing;
  final bool isExpanded;
  final ValueChanged<bool>? onExpandedChanged;
  final Widget? child;
  final TasklySettingsCardDensity density;
  final String expandLabel;
  final String collapseLabel;

  bool get _showBody => child != null;
  bool get _showExpandAction => onExpandedChanged != null && child != null;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final padding = density == TasklySettingsCardDensity.regular
        ? EdgeInsets.all(tokens.spaceLg)
        : EdgeInsets.all(tokens.spaceMd);
    final actionLabel = isExpanded ? collapseLabel : expandLabel;
    final actionIcon = isExpanded ? Icons.expand_less : Icons.tune;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.titleMedium),
                      if (subtitle != null) ...[
                        SizedBox(height: tokens.spaceXs2),
                        Text(
                          subtitle!,
                          style: textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                      if (summary != null) ...[
                        SizedBox(height: tokens.spaceXs),
                        Text(
                          summary!,
                          style: textTheme.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  SizedBox(width: tokens.spaceSm),
                  trailing!,
                ],
              ],
            ),
            if (_showExpandAction) ...[
              SizedBox(height: tokens.spaceSm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => onExpandedChanged?.call(!isExpanded),
                  icon: Icon(actionIcon),
                  label: Text(actionLabel),
                ),
              ),
            ],
            if (_showBody) ...[
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                child: isExpanded
                    ? Padding(
                        padding: EdgeInsets.only(top: tokens.spaceSm),
                        child: child,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
