import 'package:flutter/material.dart';

import 'package:taskly_ui/src/forms/taskly_form_preset.dart';
import 'package:taskly_ui/src/primitives/taskly_form_action_row.dart';

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

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          body,
          const SizedBox(height: 24),
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
