import 'package:flutter/material.dart';

import 'package:taskly_ui/src/foundations/tokens/taskly_tokens.dart';

class TasklyFormActionRow extends StatelessWidget {
  const TasklyFormActionRow({
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    super.key,
  });

  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final tokens = TasklyTokens.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancel,
          child: Text(cancelLabel),
        ),
        SizedBox(width: tokens.spaceSm),
        FilledButton(
          onPressed: onConfirm,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
