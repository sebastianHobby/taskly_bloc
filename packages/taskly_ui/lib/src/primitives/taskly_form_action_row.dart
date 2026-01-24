import 'package:flutter/material.dart';

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: onCancel,
          child: Text(cancelLabel),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: onConfirm,
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
