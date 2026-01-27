import 'package:flutter/material.dart';

import 'package:taskly_ui/src/forms/taskly_form_preset.dart';
import 'package:taskly_ui/src/primitives/taskly_form_action_row.dart';
import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

class TasklyFormPickerShell extends StatelessWidget {
  const TasklyFormPickerShell({
    required this.title,
    required this.body,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    required this.preset,
    super.key,
  });

  final String title;
  final Widget body;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;
  final TasklyFormPreset preset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = TasklyTokens.of(context);

    return Padding(
      padding: EdgeInsets.all(tokens.spaceXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall,
          ),
          SizedBox(height: tokens.spaceXl),
          body,
          SizedBox(height: tokens.spaceXl),
          TasklyFormActionRow(
            cancelLabel: cancelLabel,
            confirmLabel: confirmLabel,
            onCancel: onCancel,
            onConfirm: onConfirm,
          ),
        ],
      ),
    );
  }
}
