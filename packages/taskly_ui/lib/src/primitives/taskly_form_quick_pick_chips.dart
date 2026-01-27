import 'package:flutter/material.dart';

import 'package:taskly_ui/src/forms/taskly_form_preset.dart';
import 'package:taskly_ui/src/primitives/taskly_form_row_group.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

@immutable
class TasklyFormQuickPickItem {
  const TasklyFormQuickPickItem({
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasized;
}

class TasklyFormQuickPickChips extends StatelessWidget {
  const TasklyFormQuickPickChips({
    required this.items,
    required this.preset,
    super.key,
  });

  final List<TasklyFormQuickPickItem> items;
  final TasklyFormPreset preset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = TasklyTokens.of(context);

    return TasklyFormRowGroup(
      spacing: tokens.spaceSm,
      runSpacing: tokens.spaceSm,
      children: [
        for (final item in items)
          Material(
            color: item.emphasized
                ? scheme.surfaceContainerHigh
                : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(tokens.radiusPill),
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(tokens.radiusPill),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: preset.chip.padding.horizontal / 2,
                  vertical: preset.chip.padding.vertical,
                ),
                child: Text(
                  item.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: item.emphasized ? FontWeight.w700 : null,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
