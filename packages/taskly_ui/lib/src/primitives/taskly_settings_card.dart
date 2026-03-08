import 'package:flutter/material.dart';
import 'package:taskly_ui/src/foundations/theme/taskly_semantic_themes.dart';
import 'package:taskly_ui/src/primitives/taskly_card_surface.dart';
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

  bool get _showExpandAction => onExpandedChanged != null && child != null;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final panelTheme = TasklyPanelTheme.of(context);
    final muted = scheme.onSurfaceVariant;
    final actionLabel = isExpanded ? collapseLabel : expandLabel;
    final actionIcon = isExpanded ? Icons.expand_less : Icons.tune;
    final body = child;
    final subtitleText = subtitle;
    final summaryText = summary;
    final trailingWidget = trailing;
    final titleStyle = density == TasklySettingsCardDensity.regular
        ? textTheme.titleLarge
        : textTheme.titleMedium;
    final summaryStyle = textTheme.labelLarge?.copyWith(
      color: scheme.primary,
      fontWeight: FontWeight.w700,
    );

    return TasklyCardSurface(
      variant: density == TasklySettingsCardDensity.regular
          ? TasklyCardVariant.maintenance
          : TasklyCardVariant.subtle,
      margin: EdgeInsets.zero,
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
                    Text(title, style: titleStyle),
                    if (subtitleText != null) ...[
                      SizedBox(height: tokens.spaceXs2),
                      Text(
                        subtitleText,
                        style: textTheme.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                    if (summaryText != null) ...[
                      SizedBox(height: tokens.spaceSm),
                      Text(summaryText, style: summaryStyle),
                    ],
                  ],
                ),
              ),
              if (trailingWidget != null) ...[
                SizedBox(width: tokens.spaceSm),
                Padding(
                  padding: EdgeInsets.only(top: tokens.spaceXxs),
                  child: trailingWidget,
                ),
              ],
            ],
          ),
          if (_showExpandAction) ...[
            SizedBox(height: tokens.spaceMd),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () => onExpandedChanged?.call(!isExpanded),
                icon: Icon(actionIcon),
                label: Text(actionLabel),
              ),
            ),
          ],
          if (body != null) ...[
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Padding(
                      padding: EdgeInsets.only(top: tokens.spaceMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(
                            height: 1,
                            color: panelTheme.mutedBorder,
                          ),
                          SizedBox(height: tokens.spaceMd),
                          body,
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ],
      ),
    );
  }
}
